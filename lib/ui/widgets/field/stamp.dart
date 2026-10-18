import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/field_palette.dart';

/// The primary action as a rubber stamp: double border in stamp ink,
/// spaced capitals, worn ink, a hair of rotation. Pressing it "stamps":
/// the ink fills in. Use at most one per screen.
class StampButton extends StatefulWidget {
  const StampButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = FieldPalette.stamp,
    this.fontSize = 17,
    this.tilt = -1.2,
    this.minWidth = 140,
    this.round = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double fontSize;
  final double tilt;
  final double minWidth;

  /// A round seal instead of a rectangle (the Fire button).
  final bool round;

  @override
  State<StampButton> createState() => _StampButtonState();
}

class _StampButtonState extends State<StampButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final ink = enabled ? widget.color : FieldPalette.pencil;
    final filled = _down && enabled;
    final text = Text(
      widget.label.toUpperCase(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: widget.fontSize,
        letterSpacing: widget.fontSize * 0.2,
        color: filled ? FieldPalette.paper : ink,
      ),
    );
    // Shrink-wraps the label (at least minWidth wide), centred.
    final body = CustomPaint(
      painter: _StampPainter(ink, filled: filled, round: widget.round),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.round ? 0 : widget.minWidth,
          minHeight: 48,
        ),
        child: Padding(
          padding: widget.round
              ? const EdgeInsets.all(22)
              : const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Align(widthFactor: 1, heightFactor: 1, child: text),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onPressed!();
              }
            : null,
        child: Transform.rotate(
          angle: widget.tilt * math.pi / 180,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 70),
            scale: filled ? 0.96 : 1,
            child: ExcludeSemantics(child: body),
          ),
        ),
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  _StampPainter(this.ink, {required this.filled, required this.round});
  final Color ink;
  final bool filled;
  final bool round;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    final inner = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    // Always on paper, so the stamp reads over the scene too.
    final paper = Paint()
      ..color = filled
          ? ink
          : Color.alphaBlend(ink.withValues(alpha: 0.07), FieldPalette.paper);
    round ? canvas.drawOval(rect, paper) : canvas.drawRect(rect, paper);
    if (round) {
      canvas
        ..drawOval(rect.deflate(1.2), outer)
        ..drawOval(rect.deflate(5), inner);
    } else {
      canvas
        ..drawRect(rect.deflate(1.2), outer)
        ..drawRect(rect.deflate(5), inner);
    }
    // Worn ink: paper showing through in small gaps.
    final rng = math.Random(7);
    final gap = Paint()..color = FieldPalette.paper.withValues(alpha: 0.75);
    for (var i = 0; i < 26; i++) {
      final onTop = rng.nextBool();
      final t = rng.nextDouble();
      final p = onTop
          ? Offset(t * size.width, rng.nextBool() ? 1.2 : size.height - 1.2)
          : Offset(rng.nextBool() ? 1.2 : size.width - 1.2, t * size.height);
      if (round) continue;
      canvas.drawCircle(p, 0.6 + rng.nextDouble() * 0.9, gap);
    }
  }

  @override
  bool shouldRepaint(_StampPainter old) =>
      old.ink != ink || old.filled != filled || old.round != round;
}

/// A stamp that is only a mark (e.g. the winner on the field report).
class StampMark extends StatelessWidget {
  const StampMark({
    super.key,
    required this.label,
    this.color = FieldPalette.stamp,
    this.fontSize = 22,
    this.tilt = -4,
  });

  final String label;
  final Color color;
  final double fontSize;
  final double tilt;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: tilt * math.pi / 180,
    child: CustomPaint(
      painter: _StampPainter(color, filled: false, round: false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            letterSpacing: fontSize * 0.2,
            color: color,
          ),
        ),
      ),
    ),
  );
}

/// A secondary action: label in ink inside a hairline box.
class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.minWidth = 120,
  });

  final String label;
  final VoidCallback? onPressed;
  final double minWidth;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      minimumSize: Size(minWidth, 48),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    ),
    onPressed: onPressed,
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(letterSpacing: 2, fontSize: 14),
    ),
  );
}

/// A line of a table of contents: numeral, title, dot leaders, page mark.
/// Used for the main menu's actions.
class ContentsEntry extends StatelessWidget {
  const ContentsEntry({
    super.key,
    required this.numeral,
    required this.label,
    required this.onTap,
    this.page,
  });

  final String numeral;
  final String label;
  final VoidCallback? onTap;
  final String? page;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? FieldPalette.pencil : FieldPalette.ink;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 34,
              child: Text(
                numeral,
                style: const TextStyle(
                  fontSize: 15,
                  color: FieldPalette.inkSoft,
                ),
              ),
            ),
            Text(label, style: TextStyle(fontSize: 19, color: color)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6, right: 6, bottom: 5),
                child: CustomPaint(
                  painter: _DotsPainter(),
                  size: const Size(0, 2),
                ),
              ),
            ),
            Text(
              page ?? '',
              style: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: FieldPalette.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = FieldPalette.pencil;
    for (var x = 0.0; x < size.width; x += 5) {
      canvas.drawCircle(Offset(x, size.height / 2), 0.8, p);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => false;
}

/// A specimen tag: a small paper label with a punched hole and string.
class SpecimenTag extends StatelessWidget {
  const SpecimenTag({
    super.key,
    required this.child,
    this.ink = FieldPalette.ink,
  });

  final Widget child;
  final Color ink;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _TagPainter(ink),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 3, 8, 3),
      child: child,
    ),
  );
}

class _TagPainter extends CustomPainter {
  _TagPainter(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final path = Path()
      ..moveTo(h * 0.45, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, h)
      ..lineTo(h * 0.45, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = FieldPalette.paper)
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = ink,
      )
      ..drawCircle(Offset(h * 0.42, h / 2), 2, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_TagPainter old) => old.ink != ink;
}
