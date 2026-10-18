import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/sim/terrain_mask.dart';

void main() {
  group('fromRgba', () {
    test('alpha above 128 is ground, 128 and below is empty', () {
      final rgba = Uint8List.fromList([
        0, 0, 0, 255, //
        0, 0, 0, 129,
        0, 0, 0, 128,
        0, 0, 0, 0,
      ]);
      final mask = TerrainMask.fromRgba(4, 1, rgba);
      expect([for (var x = 0; x < 4; x++) mask.isSolid(x, 0)],
          [true, true, false, false]);
    });

    test('rejects a buffer of the wrong size', () {
      expect(() => TerrainMask.fromRgba(2, 2, Uint8List(4)),
          throwsArgumentError);
    });
  });

  group('isSolid', () {
    test('everything outside the map is empty', () {
      final mask = _full(10, 10);
      expect(mask.isSolid(0, 0), isTrue);
      expect(mask.isSolid(9, 9), isTrue);
      for (final (x, y) in [(-1, 0), (0, -1), (10, 0), (0, 10), (-5, 50)]) {
        expect(mask.isSolid(x, y), isFalse, reason: '($x, $y)');
      }
    });
  });

  group('carveCircle', () {
    test('clears exactly the pixels within the radius', () {
      final mask = _full(21, 21);
      final area = mask.carveCircle(10, 10, 5);
      expect(area, const IntRect(5, 5, 16, 16));
      for (var y = 0; y < 21; y++) {
        for (var x = 0; x < 21; x++) {
          final inside = (x - 10) * (x - 10) + (y - 10) * (y - 10) <= 25;
          expect(mask.isSolid(x, y), !inside, reason: '($x, $y)');
        }
      }
    });

    test('is clipped at the map edges', () {
      final mask = _full(20, 20);
      expect(mask.carveCircle(0, 0, 5), const IntRect(0, 0, 6, 6));
      expect(mask.isSolid(0, 0), isFalse);
      expect(mask.isSolid(10, 10), isTrue);
    });

    test('fully outside the map touches nothing', () {
      final mask = _full(20, 20);
      expect(mask.carveCircle(-50, -50, 10), isNull);
      expect(mask.carveCircle(100, 5, 10), isNull);
      expect(mask.data.every((v) => v == 1), isTrue);
    });

    test('radius 0 clears a single pixel', () {
      final mask = _full(5, 5)..carveCircle(2, 2, 0);
      expect(mask.data.where((v) => v == 0).length, 1);
      expect(mask.isSolid(2, 2), isFalse);
    });
  });

  group('adding terrain', () {
    test('fillCircle is the inverse of carveCircle', () {
      final mask = _full(30, 30)..carveCircle(15, 15, 8);
      mask.fillCircle(15, 15, 8);
      expect(mask.data.every((v) => v == 1), isTrue);
    });

    test('fillRect fills and clips', () {
      final mask = TerrainMask(10, 10);
      expect(mask.fillRect(8, 8, 5, 5), const IntRect(8, 8, 10, 10));
      expect(mask.data.where((v) => v == 1).length, 4);
      expect(mask.fillRect(20, 20, 2, 2), isNull);
    });
  });
}

TerrainMask _full(int w, int h) => TerrainMask(w, h)..data.fillRange(0, w * h, 1);
