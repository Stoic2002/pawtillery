import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/sim/rng.dart';

void main() {
  test('same seed yields the same sequence', () {
    final a = SimRng(42);
    final b = SimRng(42);
    for (var i = 0; i < 1000; i++) {
      expect(a.nextUint32(), b.nextUint32());
    }
  });

  test('different seeds diverge', () {
    expect(_take(SimRng(1), 8), isNot(_take(SimRng(2), 8)));
  });

  test('sequence is pinned (guards against accidental algorithm changes)', () {
    // Reference values from the canonical mulberry32 for seed 1.
    expect(_take(SimRng(1), 3), [2693262067, 11749833, 2265367787]);
  });

  test('state can be snapshotted and restored', () {
    final rng = SimRng(7)..nextUint32();
    final saved = rng.state;
    final next = _take(rng, 5);
    rng.state = saved;
    expect(_take(rng, 5), next);
  });

  test('ranges stay in bounds', () {
    final rng = SimRng(99);
    for (var i = 0; i < 10000; i++) {
      final d = rng.nextDouble();
      expect(d >= 0 && d < 1, isTrue);
      final n = rng.nextIntInRange(-10, 10);
      expect(n >= -10 && n <= 10, isTrue);
    }
  });
}

List<int> _take(SimRng rng, int n) => List.generate(n, (_) => rng.nextUint32());
