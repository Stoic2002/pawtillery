part of 'world.dart';

/// Using a weapon: what each delivery does when fired, and the air
/// support, strikes and held tools (grapple, dig, shotgun) it leaves
/// running.
extension _Weapons on SimWorld {
  void _fire(Unit unit, Fire input) {
    final WeaponDef weapon;
    try {
      weapon = Weapons.byId(input.weaponId);
    } on ArgumentError {
      return;
    }
    if (!canUse(unit, weapon)) return;
    final needsTarget = weapon.aim == AimMode.target;
    final tx = input.targetX;
    final ty = input.targetY;
    if (needsTarget &&
        (tx == null || ty == null || !isValidTarget(unit, weapon, tx, ty))) {
      return;
    }
    final dir = SimWorld._horizontalDir(unit, input.angleDeg);

    if (weapon.delivery case final Shotgun spec) {
      _shotgun(unit, weapon, spec, input.angleDeg);
      return;
    }
    if (weapon.delivery case Grapple(:final length)) {
      _grapple(unit, weapon, input.angleDeg, length);
      return;
    }
    switch (weapon.delivery) {
      case Launch(:final shots, :final spreadDeg)
          when spreadDeg > 0 && shots > 1:
        for (var i = 0; i < shots; i++) {
          final offset = (spreadDeg * (2 * i - (shots - 1))) ~/ (2 * (shots - 1));
          _launchShot(unit, weapon, input, angleDeg: input.angleDeg + offset);
        }
      case Launch(:final shots, :final shotIntervalTicks):
        _launchShot(unit, weapon, input);
        for (var i = 1; i < shots; i++) {
          _pendingShots.add((_tick + i * shotIntervalTicks, unit.id, input));
        }
      case AirStrike(:final childId, :final count, :final spacing,
            :final stagger):
        final child = Weapons.byId(childId);
        for (var i = 0; i < count; i++) {
          spawnProjectile(Projectile(
            id: nextProjectileId(),
            ownerId: unit.id,
            weapon: child,
            x: tx! + (i * 2 - (count - 1)) * spacing / 2,
            y: -280.0 - i * stagger,
            vx: 0,
            vy: 0,
            fuseTicks: child.fuseTicks,
          ));
        }
      case final AirRaid raid:
        _callAirRaid(unit, raid, tx!, ty!);
      case final MeteorShower shower:
        _meteorShower(unit, shower, tx!, ty!);
      case Grapple() || Shotgun():
        break; // Handled above.
      case ShieldUp():
        unit.shielded = true;
        _events.add(ShieldRaised(unit.id));
      case Heal(:final amount):
        final before = unit.hp;
        unit
          ..hp = min(unit.stats.maxHp, unit.hp + amount)
          ..poisoned = false;
        // Held on like a hit, so the heal is seen before the next turn.
        _lastHitTick = _tick;
        _events.add(UnitHealed(unit.id, unit.hp - before));
      case OrbitalStrike(:final delayTicks) ||
          Lightning(:final delayTicks) when delayTicks > 0:
        _strikes.add(PendingStrike(
          dueTick: _tick + delayTicks,
          x: tx!,
          y: ty!,
          ownerId: unit.id,
          weapon: weapon,
          firedTick: _tick,
          // The cloud rides in on the wind; the satellite parks on the
          // side towards the middle of the map, so its beams start on it.
          fromDir: weapon.delivery is OrbitalStrike
              ? (tx < terrain.width / 2 ? 1 : -1)
              : (_wind >= 0 ? -1 : 1),
          originY: switch (weapon.delivery) {
            final OrbitalStrike spec => _parkY(
              tx + (tx < terrain.width / 2 ? 1 : -1) * spec.offset,
              ty - spec.height,
            ),
            _ => 0,
          },
        ));
      case PlaceMine():
        unit.facing = dir;
        spawnMine(weapon, unit.centerX + dir * (unit.stats.hitRadius + 4),
            unit.y - 4, 0, 0,
            ownerId: unit.id);
      case AreaHit(:final reach):
        final cx = unit.centerX + SimTrig.cosDeg(input.angleDeg) * reach;
        final cy = unit.centerY - SimTrig.sinDeg(input.angleDeg) * reach;
        if (reach > 0) unit.facing = dir;
        _blast(cx.round(), cy.round(), weapon,
            cause: DamageCause.impact,
            excludeUnitId: unit.id,
            sourceId: unit.id);
      case Dash(:final distance):
        unit
          ..facing = dir
          ..dashDir = dir
          ..dashRemaining = distance.toDouble()
          ..dashSinceCarve = 0
          ..dashWeapon = weapon;
      case DigMode(:final durationTicks, :final maxDistance):
        unit
          ..digTicks = durationTicks
          ..digLeft = maxDistance;
        // Digging starts with a hole around the body.
        carveTunnel(unit.centerX.round(), unit.centerY.round(),
            (weapon.delivery as DigMode).carveRadius);
      case SwapPlaces():
        final other = ProjectilePhysics.unitAt(
            tx!.toDouble(), ty!.toDouble(), _units)!;
        final (x, y) = (unit.x, unit.y);
        unit
          ..x = other.x
          ..y = other.y;
        other
          ..x = x
          ..y = y;
        UnitPhysics.launch(unit, 0, 0);
        UnitPhysics.launch(other, 0, 0);
        _events
          ..add(UnitTeleported(unit.id))
          ..add(UnitTeleported(other.id));
      case Teleport():
        unit
          ..x = tx!.toDouble()
          ..y = (ty! + unit.stats.bodyHeight ~/ 2).toDouble();
        UnitPhysics.launch(unit, 0, 0);
        _events.add(UnitTeleported(unit.id));
      case BuildWall(:final width, :final height):
        final rect = _wallRect(tx!, ty!, width, height)!;
        terrain.fillRect(rect.left, rect.top, rect.width, rect.height);
        _events.add(TerrainAdded(rect));
      case Beam(:final length, :final carveRadius):
        unit.facing = dir;
        _beam(unit, weapon, input.angleDeg, length, carveRadius);
      case Lightning():
        _lightning(unit.id, weapon, tx!);
      case OrbitalStrike():
        _strikes.add(PendingStrike(
            dueTick: _tick + 1, x: tx!, y: ty!, ownerId: unit.id,
            weapon: weapon, firedTick: _tick));
      case DropCharge():
        final f = unit.facing;
        spawnProjectile(Projectile(
          id: nextProjectileId(),
          ownerId: unit.id,
          weapon: weapon,
          x: unit.centerX + f * (unit.stats.hitRadius + 3),
          y: unit.centerY,
          vx: f * 20,
          vy: -60,
          fuseTicks: weapon.fuseTicks,
        ));
      case SkipTurn():
        break;
      case final SpawnWalker spec:
        final body = WalkerBehavior.makeBody(spec,
            unit.x + dir * (unit.stats.hitRadius + 4), unit.y, dir);
        spawnProjectile(Projectile(
          id: nextProjectileId(),
          ownerId: unit.id,
          weapon: weapon,
          x: body.centerX,
          y: body.centerY,
          vx: 0,
          vy: 0,
          fuseTicks: weapon.fuseTicks,
        )..body = body);
    }

    if (weapon.isSignature) {
      unit.signatureUsed = true;
    } else if (randomWeapons) {
      // A drawn weapon is free.
    } else if (_ammo[unit.team][weapon.id] case final int left) {
      _ammo[unit.team][weapon.id] = left - 1;
    }
    _events.add(WeaponUsed(unit.id, weapon.id));
    turn.hasFired = true;
    // Digging keeps the action phase (and its clock) until it ends.
    if (weapon.delivery is DigMode) return;
    _setPhase(weapon.endsTurn ? TurnPhase.settling : TurnPhase.retreat);
  }

