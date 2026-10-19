import 'package:flutter/widgets.dart';

import '../../../app/iron_palette.dart';
import '../../../app/iron_theme.dart';

/// The engraved look for display text: a crisp dark shadow just below,
/// as if cut into metal, and a faint dark halo for legibility over the
/// arena. One Text widget (selectable, findable, one semantics node).
List<Shadow> ironOutline({
  Color color = IronPalette.ink,
  double width = 1,
  double drop = 1.5,
}) => [
  Shadow(color: color.withValues(alpha: 0.9), offset: Offset(0, drop)),
  Shadow(color: color.withValues(alpha: 0.6), blurRadius: width * 3),
];

/// Display text in Cinzel: titles, button labels, HUD numbers.
class IronText extends StatelessWidget {
  const IronText(
    this.text, {
    super.key,
    this.size = 20,
    this.color = IronPalette.parchment,
    this.outline = IronPalette.ink,
    this.outlineWidth,
    this.drop,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.letterSpacing = 1,
  });

  final String text;
  final double size;
  final Color color;
  final Color outline;
  final double? outlineWidth;
  final double? drop;
  final TextAlign textAlign;
  final int? maxLines;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
    style: IronTheme.displayStyle(
      size: size,
      color: color,
      letterSpacing: letterSpacing,
      shadows: ironOutline(
        color: outline,
        width: outlineWidth ?? 1,
        drop: drop ?? (size / 14).clamp(1.0, 2.5),
      ),
    ),
  );
}
