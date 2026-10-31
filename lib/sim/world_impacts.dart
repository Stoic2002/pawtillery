part of 'world.dart';

/// Blasts, damage and knockback; projectiles, mines and map objects each
/// tick; units moving, dashing, drowning and dying; where teleports and
/// walls may go.
extension _Impacts on SimWorld {
  /// Starter objects on flat ground away from the units ([unitPoints]):
  /// mines (armed from the first turn), barrels and crates.
  void _placeObjects(ObjectMix mix, List<(int, int)> unitPoints) {
    final points = findObjectPoints(
      terrain: terrain,
      waterLevel: waterLevel,
      count: mix.total,
      rng: rng,
      avoid: unitPoints,
      minDistance: ObjectConfig.minDistanceBetween,
      avoidDistance: ObjectConfig.minDistanceFromUnits,
    );
    final kinds = [
      for (var i = 0; i < mix.mines; i++) null,
      for (var i = 0; i < mix.barrels; i++) ObjectKind.barrel,
      for (var i = 0; i < mix.healthCrates; i++) ObjectKind.healthCrate,
      for (var i = 0; i < mix.weaponCrates; i++) ObjectKind.weaponCrate,
    ];
    for (var i = 0; i < points.length; i++) {
      final (x, y) = points[i];
      final kind = kinds[i];
      if (kind == null) {
        _mines.add(Mine(
          id: _nextMineId++,
          weapon: Weapons.mine,
          x: x.toDouble(),
          y: y.toDouble(),
          armedOnTurn: 0,
        )..grounded = true);
      } else {
        addObject(kind, x, y);
      }
    }
  }

  /// Damage with linear falloff and knockback to every living unit in
  /// range, optionally carving terrain, and sets off nearby mines.
  void _blast(
    int x,
    int y,
    WeaponDef weapon, {
    required DamageCause cause,
    bool carve = false,
    int? excludeUnitId,
    int? sourceId,
  }) {
    final radius = weapon.radius;
    final carved = carve ? terrain.carveCircle(x, y, radius) : null;
    _events.add(ExplosionEvent(x: x, y: y, radius: radius, carved: carved));

    for (final u in _units) {
      if (!u.alive || u.id == excludeUnitId) continue;
      final dx = u.centerX - x;
      final dy = u.centerY - y;
      final dist = sqrt(dx * dx + dy * dy);
      final edge = dist - u.stats.hitRadius;
      final damage = Damage.explosion(
        maxDamage: weapon.maxDamage,
        radius: radius,
        distance: edge < 0 ? 0 : edge,
      );
      if (damage == 0) continue;
      if (!_damage(u, damage, cause, sourceId: sourceId)) continue;
      _knockback(u, damage, dist > 0 ? dx / dist : 0.0,
          dist > 0 ? dy / dist : -1.0, weapon.knockbackScale);
    }

    for (final m in _mines) {
      final dx = m.x - x;
      final dy = m.centerY - y;
      if (dx * dx + dy * dy <= radius * radius) {
        m.countdown = min(m.countdown ?? 1, 1);
      }
    }

    final reach = radius + ObjectConfig.size / 2;
    for (final o in _objects) {
      final dx = o.x - x;
      final dy = o.centerY - y;
      if (dx * dx + dy * dy <= reach * reach) _hitObject(o);
    }
  }

  /// Caught in a blast or a beam: a barrel lights (and blows up shortly),
  /// a crate breaks.
  void _hitObject(MapObject o) {
    if (o.kind == ObjectKind.barrel) {
      o.fuse = min(o.fuse ?? ObjectConfig.barrelFuseTicks,
          ObjectConfig.barrelFuseTicks);
    } else {
      o.destroyed = true;
    }
  }

