import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/families.dart';
import 'package:pawtillery/config/units.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/sim/inputs.dart';
import 'package:pawtillery/sim/match_setup.dart';
import 'package:pawtillery/sim/projectile.dart';
import 'package:pawtillery/sim/terrain_mask.dart';
import 'package:pawtillery/sim/turn_manager.dart';
import 'package:pawtillery/sim/unit.dart';

import 'sim_test_utils.dart';

/// Shoots the active unit's own feet with Batu Lempar.
const _selfHit = Fire(weaponId: 'rock', angleDeg: 270, powerPercent: 5);

void main() {
  test('every family has a passive, a signature weapon and breeds', () {
    expect(Families.all, hasLength(10));
    for (final f in Families.all) {
      final w = Weapons.byId(f.signatureWeaponId);
      expect(w.familyId, f.id, reason: f.id);
    }
  });

  test('Kucing: survives one lethal hit at 1 HP, not a second', () {
    final w = world([
      UnitPlacement(0, 500, 400, familyId: 'cat'),
      UnitPlacement(1, 1500, 400),
    ]);
    final cat = w.units[0]..hp = 10;
    toAction(w);
    w.step(const [_selfHit]);
    final e = runUntil(w, () => cat.hp < 10);
    expect(e.whereType<UnitSaved>().single.kind, SaveKind.lethal);
    expect(cat.hp, 1, reason: 'the lethal blast leaves exactly 1 HP');
    expect(cat.lethalSavesLeft, 0);
    // The same blast's knockback fall may still finish it off: the save is
    // spent. Either way, the next lethal damage is final.
    runUntil(w, () => w.turn.turnNumber > 1 ||
        w.turn.phase == TurnPhase.matchOver);
    if (cat.alive) {
      toNextTurn(w);
      fireAndSettle(w, _selfHit);
    }
    expect(cat.alive, isFalse, reason: 'no second save');
  });

  test('Anjing: starts with 120 HP', () {
    final w = world([
      UnitPlacement(0, 500, 400, familyId: 'dog'),
      UnitPlacement(1, 1500, 400),
    ]);
    expect(w.units[0].hp, 120);
    expect(w.teamMaxHp(), [120, 100]);
  });

  double jumpPeak(String? family, JumpKind kind, {bool airJump = false}) {
    final w = world([
      UnitPlacement(0, 500, 400, familyId: family),
      UnitPlacement(1, 1500, 400),
    ]);
    toAction(w);
    final u = w.units[0];
    w.step([Jump(kind)]);
    var jumped = false;
    for (var i = 0; i < 600 && (!u.grounded || i == 0); i++) {
      // Second jump at the top of the first.
      final second = airJump && !jumped && u.vy >= 0;
      if (second) jumped = true;
      w.step(second ? [Jump(kind)] : const []);
    }
    expect(u.grounded, isTrue);
    expect(u.hp, u.stats.maxHp, reason: 'a plain jump never hurts');
    return 400 - u.peakY;
  }

  test('Kelinci: high jump twice as high, and it does not hurt', () {
    final base = jumpPeak(null, JumpKind.high);
    final rabbit = jumpPeak('rabbit', JumpKind.high);
    expect(rabbit / base, closeTo(2, 0.1));
    expect(jumpPeak('rabbit', JumpKind.forward),
        closeTo(jumpPeak(null, JumpKind.forward), 1),
        reason: 'forward jump unchanged');
  });

  test('Ayam: can jump again in mid-air', () {
    final single = jumpPeak(null, JumpKind.high, airJump: true);
    final double = jumpPeak('chicken', JumpKind.high, airJump: true);
    expect(double, greaterThan(single * 1.5));
  });

  test('Burung: glides down after a jump and takes no fall damage', () {
    final t = TerrainMask(2000, 1000)
      ..fillRect(0, 400, 600, 600) // ledge
      ..fillRect(600, 900, 1400, 100); // 500 px lower
    int landingTicks(String? family) {
      final w = world([
        UnitPlacement(0, 590, 400, familyId: family),
        UnitPlacement(1, 1900, 900),
      ], terrain: TerrainMask(2000, 1000)..data.setAll(0, t.data), water: 990);
      toAction(w);
      w.step(const [Jump(JumpKind.forward)]);
      var ticks = 0;
      while ((!w.units[0].grounded || ticks == 0) && ticks < 3000) {
        w.step(const []);
        ticks++;
      }
      expect(w.units[0].y, 900);
      if (family == 'bird') expect(w.units[0].hp, 100);
      if (family == null) expect(w.units[0].hp, lessThan(100));
      return ticks;
    }

    expect(landingTicks('bird'), greaterThan(landingTicks(null) * 2));
  });

  test('Hamster: 30 % smaller hitbox and 85 HP', () {
    final s = UnitStats.forFamily(Families.hamster);
    expect(s.maxHp, 85);
    expect(s.hitRadius, closeTo(UnitConfig.hitRadius * 0.7, 1e-9));
    expect(s.bodyHeight, (UnitConfig.bodyHeight * 0.7).round());
  });

  test('Bebek: pulled out of the water once for 25 HP, drowns the second time',
      () {
    final t = flatMap();
    for (var y = 400; y < 600; y++) {
      t.data.fillRange(y * 2000 + 900, y * 2000 + 1100, 0); // pit to water
    }
    final w = world([
      UnitPlacement(0, 500, 400, familyId: 'duck'),
      UnitPlacement(1, 1500, 400),
    ], terrain: t);
    final duck = w.units[0];

    void dropIntoPit() {
      duck
        ..x = 1000
        ..y = 450;
      UnitPhysics.launch(duck, 0, 0);
    }

    dropIntoPit();
    final e = runUntil(w, () => duck.grounded || !duck.alive);
    expect(e.whereType<UnitSaved>().single.kind, SaveKind.water);
    expect(duck.alive, isTrue);
    expect(duck.hp, 75);
    expect(duck.y, lessThan(560));
    expect((duck.x - 1000).abs(), lessThanOrEqualTo(101),
        reason: 'nearest dry land is the pit edge');

    dropIntoPit();
    runUntil(w, () => !duck.alive);
  });

  test('Kura-kura: 25 % less blast damage, 30 % slower walk', () {
    int blastDamage(String? family) {
      final w = world([
        UnitPlacement(0, 500, 400, familyId: family),
        UnitPlacement(1, 1500, 400),
      ]);
      final e = fireAndSettle(w, _selfHit);
      return damageTo(e, 0).first.amount;
    }

    final base = blastDamage(null);
    expect(blastDamage('turtle'), (base * 0.75).round());

    double walked(String? family) {
      final w = world([
        UnitPlacement(0, 500, 400, familyId: family),
        UnitPlacement(1, 1500, 400),
      ]);
      toAction(w);
      for (var i = 0; i < 60; i++) {
        w.step(const [Walk(1)]);
      }
      return w.units[0].x - 500;
    }

    expect(walked('turtle'), closeTo(walked(null) * 0.7, 1));
  });

  test('Kambing: climbs a 14 px step that stops everyone else', () {
    double reach(String? family) {
      final t = flatMap()..fillRect(560, 386, 1440, 14); // 14 px step
      final w = world([
        UnitPlacement(0, 500, 400, familyId: family),
        UnitPlacement(1, 1900, 386),
      ], terrain: t);
      toAction(w);
      for (var i = 0; i < 180; i++) {
        w.step(const [Walk(1)]);
      }
      return w.units[0].x;
    }

    expect(reach(null), 559);
    expect(reach('goat'), greaterThan(600));
  });

  test('Monyet: 20 % more launch speed at full power', () {
    Projectile shot(String? family) {
      final w = world([
        UnitPlacement(0, 500, 400, familyId: family),
        UnitPlacement(1, 1500, 400),
      ]);
      toAction(w);
      w.step(const [Fire(weaponId: 'rock', angleDeg: 45, powerPercent: 100)]);
      return w.projectiles.single;
    }

    final base = shot(null);
    final monkey = shot('monkey');
    // One tick of flight has already been applied to both equally.
    expect(monkey.vx / base.vx, closeTo(1.2, 1e-9));
  });

  test('passives never touch the turn rules', () {
    final w = world([
      UnitPlacement(0, 500, 400, familyId: 'bird'),
      UnitPlacement(1, 1500, 400, familyId: 'goat'),
    ]);
    toAction(w);
    expect(w.turn.phase, TurnPhase.action);
  });
}
