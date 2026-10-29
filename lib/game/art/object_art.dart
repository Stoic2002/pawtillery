import 'dart:math' as math;
import 'dart:ui' as ui;

import '../../sim/map_object.dart';
import 'paint_kit.dart';
import 'sprites.dart';

/// Starter objects, drawn with their base centre at the origin, about
/// 16 px wide: a red fuel barrel, a health crate with a green cross and a
/// wooden weapon crate. Painted sprites ([Sprites]) where there are some,
/// else code-drawn and recorded once into pictures.
abstract final class ObjectArt {
  static final Map<ObjectKind, ui.Picture> _cache = {};

  /// The painted sprite and its height, px.
  static (String, double) _painted(ObjectKind kind) => switch (kind) {
    ObjectKind.barrel => ('obj_barrel', 23),
    ObjectKind.healthCrate => ('obj_healthCrate', 16),
    ObjectKind.weaponCrate => ('obj_weaponCrate', 17),
  };

  static void draw(ui.Canvas canvas, ObjectKind kind) {
    final (name, height) = _painted(kind);
    if (Sprites.of(name) case final sprite?) {
      final longest = height * math.max(sprite.width, sprite.height) /
          sprite.height;
      Sprites.draw(canvas, sprite, longest, center: ui.Offset(0, -height / 2));
      return;
    }
    _drawCoded(canvas, kind);
  }

  static void _drawCoded(ui.Canvas canvas, ObjectKind kind) =>
      canvas.drawPicture(_cache.putIfAbsent(kind, () {
        final recorder = ui.PictureRecorder();
        final c = ui.Canvas(recorder);
        switch (kind) {
          case ObjectKind.barrel:
            _barrel(c);
          case ObjectKind.healthCrate:
            _healthCrate(c);
          case ObjectKind.weaponCrate:
            _weaponCrate(c);
        }
        return recorder.endRecording();
      }));

  /// A red steel drum with two ribs and a yellow flame label.
  static void _barrel(ui.Canvas c) {
    const red = 0xFFC0392B;
    final body = ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(-8, -20, 16, 20),
      const ui.Radius.circular(3),
    );
    c
      ..drawRRect(body, PaintKit.lit(body.outerRect, red, light: 0.4))
      ..drawRRect(body, PaintKit.edge(red, 0.9));
    for (final y in [-15.0, -5.0]) {
      c.drawLine(
        ui.Offset(-8, y),
        ui.Offset(8, y),
        PaintKit.solid(0xFF7E2219)..strokeWidth = 1.2,
      );
    }
    c
      ..drawOval(
        const ui.Rect.fromLTWH(-7.5, -21.5, 15, 3.4),
        PaintKit.solid(0xFFD9584A),
      )
      ..drawOval(
        const ui.Rect.fromLTWH(-7.5, -21.5, 15, 3.4),
        PaintKit.edge(red, 0.6),
      )
      ..drawCircle(const ui.Offset(3, -20), 1.2, PaintKit.solid(0xFF4A1A14));
    // Flame label.
    final label = ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(-4.5, -13.5, 9, 7),
      const ui.Radius.circular(1),
    );
    c.drawRRect(label, PaintKit.solid(0xFFF5B700));
    final flame = ui.Path()
      ..moveTo(0, -12.6)
      ..quadraticBezierTo(2.6, -10, 1.6, -7.6)
      ..lineTo(-1.6, -7.6)
      ..quadraticBezierTo(-2.6, -10, 0, -12.6)
      ..close();
    c
      ..drawPath(flame, PaintKit.solid(0xFF2B2118))
      ..drawLine(
        const ui.Offset(-5, -18),
        const ui.Offset(-5, -2),
        PaintKit.solid(0x33FFFFFF)..strokeWidth = 1.4,
      );
  }

  /// A cream supply box with a green cross.
  static void _healthCrate(ui.Canvas c) {
    const cream = 0xFFF4EEDF;
    final box = ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(-8, -14, 16, 14),
      const ui.Radius.circular(2),
    );
    c
      ..drawRRect(box, PaintKit.lit(box.outerRect, cream, light: 0.2))
      ..drawRRect(box, PaintKit.edge(0xFF9A8F78, 0.9))
      ..drawRect(
        const ui.Rect.fromLTWH(-1.8, -11.5, 3.6, 9),
        PaintKit.solid(0xFF2E9E57),
      )
      ..drawRect(
        const ui.Rect.fromLTWH(-4.5, -8.8, 9, 3.6),
        PaintKit.solid(0xFF2E9E57),
      )
      ..drawLine(
        const ui.Offset(-8, -11),
        const ui.Offset(8, -11),
        PaintKit.solid(0x22000000)..strokeWidth = 0.6,
      );
  }

  /// A wooden crate with planks and a dark star stencil.
  static void _weaponCrate(ui.Canvas c) {
    const wood = 0xFFB07A44;
    final box = ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(-8, -15, 16, 15),
      const ui.Radius.circular(1.5),
    );
    c
      ..drawRRect(box, PaintKit.lit(box.outerRect, wood, light: 0.3))
      ..drawRRect(box, PaintKit.edge(wood, 0.9));
    for (final y in [-10.0, -5.0]) {
      c.drawLine(
        ui.Offset(-8, y),
        ui.Offset(8, y),
        PaintKit.solid(0x553E2A16)..strokeWidth = 0.7,
      );
    }
    c
      ..drawLine(
        const ui.Offset(-7, -14),
        const ui.Offset(7, -1),
        PaintKit.solid(0x663E2A16)..strokeWidth = 1.4,
      )
      ..drawLine(
        const ui.Offset(7, -14),
        const ui.Offset(-7, -1),
        PaintKit.solid(0x663E2A16)..strokeWidth = 1.4,
      );
    final star = ui.Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 4.2 : 1.8;
      final a = -1.5708 + i * 0.6283;
      final p = ui.Offset(r * math.cos(a), -7.5 + r * math.sin(a));
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    c.drawPath(star, PaintKit.solid(0xFF2B2118));
  }
}
