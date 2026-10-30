import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_services.dart';
import '../../../app/paw_palette.dart';
import '../../../config/teams.dart';
import '../../../services/audio_service.dart';
import 'paw_icon.dart';

/// Shared building blocks of the prototype's look (docs/art_style_guide.md):
/// cream shapes with an ink outline and a solid ink shadow that they sink
/// into when pressed.

/// Wraps a control so it drops onto its shadow while pressed, with a soft
/// click on tap (hold controls stay quiet: they repeat).
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.builder,
    required this.onPressed,
    this.onHold,
  });

  final Widget Function(bool pressed) builder;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onHold;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null || widget.onHold != null;

  void _set(bool down) {
    if (_down == down) return;
    setState(() => _down = down);
    widget.onHold?.call(down);
  }

  @override
  void didUpdateWidget(_Pressable old) {
    super.didUpdateWidget(old);
    if (!_enabled && _down) _set(false);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(_down && _enabled);
    if (widget.onHold != null) {
      return Listener(
        onPointerDown: _enabled ? (_) => _set(true) : null,
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: _enabled
          ? (_) {
              setState(() => _down = false);
              context.getInheritedWidgetOfExactType<AppServices>()?.audio.play(
                Sfx.ui,
              );
              widget.onPressed!();
            }
          : null,
      child: child,
    );
  }
}

/// A rounded button with an ink outline and a solid shadow. [fill] picks
/// the role: [Paw.orange] for the one primary action, [Paw.green] for
/// confirm/randomize, [Paw.cream] for the rest.
class PawButton extends StatelessWidget {
  const PawButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.fill = Paw.cream,
    this.foreground = Paw.ink,
    this.border = Paw.ink,
    this.height = 52,
    this.fontSize = 16,
    this.display = false,
    this.radius = 14,
    this.borderWidth = 2,
    this.shadow = 4,
    this.expand = false,
    this.padding = 18,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final Color fill;
  final Color foreground;
  final Color border;
  final double height;
  final double fontSize;

  /// Baloo 2 label (big primary buttons) instead of Nunito.
  final bool display;
  final double radius;
  final double borderWidth;
  final double shadow;
  final bool expand;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final style = display
        ? Paw.title(
            fontSize,
            weight: 800,
            color: enabled ? foreground : Paw.muted,
          )
        : Paw.text(fontSize, color: enabled ? foreground : Paw.muted);
    final iconSize = fontSize * (display ? 1.15 : 1.3);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: _Pressable(
        onPressed: onPressed,
        builder: (down) => AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: height,
          transform: Matrix4.translationValues(0, down ? shadow - 1 : 0, 0),
          padding: EdgeInsets.symmetric(horizontal: padding),
          decoration: BoxDecoration(
            gradient: Paw.bevel(
              !enabled
                  ? Paw.line
                  : down && fill == Paw.orange
                  ? Paw.orangeDeep
                  : fill,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border, width: borderWidth),
            boxShadow: Paw.drop(down ? 1 : shadow),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                PawIcon(icon, size: iconSize, color: style.color),
                SizedBox(width: fontSize * 0.4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: fontSize * 0.35),
                PawIcon(trailingIcon, size: iconSize, color: style.color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A round icon button (HUD, headers). With [onHold] it reports touch down
/// and up instead of taps (hold-to-walk).
class PawCircleButton extends StatelessWidget {
  const PawCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.onHold,
    this.size = 48,
    this.fill = Paw.cream,
    this.borderWidth = 2,
    this.iconSize,
    this.badge,
    this.enabled = true,
    this.mirror = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onHold;
  final double size;
  final Color fill;
  final double borderWidth;
  final double? iconSize;

  /// A small counter in the top-right corner (ammo).
  final String? badge;
  final bool enabled;

  /// Flips the icon horizontally (facing).
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final shadow = size >= 60 ? 4.0 : 3.0;
    Widget face(bool down) => SizedBox(
      width: size,
      height: size + shadow,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: size,
            height: size,
            transform: Matrix4.translationValues(0, down ? shadow - 1 : 0, 0),
            decoration: BoxDecoration(
              gradient: Paw.bevel(fill),
              shape: BoxShape.circle,
              border: Border.all(color: Paw.ink, width: borderWidth),
              boxShadow: Paw.drop(down ? 1 : shadow),
            ),
            alignment: Alignment.center,
            child: Transform.scale(
              scaleX: mirror ? -1 : 1,
              child: PawIcon(icon, size: iconSize ?? size * 0.54, color: Paw.ink),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 26),
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Paw.cream,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Paw.ink, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge!,
                  style: Paw.title(14, weight: 800, height: 1),
                ),
              ),
            ),
        ],
      ),
    );
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        excludeSemantics: true,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: _Pressable(
            onPressed: enabled ? onPressed : null,
            onHold: enabled ? onHold : null,
            builder: face,
          ),
        ),
      ),
    );
  }
}

