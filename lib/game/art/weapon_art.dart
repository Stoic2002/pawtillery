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
      case 'bottleRocket':
        _rocket(c, 0xFF5AA9E6, 0xFFE5484D);
      case 'snifferRocket':
        _sniffer(c);
      case 'seedSpitter':
        _seed(c, 0.55);
      case 'firecracker':
        _firecracker(c, 1);
      case 'flowerpot':
        _flowerpot(c, 1);
      default:
        _rock(c, 5, 0xFF9E9A94);
    }
  }

  /// Weapons drawn pointing along their flight (the renderer rotates them
  /// to the velocity instead of tumbling them), with a motor flame.
  static bool pointsAlongFlight(String id) =>
      id == 'bottleRocket' || id == 'snifferRocket';

  /// A small bottle rocket pointing right, about 18 px long: a translucent
  /// bottle body, a coloured nose cone and two fins.
  static void _rocket(ui.Canvas c, int body, int nose) {
    for (final s in [-1.0, 1.0]) {
      final fin = ui.Path()
        ..moveTo(-4, s * 2.5)
        ..lineTo(-9, s * 6)
        ..lineTo(-8.5, s * 2)
        ..close();
      _shaded(c, fin, nose);
    }
    final bottle = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-8, -3.2, 12, 6.4), const ui.Radius.circular(2.4));
    c
      ..drawRRect(bottle, PaintKit.lit(bottle.outerRect, body, light: 0.45))
      ..drawRRect(bottle, PaintKit.edge(body, 0.7))
      ..drawRect(const ui.Rect.fromLTWH(-4, -3.2, 3, 6.4),
          PaintKit.solid(0xCCFFF6E6));
    final cone = ui.Path()
      ..moveTo(3.5, -3.2)
      ..quadraticBezierTo(10, -1.5, 10.5, 0)
      ..quadraticBezierTo(10, 1.5, 3.5, 3.2)
      ..close();
    _shaded(c, cone, nose);
    c.drawLine(const ui.Offset(-6.5, -1.8), const ui.Offset(1.5, -1.8),
        PaintKit.solid(0x66FFFFFF)..strokeWidth = 0.8);
  }

  /// The homing rocket: a round lavender body with a dark sniffing nose and
  /// a little eye, pointing right.
  static void _sniffer(ui.Canvas c) {
    const body = 0xFF9C7BE8;
    for (final s in [-1.0, 1.0]) {
      final fin = ui.Path()
        ..moveTo(-3, s * 3)
        ..lineTo(-8.5, s * 6.5)
        ..lineTo(-7.5, s * 1.5)
        ..close();
      _shaded(c, fin, 0xFFF5B700);
    }
    final hull = ui.Rect.fromCenter(
        center: const ui.Offset(0.5, 0), width: 16, height: 8);
    c
      ..drawOval(hull, PaintKit.lit(hull, body, light: 0.4))
      ..drawOval(hull, PaintKit.edge(body, 0.7))
      ..drawCircle(const ui.Offset(8.4, 0), 2, PaintKit.solid(0xFF2B2118))
      ..drawCircle(const ui.Offset(8.9, -0.6), 0.6, PaintKit.solid(0xAAFFFFFF))
      ..drawCircle(const ui.Offset(3.5, -1.6), 1.3, PaintKit.solid(0xFFFFFFFF))
      ..drawCircle(const ui.Offset(3.8, -1.6), 0.7, PaintKit.solid(0xFF2B2118));
  }

  /// A red paper firecracker with gold bands and a fuse, upright.
  static void _firecracker(ui.Canvas c, double s) {
    const red = 0xFFD63A2F;
    final tube = ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(center: ui.Offset.zero, width: 7 * s, height: 13 * s),
        ui.Radius.circular(1.5 * s));
    c
      ..drawRRect(tube, PaintKit.lit(tube.outerRect, red, light: 0.4))
      ..drawRRect(tube, PaintKit.edge(red, 0.7));
    for (final y in [-4.0, 4.0]) {
      c.drawRect(
          ui.Rect.fromCenter(
              center: ui.Offset(0, y * s), width: 7 * s, height: 1.6 * s),
          PaintKit.solid(0xFFF5C542));
    }
    c.drawPath(
        ui.Path()
          ..moveTo(0, -6.5 * s)
          ..quadraticBezierTo(2 * s, -9 * s, 0.5 * s, -10.5 * s),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 0.9 * s
          ..strokeCap = ui.StrokeCap.round
          ..color = const ui.Color(0xFF5A4636));
  }

  /// A terracotta flowerpot with a little green sprout.
  static void _flowerpot(ui.Canvas c, double s) {
    const clay = 0xFFC0623A;
    for (final a in [-0.5, 0.5]) {
      c
        ..save()
        ..translate(0, -4 * s)
        ..rotate(a);
      final leaf = ui.Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(2.5 * s, -2 * s, 0, -6 * s)
        ..quadraticBezierTo(-2.5 * s, -2 * s, 0, 0);
      _shaded(c, leaf, 0xFF4CA35A);
      c.restore();
    }
    final pot = ui.Path()
      ..moveTo(-5 * s, -3 * s)
      ..lineTo(5 * s, -3 * s)
      ..lineTo(3.6 * s, 6 * s)
      ..lineTo(-3.6 * s, 6 * s)
      ..close();
    _shaded(c, pot, clay);
    final rim = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(-6 * s, -5 * s, 12 * s, 3 * s),
        ui.Radius.circular(1 * s));
    c
      ..drawRRect(rim, PaintKit.lit(rim.outerRect, PaintKit.toneArgb(clay, 0.1)))
      ..drawRRect(rim, PaintKit.edge(clay, 0.6));
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
    // Irregular pebble: uneven radii, smoothed with curves.
    const radii = [1.0, 0.86, 0.94, 0.72, 0.9, 1.0, 0.8, 0.88, 0.76];
    final pts = [
      for (var i = 0; i < radii.length; i++)
        ui.Offset(math.cos(i / radii.length * math.pi * 2 + 0.3) * r * radii[i],
            math.sin(i / radii.length * math.pi * 2 + 0.3) * r * radii[i] * 0.82),
    ];
    final path = ui.Path();
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      final mid = (a + b) / 2;
      if (i == 0) path.moveTo(mid.dx, mid.dy);
      final next = (b + pts[(i + 2) % pts.length]) / 2;
      path.quadraticBezierTo(b.dx, b.dy, next.dx, next.dy);
    }
    path.close();
    _shaded(c, path, argb, light: 0.35);
    c
      ..drawCircle(ui.Offset(-r * 0.3, -r * 0.3), r * 0.2,
          PaintKit.solid(0x40FFFFFF))
      ..drawCircle(ui.Offset(r * 0.25, r * 0.15), r * 0.12,
          PaintKit.solid(0x33000000));
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

  /// Sunflower seed: a dark teardrop with pale lengthwise stripes.
  static void _seed(ui.Canvas c, double s) {
    final path = ui.Path()
      ..moveTo(0, -6.5 * s)
      ..quadraticBezierTo(5 * s, -2 * s, 3.2 * s, 4 * s)
      ..quadraticBezierTo(0, 7 * s, -3.2 * s, 4 * s)
      ..quadraticBezierTo(-5 * s, -2 * s, 0, -6.5 * s)
      ..close();
    _shaded(c, path, 0xFF3A3530, light: 0.4);
    c
      ..save()
      ..clipPath(path);
    final stripe = ui.Paint()
      ..color = const ui.Color(0x99D8D0BC)
      ..strokeWidth = 0.7 * s;
    for (final x in [-2.0, 0.0, 2.0]) {
      c.drawLine(ui.Offset(x * s * 0.6, -5.5 * s), ui.Offset(x * s, 6 * s),
          stripe);
    }
    c.restore();
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
      case 'bottleRocket':
        big(() {
          c.rotate(-0.7);
          _rocket(c, 0xFF5AA9E6, 0xFFE5484D);
        }, 1.45);
      case 'snifferRocket':
        _trail(c, const [ui.Offset(-13, 11), ui.Offset(-8, 2), ui.Offset(-2, -2)]);
        big(() {
          c
            ..translate(2, -2)
            ..rotate(-0.35);
          _sniffer(c);
        }, 1.4);
      case 'laserPointer':
        _laser(c);
      case 'thunderCloud':
        _cloudBolt(c);
      case 'seedSpitter':
        _spitter(c);
      case 'firecracker':
        big(() {
          c.rotate(0.25);
          _firecracker(c, 1);
        }, 1.75);
        _spark(c, const ui.Offset(5, -14), 3.4);
      case 'flowerpotRain':
        for (final (x, y, a) in [(-7.0, -5.0, -0.3), (6.0, -8.0, 0.25), (0.0, 7.0, 0.1)]) {
          c
            ..save()
            ..translate(x, y)
            ..rotate(a)
            ..scale(1.1);
          _flowerpot(c, 1);
          c.restore();
        }
      case 'digClaws':
        _claws(c);
      default:
        big(() => _rock(c, 6, 0xFF9E9A94));
    }
  }

  /// Speed dashes behind something moving along [points].
  static void _trail(ui.Canvas c, List<ui.Offset> points) {
    final paint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = ui.StrokeCap.round
      ..color = const ui.Color(0x998B5CF6);
    final path = ui.Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i + 1 < points.length; i += 2) {
      path.quadraticBezierTo(
          points[i].dx, points[i].dy, points[i + 1].dx, points[i + 1].dy);
    }
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 5) {
        c.drawPath(m.extractPath(d, d + 2.6), paint);
      }
    }
  }

  static void _spark(ui.Canvas c, ui.Offset at, double r) {
    final star = ui.Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.42;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = at + ui.Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    c
      ..drawPath(star, PaintKit.solid(0xFFFFD25A))
      ..drawPath(star, PaintKit.edge(0xFFE2681C, 0.6));
  }

  /// A pen-shaped laser pointer firing a red beam at a dot.
  static void _laser(ui.Canvas c) {
    c
      ..drawLine(
          const ui.Offset(1, 3),
          const ui.Offset(13, -9),
          ui.Paint()
            ..color = const ui.Color(0x66FF3B30)
            ..strokeWidth = 4
            ..strokeCap = ui.StrokeCap.round)
      ..drawLine(
          const ui.Offset(1, 3),
          const ui.Offset(13, -9),
          ui.Paint()
            ..color = const ui.Color(0xFFFF5A4E)
            ..strokeWidth = 1.4
            ..strokeCap = ui.StrokeCap.round)
      ..drawCircle(const ui.Offset(13, -9), 3.2, PaintKit.solid(0x88FF3B30))
      ..drawCircle(const ui.Offset(13, -9), 1.6, PaintKit.solid(0xFFFFE0DC));
    c
      ..save()
      ..translate(-5, 9)
      ..rotate(-math.pi / 4);
    final body = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-9, -2.6, 16, 5.2), const ui.Radius.circular(2.4));
    c
      ..drawRRect(body, PaintKit.lit(body.outerRect, 0xFF4A5560, light: 0.4))
      ..drawRRect(body, PaintKit.edge(0xFF4A5560, 0.7))
      ..drawRect(const ui.Rect.fromLTWH(5, -2.6, 2.4, 5.2),
          PaintKit.solid(0xFFC9CED4))
      ..drawCircle(const ui.Offset(-1, -2.6), 1.3, PaintKit.solid(0xFFE5484D))
      ..restore();
  }

  /// A grey storm cloud with a yellow bolt.
  static void _cloudBolt(ui.Canvas c) {
    final bolt = ui.Path()
      ..moveTo(1, -1)
      ..lineTo(-5, 8)
      ..lineTo(0, 8)
      ..lineTo(-3, 15)
      ..lineTo(6, 4)
      ..lineTo(1, 4)
      ..lineTo(5, -1)
      ..close();
    c
      ..drawPath(bolt, PaintKit.solid(0xFFF5C542))
      ..drawPath(bolt, PaintKit.edge(0xFFB8860B, 0.7));
    final cloud = ui.Path()
      ..addOval(ui.Rect.fromCircle(center: const ui.Offset(-7, -4), radius: 6))
      ..addOval(ui.Rect.fromCircle(center: const ui.Offset(1, -8), radius: 8))
      ..addOval(ui.Rect.fromCircle(center: const ui.Offset(9, -3), radius: 6))
      ..addRRect(ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTRB(-13, -4, 15, 3), const ui.Radius.circular(3.5)));
    final merged = ui.Path.combine(ui.PathOperation.union, cloud, ui.Path());
    _shaded(c, merged, 0xFF8C96A4, light: 0.35);
  }

  /// A green pod tube spitting a fan of seeds.
  static void _spitter(ui.Canvas c) {
    for (final (dy, a) in [(-7.0, -0.35), (0.0, 0.0), (7.0, 0.35)]) {
      c
        ..save()
        ..translate(9, dy)
        ..rotate(math.pi / 2 + a);
      _seed(c, 0.6);
      c.restore();
    }
    c
      ..save()
      ..rotate(-0.15);
    final pod = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-14, -4.5, 17, 9), const ui.Radius.circular(4.5));
    c
      ..drawRRect(pod, PaintKit.lit(pod.outerRect, 0xFF6FAE45, light: 0.4))
      ..drawRRect(pod, PaintKit.edge(0xFF6FAE45, 0.7))
      ..drawOval(const ui.Rect.fromLTWH(0.5, -3.2, 3.6, 6.4),
          PaintKit.solid(0xFF2E4A1E))
      ..restore();
  }

  /// A paw with three long claws and dug-up earth.
  static void _claws(ui.Canvas c) {
    const pad = 0xFF8D6E63;
    const claw = 0xFFEDE3D2;
    for (final (x, a) in [(-6.0, -0.35), (0.0, 0.0), (6.0, 0.35)]) {
      c
        ..save()
        ..translate(x, -4)
        ..rotate(a);
      final path = ui.Path()
        ..moveTo(-1.8, 0)
        ..quadraticBezierTo(-1.5, -9, 2.5, -12)
        ..quadraticBezierTo(1.5, -6, 1.8, 0)
        ..close();
      _shaded(c, path, claw, light: 0.4);
      c.restore();
    }
    final palm = ui.Rect.fromCenter(
        center: const ui.Offset(0, 4), width: 20, height: 13);
    c
      ..drawOval(palm, PaintKit.lit(palm, pad))
      ..drawOval(palm, PaintKit.edge(pad, 0.7));
    for (final (x, y) in [(-9.0, 12.0), (-4.0, 13.5), (8.0, 12.5)]) {
      c.drawCircle(ui.Offset(x, y), 1.8, PaintKit.solid(0xFF7A5A3A));
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
