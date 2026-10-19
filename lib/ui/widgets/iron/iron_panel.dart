import 'package:flutter/material.dart';

import '../../../app/iron_palette.dart';
import 'iron_text.dart';

enum IronPanelStyle {
  /// A forged iron plate for menus and dialogs.
  plate,

  /// Translucent dark iron for the HUD over the arena.
  night,
}

/// A forged panel: dark iron face, a fine brass inlay inset from the edge,
/// brass corner brackets and a soft shadow. An optional [title] is
/// engraved across the top between ornamental rules.
class IronPanel extends StatelessWidget {
  const IronPanel({
    super.key,
    required this.child,
    this.style = IronPanelStyle.plate,
    this.padding = const EdgeInsets.all(14),
    this.radius = 4,
    this.accent,
    this.title,
    this.titleTone,
  });

  final Widget child;
  final IronPanelStyle style;
  final EdgeInsets padding;
  final double radius;

  /// Colours the inlay (e.g. the active team).
  final Color? accent;
  final String? title;
  final IronTone? titleTone;

  @override
  Widget build(BuildContext context) {
    final night = style == IronPanelStyle.night;
    return CustomPaint(
      painter: _PanelPainter(
        night: night,
        inlay: accent ?? IronPalette.brass,
        radius: radius.clamp(0, 6).toDouble(),
      ),
      child: Padding(
        padding: padding,
        child: title == null
            ? child
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IronRibbon(
                    title!,
                    tone: titleTone ?? IronTone.brass,
                    fontSize: 18,
                    plate: false,
                  ),
                  const SizedBox(height: 10),
                  Flexible(child: child),
                ],
              ),
      ),
    );
  }
}

class _PanelPainter extends CustomPainter {
  _PanelPainter({
    required this.night,
    required this.inlay,
    required this.radius,
  });

  final bool night;
  final Color inlay;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas
      ..drawRRect(
        r.shift(const Offset(0, 4)),
        Paint()
          ..color = const Color(0xAA000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawRRect(r, Paint()..color = IronPalette.ink)
      ..drawRRect(
        r.deflate(1),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: night
                ? const [Color(0xE6202227), Color(0xE6121316)]
                : const [Color(0xFF2B2D33), Color(0xFF17181C)],
          ).createShader(rect),
      );
    // Fine inlay line inset from the edge.
    final inset = night ? 3.0 : 4.0;
    canvas.drawRRect(
      r.deflate(inset),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = inlay.withValues(alpha: night ? 0.55 : 0.7),
    );
    // Brass corner brackets.
    if (size.width > 60 && size.height > 40) {
      final b = Paint()
        ..color = inlay
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.square;
      const l = 10.0;
      final i = inset - 1.5;
      for (final (x, y, dx, dy) in [
        (i, i, 1.0, 1.0),
        (size.width - i, i, -1.0, 1.0),
        (i, size.height - i, 1.0, -1.0),
        (size.width - i, size.height - i, -1.0, -1.0),
      ]) {
        canvas
          ..drawLine(Offset(x, y), Offset(x + dx * l, y), b)
          ..drawLine(Offset(x, y), Offset(x, y + dy * l), b)
          ..drawCircle(
            Offset(x + dx * 4, y + dy * 4),
            1.3,
            Paint()..color = Color.lerp(inlay, Colors.white, 0.3)!,
          );
      }
    }
  }

  @override
  bool shouldRepaint(_PanelPainter old) =>
      old.night != night || old.inlay != inlay || old.radius != radius;
}

/// A title engraved between two ornamental rules with diamond studs:
/// screen headers, dialog titles, the turn banner. With [plate] it sits on
/// a dark iron plate of its own.
class IronRibbon extends StatelessWidget {
  const IronRibbon(
    this.text, {
    super.key,
    this.tone = IronTone.brass,
    this.fontSize = 22,
    this.plate = true,
  });

  final String text;
  final IronTone tone;
  final double fontSize;
  final bool plate;

  @override
  Widget build(BuildContext context) {
    // Brass titles stay brass; team tones show their own colour.
    final color = tone == IronTone.brass
        ? IronPalette.brassLight
        : Color.lerp(tone.light, Colors.white, 0.3)!;
    final rule = color.withValues(alpha: 0.8);
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Rule(color: rule, flip: false),
        const SizedBox(width: 8),
        Flexible(
          child: IronText(
            text,
            size: fontSize * 0.8,
            color: color,
            maxLines: 1,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(width: 8),
        _Rule(color: rule, flip: true),
      ],
    );
    if (!plate) return Center(child: title);
    return CustomPaint(
      painter: _PlatePainter(color),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 7, 16, 8),
        child: title,
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.color, required this.flip});
  final Color color;
  final bool flip;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 28,
    height: 10,
    child: CustomPaint(painter: _RulePainter(color, flip)),
  );
}

class _RulePainter extends CustomPainter {
  _RulePainter(this.color, this.flip);
  final Color color;
  final bool flip;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final line = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    final d = flip ? 4.0 : size.width - 4;
    canvas
      ..drawLine(
        Offset(flip ? 9 : 0, y),
        Offset(flip ? size.width : size.width - 9, y),
        line,
      )
      ..drawPath(
        Path()
          ..moveTo(d, y - 4)
          ..lineTo(d + 4, y)
          ..lineTo(d, y + 4)
          ..lineTo(d - 4, y)
          ..close(),
        Paint()..color = color,
      );
  }

  @override
  bool shouldRepaint(_RulePainter old) => old.color != color;
}

class _PlatePainter extends CustomPainter {
  _PlatePainter(this.accent);
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(3),
    );
    canvas
      ..drawRRect(
        r.shift(const Offset(0, 3)),
        Paint()
          ..color = const Color(0x99000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawRRect(r, Paint()..color = const Color(0xEE16171A))
      ..drawRRect(
        r.deflate(2.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = accent.withValues(alpha: 0.6),
      );
  }

  @override
  bool shouldRepaint(_PlatePainter old) => old.accent != accent;
}

/// A dialog: an [IronPanel] with an engraved title, centred over a dim
/// barrier, fading and settling in.
Future<T?> showIronDialog<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext) builder,
  double maxWidth = 380,
  IronTone titleTone = IronTone.brass,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: title,
  barrierColor: const Color(0xB3050508),
  transitionDuration: const Duration(milliseconds: 200),
  pageBuilder: (context, _, _) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            type: MaterialType.transparency,
            child: IronPanel(
              title: title,
              titleTone: titleTone,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: builder(context),
            ),
          ),
        ),
      ),
    ),
  ),
  transitionBuilder: (context, anim, _, child) {
    final t = Curves.easeOutCubic.transform(anim.value);
    return Opacity(
      opacity: anim.value,
      child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
    );
  },
);