  /// Objects fall when the ground under them goes; lit barrels count down
  /// and explode; a unit touching a crate picks it up.
  void _stepObjects() {
    for (var i = _objects.length - 1; i >= 0; i--) {
      if (i >= _objects.length) continue;
      final o = _objects[i];
      if (o.destroyed) continue;
      final move = MinePhysics.step(o, terrain, waterLevel);
      if (move == MineMove.water || move == MineMove.outOfBounds) {
        o.destroyed = true;
        continue;
      }
      final fuse = o.fuse;
      if (fuse != null) {
        if (fuse <= 1) {
          _objects.removeAt(i);
          _events.add(ObjectRemoved(o.id));
          _blast(o.x.round(), o.centerY.round(), Weapons.barrel,
              cause: DamageCause.explosion, carve: true);
        } else {
          o.fuse = fuse - 1;
        }
        continue;
      }
      if (o.kind == ObjectKind.barrel) continue;
      for (final u in _units) {
        if (!u.alive) continue;
        final dx = u.centerX - o.x;
        final dy = u.centerY - o.centerY;
        const r = ObjectConfig.pickupRadius;
        if (dx * dx + dy * dy <= r * r) {
          _collect(u, o);
          o.destroyed = true;
          break;
        }
      }
    }
    for (var i = _objects.length - 1; i >= 0; i--) {
      if (!_objects[i].destroyed) continue;
      _events.add(ObjectRemoved(_objects[i].id));
      _objects.removeAt(i);
    }
  }

  /// Health crate: HP up to the unit's maximum. Weapon crate: one more of
  /// a random limited weapon this match uses, for the unit's team.
  void _collect(Unit u, MapObject crate) {
    if (crate.kind == ObjectKind.healthCrate) {
      final before = u.hp;
      u
        ..hp = min(u.stats.maxHp, u.hp + ObjectConfig.healthAmount)
        ..poisoned = false;
      _events.add(CrateCollected(u.id, health: true, hp: u.hp - before));
      return;
    }
    final ammo = _ammo[u.team];
    final choices = [
      for (final w in Weapons.shared)
        if (loadout.enabled(w) && ammo[w.id] != null) w,
    ];
    if (choices.isEmpty) {
      _events.add(CrateCollected(u.id, health: false));
      return;
    }
    final w = choices[rng.nextIntInRange(0, choices.length - 1)];
    ammo[w.id] = ammo[w.id]! + 1;
    _events.add(CrateCollected(u.id, health: false, weaponId: w.id));
  }

  /// Applies [amount] of damage, with the unit's damage-taken modifier for
  /// explosions and its lethal save (Kucing) if it has one left.
  ///
  /// A shield takes the hit instead (not a fall or the water): returns
  /// false then, so the caller skips knockback and other effects.
  bool _damage(Unit u, int amount, DamageCause cause, {int? sourceId}) {
    if (u.shielded &&
        cause != DamageCause.fall &&
        cause != DamageCause.water) {
      u.shielded = false;
      _lastHitTick = _tick;
      _events.add(ShieldPopped(u.id, blocked: true));
      return false;
    }
    var dealt = amount;
    if (cause == DamageCause.explosion) {
      dealt = (amount * u.stats.explosionDamageScale).round();
      if (dealt < 1) dealt = 1;
    }
    if (twist == MatchTwist.oneHit &&
        dealt > 0 &&
        cause != DamageCause.fall &&
        cause != DamageCause.poison) {
      dealt = u.hp;
    }
    if (u.hp > 0 && u.hp - dealt <= 0 && u.lethalSavesLeft > 0) {
      dealt = u.hp - 1;
      u.lethalSavesLeft--;
      _events.add(UnitSaved(u.id, SaveKind.lethal));
    }
    if (dealt <= 0) return true;
    u.hp -= dealt;
    _lastHitTick = _tick;
    _events.add(UnitDamaged(u.id, dealt, cause, sourceUnitId: sourceId));
    return true;
  }

  void _knockback(
      Unit u, int damage, double dirX, double dirY, double knockbackScale) {
    final speed = damage * UnitConfig.knockbackPerDamage * knockbackScale;
    UnitPhysics.launch(
        u, dirX * speed, (dirY - UnitConfig.knockbackLift) * speed);
  }