  /// Hujan Meteor: every meteor is in the air at once, stacked high above
  /// the map, so they land one after another. Each falls at a slant with
  /// the wind, aimed to reach the marked height at its landing column.
  void _meteorShower(Unit unit, MeteorShower spec, int tx, int ty) {
    final child = Weapons.byId(spec.childId);
    final g = PhysicsConfig.gravity * child.gravityScale;
    final windDir = _wind >= 0 ? 1 : -1;
    final vx = spec.speed * 0.45;
    for (var i = 0; i < spec.count; i++) {
      final landX = (tx + rng.nextIntInRange(-spec.spread, spec.spread))
          .clamp(4, terrain.width - 5);
      final y0 = -320.0 - i * spec.gap;
      final vy = spec.speed;
      final t = (-vy + sqrt(vy * vy + 2 * g * (ty - y0))) / g;
      var dir = windDir;
      var x0 = landX - dir * vx * t;
      // Coming in from off the map: from the other side instead.
      if (x0 < 1 || x0 > terrain.width - 2) {
        dir = -dir;
        x0 = landX - dir * vx * t;
      }
      spawnProjectile(Projectile(
        id: nextProjectileId(),
        ownerId: unit.id,
        weapon: child,
        x: x0.clamp(1.0, terrain.width - 2.0),
        y: y0,
        vx: dir * vx,
        vy: vy,
      ));
    }
  }

