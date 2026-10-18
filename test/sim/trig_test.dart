import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/sim/trig.dart';

void main() {
  test('matches dart:math within 1e-15 for every whole degree', () {
    for (var d = 0; d < 360; d++) {
      final rad = d * math.pi / 180;
      expect(SimTrig.sinDeg(d), closeTo(math.sin(rad), 1e-15), reason: 'sin $d');
      expect(SimTrig.cosDeg(d), closeTo(math.cos(rad), 1e-15), reason: 'cos $d');
    }
  });

  test('exact at the axes', () {
    expect(SimTrig.sinDeg(0), 0);
    expect(SimTrig.sinDeg(90), 1);
    expect(SimTrig.sinDeg(180), 0);
    expect(SimTrig.sinDeg(270), -1);
    expect(SimTrig.cosDeg(0), 1);
    expect(SimTrig.cosDeg(180), -1);
  });

  test('wraps negative and large angles', () {
    expect(SimTrig.sinDeg(-90), -1);
    expect(SimTrig.sinDeg(450), 1);
  });
}
