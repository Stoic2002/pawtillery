import 'package:flutter/material.dart';

import '../../../app/iron_palette.dart';
import 'iron_icons.dart';
import 'iron_text.dart';

/// Paints a forged plate: a dark edge, a two-tone metal face, a thin brass
/// border with a highlight along its top, rivets in the corners, and a
/// soft shadow underneath. Pressing darkens it and drops it a pixel.
/// Shared by buttons, badges, chips and tiles.
///
/// [depth] is space reserved under the plate for its shadow; [gloss]
/// turns the corner rivets on.
class IronSlabPainter extends CustomPainter {
  IronSlabPainter({
    required this.tone,
    this.radius = 4,
    this.depth = 3,
    this.pressed = false,
    this.outlineWidth = 1.2,
    this.circle = false,
    this.gloss = true,
    this.border = IronPalette.brass,
  });

  final IronTone tone;
  final double radius;
  final double depth;
  final bool pressed;
  final double outlineWidth;
  final bool circle;
  final bool gloss;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final r = circle ? 0.0 : radius.clamp(0, 6).toDouble();
    final drop = pressed ? 1.0 : 0.0;
    final body = Rect.fromLTWH(0, drop, size.width, size.height - depth);
    RRect shape(Rect rect) => circle
        ? RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2))
        : RRect.fromRectAndRadius(rect, Radius.circular(r));

    final outer = shape(body);
    if (!pressed) {
      canvas.drawRRect(
        outer.shift(Offset(0, depth * 0.7)),
        Paint()
          ..color = const Color(0x99000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas
      ..drawRRect(outer, Paint()..color = IronPalette.ink)
      ..drawRRect(
        outer.deflate(1),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: pressed
                ? [tone.deep, Color.lerp(tone.deep, tone.light, 0.4)!]
                : [tone.light, tone.deep],
          ).createShader(body),
      );
    // Brass border, brighter along the top edge.
    final trim = outer.deflate(2.5);
    canvas.drawRRect(
      trim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth.clamp(1.0, 2.0)
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(border, Colors.white, 0.35)!,
            border,
            Color.lerp(border, Colors.black, 0.45)!,
          ],
        ).createShader(body),
    );
    // A thin highlight just inside the top.
    if (!circle) {
      canvas.drawLine(
        Offset(trim.left + r + 2, trim.top + 2),
        Offset(trim.right - r - 2, trim.top + 2),
        Paint()
          ..color = const Color(0x22FFFFFF)
          ..strokeWidth = 1,
      );
    }
    if (gloss && !circle && size.width > 44 && size.height > 26) {
      final rivet = Paint()..color = Color.lerp(border, Colors.white, 0.2)!;
      final shade = Paint()..color = const Color(0xAA000000);
      for (final p in [
        trim.outerRect.topLeft + const Offset(4, 4),
        trim.outerRect.topRight + const Offset(-4, 4),
        trim.outerRect.bottomLeft + const Offset(4, -4),
        trim.outerRect.bottomRight + const Offset(-4, -4),
      ]) {
        canvas
          ..drawCircle(p + const Offset(0.4, 0.6), 1.5, shade)
          ..drawCircle(p, 1.3, rivet);
      }
    }
  }

  @override
  bool shouldRepaint(IronSlabPainter old) =>
      old.tone.light != tone.light ||
      old.tone.deep != tone.deep ||
      old.pressed != pressed ||
      old.radius != radius ||
      old.depth != depth ||
      old.circle != circle ||
      old.border != border;
}

/// A forged button: a metal plate with a brass trim and an engraved label
/// in Cinzel capitals, optional icon. The primary action uses
/// [IronTone.brass].
class IronButton extends StatefulWidget {
  const IronButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = IronTone.brass,
    this.icon,
    this.fontSize = 20,
    this.minWidth = 0,
    this.height = 52,
    this.uppercase = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IronTone tone;
  final IronGlyph? icon;
  final double fontSize;
  final double minWidth;
  final double height;
  final bool uppercase;

  @override
  State<IronButton> createState() => _IronButtonState();
}

class _IronButtonState extends State<IronButton> {
  bool _down = false;
  static const _depth = 3.0;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final tone = enabled ? widget.tone : IronTone.ash;
    final pressed = _down && enabled;
    final label = widget.uppercase ? widget.label.toUpperCase() : widget.label;
    // Cinzel capitals run wide: a little smaller than the old toon size.
    final size = widget.fontSize * 0.78;
    final pad = (size * 1.1).clamp(12.0, 22.0);
    final textColor = enabled ? tone.text : IronPalette.mute;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
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
        child: CustomPaint(
          painter: IronSlabPainter(
            tone: tone,
            pressed: pressed,
            depth: _depth,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: widget.minWidth,
              minHeight: widget.height * 0.86 + _depth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                pad,
                pressed ? 1 : 0,
                pad,
                pressed ? _depth - 1 : _depth,
              ),
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      IronIcon(widget.icon!, size: size * 1.1, color: textColor),
                      SizedBox(width: size * 0.45),
                    ],
                    Flexible(
                      child: IronText(
                        label,
                        size: size,
                        maxLines: 1,
                        color: textColor,
                        outline: tone.text == IronPalette.parchment
                            ? IronPalette.ink
                            : const Color(0x00000000),
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round iron stud with a brass ring and an icon (HUD, headers). With
/// [onHold] it reports touch down and up instead of taps (hold-to-walk),
/// reacting on pointer down.
class IronRoundButton extends StatefulWidget {
  const IronRoundButton({
    super.key,
    required this.glyph,
    required this.tooltip,
    this.onPressed,
    this.onHold,
    this.enabled = true,
    this.tone = IronTone.iron,
    this.size = 52,
    this.iconColor,
  });

  final IronGlyph glyph;
  final String tooltip;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onHold;
  final bool enabled;
  final IronTone tone;
  final double size;
  final Color? iconColor;

  @override
  State<IronRoundButton> createState() => _IronRoundButtonState();
}

class _IronRoundButtonState extends State<IronRoundButton> {
  bool _down = false;

  bool get _enabled =>
      widget.enabled && (widget.onPressed != null || widget.onHold != null);

  void _set(bool down) {
    if (_down == down) return;
    setState(() => _down = down);
    widget.onHold?.call(down);
  }

  @override
  void didUpdateWidget(IronRoundButton old) {
    super.didUpdateWidget(old);
    if (!_enabled && _down) _set(false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    const depth = 3.0;
    final tone = enabled ? widget.tone : IronTone.ash;
    final iconColor = !enabled
        ? IronPalette.mute
        : widget.iconColor ?? tone.text;
    final face = CustomPaint(
      painter: IronSlabPainter(
        tone: tone,
        pressed: _down,
        depth: depth,
        circle: true,
        outlineWidth: 1.6,
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size + depth,
        child: Padding(
          padding: EdgeInsets.only(
            top: _down ? 1 : 0,
            bottom: _down ? depth - 1 : depth,
          ),
          child: Center(
            child: IronIcon(
              widget.glyph,
              size: widget.size * 0.46,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
    final Widget input = widget.onHold != null
        ? Listener(
            onPointerDown: enabled ? (_) => _set(true) : null,
            onPointerUp: (_) => _set(false),
            onPointerCancel: (_) => _set(false),
            child: face,
          )
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => setState(() => _down = true) : null,
            onTapCancel: () => setState(() => _down = false),
            onTapUp: enabled
                ? (_) {
                    setState(() => _down = false);
                    widget.onPressed!();
                  }
                : null,
            child: face,
          );
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.tooltip,
        excludeSemantics: true,
        child: input,
      ),
    );
  }
}