/// A cream card with a thick ink outline and a solid shadow.
class PawCard extends StatelessWidget {
  const PawCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Paw.cream,
    this.radius = 20,
    this.borderWidth = 3,
    this.borderColor = Paw.ink,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;
  final double borderWidth;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: Paw.paper(color),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: Paw.drop(),
    ),
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        Padding(padding: padding, child: child),
        // A thin inner line, as on a painted sign.
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius - 5),
                border: Border.all(color: _line, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  static const Color _line = Color(0x55A8763E);
}

/// A pill holding a few options; the chosen one is an ink pill with cream
/// text (tabs, turn time, language...).
class PawPillToggle<T> extends StatelessWidget {
  const PawPillToggle({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
    this.background = Paw.peach,
    this.shadow = false,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;
  final Color background;
  final bool shadow;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Paw.ink, width: 2),
      boxShadow: shadow ? Paw.drop(3) : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final v in values)
          Semantics(
            button: true,
            selected: v == selected,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                margin: const EdgeInsets.symmetric(horizontal: 1),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: v == selected ? Paw.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label(v),
                  maxLines: 1,
                  style: Paw.text(
                    14,
                    color: v == selected ? Paw.cream : Paw.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// A square-ish icon button (steppers, small actions).
class PawIconBox extends StatelessWidget {
  const PawIconBox({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
    this.fill = Paw.cream,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final Color fill;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      enabled: onPressed != null,
      label: tooltip,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: _Pressable(
          onPressed: onPressed,
          builder: (down) => AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: size,
            height: size,
            transform: Matrix4.translationValues(0, down ? 2 : 0, 0),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Paw.ink, width: 2),
              boxShadow: Paw.drop(down ? 1 : 3),
            ),
            alignment: Alignment.center,
            child: PawIcon(icon, size: size * 0.5, color: Paw.ink),
          ),
        ),
      ),
    ),
  );
}

/// − value + with square-ish buttons.
class PawStepper extends StatelessWidget {
  const PawStepper({
    super.key,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
    required this.decreaseLabel,
    required this.increaseLabel,
  });

  final int value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final String decreaseLabel;
  final String increaseLabel;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      PawIconBox(
        icon: Icons.remove_rounded,
        tooltip: decreaseLabel,
        onPressed: onDecrease,
      ),
      SizedBox(
        width: 38,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: Paw.title(22, weight: 800),
        ),
      ),
      PawIconBox(
        icon: Icons.add_rounded,
        tooltip: increaseLabel,
        onPressed: onIncrease,
      ),
    ],
  );
}

/// The prototype's switch: a pill with a cream knob, ink when on.
class PawSwitch extends StatelessWidget {
  const PawSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: SizedBox(
        width: 64,
        height: 48,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 60,
            height: 34,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value ? Paw.green : Paw.line,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Paw.ink, width: 2),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 120),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Paw.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: Paw.ink, width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A chunky slider: an outlined track filled orange and a cream knob.
class PawSlider extends StatelessWidget {
  const PawSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.width = 200,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    void set(double dx) =>
        onChanged(((dx / width) * 10).round().clamp(0, 10) / 10);
    return Semantics(
      slider: true,
      label: label,
      value: '${(value * 100).round()}%',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => set(d.localPosition.dx),
        onHorizontalDragUpdate: (d) => set(d.localPosition.dx),
        child: SizedBox(
          width: width,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Paw.peach,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Paw.ink, width: 2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0, 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Paw.orange,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: value.clamp(0, 1) * width - 13,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Paw.cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: Paw.ink, width: 2),
                    boxShadow: Paw.drop(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A team's colour disc with its white mark (circle, triangle, ...).
class TeamBadge extends StatelessWidget {
  const TeamBadge({
    super.key,
    required this.color,
    required this.symbol,
    this.size = 28,
  });

  final Color color;
  final TeamSymbol symbol;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Paw.ink, width: 2),
    ),
    alignment: Alignment.center,
    child: SizedBox.square(
      dimension: size * 0.5,
      child: CustomPaint(painter: TeamSymbolPainter(symbol)),
    ),
  );
}

/// Draws a [TeamSymbol] in a 20 × 20 box scaled to the canvas: [fill]
/// with an ink edge.
class TeamSymbolPainter extends CustomPainter {
  const TeamSymbolPainter(
    this.symbol, {
    this.fill = Colors.white,
    this.edge = Paw.ink,
    this.strokeWidth = 2.5,
  });

  final TeamSymbol symbol;
  final Color fill;
  final Color? edge;
  final double strokeWidth;

