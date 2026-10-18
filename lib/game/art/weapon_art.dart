import 'dart:math' as math;
import 'dart:ui' as ui;

import 'animal_art.dart';
import 'paint_kit.dart';

/// Procedural, softly shaded weapon art: the projectiles in flight, mines
/// on the ground, and the icons in the weapon menu. Everything is drawn
/// centred on the origin; callers rotate and place it. Static shapes are
/// recorded once into pictures.
abstract final class WeaponArt {
  static final Map<String, ui.Picture> _cache = {};

  static ui.Picture _cached(String key, void Function(ui.Canvas) draw) =>
      _cache.putIfAbsent(key, () {
        final recorder = ui.PictureRecorder();
        draw(ui.Canvas(recorder));
        return recorder.endRecording();
      });

  /// A projectile of weapon [id] in flight, about 8–14 px across.
  static void projectile(ui.Canvas canvas, String id) {
    canvas.drawPicture(_cached('p:$id', (c) => _projectile(c, id)));
  }

  /// A mine lying on the ground (origin = resting point).
  static void mine(ui.Canvas canvas, {required bool small}) =>
      canvas.drawPicture(_cached('mine:$small', (c) {
        c.scale(small ? 0.7 : 1);
        _mine(c);
      }));

  /// Menu icon for weapon [id], fitting a [size]-px box centred on the
  /// origin.
  static void icon(ui.Canvas canvas, String id, double size) {
    canvas
      ..save()
      ..scale(size / 32);
    canvas.drawPicture(_cached('i:$id', (c) => _icon(c, id)));
    canvas.restore();
  }

  // -------------------------------------------------------------- shapes

  static void _projectile(ui.Canvas c, String id) {
    switch (id) {
      case 'rock':
        _rock(c, 6, 0xFF8E8A84);
      case 'twinSling':
        _rock(c, 3.6, 0xFF7C756C);
      case 'grenade':
        _grenade(c);
      case 'cluster':
        _bomb(c, 6.5);
      case 'clusterBomblet':
        _bomb(c, 3.6);
      case 'hairball':
        _hairball(c, 6.5);
      case 'hairballBomb':
        _hairball(c, 4);
      case 'boneBoomerang':
        _bone(c);
      case 'drillCarrot':
        _carrot(c);
      case 'egg':
        _egg(c, 1);
      case 'seedMines':
        _seed(c, 1.2);
      case 'coconut':
        _coconut(c);
      default:
        _rock(c, 5, 0xFF9E9A94);
    }
  }

  static void _shaded(ui.Canvas c, ui.Path path, int argb,
      {double light = 0.3}) {
    c
      ..drawPath(path, PaintKit.lit(path.getBounds(), argb, light: light))
      ..drawPath(path, PaintKit.edge(argb, 0.7));
  }

  static void _ball(ui.Canvas c, double r, int argb, {double light = 0.35}) {
    final rect = ui.Rect.fromCircle(center: ui.Offset.zero, radius: r);
    c
      ..drawCircle(ui.Offset.zero, r, PaintKit.lit(rect, argb, light: light))
      ..drawCircle(ui.Offset.zero, r, PaintKit.edge(argb, 0.7));
  }

