import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/breeds.dart';
import '../../config/families.dart';
import '../../config/teams.dart';
import '../../game/art/animal_art.dart';

/// Scenic background for the menus: a sunset sky, a warm sun, layered
/// hills fading into the distance and a few animals on the grass, with a
/// dark wash on the left so menu text stays readable.
class MenuBackdrop extends StatelessWidget {
  const MenuBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: CustomPaint(painter: _BackdropPainter())),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xB3111A22), Color(0x22111A22)],
                stops: [0.25, 0.75],
              ),
            ),
          ),
          child,
        ],
      );
}

/// Static on purpose: a still scene costs nothing on menu screens.
class _BackdropPainter extends CustomPainter {
  static final _cast = [
    (Families.cat, 0),
    (Families.dog, 1),
    (Families.rabbit, 0),
    (Families.duck, 1),
    (Families.goat, 0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF233B5E), Color(0xFFE08A5A), Color(0xFFF6C88A)],
          stops: [0, 0.55, 0.8],
        ).createShader(Offset.zero & size),
    );
    final sun = Offset(w * 0.88, h * 0.42);
    canvas
      ..drawCircle(
          sun,
          h * 0.5,
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0xFFFFE2A8).withValues(alpha: 0.55),
              const Color(0x00FFE2A8),
            ]).createShader(Rect.fromCircle(center: sun, radius: h * 0.5)))
      ..drawCircle(sun, h * 0.08, Paint()..color = const Color(0xFFFFEBC4));

    for (final (base, amp, color, phase) in const [
      (0.62, 0.05, Color(0xFF8E6E78), 0.0),
      (0.7, 0.06, Color(0xFF6E5A5E), 2.0),
      (0.8, 0.05, Color(0xFF4E5A3E), 4.0),
    ]) {
      final path = Path()..moveTo(0, h);
      for (var x = 0.0; x <= w; x += 12) {
        path.lineTo(
            x,
            h * base -
                h * amp * math.sin(x / w * 5 + phase) -
                h * amp * 0.4 * math.sin(x / w * 13 + phase));
      }
      path
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
    // Grass strip with the animals.
    final ground = h * 0.9;
    canvas.drawRect(Rect.fromLTRB(0, ground, w, h),
        Paint()..color = const Color(0xFF3E5A2E));
    // Fit the cast into the right half without overlapping.
    final slot = w * 0.5 / _cast.length;
    final scale = math.min(h / 160, slot / 44);
    for (var i = 0; i < _cast.length; i++) {
      final (family, team) = _cast[i];
      final x = w * 0.47 + slot * (i + 0.5);
      canvas
        ..save()
        ..translate(x, ground + 1)
        ..scale((i.isEven ? 1 : -1) * scale, scale);
      AnimalArt.draw(canvas,
          familyId: family.id,
          breedId: Breeds.ofFamily(family.id)[i % 3].id,
          teamArgb: Teams.styles[team].colorArgb,
          pose: AnimalPose.idle);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => false;
}
