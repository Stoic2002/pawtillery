import 'package:flutter/material.dart';

/// Placeholder logo: a paw print. Replaced by real art later.
class PawLogo extends StatelessWidget {
  const PawLogo({super.key, this.size = 96, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _PawPainter(color ?? Theme.of(context).colorScheme.primary),
        ),
      );
}

class _PawPainter extends CustomPainter {
  _PawPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final s = size.shortestSide;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(s * 0.5, s * 0.66), width: s * 0.5, height: s * 0.42),
        p);
    for (final (dx, dy) in const [
      (0.2, 0.38),
      (0.38, 0.22),
      (0.62, 0.22),
      (0.8, 0.38),
    ]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(s * dx, s * dy), width: s * 0.17, height: s * 0.22),
          p);
    }
  }

  @override
  bool shouldRepaint(_PawPainter old) => old.color != color;
}
