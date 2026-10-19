import 'dart:math' as math;
import 'dart:ui';

import 'package:pawtillery/app/paw_palette.dart';
import 'package:pawtillery/game/art/animal_art.dart';

/// Which part of the launcher icon to paint.
enum AppIconLayer {
  /// Legacy Android icon: the whole picture in a rounded square on a
  /// transparent canvas.
  full,

  /// iOS: the whole picture edge to edge, opaque (iOS rounds it).
  square,

  /// Adaptive icon background: sky and hill, edge to edge.
  background,

  /// Adaptive icon foreground: the pet and its shot, transparent.
  foreground,

  /// Android 13 themed icon: the foreground as one white silhouette.
  monochrome,
}

/// The launcher icon, code-drawn in the redesign's style (no image
/// assets): an orange-collared chibi cat standing on the menu's green hill
/// under a blue sky, with a dashed shot arc ending in a lit bomb.
///
/// Everything is laid out in a 100 × 100 content box. Each layer maps that
/// box into the canvas: adaptive layers keep it inside the 66/108 safe zone,
/// the others fill most of the icon.
void paintAppIcon(Canvas canvas, Size size, {required AppIconLayer layer}) {
  final adaptive =
      layer == AppIconLayer.background ||
      layer == AppIconLayer.foreground ||
      layer == AppIconLayer.monochrome;
  final contentFrac = adaptive
      ? 0.66
      : (layer == AppIconLayer.full ? 0.9 : 1.0);
  final box = size.shortestSide * contentFrac;
  final origin = Offset((size.width - box) / 2, (size.height - box) / 2);

  void inBox(void Function() draw) {
    canvas
      ..save()
      ..translate(origin.dx, origin.dy)
      ..scale(box / 100);
    draw();
    canvas.restore();
  }

  switch (layer) {
    case AppIconLayer.full:
      final rect =
          Offset(size.width * 0.04, size.height * 0.04) &
          Size(size.width * 0.92, size.height * 0.92);
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(size.width * 0.2),
      );
      canvas
        ..save()
        ..clipRRect(rrect);
      inBox(() => _background(canvas, origin, box, size));
      inBox(() => _foreground(canvas));
      canvas
        ..restore()
        ..drawRRect(
          rrect.deflate(size.width * 0.012),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * 0.024
            ..color = Paw.ink,
        );
    case AppIconLayer.square:
      inBox(() => _background(canvas, origin, box, size));
      inBox(() => _foreground(canvas));
    case AppIconLayer.background:
      inBox(() => _background(canvas, origin, box, size));
    case AppIconLayer.foreground:
      inBox(() => _foreground(canvas));
    case AppIconLayer.monochrome:
      canvas.saveLayer(
        Offset.zero & size,
        Paint()
          ..colorFilter = const ColorFilter.mode(
            Color(0xFFFFFFFF),
            BlendMode.srcIn,
          ),
      );
      inBox(() => _foreground(canvas, mono: true));
      canvas.restore();
  }
}

/// Content-box coordinates of the canvas edges, so the sky and hill run
/// edge to edge whatever the mapping.
Rect _canvasInBox(Offset origin, double box, Size size) {
  final k = 100 / box;
  return Rect.fromLTWH(
    -origin.dx * k,
    -origin.dy * k,
    size.width * k,
    size.height * k,
  );
}

