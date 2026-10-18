import 'dart:typed_data';

import '../config/physics.dart';

/// Integer rectangle; [right] and [bottom] are exclusive.
class IntRect {
  const IntRect(this.left, this.top, this.right, this.bottom);

  final int left;
  final int top;
  final int right;
  final int bottom;

  int get width => right - left;
  int get height => bottom - top;

  @override
  bool operator ==(Object other) =>
      other is IntRect &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'IntRect($left, $top, $right, $bottom)';
}

/// Per-pixel collision data for the whole map: 1 = ground, 0 = empty.
/// Everything outside the map counts as empty.
class TerrainMask {
  TerrainMask(this.width, this.height) : data = Uint8List(width * height);

  /// Builds a mask from straight (non-premultiplied) RGBA bytes.
  factory TerrainMask.fromRgba(
    int width,
    int height,
    Uint8List rgba, {
    int alphaThreshold = PhysicsConfig.terrainAlphaThreshold,
  }) {
    if (rgba.length != width * height * 4) {
      throw ArgumentError('Expected ${width * height * 4} bytes, '
          'got ${rgba.length}');
    }
    final mask = TerrainMask(width, height);
    final data = mask.data;
    for (var i = 0; i < data.length; i++) {
      data[i] = rgba[i * 4 + 3] > alphaThreshold ? 1 : 0;
    }
    return mask;
  }

  final int width;
  final int height;
  final Uint8List data;

  bool isSolid(int x, int y) =>
      x >= 0 && y >= 0 && x < width && y < height && data[y * width + x] == 1;

  /// Clears every pixel within [radius] of (cx, cy). Returns the touched
  /// area clipped to the map, or `null` if the circle lies outside it.
  IntRect? carveCircle(int cx, int cy, int radius) =>
      _paintCircle(cx, cy, radius, 0);

  /// Opposite of [carveCircle]: turns pixels into ground.
  IntRect? fillCircle(int cx, int cy, int radius) =>
      _paintCircle(cx, cy, radius, 1);

  /// Turns a rectangle into ground (e.g. a built wall).
  IntRect? fillRect(int left, int top, int w, int h) {
    final area = _clip(left, top, left + w, top + h);
    if (area == null) return null;
    for (var y = area.top; y < area.bottom; y++) {
      data.fillRange(y * width + area.left, y * width + area.right, 1);
    }
    return area;
  }

  IntRect? _paintCircle(int cx, int cy, int radius, int value) {
    final area = _clip(cx - radius, cy - radius, cx + radius + 1,
        cy + radius + 1);
    if (area == null) return null;
    final r2 = radius * radius;
    for (var y = area.top; y < area.bottom; y++) {
      final dy = y - cy;
      final row = y * width;
      for (var x = area.left; x < area.right; x++) {
        final dx = x - cx;
        if (dx * dx + dy * dy <= r2) data[row + x] = value;
      }
    }
    return area;
  }

  IntRect? _clip(int left, int top, int right, int bottom) {
    final l = left < 0 ? 0 : left;
    final t = top < 0 ? 0 : top;
    final r = right > width ? width : right;
    final b = bottom > height ? height : bottom;
    if (l >= r || t >= b) return null;
    return IntRect(l, t, r, b);
  }
}
