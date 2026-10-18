import 'package:flutter/material.dart';

import '../../../app/field_palette.dart';
import '../../../game/art/animal_art.dart';

/// The animal art printed like an engraved plate: an ink-on-paper duotone
/// (shadows in ink, highlights in paper). Keeps menus in the field-guide
/// look while the arena shows the animals in colour.
const ColorFilter engravingFilter = ColorFilter.matrix(<double>[
  // out = ink + (paper - ink) * luminance, per channel.
  (0xEF - 0x2B) / 255 * 0.30,
  (0xEF - 0x2B) / 255 * 0.59,
  (0xEF - 0x2B) / 255 * 0.11,
  0,
  0x2B + 0.0,
  (0xE6 - 0x26) / 255 * 0.30,
  (0xE6 - 0x26) / 255 * 0.59,
  (0xE6 - 0x26) / 255 * 0.11,
  0,
  0x26 + 0.0,
  (0xD2 - 0x20) / 255 * 0.30,
  (0xD2 - 0x20) / 255 * 0.59,
  (0xD2 - 0x20) / 255 * 0.11,
  0,
  0x20 + 0.0,
  0, 0, 0, 1, 0,
]);

/// An animal drawn either in colour or as an engraving.
class AnimalFigure extends StatelessWidget {
  const AnimalFigure({
    super.key,
    required this.familyId,
    required this.breedId,
    this.teamArgb = 0xFF2B2620,
    this.size = 64,
    this.engraved = false,
    this.facing = 1,
  });

  final String? familyId;
  final String? breedId;
  final int teamArgb;
  final double size;
  final bool engraved;
  final int facing;

  @override
  Widget build(BuildContext context) {
    final figure = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _FigurePainter(this)),
    );
    return engraved
        ? ColorFiltered(colorFilter: engravingFilter, child: figure)
        : figure;
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter(this.f);
  final AnimalFigure f;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 42;
    canvas
      ..save()
      ..translate(size.width / 2, size.height * 0.92)
      ..scale(s * f.facing, s);
    AnimalArt.draw(
      canvas,
      familyId: f.familyId,
      breedId: f.breedId,
      teamArgb: f.teamArgb,
      pose: AnimalPose.idle,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.f.familyId != f.familyId ||
      old.f.breedId != f.breedId ||
      old.f.teamArgb != f.teamArgb ||
      old.f.facing != f.facing;
}

/// A framed plate: double rule, a figure, a caption in italic.
class Plate extends StatelessWidget {
  const Plate({super.key, required this.child, this.caption, this.number});

  final Widget child;
  final String? caption;

  /// e.g. "Pl. IV".
  final String? number;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (number != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              number!.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 2.5,
                color: FieldPalette.inkSoft,
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: FieldPalette.ink, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: FieldPalette.inkSoft, width: 0.5),
              ),
              child: Padding(padding: const EdgeInsets.all(6), child: child),
            ),
          ),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              caption!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: FieldPalette.inkSoft,
              ),
            ),
          ),
      ],
    );
  }
}