  static Path path(TeamSymbol s) => switch (s) {
    TeamSymbol.circle =>
      Path()..addOval(Rect.fromCircle(center: const Offset(10, 10), radius: 8)),
    TeamSymbol.triangle =>
      Path()
        ..moveTo(10, 2.5)
        ..lineTo(18.5, 17)
        ..lineTo(1.5, 17)
        ..close(),
    TeamSymbol.square => Path()..addRect(const Rect.fromLTRB(3, 3, 17, 17)),
    TeamSymbol.star => () {
      final p = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final r = i.isEven ? 8.6 : 3.9;
        final pt = Offset(10 + math.cos(a) * r, 10.6 + math.sin(a) * r);
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      return p..close();
    }(),
    TeamSymbol.diamond =>
      Path()
        ..moveTo(10, 1.5)
        ..lineTo(18, 10)
        ..lineTo(10, 18.5)
        ..lineTo(2, 10)
        ..close(),
    TeamSymbol.heart =>
      Path()
        ..moveTo(10, 17.5)
        ..cubicTo(2, 12, 1, 7, 4, 4.2)
        ..cubicTo(6.5, 2, 9, 3.2, 10, 5.4)
        ..cubicTo(11, 3.2, 13.5, 2, 16, 4.2)
        ..cubicTo(19, 7, 18, 12, 10, 17.5)
        ..close(),
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 20, size.height / 20);
    final p = path(symbol);
    canvas.drawPath(p, Paint()..color = fill);
    if (edge != null) {
      canvas.drawPath(
        p,
        Paint()
          ..color = edge!
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(TeamSymbolPainter old) =>
      old.symbol != symbol || old.fill != fill || old.edge != edge;
}

/// A small icon in a round chip (passive/signature notes, star badges).
class PawIconChip extends StatelessWidget {
  const PawIconChip(
    this.icon, {
    super.key,
    this.fill = Paw.peach,
    this.size = 28,
  });

  final IconData icon;
  final Color fill;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: fill,
      shape: BoxShape.circle,
      border: Border.all(color: Paw.ink, width: 2),
    ),
    alignment: Alignment.center,
    child: PawIcon(icon, size: size * 0.6, color: Paw.ink),
  );
}

/// A dialog: a cream card over the dim scrim.
Future<T?> showPawDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  double width = 380,
  String barrierLabel = 'Dialog',
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: barrierLabel,
  barrierColor: Paw.scrim,
  transitionDuration: const Duration(milliseconds: 160),
  pageBuilder: (context, _, _) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(child: builder(context)),
          ),
        ),
      ),
    ),
  ),
  transitionBuilder: (context, anim, _, child) => Opacity(
    opacity: anim.value,
    child: Transform.scale(
      scale: 0.94 + 0.06 * Curves.easeOut.transform(anim.value),
      child: child,
    ),
  ),
);

/// A yes/no question: title, body, Cancel and a red action.
Future<bool> showPawConfirm({
  required BuildContext context,
  required String title,
  required String body,
  required String ok,
  required String cancel,
}) async {
  final result = await showPawDialog<bool>(
    context: context,
    builder: (context) => PawCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Paw.title(22)),
          const SizedBox(height: 6),
          Text(body, style: Paw.text(16, weight: 600, height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PawButton(
                  label: cancel,
                  onPressed: () => Navigator.of(context).pop(false),
                  height: 48,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PawButton(
                  label: ok,
                  onPressed: () => Navigator.of(context).pop(true),
                  height: 48,
                  fontSize: 15,
                  fill: Paw.red,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// Screen header: round back button and the title in Baloo 2.
class PawHeader extends StatelessWidget {
  const PawHeader({
    super.key,
    required this.title,
    required this.backLabel,
    this.center,
    this.trailing,
    this.onBack,
  });

  final String title;
  final String backLabel;
  final Widget? center;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 60,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          PawCircleButton(
            icon: Icons.arrow_back_rounded,
            tooltip: backLabel,
            size: 44,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(title, maxLines: 1, style: Paw.title(20)),
                  ),
                ),
                if (center != null) ...[
                  const Spacer(),
                  center!,
                  const Spacer(),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

/// Diagonal peach stripes (empty art panels, the "random" map card).
class StripesPainter extends CustomPainter {
  const StripesPainter({this.band = 10});
  final double band;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..clipRect(Offset.zero & size)
      ..drawRect(Offset.zero & size, Paint()..color = Paw.peachLight);
    final p = Paint()..color = Paw.peach;
    for (var x = -size.height; x < size.width + size.height; x += band * 2) {
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..lineTo(x + size.height, 0)
          ..lineTo(x + size.height + band, 0)
          ..lineTo(x + band, size.height)
          ..close(),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(StripesPainter old) => old.band != band;
}