  static void _rock(ui.Canvas c, double r, int argb) {
    final path = ui.Path();
    const pts = [1.0, 0.82, 0.95, 0.78, 1.0, 0.86, 0.92, 0.8];
    for (var i = 0; i < pts.length; i++) {
      final a = i / pts.length * math.pi * 2;
      final p = ui.Offset(math.cos(a) * r * pts[i], math.sin(a) * r * pts[i]);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    _shaded(c, path, argb, light: 0.35);
    c.drawCircle(ui.Offset(-r * 0.35, -r * 0.35), r * 0.18,
        PaintKit.solid(0x55FFFFFF));
  }

  static void _grenade(ui.Canvas c) {
    const body = 0xFF4E6B3A;
    final rect = ui.Rect.fromCenter(
        center: const ui.Offset(0, 1), width: 11, height: 13);
    c
      ..drawOval(rect, PaintKit.lit(rect, body))
      ..drawOval(rect, PaintKit.edge(body, 0.7));
    final groove = ui.Paint()
      ..color = PaintKit.tone(body, -0.45)
      ..strokeWidth = 0.6;
    for (final y in [-2.5, 1.0, 4.5]) {
      c.drawLine(ui.Offset(-5, y), ui.Offset(5, y), groove);
    }
    for (final x in [-2.2, 2.2]) {
      c.drawLine(ui.Offset(x, -5), ui.Offset(x, 7), groove);
    }
    final cap = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-2.5, -8, 5, 3.2), const ui.Radius.circular(1));
    c
      ..drawRRect(cap, PaintKit.lit(cap.outerRect, 0xFFA8A8A0))
      ..drawLine(
          const ui.Offset(2.5, -7),
          const ui.Offset(5, -2),
          ui.Paint()
            ..color = const ui.Color(0xFF9A9A92)
            ..strokeWidth = 1.2
            ..strokeCap = ui.StrokeCap.round);
  }

  static void _bomb(ui.Canvas c, double r) {
    const body = 0xFF2E3238;
    _ball(c, r, body, light: 0.45);
    c.drawRect(
        ui.Rect.fromCenter(center: ui.Offset.zero, width: r * 2, height: r * 0.4),
        PaintKit.solid(0xCCB3261E));
    final cap = ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(
            center: ui.Offset(0, -r * 1.05), width: r * 0.8, height: r * 0.4),
        const ui.Radius.circular(1));
    c.drawRRect(cap, PaintKit.lit(cap.outerRect, 0xFF8A8A84));
  }

  static void _hairball(ui.Canvas c, double r) {
    const fur = 0xFFBCA48A;
    _ball(c, r, fur, light: 0.25);
    final strand = ui.Paint()
      ..color = PaintKit.tone(fur, -0.3)
      ..strokeWidth = 0.6
      ..strokeCap = ui.StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2;
      final inner = r * 0.55;
      c.drawLine(ui.Offset(math.cos(a) * inner, math.sin(a) * inner),
          ui.Offset(math.cos(a + 0.4) * (r + 1.6), math.sin(a + 0.4) * (r + 1.6)),
          strand);
    }
  }

  static void _bone(ui.Canvas c) {
    const bone = 0xFFF1E9D8;
    final shaft = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-9, -1.8, 18, 3.6), const ui.Radius.circular(1.8));
    c.drawRRect(shaft, PaintKit.lit(shaft.outerRect, bone));
    for (final x in [-9.5, 9.5]) {
      for (final y in [-2.2, 2.2]) {
        final rect = ui.Rect.fromCircle(center: ui.Offset(x, y), radius: 2.6);
        c
          ..drawCircle(ui.Offset(x, y), 2.6, PaintKit.lit(rect, bone))
          ..drawCircle(ui.Offset(x, y), 2.6, PaintKit.edge(bone, 0.6));
      }
    }
    c.drawRRect(shaft, PaintKit.edge(bone, 0.6));
  }

  /// Pointing right.
  static void _carrot(ui.Canvas c) {
    const orange = 0xFFE8742C;
    final body = ui.Path()
      ..moveTo(12, 0)
      ..quadraticBezierTo(2, -4.6, -6, -3.8)
      ..quadraticBezierTo(-8, 0, -6, 3.8)
      ..quadraticBezierTo(2, 4.6, 12, 0)
      ..close();
    _shaded(c, body, orange);
    final ridge = ui.Paint()
      ..color = PaintKit.tone(orange, -0.35)
      ..strokeWidth = 0.6;
    for (final x in [-2.0, 2.0, 6.0]) {
      c.drawLine(ui.Offset(x, -2.6 + x * 0.12), ui.Offset(x + 1, -0.6), ridge);
    }
    const leaf = 0xFF5E9E3A;
    for (final a in [-0.5, 0.0, 0.5]) {
      c
        ..save()
        ..translate(-7, 0)
        ..rotate(math.pi + a);
      final l = ui.Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(3, -1.6, 6, 0)
        ..quadraticBezierTo(3, 1.6, 0, 0);
      c
        ..drawPath(l, PaintKit.lit(l.getBounds(), leaf))
        ..restore();
    }
  }

  static void _egg(ui.Canvas c, double s) {
    const shell = 0xFFF4E9D6;
    final rect = ui.Rect.fromCenter(
        center: ui.Offset.zero, width: 8 * s, height: 10.5 * s);
    c
      ..drawOval(rect, PaintKit.lit(rect, shell, light: 0.4))
      ..drawOval(rect, PaintKit.edge(shell, 0.6));
    for (final (x, y) in [(-1.4, -2.0), (1.6, 1.4), (-0.6, 2.6)]) {
      c.drawCircle(ui.Offset(x * s, y * s), 0.5 * s, PaintKit.solid(0x66A8865A));
    }
  }

  static void _seed(ui.Canvas c, double s) {
    final path = ui.Path()
      ..moveTo(0, -6 * s)
      ..quadraticBezierTo(4 * s, 0, 0, 6 * s)
      ..quadraticBezierTo(-4 * s, 0, 0, -6 * s)
      ..close();
    _shaded(c, path, 0xFF3A3530);
    final stripe = ui.Paint()
      ..color = const ui.Color(0xFFE8E0CC)
      ..strokeWidth = 0.8 * s;
    for (final x in [-1.3, 1.3]) {
      c.drawLine(ui.Offset(x * s, -4 * s), ui.Offset(x * s, 4 * s), stripe);
    }
  }

  static void _coconut(ui.Canvas c) {
    const husk = 0xFF6B4A30;
    _ball(c, 7.5, husk, light: 0.3);
    final fiber = ui.Paint()
      ..color = PaintKit.tone(husk, 0.25)
      ..strokeWidth = 0.5;
    for (var i = 0; i < 10; i++) {
      final a = i * 0.63;
      c.drawLine(ui.Offset(math.cos(a) * 3, math.sin(a) * 3),
          ui.Offset(math.cos(a + 0.3) * 7, math.sin(a + 0.3) * 7), fiber);
    }
    for (final (x, y) in [(-1.6, -2.4), (1.6, -2.4), (0.0, 0.4)]) {
      c.drawCircle(ui.Offset(x, y), 1, PaintKit.solid(0xFF2A1A10));
    }
  }

  static void _mine(ui.Canvas c) {
    const metal = 0xFF4A5056;
    final base = ui.Rect.fromCenter(
        center: const ui.Offset(0, -1.5), width: 15, height: 4);
    c
      ..drawOval(base, PaintKit.lit(base, metal))
      ..drawOval(base, PaintKit.edge(metal, 0.6));
    final dome = ui.Path()
      ..moveTo(-5.5, -2.5)
      ..quadraticBezierTo(0, -9, 5.5, -2.5)
      ..close();
    _shaded(c, dome, 0xFF60686E, light: 0.4);
    c.drawRect(const ui.Rect.fromLTWH(-0.8, -8.5, 1.6, 2),
        PaintKit.solid(0xFF2A2E32));
  }

  // --------------------------------------------------------------- icons

  /// Icons are drawn for a 32 px box.
  static void _icon(ui.Canvas c, String id) {
    void big(void Function() draw, [double s = 2]) {
      c
        ..save()
        ..scale(s);
      draw();
      c.restore();
    }

    switch (id) {
      case 'rock':
        big(() => _rock(c, 6.5, 0xFF8E8A84));
      case 'grenade':
        big(() => _grenade(c), 1.9);
      case 'cluster':
        big(() {
          _bomb(c, 6);
          for (final (x, y) in [(-7.0, 5.0), (7.0, 5.0), (0.0, 8.5)]) {
            c
              ..save()
              ..translate(x, y)
              ..scale(0.5);
            _bomb(c, 4);
            c.restore();
          }
        }, 1.8);
      case 'twinSling':
        _slingshot(c);
      case 'punch':
        _glove(c);
      case 'mine':
        big(() {
          c.translate(0, 4);
          _mine(c);
        }, 1.8);
      case 'teleport':
        _portal(c);
      case 'skip':
        _hourglass(c);
      case 'hairball':
        big(() => _hairball(c, 6));
      case 'boneBoomerang':
        big(() {
          c.rotate(-0.5);
          _bone(c);
        }, 1.4);
      case 'drillCarrot':
        big(() {
          c.rotate(0.6);
          _carrot(c);
        }, 1.4);
      case 'eggStrike':
        for (final (x, y) in [(-7.0, -4.0), (0.0, 2.0), (7.0, -4.0)]) {
          c
            ..save()
            ..translate(x, y)
            ..scale(1.2);
          _egg(c, 1);
          c.restore();
        }
      case 'seedMines':
        for (final (x, y, a) in [(-6.0, 3.0, -0.4), (0.0, -4.0, 0.2), (6.0, 3.0, 0.6)]) {
          c
            ..save()
            ..translate(x, y)
            ..rotate(a);
          _seed(c, 1);
          c.restore();
        }
      case 'boomDuck':
        c
          ..save()
          ..translate(-1, 11)
          ..scale(0.85);
        AnimalArt.draw(c,
            familyId: 'duck',
            breedId: 'duckCallDuck',
            teamArgb: 0xFFE53935,
            pose: AnimalPose.idle);
        c.restore();
        c
          ..save()
          ..translate(-5, -2)
          ..scale(0.8);
        _bomb(c, 5);
        c.restore();
      case 'startleCrow':
        _shout(c);
      case 'fortress':
        _bricks(c);
      case 'headbutt':
        _horns(c);
      case 'coconut':
        big(() => _coconut(c), 1.8);
      default:
        big(() => _rock(c, 6, 0xFF9E9A94));
    }
  }

  static void _slingshot(ui.Canvas c) {
    const wood = 0xFF8A5A34;
    final fork = ui.Path()
      ..moveTo(-2, 14)
      ..lineTo(2, 14)
      ..lineTo(2, 2)
      ..lineTo(8, -10)
      ..lineTo(5, -11)
      ..lineTo(0, -1)
      ..lineTo(-5, -11)
      ..lineTo(-8, -10)
      ..lineTo(-2, 2)
      ..close();
    _shaded(c, fork, wood);
    c.drawLine(
        const ui.Offset(-6.5, -10),
        const ui.Offset(6.5, -10),
        ui.Paint()
          ..color = const ui.Color(0xFF5A3A26)
          ..strokeWidth = 1.2);
    for (final x in [-3.0, 3.0]) {
      c
        ..save()
        ..translate(x, -12);
      _rock(c, 2.6, 0xFF7C756C);
      c.restore();
    }
  }

  static void _glove(ui.Canvas c) {
    const red = 0xFFC8342C;
    final glove = ui.Path()
      ..moveTo(-10, 4)
      ..quadraticBezierTo(-12, -10, 0, -11)
      ..quadraticBezierTo(12, -11, 11, 1)
      ..quadraticBezierTo(10, 9, 0, 8)
      ..lineTo(-10, 8)
      ..close();
    _shaded(c, glove, red);
    final thumb = ui.Path()
      ..moveTo(-4, 1)
      ..quadraticBezierTo(2, -3, 6, 2)
      ..quadraticBezierTo(2, 5, -4, 3)
      ..close();
    _shaded(c, thumb, PaintKit.toneArgb(red, -0.08));
    final cuff = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-12, 7, 14, 6), const ui.Radius.circular(2));
    c.drawRRect(cuff, PaintKit.lit(cuff.outerRect, 0xFFF2F0EA));
  }

  static void _portal(ui.Canvas c) {
    for (var i = 0; i < 4; i++) {
      final r = 13.0 - i * 3;
      c.drawCircle(
          ui.Offset.zero,
          r,
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = ui.Color.lerp(const ui.Color(0xFF7E57C2),
                const ui.Color(0xFFE1BEE7), i / 3)!);
    }
    c.drawCircle(ui.Offset.zero, 2.5, PaintKit.solid(0xFFFFFFFF));
  }

  static void _hourglass(ui.Canvas c) {
    const wood = 0xFF8A5A34;
    final glass = ui.Path()
      ..moveTo(-7, -11)
      ..lineTo(7, -11)
      ..lineTo(1, 0)
      ..lineTo(7, 11)
      ..lineTo(-7, 11)
      ..lineTo(-1, 0)
      ..close();
    c
      ..drawPath(glass, PaintKit.solid(0x55BFE3F2))
      ..drawPath(glass, PaintKit.edge(0xFF9AB8C4, 1));
    final sand = ui.Path()
      ..moveTo(-5, 10)
      ..lineTo(5, 10)
      ..lineTo(0, 4)
      ..close();
    c.drawPath(sand, PaintKit.solid(0xFFE0B860));
    for (final y in [-13.0, 11.0]) {
      final bar = ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(-10, y, 20, 2.6), const ui.Radius.circular(1.2));
      c.drawRRect(bar, PaintKit.lit(bar.outerRect, wood));
    }
  }

  static void _shout(ui.Canvas c) {
    c
      ..save()
      ..translate(-6, 12)
      ..scale(0.8);
    AnimalArt.draw(c,
        familyId: 'chicken',
        breedId: 'chickenKampung',
        teamArgb: 0xFFE53935,
        pose: AnimalPose.idle);
    c.restore();
    final wave = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = ui.StrokeCap.round
      ..color = const ui.Color(0xFFFFC107);
    for (final r in [5.0, 9.0, 13.0]) {
      c.drawArc(ui.Rect.fromCircle(center: const ui.Offset(2, -9), radius: r),
          -0.7, 1.4, false, wave);
    }
  }

  static void _bricks(ui.Canvas c) {
    const brick = 0xFFA0522D;
    for (var row = 0; row < 4; row++) {
      final offset = row.isEven ? 0.0 : 4.0;
      for (var col = 0; col < 3; col++) {
        final rect = ui.Rect.fromLTWH(
            -12 + col * 8 + offset - (row.isEven ? 0 : 4), -10 + row * 5.5, 7.4, 4.8);
        if (rect.right > 13) continue;
        c
          ..drawRect(rect, PaintKit.lit(rect, brick))
          ..drawRect(rect, PaintKit.edge(brick, 0.5));
      }
    }
  }

  static void _horns(ui.Canvas c) {
    const horn = 0xFF9C8C74;
    for (final s in [-1.0, 1.0]) {
      final path = ui.Path()
        ..moveTo(s * 2, 8)
        ..quadraticBezierTo(s * 4, -8, s * 13, -10)
        ..quadraticBezierTo(s * 7, -4, s * 6, 9)
        ..close();
      _shaded(c, path, horn);
    }
    final dash = ui.Paint()
      ..color = const ui.Color(0xAAFFFFFF)
      ..strokeWidth = 1.4
      ..strokeCap = ui.StrokeCap.round;
    for (final y in [-2.0, 3.0, 8.0]) {
      c.drawLine(ui.Offset(-15, y), ui.Offset(-10, y), dash);
    }
  }
}
