import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/sim/damage.dart';

void main() {
  group('explosion falloff', () {
    int dmg(double d) =>
        Damage.explosion(maxDamage: 45, radius: 40, distance: d);

    test('full damage at the centre, linear towards the edge', () {
      expect(dmg(0), 45);
      expect(dmg(20), 23); // 22.5 rounds up
      expect(dmg(10), 34); // 33.75
    });

    test('at least 1 anywhere inside the radius', () {
      expect(dmg(39.9), 1);
    });

    test('nothing at or beyond the radius', () {
      expect(dmg(40), 0);
      expect(dmg(100), 0);
    });
  });

  group('fall damage', () {
    test('nothing up to the 120 px threshold', () {
      expect(Damage.fall(0), 0);
      expect(Damage.fall(120), 0);
      expect(Damage.fall(123.9), 0);
    });

    test('1 HP per 4 px beyond it', () {
      expect(Damage.fall(124), 1);
      expect(Damage.fall(160), 10);
    });

    test('capped at 40', () {
      expect(Damage.fall(280), 40);
      expect(Damage.fall(5000), 40);
    });
  });
}