  void _stepProjectiles() {
    for (var i = _projectiles.length - 1; i >= 0; i--) {
      final p = _projectiles[i];
      final outcome = FlightBehavior.of(p.weapon).tick(p, this);
      if (outcome == FlightOutcome.flying) continue;
      _projectiles.removeAt(i);
      _events.add(ProjectileRemoved(p.id, outcome, x: p.x, y: p.y));
    }
    _projectiles.addAll(_spawned);
    _spawned.clear();
  }

  void _stepMines() {
    for (var i = _mines.length - 1; i >= 0; i--) {
      final m = _mines[i];
      final move = MinePhysics.step(m, terrain, waterLevel);
      if (move == MineMove.water || move == MineMove.outOfBounds) {
        _mines.removeAt(i);
        _events.add(MineRemoved(m.id));
        continue;
      }
      final countdown = m.countdown;
      if (countdown != null) {
        if (countdown <= 1) {
          _mines.removeAt(i);
          _events.add(MineRemoved(m.id));
          _blast(m.x.round(), m.centerY.round(), m.weapon,
              cause: DamageCause.explosion, carve: true, sourceId: m.ownerId);
        } else {
          m.countdown = countdown - 1;
        }
        continue;
      }
      if (!m.grounded || turn.turnNumber < m.armedOnTurn) continue;
      for (final u in _units) {
        if (!u.alive) continue;
        final dx = u.centerX - m.x;
        final dy = u.centerY - m.centerY;
        const r = MineConfig.triggerRadius;
        if (dx * dx + dy * dy <= r * r) {
          m.countdown = MineConfig.triggerDelayTicks;
          _events.add(MineTriggered(m.id));
          break;
        }
      }
    }
  }

  void _stepUnits(int walkDir) {
    final active = activeUnit;
    for (final u in _units) {
      if (!u.alive) continue;
      if (u.isDigging) {
        // Held in its tunnel (no gravity) until digging ends.
        u.digTicks--;
        if (u.digTicks <= 0 || u.digLeft <= 0 ||
            turn.phase != TurnPhase.action) {
          _stopDigging(u);
        }
      } else if (u.isDashing) {
        _stepDash(u);
      } else if (u.isGrappling) {
        _stepGrapple(u);
      } else {
        if (walkDir != 0 && u == active) {
          UnitPhysics.walk(u, walkDir, terrain);
        }
        UnitPhysics.checkSupport(u, terrain);
        if (!u.grounded) {
          final fell = UnitPhysics.stepAirborne(u, terrain);
          if (fell != null) _events.add(UnitLanded(u.id, fell));
          if (fell != null && u.stats.fallDamage) {
            final damage =
                Damage.fall(fell, threshold: u.stats.fallDamageThreshold);
            if (damage > 0) _damage(u, damage, DamageCause.fall);
          }
        }
      }
      _checkBounds(u);
    }
  }

  /// Water and leaving the map kill at once (PRD: Gerak unit), unless the
  /// unit can be rescued from the water (Bebek).
  void _checkBounds(Unit u) {
    if (u.x < 0 || u.x >= terrain.width || u.y >= terrain.height) {
      _kill(u, DeathCause.outOfBounds);
    } else if (u.centerY >= waterLevel) {
      if (u.waterSavesLeft > 0 && _rescueFromWater(u)) return;
      _kill(u, DeathCause.water);
    }
  }

