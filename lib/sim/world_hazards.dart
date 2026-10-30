part of 'world.dart';

/// Poison gas and fire on the ground: clouds drifting and poisoning,
/// patches burning.
extension _Hazards on SimWorld {
  void _releaseGas(double x, double y, int radius,
      {int? sourceId, bool fallout = false}) {
    final count = (pi * radius * radius / (GasConfig.puffSpacing * GasConfig.puffSpacing))
        .round()
        .clamp(GasConfig.minPuffs, GasConfig.maxPuffs);
    final cy = y - radius * 0.3;
    // Packed tight around the release (golden angle); the pressure of
    // being packed is what bursts it outwards.
    final puffs = <GasPuff>[];
    for (var i = 0; i < count; i++) {
      final d = radius * 0.5 * sqrt((i + 0.5) / count);
      final a = i * 137;
      final px = (x + SimTrig.cosDeg(a) * d).clamp(1.0, terrain.width - 2.0);
      var py = cy + SimTrig.sinDeg(a) * d;
      // Never starts inside the ground: comes up out of it.
      for (var k = 0;
          k < radius && terrain.isSolid(px.floor(), py.floor());
          k += 2) {
        py -= 2;
      }
      puffs.add(GasPuff(px, py));
    }
    final cloud = PoisonCloud(
      id: _nextCloudId++,
      radius: radius,
      spacing: sqrt(pi * radius * radius / count),
      puffs: puffs,
      turnsLeft: GasConfig.turns,
      ownerId: sourceId,
      fallout: fallout,
    );
    _clouds.add(cloud);
    _events.add(GasReleased(cloud.id, x, cy));
  }

  /// A puff can't be here: ground, or water (gas lies on top of it).
  bool _gasBlocked(double x, double y) =>
      y >= waterLevel - 1 || terrain.isSolid(x.floor(), y.floor());

  /// How far below (x, y) the gas could sink, up to [GasConfig.seekDepth].
  int _gasDrop(double x, double y) {
    var d = 0;
    while (d < GasConfig.seekDepth && !_gasBlocked(x, y + d + 1)) {
      d++;
    }
    return d;
  }

  /// Heavy gas: falls, pushes itself apart, runs along the ground towards
  /// the lower side (so into any gap), drifts with the wind. It never
  /// moves through the ground.
  void _stepCloud(PoisonCloud c) {
    const dt = PhysicsConfig.dt;
    final puffs = c.puffs;
    final reach = c.spacing;
    for (var i = 0; i < puffs.length; i++) {
      final a = puffs[i];
      for (var j = i + 1; j < puffs.length; j++) {
        final b = puffs[j];
        var dx = b.x - a.x;
        var dy = b.y - a.y;
        final dist2 = dx * dx + dy * dy;
        if (dist2 >= reach * reach) continue;
        var dist = sqrt(dist2);
        if (dist < 0.01) {
          // On the same spot: apart by their order.
          dx = (i + j).isEven ? 1 : -1;
          dy = 0;
          dist = 1;
        }
        final push = (1 - dist / reach) * GasConfig.pressure * dt / dist;
        a
          ..vx -= dx * push
          ..vy -= dy * push;
        b
          ..vx += dx * push
          ..vy += dy * push;
      }
    }
    final windPush =
        _wind * GasConfig.driftPerWind * (1 - GasConfig.damping) / dt;
    for (final p in puffs) {
      // New ground on top of it (clay, a wall): it comes up out of it.
      if (terrain.isSolid(p.x.floor(), p.y.floor())) {
        p
          ..y -= 2
          ..vy = 0;
        continue;
      }
      final grounded = _gasBlocked(p.x, p.y + GasConfig.clearance);
      if (grounded) {
        // Towards the lower side, as far as it can see past no wall.
        var left = 0;
        var right = 0;
        for (var s = GasConfig.seekStep;
            s <= GasConfig.seekStep * 2;
            s += GasConfig.seekStep) {
          if (!_gasBlocked(p.x - s, p.y)) left = max(left, _gasDrop(p.x - s, p.y));
          if (!_gasBlocked(p.x + s, p.y)) right = max(right, _gasDrop(p.x + s, p.y));
        }
        if ((left - right).abs() >= 3) {
          p.vx += (left > right ? -1 : 1) * GasConfig.seekAccel * dt;
        }
      } else {
        p.vy += GasConfig.fallAccel * dt;
      }
      p
        ..vx = (p.vx + windPush * dt) * GasConfig.damping
        ..vy *= GasConfig.damping;
      final mx = (p.vx * dt).clamp(-GasConfig.maxStep, GasConfig.maxStep);
      final my = (p.vy * dt).clamp(-GasConfig.maxStep, GasConfig.maxStep);
      final nx = (p.x + mx).clamp(1.0, terrain.width - 2.0);
      if (!_gasBlocked(nx, p.y)) {
        p.x = nx;
      } else if (!_gasBlocked(nx, p.y - GasConfig.climb)) {
        // Over a small bump.
        p
          ..x = nx
          ..y -= GasConfig.climb;
      } else {
        p.vx *= -0.2;
      }
      final foot = my > 0 ? p.y + my + GasConfig.clearance : p.y + my;
      if (_gasBlocked(p.x, foot)) {
        p.vy = 0;
      } else {
        p.y += my;
      }
    }
  }