  /// One shotgun pull. The first uses up the weapon and leaves the turn
  /// in the action phase for the rest; the last moves on to the retreat.
  void _shotgun(Unit unit, WeaponDef weapon, Shotgun spec, int angleDeg) {
    if (_shotgunLeft == 0) {
      if (_ammo[unit.team][weapon.id] case final int left) {
        _ammo[unit.team][weapon.id] = left - 1;
      }
      _shotgunLeft = spec.shots;
      _events.add(WeaponUsed(unit.id, weapon.id));
    }
    _shotgunLeft--;
    unit.facing = SimTrig.cosDeg(angleDeg) >= 0 ? 1 : -1;
    final (x0, y0) = SimWorld.launchOrigin(unit, angleDeg);
    final (x, y, hit) = SimWorld.shotgunReach(this, unit, angleDeg, spec.range);
    _events.add(ShotgunFired(unit.id, x0, y0, x, y));
    switch (hit) {
      case final Unit u:
        strikeUnit(u, weapon.maxDamage, SimTrig.cosDeg(angleDeg),
            -SimTrig.sinDeg(angleDeg), weapon.knockbackScale,
            sourceId: unit.id);
      case final MapObject o:
        _hitObject(o);
      case final Mine m:
        m.countdown = min(m.countdown ?? 1, 1);
      case TerrainMask():
        carveTunnel(x.round(), y.round(), spec.carveRadius);
      default:
        break;
    }
    if (_shotgunLeft == 0) {
      turn.hasFired = true;
      _setPhase(TurnPhase.retreat);
    }
  }

  /// Tali Pengait: a hooked shot reels the unit in (see [_stepGrapple]);
  /// only then is a hook used up. Either way the turn goes on.
  void _grapple(Unit unit, WeaponDef weapon, int angleDeg, int length) {
    final (x0, y0) = SimWorld.launchOrigin(unit, angleDeg);
    final (x, y, hooked) =
        SimWorld.grappleReach(terrain, waterLevel, unit, angleDeg, length);
    unit.facing = SimTrig.cosDeg(angleDeg) >= 0 ? 1 : -1;
    _events.add(GrappleFired(unit.id, x0, y0, x, y, hooked));
    if (!hooked) return;
    unit
      ..grappleTicks = GrappleConfig.maxReelTicks
      ..grappleX = x
      ..grappleY = y
      ..grounded = false
      ..gliding = false
      ..vx = 0
      ..vy = 0;
    if (_ammo[unit.team][weapon.id] case final int left) {
      _ammo[unit.team][weapon.id] = left - 1;
    }
    _events.add(WeaponUsed(unit.id, weapon.id));
  }

