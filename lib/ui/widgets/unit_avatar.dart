import 'package:flutter/material.dart';

import '../../game/components/unit_painter.dart';

/// A unit's placeholder look in Flutter UI (setup, how to play).
class UnitAvatar extends StatelessWidget {
  const UnitAvatar({
    super.key,
    required this.familyId,
    required this.breedId,
    required this.teamArgb,
    this.letter,
    this.size = 44,
    this.facing = 1,
  });

  final String? familyId;
  final String? breedId;
  final int teamArgb;
  final String? letter;
  final double size;
  final int facing;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _AvatarPainter(this),
        ),
      );
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.avatar);
  final UnitAvatar avatar;
  static final _painter = UnitPlaceholderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Leave room above for ears, horns and combs.
    final r = size.shortestSide * 0.3;
    _painter.paint(
      canvas,
      center: Offset(size.width / 2, size.height * 0.6),
      radius: r,
      facing: avatar.facing,
      teamArgb: avatar.teamArgb,
      familyId: avatar.familyId,
      breedId: avatar.breedId,
      letter: avatar.letter,
    );
  }

  @override
  bool shouldRepaint(_AvatarPainter old) =>
      old.avatar.familyId != avatar.familyId ||
      old.avatar.breedId != avatar.breedId ||
      old.avatar.teamArgb != avatar.teamArgb ||
      old.avatar.letter != avatar.letter ||
      old.avatar.facing != avatar.facing;
}
