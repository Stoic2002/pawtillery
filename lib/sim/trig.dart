import 'dart:typed_data';

/// Sine/cosine for whole degrees, computed with plain + and * only, so the
/// result is bit-identical on every CPU (libm `sin` is not guaranteed to be).
abstract final class SimTrig {
  static final Float64List _sinTable = _buildTable();

  static double sinDeg(int degrees) => _sinTable[degrees % 360];
  static double cosDeg(int degrees) => _sinTable[(degrees + 90) % 360];

  static const double _pi = 3.141592653589793;

  static Float64List _buildTable() {
    final table = Float64List(360);
    for (var d = 0; d < 360; d++) {
      final r = d % 90;
      table[d] = switch (d ~/ 90) {
        0 => _sinQuadrant(r),
        1 => _sinQuadrant(90 - r),
        2 => -_sinQuadrant(r),
        _ => -_sinQuadrant(90 - r),
      };
    }
    return table;
  }

  /// sin for 0..90 degrees via Taylor series (error < 1e-16 on this range).
  static double _sinQuadrant(int degrees) {
    if (degrees == 0) return 0;
    if (degrees == 30) return 0.5;
    if (degrees == 90) return 1;
    final x = degrees * (_pi / 180);
    final x2 = x * x;
    var term = x;
    var sum = x;
    for (var n = 1; n <= 12; n++) {
      term *= -x2 / ((2 * n) * (2 * n + 1));
      sum += term;
    }
    return sum;
  }
}