  /// Seruduk: charge sideways, digging, until the distance is covered or a
  /// unit is hit. Gravity is suspended during the charge.
  void _stepDash(Unit u) {
    final weapon = u.dashWeapon!;
    final spec = weapon.delivery as Dash;
    var move = min(u.dashRemaining, spec.speed * PhysicsConfig.dt);
    final carveY = (u.y - spec.carveRadius - 1).round();
    if (u.dashSinceCarve == 0) {
      carveTunnel(u.x.round(), carveY, spec.carveRadius);
    }
    while (move > 0 && u.dashRemaining > 0) {
      final s = min(1.0, move);
      move -= s;
      u
        ..x += u.dashDir * s
        ..dashRemaining -= s
        ..dashSinceCarve += s;
      if (u.x < 0 || u.x >= terrain.width) {
        u.dashRemaining = 0;
        break;
      }
      if (u.dashSinceCarve >= 6) {
        carveTunnel(u.x.round(), carveY, spec.carveRadius);
        u.dashSinceCarve = 0.001;
      }
      for (final v in _units) {
        if (!v.alive || v == u) continue;
        final dx = v.centerX - u.centerX;
        final dy = v.centerY - u.centerY;
        final reach = v.stats.hitRadius + u.stats.hitRadius;
        if (dx * dx + dy * dy <= reach * reach) {
          strikeUnit(v, weapon.maxDamage, u.dashDir.toDouble(), 0,
              weapon.knockbackScale,
              sourceId: u.id);
          u.dashRemaining = 0;
          break;
        }
      }
    }
    if (u.dashRemaining <= 0) {
      carveTunnel(u.x.round(), carveY, spec.carveRadius);
      u
        ..dashRemaining = 0
        ..x = u.x.floorToDouble();
      UnitPhysics.launch(u, 0, 0);
    }
  }

  /// Bebek: costs some HP and puts the unit back on the nearest dry
  /// ground. Returns false if there is no dry ground anywhere.
  bool _rescueFromWater(Unit u) {
    final x0 = u.x.round().clamp(0, terrain.width - 1);
    for (var d = 0; d < terrain.width; d++) {
      for (final x in d == 0 ? [x0] : [x0 - d, x0 + d]) {
        if (x < 0 || x >= terrain.width) continue;
        final y = surfaceY(terrain, x, u.stats.bodyHeight);
        if (y == null || y >= waterLevel - 2) continue;
        u
          ..waterSavesLeft -= 1
          ..x = x.toDouble()
          ..y = y.toDouble()
          ..vx = 0
          ..vy = 0
          ..grounded = true
          ..gliding = false
          ..peakY = y.toDouble();
        _events.add(UnitSaved(u.id, SaveKind.water));
        _damage(u, u.stats.waterSaveDamage, DamageCause.water);
        return true;
      }
    }
    return false;
  }

  void _kill(Unit u, DeathCause cause) {
    u
      ..alive = false
      ..hp = 0
      ..vx = 0
      ..vy = 0
      ..dashRemaining = 0;
    _lastHitTick = _tick;
    _events.add(UnitDied(u.id, cause));
  }

  /// Whether pixel ([px], [py]) is in (or right next to) a living unit's
  /// body column, which added ground must never fill.
  bool _insideAUnit(int px, int py) {
    for (final u in _units) {
      if (!u.alive) continue;
      final cx = u.x.floor();
      if ((px - cx).abs() > 2) continue;
      if (py >= u.y - u.stats.bodyHeight - 2 && py <= u.y) return true;
    }
    return false;
  }

  bool _canTeleportTo(Unit u, int x, int y) {
    final feet = y + u.stats.bodyHeight ~/ 2;
    if (x < 0 || x >= terrain.width || y < 0 || feet >= waterLevel) {
      return false;
    }
    return UnitPhysics.bodyFree(terrain, x, feet, u.stats.bodyHeight);
  }

  IntRect? _wallRect(int cx, int cy, int width, int height) {
    final left = cx - width ~/ 2;
    final top = cy - height ~/ 2;
    if (left < 0 ||
        top < 0 ||
        left + width > terrain.width ||
        top + height > terrain.height) {
      return null;
    }
    return IntRect(left, top, left + width, top + height);
  }

  /// A wall must fit on the map and may not be built on a living unit.
  bool _wallFits(IntRect? r) {
    if (r == null) return false;
    for (final u in _units) {
      if (!u.alive) continue;
      final nx = u.centerX.clamp(r.left.toDouble(), r.right.toDouble());
      final ny = u.centerY.clamp(r.top.toDouble(), r.bottom.toDouble());
      final dx = u.centerX - nx;
      final dy = u.centerY - ny;
      if (dx * dx + dy * dy <= u.stats.hitRadius * u.stats.hitRadius) {
        return false;
      }
    }
    return true;
  }
}