  /// One tick of being reeled in: the body moves straight at the anchor
  /// (no gravity) until it is there, the ground is in the way, or time is
  /// up. Then it lets go and falls from where it is.
  void _stepGrapple(Unit u) {
    final spec = Weapons.grapple.delivery as Grapple;
    var move = spec.speed * PhysicsConfig.dt;
    var done = --u.grappleTicks <= 0;
    final h = u.stats.bodyHeight;
    while (!done && move > 0) {
      final dx = u.grappleX - u.centerX;
      final dy = u.grappleY - u.centerY;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist <= u.stats.hitRadius + 1) {
        done = true;
        break;
      }
      final s = min(1.0, move);
      move -= s;
      final nx = u.x + dx / dist * s;
      final ny = u.y + dy / dist * s;
      if (nx < 1 ||
          nx >= terrain.width - 1 ||
          !UnitPhysics.bodyFree(terrain, nx.floor(), ny.floor(), h)) {
        done = true;
        break;
      }
      u
        ..x = nx
        ..y = ny;
    }
    if (done) {
      u
        ..grappleTicks = 0
        ..peakY = u.y;
      if (!_pullUpOnto(u)) UnitPhysics.launch(u, 0, 0);
    }
  }

  /// At the end of a reel-in close to the hook: if the hook is in the lip
  /// of a ledge (ground with room for the body on top within a pull-up),
  /// climb onto it. Hooking the top of the ground lands there too.
  bool _pullUpOnto(Unit u) {
    final ax = u.grappleX.floor();
    final ay = u.grappleY.floor();
    final h = u.stats.bodyHeight;
    final dx = u.grappleX - u.centerX;
    final dy = u.grappleY - u.centerY;
    final reach = u.stats.hitRadius + h;
    if (dx * dx + dy * dy > reach * reach) return false;
    for (var foot = ay; foot >= ay - h - GrappleConfig.pullUp; foot--) {
      if (!terrain.isSolid(ax, foot)) return false;
      if (!terrain.isSolid(ax, foot - 1) &&
          UnitPhysics.bodyFree(terrain, ax, foot, h)) {
        u
          ..x = ax.toDouble()
          ..y = foot.toDouble()
          ..vx = 0
          ..vy = 0
          ..grounded = true
          ..gliding = false
          ..peakY = foot.toDouble()
          ..airJumpsLeft = u.stats.airJumps;
        return true;
      }
    }
    return false;
  }

  /// One tick of tunnelling towards [angleDeg]: carves ahead of the body
  /// and moves it, staying inside the map and above the water.
  void _dig(Unit unit, int angleDeg) {
    final spec = Weapons.digClaws.delivery as DigMode;
    final step = min(unit.digLeft, spec.speed * PhysicsConfig.dt);
    if (step <= 0) return;
    final dx = SimTrig.cosDeg(angleDeg) * step;
    final dy = -SimTrig.sinDeg(angleDeg) * step;
    final h = unit.stats.bodyHeight.toDouble();
    final nx = (unit.x + dx).clamp(2.0, terrain.width - 3.0);
    final ny = (unit.y + dy).clamp(h + 2, waterLevel - 2.0);
    unit
      ..x = nx
      ..y = ny
      ..digLeft -= step
      ..vx = 0
      ..vy = 0;
    if (dx.abs() > 1e-9) unit.facing = dx > 0 ? 1 : -1;
    carveTunnel(unit.centerX.round(), unit.centerY.round(), spec.carveRadius);
  }

  /// Dig mode is over: the unit drops from wherever it is and the retreat
  /// starts.
  void _stopDigging(Unit unit) {
    unit
      ..digTicks = 0
      ..digLeft = 0;
    UnitPhysics.launch(unit, 0, 0);
    if (turn.phase == TurnPhase.action) _setPhase(TurnPhase.retreat);
  }

  void _launchShot(Unit unit, WeaponDef weapon, Fire input, {int? angleDeg}) {
    final angle = angleDeg ?? input.angleDeg;
    final p = SimWorld.shotFor(
      unit,
      weapon,
      id: nextProjectileId(),
      angleDeg: angle,
      powerPercent: input.powerPercent,
      fuseTicks: input.fuseTicks,
    );
    final dirX = SimTrig.cosDeg(angle);
    if (dirX.abs() > 1e-9) unit.facing = dirX > 0 ? 1 : -1;
    spawnProjectile(p);
  }

  /// The satellite parks at [wanted] (world y) or higher, clear of any
  /// ground under its [SimWorld.satelliteClearance] wide body at column [x].
  double _parkY(int x, int wanted) {
    var top = wanted;
    const reach = SimWorld.satelliteClearance;
    for (var cx = x - reach; cx <= x + reach; cx += 12) {
      for (var y = 0; y < wanted + reach; y++) {
        if (terrain.isSolid(cx, y)) {
          if (y - reach < top) top = y - reach;
          break;
        }
      }
    }
    return top.toDouble();
  }

  /// Air raids come from the shooter's side of the target. Free-falling
  /// payloads are released early by the distance they drift while falling
  /// from the craft to the ground under the tapped column (or the water),
  /// so they land around it wherever in the column the player tapped; a
  /// guided payload is released [AirRaid.releaseAhead] before the spot.
  void _callAirRaid(Unit unit, AirRaid raid, int tx, int ty) {
    final payload = Weapons.byId(raid.childId);
    final dir = tx >= unit.centerX ? 1 : -1;
    final ahead = raid.releaseAhead;
    final double lead;
    if (ahead != null) {
      lead = ahead.toDouble();
    } else {
      var ground = raid.altitude;
      while (ground < waterLevel && !terrain.isSolid(tx, ground)) {
        ground++;
      }
      final height = ground - raid.altitude;
      final fallSeconds = height > 0
          ? sqrt(2 * height / (PhysicsConfig.gravity * payload.gravityScale))
          : 0.0;
      lead = raid.speed * fallSeconds;
    }
    final drops = [
      for (var i = 0; i < raid.count; i++)
        (tx + dir * ((i * 2 - (raid.count - 1)) * raid.spacing / 2 - lead))
            .clamp(0, terrain.width - 1)
            .toDouble(),
    ];
    _aircraft.add(Aircraft(
      ownerId: unit.id,
      craft: raid.craft,
      payload: payload,
      dir: dir,
      x: drops.first - dir * raid.leadIn,
      y: raid.altitude.toDouble(),
      speed: raid.speed,
      dropXs: drops,
      exitX: drops.last + dir * raid.leadIn,
      targetX: tx.toDouble(),
      targetY: ty.toDouble(),
    ));
  }

  /// Moves aircraft (dropping their payload as they pass their release
  /// points) and lands strikes from the sky that are due.
  void _stepAirSupport() {
    for (var i = _aircraft.length - 1; i >= 0; i--) {
      final b = _aircraft[i];
      b.x += b.dir * b.speed * PhysicsConfig.dt;
      while (b.dropped < b.dropXs.length &&
          (b.dir > 0
              ? b.x >= b.dropXs[b.dropped]
              : b.x <= b.dropXs[b.dropped])) {
        final x = b.dropXs[b.dropped++];
        final y = b.y + 8;
        final p = Projectile(
          id: nextProjectileId(),
          ownerId: b.ownerId,
          weapon: b.payload,
          x: x,
          y: y,
          vx: b.dir * b.speed,
          vy: 0,
          fuseTicks: b.payload.fuseTicks,
        );
        if (b.payload.flight case Homing(chosenTarget: true)) {
          p
            ..targetX = b.targetX
            ..targetY = b.targetY;
        }
        spawnProjectile(p);
        _events.add(BombDropped(x, y));
      }
      if (b.gone) _aircraft.removeAt(i);
    }
    for (var i = _strikes.length - 1; i >= 0; i--) {
      final strike = _strikes[i];
      if (strike.dueTick > _tick) continue;
      _strikes.removeAt(i);
      if (strike.weapon.delivery case final OrbitalStrike spec) {
        _orbital(strike);
        if (strike.shot + 1 < spec.beams) {
          _strikes.add(strike.nextShot(_tick + spec.intervalTicks));
        }
      } else {
        _lightning(strike.ownerId, strike.weapon, strike.x);
      }
    }
  }

  /// Satelit: fires beam [PendingStrike.shot] from the satellite through
  /// its aim point. It burns a channel only [OrbitalStrike.depth] px past
  /// the first ground or pet it meets, hits every unit within reach of its
  /// line once (pushed along the beam), and sets off mines and objects on
  /// it.
  void _orbital(PendingStrike strike) {
    final weapon = strike.weapon;
    final spec = weapon.delivery as OrbitalStrike;
    final ((ox, oy), aims) = SimWorld.satelliteAim(strike);
    final (ax, ay) = aims[strike.shot];
    final len = sqrt((ax - ox) * (ax - ox) + (ay - oy) * (ay - oy));
    final dx = (ax - ox) / len;
    final dy = (ay - oy) / len;
    var x = ox;
    var y = oy;
    var burnt = -1;
    final hit = <int>{};
    for (var d = 0; burnt < spec.depth; d++) {
      final nx = ox + dx * d;
      final ny = oy + dy * d;
      if (nx < 0 || nx >= terrain.width || ny >= waterLevel ||
          ny >= terrain.height) {
        break;
      }
      x = nx;
      y = ny;
      if (burnt < 0 &&
          (terrain.isSolid(nx.floor(), ny.floor()) ||
              ProjectilePhysics.unitAt(nx, ny, _units) != null)) {
        burnt = 0;
      }
      if (burnt >= 0) {
        if (burnt % 3 == 0) {
          terrain.carveCircle(nx.round(), ny.round(), spec.carveRadius);
        }
        burnt++;
      }
      for (final u in _units) {
        if (!u.alive || hit.contains(u.id)) continue;
        final ux = u.centerX - nx;
        final uy = u.centerY - ny;
        final r = weapon.radius + u.stats.hitRadius;
        if (ux * ux + uy * uy <= r * r) {
          hit.add(u.id);
          strikeUnit(u, weapon.maxDamage, dx, dy, weapon.knockbackScale,
              sourceId: strike.ownerId);
        }
      }
      for (final m in _mines) {
        final mx = m.x - nx;
        final my = m.centerY - ny;
        if (mx * mx + my * my <= weapon.radius * weapon.radius + 36) {
          m.countdown = min(m.countdown ?? 1, 1);
        }
      }
      for (final o in _objects) {
        final px = o.x - nx;
        final py = o.centerY - ny;
        final r = ObjectConfig.size / 2 + weapon.radius;
        if (px * px + py * py <= r * r) _hitObject(o);
      }
    }
    _events.add(SatelliteStruck(ox, oy, x, y, spec.carveRadius,
        last: strike.shot + 1 >= spec.beams));
  }

  /// Laser: walks the line 1 px at a time from the launch point, burning
  /// the ground every few px, hitting each unit once and setting off mines
  /// it touches. Stops at the map edge or the water.
  void _beam(Unit unit, WeaponDef weapon, int angleDeg, int length, int radius) {
    final (x0, y0) = SimWorld.launchOrigin(unit, angleDeg);
    final dx = SimTrig.cosDeg(angleDeg);
    final dy = -SimTrig.sinDeg(angleDeg);
    var x = x0;
    var y = y0;
    final hit = <int>{};
    for (var d = 0; d < length; d++) {
      final nx = x0 + dx * d;
      final ny = y0 + dy * d;
      if (nx < 0 || nx >= terrain.width || ny < 0 || ny >= terrain.height ||
          ny >= waterLevel) {
        break;
      }
      x = nx;
      y = ny;
      if (d % 3 == 0) terrain.carveCircle(x.round(), y.round(), radius);
      for (final u in _units) {
        if (!u.alive || u.id == unit.id || hit.contains(u.id)) continue;
        final ux = u.centerX - x;
        final uy = u.centerY - y;
        final r = u.stats.hitRadius;
        if (ux * ux + uy * uy <= r * r) {
          hit.add(u.id);
          strikeUnit(u, weapon.maxDamage, dx, dy, weapon.knockbackScale,
              sourceId: unit.id);
        }
      }
      for (final m in _mines) {
        final mx = m.x - x;
        final my = m.centerY - y;
        if (mx * mx + my * my <= 36) m.countdown = min(m.countdown ?? 1, 1);
      }
      for (final o in _objects) {
        final ox = o.x - x;
        final oy = o.centerY - y;
        const r = ObjectConfig.size / 2 + 2;
        if (ox * ox + oy * oy <= r * r) _hitObject(o);
      }
    }
    _events.add(BeamFired(x0, y0, x, y, radius));
  }

  /// Thunder Cloud: the bolt runs down column [x] from the top of the map
  /// and blasts the first ground or living unit; over open water it fizzles
  /// at the surface.
  void _lightning(int ownerId, WeaponDef weapon, int x) {
    var y = 0;
    while (y < waterLevel && y < terrain.height) {
      if (terrain.isSolid(x, y) ||
          ProjectilePhysics.unitAt(x + 0.5, y + 0.5, _units) != null) {
        break;
      }
      y++;
    }
    _events.add(LightningStruck(x, y));
    _blast(x, y, weapon,
        cause: DamageCause.explosion,
        carve: weapon.terrainDamage,
        sourceId: ownerId);
  }

  void _firePendingShots() {
    for (var i = _pendingShots.length - 1; i >= 0; i--) {
      final (due, unitId, input) = _pendingShots[i];
      if (due > _tick) continue;
      _pendingShots.removeAt(i);
      final unit = _units[unitId];
      if (unit.alive) _launchShot(unit, Weapons.byId(input.weaponId), input);
    }
  }

  /// Random weapons: one weapon for [unit]'s turn, drawn from the shared
  /// weapons this match uses (no tools) and its unused signature weapon.
  void _drawWeapon(Unit unit) {
    final family = unit.familyId == null ? null : Families.byId(unit.familyId!);
    final pool = [
      for (final w in Weapons.shared)
        if (loadout.enabled(w) && Weapons.groupOf(w) != WeaponGroup.tools) w,
      if (family != null && !unit.signatureUsed)
        if (Weapons.byId(family.signatureWeaponId) case final sig
            when loadout.enabled(sig))
          sig,
    ];
    _drawn = pool.isEmpty
        ? null
        : pool[rng.nextIntInRange(0, pool.length - 1)].id;
    if (_drawn case final id?) _events.add(WeaponDrawn(unit.id, id));
  }
}
