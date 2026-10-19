import 'package:flutter/widgets.dart';

import '../../../game/art/animal_art.dart';

/// A pet drawn at a given size (menus, setup, results), the same art as in
/// the arena.
class PetFigure extends StatelessWidget {
  const PetFigure({
    super.key,
    required this.familyId,
    required this.breedId,
    required this.teamArgb,
    this.size = 64,
    this.flip = false,
  });

  final String? familyId;
  final String? breedId;
  final int teamArgb;
  final double size;
  final bool flip;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _PetPainter(this)),
  );
}

class _PetPainter extends CustomPainter {
  _PetPainter(this.f);
  final PetFigure f;

  @override
  void paint(Canvas canvas, Size size) {
    // The art is 40 wide (the prototype's 100 box at 0.4) with the feet at
    // the bottom.
    final s = size.shortestSide / 40;
    canvas
      ..save()
      ..translate(size.width / 2, size.height * 0.98)
      ..scale(s * (f.flip ? -1 : 1), s);
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
  bool shouldRepaint(_PetPainter old) =>
      old.f.familyId != f.familyId ||
      old.f.breedId != f.breedId ||
      old.f.teamArgb != f.teamArgb ||
      old.f.flip != f.flip;
}
