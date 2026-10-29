import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The painted weapons, aircraft and objects (`assets/sprites/<name>.webp`,
/// cut out of the sheets in art/src/ by tool/art/convert_art.py), loaded
/// once at start. Without one (and in tests) the code-drawn art of
/// WeaponArt and ObjectArt is used.
abstract final class Sprites {
  static final Map<String, ui.Image> _images = {};

  /// Smooth when scaled far down (a 192 px icon drawn 14 px across).
  static final ui.Paint _paint = ui.Paint()
    ..filterQuality = ui.FilterQuality.medium;

  static const String _dir = 'assets/sprites/';

  static ui.Image? of(String name) => _images[name];

  static Future<void> load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      await Future.wait([
        for (final asset in manifest.listAssets())
          if (asset.startsWith(_dir) && asset.endsWith('.webp')) _load(asset),
      ]);
    } on Object catch (e) {
      debugPrint('Sprites not loaded: $e');
    }
  }

  static Future<void> _load(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final name = asset.substring(_dir.length, asset.length - 5);
      _images[name] = (await codec.getNextFrame()).image;
      codec.dispose();
    } on Object catch (e) {
      debugPrint('Sprite $asset not loaded: $e');
    }
  }

  /// Draws [image] centred on [center] with its longest side [size] px,
  /// turned by [turnDeg] degrees (clockwise) about its centre.
  static void draw(
    ui.Canvas canvas,
    ui.Image image,
    double size, {
    double turnDeg = 0,
    ui.Offset center = ui.Offset.zero,
  }) {
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    final s = size / math.max(w, h);
    canvas
      ..save()
      ..translate(center.dx, center.dy);
    if (turnDeg != 0) canvas.rotate(turnDeg * math.pi / 180);
    canvas
      ..drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, w, h),
        ui.Rect.fromCenter(center: ui.Offset.zero, width: w * s, height: h * s),
        _paint,
      )
      ..restore();
  }

  /// Width and height of [image] drawn with its longest side [size].
  static ui.Size sizeOf(ui.Image image, double size) {
    final s = size / math.max(image.width, image.height);
    return ui.Size(image.width * s, image.height * s);
  }
}
