part of 'world.dart';

/// Poison gas and fire on the ground: clouds drifting and poisoning,
/// patches burning.
extension _Hazards on SimWorld {
  void _releaseGas(double x, double y, int radius,
      {int? sourceId, bool fallout = false}) {
    final cloud = PoisonCloud(
      id: _nextCloudId++,
      x: x,
      y: y - radius * 0.3,
      radius: radius,
      turnsLeft: GasConfig.turns,
      ownerId: sourceId,
      fallout: fallout,
    );
    _clouds.add(cloud);
    _events.add(GasReleased(cloud.id, cloud.x, cloud.y));
  }

  /// Gas drifts with the wind (staying over the map) and poisons any pet
  /// inside it; a shield keeps it out once.
  void _stepGas() {
    if (_clouds.isEmpty || turn.phase == TurnPhase.matchOver) return;
    for (final c in _clouds) {
      c.x = (c.x + _wind * GasConfig.driftPerWind * PhysicsConfig.dt)
          .clamp(0.0, terrain.width - 1.0);
    }
    for (final u in _units) {
      if (!u.alive) continue;
      PoisonCloud? inside;
      for (final c in _clouds) {
        final dx = u.centerX - c.x;
        final dy = u.centerY - c.y;
        final r = c.radius + u.stats.hitRadius * 0.5;
        if (dx * dx + dy * dy <= r * r) {
          inside = c;
          break;
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

  /// Fire settles onto the ground below it if that is blown away, goes out
  /// in water, and burns any pet touching it once a turn.
  void _stepFires() {
    for (var i = _fires.length - 1; i >= 0; i--) {
      final f = _fires[i];
      for (var k = 0; k < 3 && !terrain.isSolid(f.x, f.y); k++) {
        f.y++;
      }
      if (f.y >= waterLevel || f.y >= terrain.height) {
        _fires.removeAt(i);
        _events.add(FireOut(f.id));
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
}
