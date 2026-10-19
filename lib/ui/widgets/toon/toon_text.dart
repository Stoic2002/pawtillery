import 'package:flutter/widgets.dart';

import '../../../app/toon_palette.dart';

/// A thick outline around text, made of shadows so it stays one Text
/// widget (selectable, findable, one semantics node). [drop] adds the solid
/// shadow below that every title and button label has.
List<Shadow> toonOutline({
  Color color = ToonPalette.outline,
  double width = 2.5,
  double drop = 3,
}) => [
  for (final (dx, dy) in const [
    (1.0, 0.0),
    (-1.0, 0.0),
    (0.0, 1.0),
    (0.0, -1.0),
    (0.7, 0.7),
    (-0.7, 0.7),
    (0.7, -0.7),
    (-0.7, -0.7),
  ])
    Shadow(color: color, offset: Offset(dx * width, dy * width)),
  if (drop > 0) Shadow(color: color, offset: Offset(0, width + drop)),
];

/// White (or [color]) text with a dark outline and drop: titles, button
/// labels, HUD numbers.
class ToonText extends StatelessWidget {
  const ToonText(
    this.text, {
    super.key,
    this.size = 20,
    this.color = ToonPalette.white,
    this.outline = ToonPalette.outline,
    this.outlineWidth,
    this.drop,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.letterSpacing = 0.5,
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
  Widget build(BuildContext context) {
    final w = outlineWidth ?? (size / 9).clamp(1.5, 5.0);
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        height: 1.1,
        color: color,
        letterSpacing: letterSpacing,
        shadows: toonOutline(
          color: outline,
          width: w,
          drop: drop ?? (size / 12).clamp(1.0, 4.0),
        ),
      ),
    );
  }
}
