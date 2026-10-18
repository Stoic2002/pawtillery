import 'dart:ui' as ui;

/// Small helpers for the procedural art: colour shading and soft,
/// top-left-lit fills that give flat shapes a rounded, 3D read.
abstract final class PaintKit {
  static ui.Color c(int argb) => ui.Color(argb);

  /// Mix towards white ([t] > 0) or black ([t] < 0).
  static ui.Color tone(int argb, double t) {
    final base = ui.Color(argb);
    return t >= 0
        ? ui.Color.lerp(base, const ui.Color(0xFFFFFFFF), t)!
        : ui.Color.lerp(base, const ui.Color(0xFF000000), -t)!;
  }

  static int toneArgb(int argb, double t) => tone(argb, t).toARGB32();

  /// Fill lit from the top-left: a highlight, the base colour, then a
  /// shadowed rim. [light] and [dark] set how strong each end is.
  static ui.Paint lit(ui.Rect bounds, int argb,
      {double light = 0.28, double dark = 0.34}) {
    final focus = ui.Offset(bounds.left + bounds.width * 0.32,
        bounds.top + bounds.height * 0.28);
    final radius = (bounds.width > bounds.height
            ? bounds.width
            : bounds.height) *
        0.85;
    return ui.Paint()
      ..shader = ui.Gradient.radial(
        focus,
        radius,
        [tone(argb, light), ui.Color(argb), tone(argb, -dark)],
        const [0, 0.5, 1],
      );
  }

  /// Vertical light-to-dark gradient (legs, necks, thin parts).
  static ui.Paint vertical(ui.Rect bounds, int argb,
          {double light = 0.15, double dark = 0.3}) =>
      ui.Paint()
        ..shader = ui.Gradient.linear(
          bounds.topCenter,
          bounds.bottomCenter,
          [tone(argb, light), tone(argb, -dark)],
        );

  /// Soft edge in a darker shade of the fill (not black), so parts read
  /// at small sizes without looking like a cartoon outline.
  static ui.Paint edge(int argb, double width) => ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = width
    ..color = tone(argb, -0.55).withValues(alpha: 0.75);

  /// Soft contact shadow on the ground: a radial fade squashed flat.
  static void groundShadow(
      ui.Canvas canvas, ui.Offset at, double rx, double ry) {
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..scale(1, ry / rx)
      ..drawCircle(
        ui.Offset.zero,
        rx,
        ui.Paint()
          ..shader = ui.Gradient.radial(
            ui.Offset.zero,
            rx,
            const [ui.Color(0x59000000), ui.Color(0x00000000)],
          ),
      )
      ..restore();
  }

  static ui.Paint solid(int argb) => ui.Paint()..color = ui.Color(argb);
}
