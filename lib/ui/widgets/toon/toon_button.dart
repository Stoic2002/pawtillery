import 'package:flutter/material.dart';

import '../../../app/toon_palette.dart';
import 'toon_icons.dart';
import 'toon_text.dart';

/// Paints a chunky slab: a solid dark base under a rounded, outlined,
/// two-tone body with a gloss band. Pressing sinks the body onto its base.
/// Shared by buttons, badges and tiles.
class ToonSlabPainter extends CustomPainter {
  ToonSlabPainter({
    required this.tone,
    this.radius = 16,
    this.depth = 5,
    this.pressed = false,
    this.outlineWidth = 3,
    this.circle = false,
    this.gloss = true,
  });

  final ToonTone tone;
  final double radius;
  final double depth;
  final bool pressed;
  final double outlineWidth;
  final bool circle;
  final bool gloss;

  @override
  void paint(Canvas canvas, Size size) {
    final half = outlineWidth / 2;
    final bodyH = size.height - depth;
    final sink = pressed ? depth - 1 : 0.0;
    RRect shape(Rect r) => circle
        ? RRect.fromRectAndRadius(r, Radius.circular(r.shortestSide / 2))
        : RRect.fromRectAndRadius(r, Radius.circular(radius));

    final base = shape(Rect.fromLTWH(half, depth + half, size.width - outlineWidth, bodyH - outlineWidth));
    final body = shape(Rect.fromLTWH(half, sink + half, size.width - outlineWidth, bodyH - outlineWidth));
    final line = Paint()
      ..color = ToonPalette.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth;

    canvas
      ..drawRRect(base, Paint()..color = ToonPalette.outline)
      ..drawRRect(base, line)
      ..drawRRect(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tone.light, tone.deep],
            stops: const [0.35, 1],
          ).createShader(body.outerRect),
      );
    if (gloss) {
      final g = body.outerRect;
      final band = shape(
        Rect.fromLTWH(
          g.left + 5,
          g.top + 3.5,
          g.width - 10,
          (g.height * 0.38).clamp(4, 22),
        ),
      );
      canvas.drawRRect(
        band,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.32),
      );
    }
    canvas.drawRRect(body, line);
  }

  @override
  bool shouldRepaint(ToonSlabPainter old) =>
      old.tone.light != tone.light ||
      old.tone.deep != tone.deep ||
      old.pressed != pressed ||
      old.radius != radius ||
      old.depth != depth ||
      old.circle != circle;
}

/// The chunky button: outlined two-tone slab, white outlined label (upper
/// case), optional icon. The primary action uses [ToonTone.sun].
class ToonButton extends StatefulWidget {
  const ToonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = ToonTone.sun,
    this.icon,
    this.fontSize = 20,
    this.minWidth = 0,
    this.height = 52,
    this.uppercase = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final ToonTone tone;
  final ToonGlyph? icon;
  final double fontSize;
  final double minWidth;
  final double height;
  final bool uppercase;

  @override
  State<ToonButton> createState() => _ToonButtonState();
}

class _ToonButtonState extends State<ToonButton> {
  bool _down = false;
  static const _depth = 5.0;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final tone = enabled ? widget.tone : ToonTone.stone;
    final pressed = _down && enabled;
    final label = widget.uppercase ? widget.label.toUpperCase() : widget.label;
    final pad = (widget.fontSize * 0.85).clamp(12.0, 22.0);
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
          painter: ToonSlabPainter(tone: tone, pressed: pressed, depth: _depth),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: widget.minWidth,
              minHeight: widget.height + _depth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                pad,
                pressed ? _depth - 1 : 0,
                pad,
                pressed ? 1 : _depth,
              ),
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      ToonIcon(widget.icon!, size: widget.fontSize * 1.15),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: ToonText(
                        label,
                        size: widget.fontSize,
                        maxLines: 1,
                        color: enabled ? ToonPalette.white : const Color(0xFFEFEAE2),
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

/// A round icon button (HUD, headers). With [onHold] it reports touch down
/// and up instead of taps (hold-to-walk), reacting on pointer down.
class ToonRoundButton extends StatefulWidget {
  const ToonRoundButton({
    super.key,
    required this.glyph,
    required this.tooltip,
    this.onPressed,
    this.onHold,
    this.enabled = true,
    this.tone = ToonTone.cream,
    this.size = 52,
    this.iconColor,
  });

  final ToonGlyph glyph;
  final String tooltip;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onHold;
  final bool enabled;
  final ToonTone tone;
  final double size;
  final Color? iconColor;

  @override
  State<ToonRoundButton> createState() => _ToonRoundButtonState();
}

class _ToonRoundButtonState extends State<ToonRoundButton> {
  bool _down = false;

  bool get _enabled =>
      widget.enabled && (widget.onPressed != null || widget.onHold != null);

  void _set(bool down) {
    if (_down == down) return;
    setState(() => _down = down);
    widget.onHold?.call(down);
  }

  @override
  void didUpdateWidget(ToonRoundButton old) {
    super.didUpdateWidget(old);
    if (!_enabled && _down) _set(false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final depth = widget.size * 0.08;
    final light = widget.tone.light.computeLuminance() > 0.6;
    final iconColor = !enabled
        ? const Color(0xFFEFEAE2)
        : widget.iconColor ?? (light ? ToonPalette.outline : ToonPalette.white);
    final iconOutline =
        iconColor == ToonPalette.outline ? ToonPalette.cream : ToonPalette.outline;
    final face = CustomPaint(
      painter: ToonSlabPainter(
        tone: enabled ? widget.tone : ToonTone.stone,
        pressed: _down,
        depth: depth,
        circle: true,
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size + depth,
        child: Padding(
          padding: EdgeInsets.only(
            top: _down ? depth - 1 : 0,
            bottom: _down ? 1 : depth,
          ),
          child: Center(
            child: ToonIcon(
              widget.glyph,
              size: widget.size * 0.5,
              color: iconColor,
              outline: iconOutline,
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
