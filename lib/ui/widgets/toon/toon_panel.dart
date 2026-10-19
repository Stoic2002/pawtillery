import 'package:flutter/material.dart';

import '../../../app/toon_palette.dart';
import 'toon_text.dart';

enum ToonPanelStyle {
  /// Cream card for menus and dialogs.
  cream,

  /// Translucent night-blue for the HUD over the arena.
  night,
}

/// A rounded panel with a thick outline, an inner highlight and a solid
/// drop shadow. An optional [title] sits on a ribbon across the top edge.
class ToonPanel extends StatelessWidget {
  const ToonPanel({
    super.key,
    required this.child,
    this.style = ToonPanelStyle.cream,
    this.padding = const EdgeInsets.all(14),
    this.radius = 18,
    this.accent,
    this.title,
    this.titleTone,
  });

  final Widget child;
  final ToonPanelStyle style;
  final EdgeInsets padding;
  final double radius;

  /// Colours the outline (e.g. the active team).
  final Color? accent;
  final String? title;
  final ToonTone? titleTone;

  @override
  Widget build(BuildContext context) {
    final night = style == ToonPanelStyle.night;
    Widget panel = CustomPaint(
      painter: _PanelPainter(
        fill: night ? ToonPalette.night : ToonPalette.cream,
        line: accent ?? (night ? ToonPalette.nightLine : ToonPalette.outline),
        radius: radius,
        night: night,
        accented: accent != null,
      ),
      child: Padding(
        padding: title == null
            ? padding
            : padding.copyWith(top: padding.top + 22),
        child: child,
      ),
    );
    if (title != null) {
      panel = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(padding: const EdgeInsets.only(top: 18), child: panel),
          ToonRibbon(title!, tone: titleTone ?? ToonTone.sun),
        ],
      );
    }
    return panel;
  }
}

class _PanelPainter extends CustomPainter {
  _PanelPainter({
    required this.fill,
    required this.line,
    required this.radius,
    required this.night,
    required this.accented,
  });

  final Color fill;
  final Color line;
  final double radius;
  final bool night;
  final bool accented;

  @override
  void paint(Canvas canvas, Size size) {
    final w = accented ? 3.5 : 3.0;
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(w / 2),
      Radius.circular(radius),
    );
    canvas
      ..drawRRect(
        r.shift(const Offset(0, 5)),
        Paint()..color = const Color(0xFF000000).withValues(alpha: night ? 0.3 : 0.28),
      )
      ..drawRRect(r, Paint()..color = fill);
    if (!night) {
      // A warm shade along the bottom, as if lit from above.
      canvas
        ..save()
        ..clipRRect(r)
        ..drawRect(
          Rect.fromLTWH(0, size.height * 0.55, size.width, size.height),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ToonPalette.creamShade.withValues(alpha: 0),
                ToonPalette.creamShade,
              ],
            ).createShader(
              Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45),
            ),
        )
        ..restore();
    }
    canvas
      ..drawRRect(
        r.deflate(w / 2 + 1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFFFFFFFF).withValues(alpha: night ? 0.14 : 0.8),
      )
      ..drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = line,
      );
  }

  @override
  bool shouldRepaint(_PanelPainter old) =>
      old.fill != fill || old.line != line || old.radius != radius;
}

/// A title ribbon with folded tails: screen and dialog titles.
class ToonRibbon extends StatelessWidget {
  const ToonRibbon(
    this.text, {
    super.key,
    this.tone = ToonTone.sun,
    this.fontSize = 22,
  });

  final String text;
  final ToonTone tone;
  final double fontSize;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _RibbonPainter(tone),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(34, 6, 34, 10),
      child: ToonText(text, size: fontSize, maxLines: 1),
    ),
  );
}

class _RibbonPainter extends CustomPainter {
  _RibbonPainter(this.tone);
  final ToonTone tone;

  @override
  void paint(Canvas canvas, Size size) {
    const tail = 16.0;
    const drop = 7.0;
    final h = size.height - 4;
    final line = Paint()
      ..color = ToonPalette.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    // Tails behind the band, notched, in the deep tone.
    for (final side in [-1.0, 1.0]) {
      final edge = side < 0 ? 10.0 : size.width - 10.0;
      final x0 = edge - side * 12;
      final x1 = edge + side * tail;
      final tailPath = Path()
        ..moveTo(x0, drop)
        ..lineTo(x1, drop)
        ..lineTo(x1 - side * 8, drop + h / 2)
        ..lineTo(x1, drop + h)
        ..lineTo(x0, drop + h)
        ..close();
      canvas
        ..drawPath(tailPath, Paint()..color = tone.deep)
        ..drawPath(tailPath, line);
      // The fold: a dark triangle where the band turns under.
      final fold = Path()
        ..moveTo(x0, h)
        ..lineTo(x0, drop + h)
        ..lineTo(edge, h)
        ..close();
      canvas
        ..drawPath(fold, Paint()..color = ToonPalette.outline)
        ..drawPath(fold, line);
    }
    final band = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 0, size.width - 20, h),
      const Radius.circular(6),
    );
    canvas
      ..drawRRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tone.light, tone.deep],
            stops: const [0.4, 1],
          ).createShader(band.outerRect),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(16, 3.5, size.width - 32, h * 0.32),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0x40FFFFFF),
      )
      ..drawRRect(band, line);
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.tone.light != tone.light;
}

/// A dialog that is a [ToonPanel] with a ribbon title, centred over a dim
/// barrier.
Future<T?> showToonDialog<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext) builder,
  double maxWidth = 380,
  ToonTone titleTone = ToonTone.sun,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: title,
  barrierColor: const Color(0x99101820),
  transitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (context, _, _) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            type: MaterialType.transparency,
            child: ToonPanel(
              title: title,
              titleTone: titleTone,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: builder(context),
            ),
          ),
        ),
      ),
    ),
  ),
  transitionBuilder: (context, anim, _, child) {
    final t = Curves.easeOutBack.transform(anim.value);
    return Opacity(
      opacity: anim.value,
      child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
    );
  },
);