  /// The gas reaches a pet from puff [p]: close, with no ground between.
  bool _gasReaches(GasPuff p, Unit u, double reach) {
    final dx = u.centerX - p.x;
    final dy = u.centerY - p.y;
    final dist2 = dx * dx + dy * dy;
    if (dist2 > reach * reach) return false;
    final n = sqrt(dist2) ~/ 2;
    for (var i = 1; i < n; i++) {
      if (terrain.isSolid((p.x + dx * i / n).floor(), (p.y + dy * i / n).floor())) {
        return false;
      }
    }
    return true;
  }

  /// Gas moves (staying over the map) and poisons any pet it reaches; a
  /// shield keeps it out once.
  void _stepGas() {
    if (_clouds.isEmpty || turn.phase == TurnPhase.matchOver) return;
    _clouds.forEach(_stepCloud);
    for (final u in _units) {
      if (!u.alive) continue;
      PoisonCloud? inside;
      search:
      for (final c in _clouds) {
        final reach = c.spacing * GasConfig.puffReach + u.stats.hitRadius * 0.5;
        for (final p in c.puffs) {
          if (_gasReaches(p, u, reach)) {
            inside = c;
            break search;
          }
        }
      }
      if (inside == null) {
        u.gasTicks = 0;
        continue;
      }
      if (!u.poisoned) {
        // A shield keeps the gas out once (and pops).
        if (_damage(u, 0, DamageCause.poison, sourceId: inside.ownerId)) {
          u.poisoned = true;
          _events.add(UnitPoisoned(u.id));
        }
        continue;
      }
      // While it stays inside, the gas keeps biting, a little at a time.
      if (++u.gasTicks < GasConfig.insideIntervalTicks) continue;
      u.gasTicks = 0;
      final amount = min(
        GasConfig.insideDamage,
        min(u.hp - 1, GasConfig.insideMaxPerTurn - u.gasTakenThisTurn),
      );
      if (amount <= 0) continue;
      u.gasTakenThisTurn += amount;
      _damage(u, amount, DamageCause.poison, sourceId: inside.ownerId);
    }
  }

  /// Fire settles onto the ground below it if that is blown away, comes
  /// up out of ground put on it, runs a little way downhill like the
  /// burning liquid it is, goes out in water, and burns any pet touching
  /// it once a turn.
  void _stepFires() {
    final creep = _tick % FireConfig.creepEveryTicks == 0;
    for (var i = _fires.length - 1; i >= 0; i--) {
      final f = _fires[i];
      for (var k = 0; k < 3 && !terrain.isSolid(f.x, f.y); k++) {
        f.y++;
      }
      for (var k = 0; k < 3 && terrain.isSolid(f.x, f.y - 1); k++) {
        f.y--;
      }
      if (f.y >= waterLevel || f.y >= terrain.height) {
        _fires.removeAt(i);
        _events.add(FireOut(f.id));
        continue;
      }
      if (creep && f.creepLeft > 0 && terrain.isSolid(f.x, f.y)) {
        final left = _downhill(f, -1);
        final right = _downhill(f, 1);
        final dir = left == null && right == null
            ? 0
            : right == null || (left != null && left > right)
            ? -1
            : 1;
        if (dir != 0) {
          f
            ..x += dir
            ..y = (dir < 0 ? left : right)!
            ..creepLeft -= 1;
        }
      }
    }
    final phase = turn.phase;
    if (_fires.isEmpty ||
        phase == TurnPhase.turnStart ||
        phase == TurnPhase.matchOver) {
      return;
    }
    for (final u in _units) {
      if (!u.alive || _burnt.contains(u.id)) continue;
      for (final f in _fires) {
        final dx = u.centerX - f.x;
        final dy = u.centerY - (f.y - 5);
        final r = u.stats.hitRadius + FireConfig.reach;
        if (dx * dx + dy * dy > r * r) continue;
        _burnt.add(u.id);
        if (!_damage(u, FireConfig.damage, DamageCause.fire,
                sourceId: f.ownerId)) {
          break;
        }
        if (u.frozen) {
          u.frozenTurns = 0;
          _events.add(UnitThawed(u.id, skippedTurn: false));
        }
        break;
      }
    }
  }

  /// The ground one px to side [dir] of fire [f], if it is lower: its y.
  int? _downhill(FirePatch f, int dir) {
    final x = f.x + dir;
    if (x < 0 || x >= terrain.width || terrain.isSolid(x, f.y - 1)) return null;
    for (var y = f.y; y <= f.y + FireConfig.creepDrop; y++) {
      if (terrain.isSolid(x, y)) return y > f.y ? y : null;
    }
    // A ledge: over it, and it falls.
    return f.y + FireConfig.creepDrop;
  }
}
