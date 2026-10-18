import 'package:flutter/material.dart';

import '../../game/art/animal_art.dart';

/// A unit's animal art in Flutter UI (setup, how to play).
class UnitAvatar extends StatelessWidget {
  const UnitAvatar({
    super.key,
    required this.familyId,
    required this.breedId,
    required this.teamArgb,
    this.size = 44,
  });

  final String? familyId;
  final String? breedId;
  final int teamArgb;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _AvatarPainter(this)),
      );
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.avatar);
  final UnitAvatar avatar;

  @override
  void paint(Canvas canvas, Size size) {
    // The art is ~36 px tall and ~34 px wide around its feet.
    final s = size.shortestSide / 42;
    canvas
      ..save()
      ..translate(size.width / 2 - 1 * s, size.height * 0.92)
      ..scale(s);
    AnimalArt.draw(
      canvas,
      familyId: avatar.familyId,
      breedId: avatar.breedId,
      teamArgb: avatar.teamArgb,
      pose: AnimalPose.idle,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AvatarPainter old) =>
      old.avatar.familyId != avatar.familyId ||
      old.avatar.breedId != avatar.breedId ||
      old.avatar.teamArgb != avatar.teamArgb;
}
