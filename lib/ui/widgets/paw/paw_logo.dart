import 'package:flutter/material.dart';

import '../../../app/paw_palette.dart';

/// The wordmark: "Pawtillery" in Baloo 2, orange with a thick ink outline
/// and a solid drop, a paw print for the dot of the i. Read by screen
/// readers as plain [title].
class PawLogo extends StatelessWidget {
  const PawLogo({super.key, required this.title, this.size = 68});

  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Only the default title gets the paw dot; any other (translated) title
    // is drawn as is.
    final i = title.toLowerCase().indexOf('i');
    final pawDot = title == 'Pawtillery' && i > 0;
    final base = Paw.title(size, weight: 800, height: 1);
    Widget word(String text) => Stack(
      children: [
        // Drop shadow, outline, then the fill.
        Transform.translate(
          offset: Offset(0, size * 0.088),
          child: Text(
            text,
            style: base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size * 0.118
                ..strokeJoin = StrokeJoin.round
                ..color = Paw.ink,
            ),
          ),
        ),
        Text(
          text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.118
              ..strokeJoin = StrokeJoin.round
              ..color = Paw.ink,
          ),
        ),
        Text(text, style: base.copyWith(color: Paw.orange)),
      ],
    );
    return Semantics(
      label: title,
      excludeSemantics: true,
      child: pawDot
          ? Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                word(title.substring(0, i)),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    word('ı'),
                    Positioned(
                      top: -size * 0.02,
                      child: Transform.rotate(
                        angle: -0.21,
                        child: Icon(
                          Icons.pets,
                          size: size * 0.36,
                          color: Paw.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                word(title.substring(i + 1)),
              ],
            )
          : word(title),
    );
  }
}
