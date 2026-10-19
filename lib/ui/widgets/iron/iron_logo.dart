import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../app/iron_palette.dart';
import '../../../app/iron_theme.dart';

/// The game's wordmark: the name in Cinzel capitals cast in brass (a
/// light-to-deep gradient, an engraved shadow), led by a brass medallion
/// with a paw. Read by screen readers as plain [title].
class IronLogo extends StatelessWidget {
  const IronLogo({super.key, required this.title, this.size = 60});

  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = IronTheme.displayStyle(
      size: size,
      weight: 900,
      letterSpacing: size * 0.08,
    );
    return Semantics(
      label: title,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: size * 1.05,
            child: const CustomPaint(painter: PawBadgePainter()),
          ),
          SizedBox(width: size * 0.25),
          Stack(
            children: [
              // Engraved shadow under the cast letters.
              Transform.translate(
                offset: Offset(0, size * 0.05),
                child: Text(
                  title.toUpperCase(),
                  style: style.copyWith(color: const Color(0xE6000000)),
                ),
              ),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    IronPalette.brassLight,
                    IronPalette.brass,
                    IronPalette.brassDeep,
                  ],
                  stops: [0.1, 0.55, 1],
                ).createShader(bounds),
                child: Text(title.toUpperCase(), style: style),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A brass medallion with a raised paw on dark iron.
class PawBadgePainter extends CustomPainter {
  const PawBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final r = s * 0.46;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas
      ..drawCircle(
        c.translate(0, s * 0.04),
        r,
        Paint()
          ..color = const Color(0xAA000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04),
      )
      ..drawCircle(
        c,
        r,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [IronPalette.brassLight, IronPalette.brassDeep],
          ).createShader(rect),
      )
      ..drawCircle(
        c,
        r * 0.8,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFF34363C), Color(0xFF121316)],
          ).createShader(rect),
      );
    // Notches around the rim.
    final notch = Paint()
      ..color = IronPalette.brassDeep
      ..strokeWidth = s * 0.012;
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.84,
        c + Offset(math.cos(a), math.sin(a)) * r * 0.95,
        notch,
      );
    }
    final paw = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [IronPalette.brassLight, IronPalette.brass],
      ).createShader(rect);
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, s * 0.09),
        width: s * 0.3,
        height: s * 0.24,
      ),
      paw,
    );
    for (final (dx, dy) in const [
      (-0.15, -0.06),
      (-0.055, -0.14),
      (0.055, -0.14),
      (0.15, -0.06),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: c.translate(dx * s, dy * s),
          width: s * 0.1,
          height: s * 0.12,
        ),
        paw,
      );
    }
  }

  @override
  bool shouldRepaint(PawBadgePainter old) => false;
}
