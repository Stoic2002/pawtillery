import 'package:flutter/material.dart';

import '../../../app/paw_palette.dart';

/// The prototype's sky behind menus: a blue gradient, soft cloud pills and
/// two big outlined hills. [hills] picks the layout: the menu's (a big
/// light hill to the right, a green one to the left) or the splash's.
enum PawHills { menu, splash, none }

class PawBackdrop extends StatelessWidget {
  const PawBackdrop({
    super.key,
    required this.child,
    this.hills = PawHills.none,
    this.clouds = true,
  });

  final Widget child;
  final PawHills hills;
  final bool clouds;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      Widget hill(
        double left,
        double bottom,
        double width,
        double height,
        Color c,
      ) => Positioned(
        left: left,
        bottom: bottom,
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.all(
              Radius.elliptical(width / 2, height / 2),
            ),
            border: Border.all(color: Paw.ink, width: 3),
          ),
        ),
      );
      Widget cloud(
        double left,
        double top,
        double width,
        double height,
        double o,
      ) => Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: o),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Paw.skyTop, Paw.skyBottom],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (clouds) ...[
              cloud(w * 0.09, h * 0.12, 130, 30, 0.85),
              cloud(w * 0.36, h * 0.24, 90, 22, 0.7),
              cloud(w - w * 0.06 - 110, h * 0.09, 110, 26, 0.8),
            ],
            if (hills == PawHills.menu) ...[
              hill(w * 0.28, -h * 0.66, w * 0.95, h, Paw.hillLight),
              hill(-w * 0.12, -h * 0.58, w * 0.72, h * 0.95, Paw.hill),
            ],
            if (hills == PawHills.splash) ...[
              hill(-w * 0.1, -h * 0.7, w * 0.7, h, Paw.hill),
              hill(
                w - w * 0.72 + w * 0.12,
                -h * 0.74,
                w * 0.72,
                h,
                Paw.hillLight,
              ),
            ],
            child,
          ],
        ),
      );
    },
  );
}
