import 'dart:math' as math;
import 'dart:ui';

import 'package:pawtillery/app/paw_palette.dart';

/// Which part of the launcher icon to paint.
enum AppIconLayer {
  /// Legacy Android icon: the whole picture in a rounded square on a
  /// transparent canvas.
  full,

  /// iOS: the whole picture edge to edge, opaque (iOS rounds it).
  square,

  /// Adaptive icon background: the warm gradient, edge to edge.
  background,

  /// Adaptive icon foreground: the bomb, transparent.
  foreground,

  /// Android 13 themed icon: the foreground as one white silhouette.
  monochrome,
}

/// The launcher icon, code-drawn (no image assets) and kept flat and
/// simple so it reads at 48 px: one round ink bomb with a cream paw print
/// on its face and a lit fuse, on a warm orange gradient.
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
      : (layer == AppIconLayer.full ? 0.86 : 0.94);
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
        Radius.circular(size.width * 0.22),
      );
      canvas
        ..save()
        ..clipRRect(rrect);
      inBox(() => _background(canvas, origin, box, size));
      inBox(() => _foreground(canvas));
      canvas.restore();
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

/// Content-box coordinates of the canvas edges, so the background runs
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

const _top = Color(0xFFFFB066);
const _bottom = Color(0xFFF26B1D);

/// Bomb centre and radius in the content box.
const _c = Offset(47, 56);
const _r = 30.0;

void _background(Canvas canvas, Offset origin, double box, Size size) {
  final all = _canvasInBox(origin, box, size);
  canvas
    ..drawRect(
      all,
      Paint()
        ..shader = Gradient.linear(all.topLeft, all.bottomRight, [
          _top,
          _bottom,
        ]),
    )
    // A soft light from the top left.
    ..drawCircle(
      const Offset(22, 14),
      70,
      Paint()
        ..shader = Gradient.radial(const Offset(22, 14), 70, [
          const Color(0x55FFF6E6),
          const Color(0x00FFF6E6),
        ]),
    );
}

void _foreground(Canvas canvas, {bool mono = false}) {
  const white = Color(0xFFFFFFFF);

  // Soft shadow under the bomb.
  if (!mono) {
    canvas.drawOval(
      Rect.fromCenter(
        center: _c + const Offset(3, _r + 4),
        width: _r * 1.7,
        height: 7,
      ),
      Paint()
        ..color = const Color(0x40A83E00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  // Cap: a short rounded block on the bomb's shoulder, tilted outwards.
  canvas
    ..save()
    ..translate(_c.dx + 21.5, _c.dy - 21.5)
    ..rotate(math.pi / 4)
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 14, height: 11),
        const Radius.circular(3),
      ),
      Paint()..color = mono ? white : const Color(0xFF4A3B2E),
    )
    ..restore();

  // Fuse: from the cap up towards the spark, a gentle S.
  final fuse = Path()
    ..moveTo(_c.dx + 25, _c.dy - 25)
    ..cubicTo(78, 26, 70, 18, 78, 13);
  canvas.drawPath(
    fuse,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..color = mono ? white : Paw.cream,
  );

  // The bomb body.
  if (mono) {
    canvas.drawCircle(_c, _r, Paint()..color = white);
  } else {
    canvas.drawCircle(
      _c,
      _r,
      Paint()
        ..shader = Gradient.radial(_c + const Offset(-10, -12), _r * 1.5, [
          const Color(0xFF55463A),
          Paw.ink,
        ]),
    );
    // Rim light along the top left.
    canvas.drawArc(
      Rect.fromCircle(center: _c, radius: _r - 4.5),
      math.pi * 1.05,
      math.pi * 0.42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x66FFF6E6),
    );
  }

  // Paw print on the bomb's face (cut out of the silhouette when mono).
  final paw = Paint()..color = mono ? white : Paw.cream;
  // Mono draws inside the colour-filter layer, so this cuts the bomb.
  if (mono) paw.blendMode = BlendMode.dstOut;
  final pad = Path()
    ..moveTo(_c.dx, _c.dy + 1)
    ..cubicTo(
      _c.dx + 8,
      _c.dy + 1,
      _c.dx + 13,
      _c.dy + 9,
      _c.dx + 13,
      _c.dy + 13,
    )
    ..cubicTo(_c.dx + 13, _c.dy + 18, _c.dx + 8, _c.dy + 19, _c.dx, _c.dy + 17)
    ..cubicTo(
      _c.dx - 8,
      _c.dy + 19,
      _c.dx - 13,
      _c.dy + 18,
      _c.dx - 13,
      _c.dy + 13,
    )
    ..cubicTo(_c.dx - 13, _c.dy + 9, _c.dx - 8, _c.dy + 1, _c.dx, _c.dy + 1)
    ..close();
  canvas.drawPath(pad, paw);
  for (final (dx, dy, rx, ry) in const [
    (-14.0, -2.0, 4.2, 5.2),
    (-5.5, -9.5, 4.4, 5.6),
    (5.5, -9.5, 4.4, 5.6),
    (14.0, -2.0, 4.2, 5.2),
  ]) {
    canvas.drawOval(
      Rect.fromCenter(
        center: _c + Offset(dx, dy),
        width: rx * 2,
        height: ry * 2,
      ),
      paw,
    );
  }

  // Spark at the end of the fuse: a glow, then a four-point star.
  const sc = Offset(79, 12.5);
  if (!mono) {
    canvas.drawCircle(
      sc,
      11,
      Paint()
        ..shader = Gradient.radial(sc, 11, [
          const Color(0xAAFFF3B0),
          const Color(0x00FFF3B0),
        ]),
    );
  }
  final star = Path();
  for (var i = 0; i < 8; i++) {
    final r = i.isEven ? 8.0 : 2.4;
    final a = -math.pi / 2 + i * math.pi / 4;
    final p = sc + Offset(math.cos(a) * r, math.sin(a) * r);
    i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
  }
  star.close();
  canvas.drawPath(
    star,
    Paint()..color = mono ? white : const Color(0xFFFFF3B0),
  );
  if (!mono) canvas.drawCircle(sc, 2.2, Paint()..color = white);
}