void _background(Canvas canvas, Offset origin, double box, Size size) {
  final all = _canvasInBox(origin, box, size);
  canvas.drawRect(
    all,
    Paint()
      ..shader = Gradient.linear(Offset(0, all.top), Offset(0, all.bottom), [
        Paw.skyTop,
        Paw.skyBottom,
      ]),
  );

  // Soft sun glow, top left.
  canvas.drawCircle(
    const Offset(18, 16),
    30,
    Paint()
      ..shader = Gradient.radial(const Offset(18, 16), 30, [
        const Color(0x66FFF6E6),
        const Color(0x00FFF6E6),
      ]),
  );

  // Two cream clouds with ink outlines.
  for (final (c, s) in [
    (const Offset(24, 30), 1.0),
    (const Offset(82, 52), 0.7),
  ]) {
    final cloud = Path()
      ..addOval(
        Rect.fromCircle(center: c + Offset(-7 * s, 2 * s), radius: 5 * s),
      )
      ..addOval(Rect.fromCircle(center: c + Offset(0, -1 * s), radius: 7 * s))
      ..addOval(
        Rect.fromCircle(center: c + Offset(8 * s, 2 * s), radius: 5 * s),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(c.dx - 12 * s, c.dy, c.dx + 13 * s, c.dy + 7 * s),
          Radius.circular(3.5 * s),
        ),
      );
    final merged = Path.combine(PathOperation.union, cloud, Path());
    canvas
      ..drawPath(merged, Paint()..color = const Color(0xFFFFFFFF))
      ..drawPath(
        merged,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Paw.ink.withValues(alpha: 0.35),
      );
  }

  // Back hill, then the front hill the pet stands on.
  final back = Path()
    ..moveTo(all.left, 74)
    ..quadraticBezierTo(70, 56, all.right, 70)
    ..lineTo(all.right, all.bottom)
    ..lineTo(all.left, all.bottom)
    ..close();
  canvas.drawPath(back, Paint()..color = Paw.hillLight);

  final front = Path()
    ..moveTo(all.left, 82)
    ..quadraticBezierTo(38, 68, all.right, 84)
    ..lineTo(all.right, all.bottom)
    ..lineTo(all.left, all.bottom)
    ..close();
  canvas
    ..drawPath(front, Paint()..color = Paw.hill)
    ..drawPath(
      front,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Paw.ink,
    );
}

void _foreground(Canvas canvas, {bool mono = false}) {
  // Ground shadow under the pet.
  if (!mono) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(36, 76.5), width: 40, height: 6),
      Paint()..color = Paw.ink.withValues(alpha: 0.22),
    );
  }

  // The pet, feet on the hill crest, about half the icon tall.
  const scale = 52 / AnimalArt.height;
  canvas
    ..save()
    ..translate(36, 77)
    ..scale(scale);
  AnimalArt.draw(
    canvas,
    familyId: 'cat',
    breedId: null,
    teamArgb: Paw.orange.toARGB32(),
    pose: AnimalPose.idle,
  );
  canvas.restore();

  // Dashed shot arc from above the pet's head to the bomb.
  final arc = Path()
    ..moveTo(52, 32)
    ..quadraticBezierTo(64, 8, 76, 22);
  final dash = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..color = mono ? const Color(0xFFFFFFFF) : Paw.cream;
  final outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5.4
    ..strokeCap = StrokeCap.round
    ..color = Paw.ink;
  for (final metric in arc.computeMetrics()) {
    for (var d = 0.0; d < metric.length - 4; d += 7) {
      final seg = metric.extractPath(d, math.min(d + 3.2, metric.length));
      if (!mono) canvas.drawPath(seg, outline);
      canvas.drawPath(seg, dash);
    }
  }

  // The bomb: an ink ball with a highlight, a cream band, and a fuse spark.
  const c = Offset(79, 28);
  canvas
    ..drawCircle(c, 8.5, Paint()..color = Paw.ink)
    ..drawCircle(
      c,
      7,
      Paint()
        ..shader = Gradient.radial(c + const Offset(-2.5, -2.5), 9, [
          const Color(0xFF6A5A4C),
          const Color(0xFF2B2118),
        ]),
    );
  if (!mono) {
    canvas.drawCircle(
      c + const Offset(-2.6, -2.8),
      1.8,
      Paint()..color = const Color(0xCCFFF6E6),
    );
  }
  // Cap and fuse.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: c + const Offset(3.6, -6.6), width: 5, height: 4),
      const Radius.circular(1),
    ),
    Paint()..color = Paw.ink,
  );
  final fuse = Path()
    ..moveTo(c.dx + 4.4, c.dy - 8.4)
    ..quadraticBezierTo(c.dx + 6.5, c.dy - 12, c.dx + 9.5, c.dy - 11);
  canvas.drawPath(
    fuse,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = Paw.ink,
  );
  // Spark: a small yellow-orange star.
  final spark = Path();
  const sc = Offset(89.5, 16.5);
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? 4.6 : 1.9;
    final a = -math.pi / 2 + i * math.pi / 5;
    final p = sc + Offset(math.cos(a) * r, math.sin(a) * r);
    i == 0 ? spark.moveTo(p.dx, p.dy) : spark.lineTo(p.dx, p.dy);
  }
  spark.close();
  canvas
    ..drawPath(
      spark,
      Paint()..color = mono ? const Color(0xFFFFFFFF) : Paw.yellow,
    )
    ..drawPath(
      spark,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round
        ..color = mono ? const Color(0xFFFFFFFF) : Paw.orangeDeep,
    );
}
