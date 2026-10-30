import 'package:flutter/painting.dart';

/// Design tokens from the approved prototype (redesign/Pawtillery.dc.html,
/// docs/art_style_guide.md). Use these names.
abstract final class Paw {
  /// Outlines, solid shadows, text.
  static const ink = Color(0xFF2B2118);

  /// Cards, buttons, pills.
  static const cream = Color(0xFFFFF6E6);

  /// Selected rows, chips, inner wells, dividers.
  static const peach = Color(0xFFFFE7C2);
  static const peachLight = Color(0xFFFFEFD6);

  /// The primary action ("Play", "Start match", "Fire").
  static const orange = Color(0xFFFF8A3D);
  static const orangeDeep = Color(0xFFE2681C);

  /// Confirm, randomize, next.
  static const green = Color(0xFF4CBF6B);

  /// Warnings (last seconds, strong wind), stars, counters.
  static const yellow = Color(0xFFF5B700);

  /// Danger.
  static const red = Color(0xFFE5484D);
  static const redText = Color(0xFFB4232A);

  /// Secondary text.
  static const muted = Color(0xFF6B5B4B);

  /// Disabled fills, quiet lines.
  static const line = Color(0xFFCFC4B3);

  /// Sky and hills behind the menus.
  static const skyTop = Color(0xFF7CC8FF);
  static const skyBottom = Color(0xFFD8F0FF);
  static const hill = Color(0xFF8FD67A);
  static const hillLight = Color(0xFFB9E49B);

  /// Dims the screen behind dialogs.
  static const scrim = Color(0x992B2118);

  static const display = 'Baloo2';
  static const body = 'Nunito';

  /// Baloo 2 (titles, big numbers).
  static TextStyle title(
    double size, {
    double weight = 700,
    Color color = ink,
    double? height,
  }) => TextStyle(
    fontFamily: display,
    fontSize: size,
    color: color,
    height: height ?? 1.15,
    fontWeight: weight >= 700 ? FontWeight.w700 : FontWeight.w500,
    fontVariations: [FontVariation('wght', weight)],
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Nunito (labels and body), extra bold by default.
  static TextStyle text(
    double size, {
    double weight = 800,
    Color color = ink,
    double? height,
  }) => TextStyle(
    fontFamily: body,
    fontSize: size,
    color: color,
    height: height,
    fontWeight: weight >= 700 ? FontWeight.w700 : FontWeight.w600,
    fontVariations: [FontVariation('wght', weight)],
  );

  /// A hand-painted look for a raised control of colour [c]: lit along the
  /// top edge, as the game's art is, darker towards the bottom. Straight
  /// down: on a wide button a slant would wash out one end.
  static LinearGradient bevel(Color c) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.lerp(c, const Color(0xFFFFFFFF), 0.34)!,
      Color.lerp(c, const Color(0xFFFFFFFF), 0.08)!,
      c,
      Color.lerp(c, const Color(0xFF3A1E08), 0.18)!,
    ],
    stops: const [0, 0.2, 0.62, 1],
  );

  /// A panel's face, like old paper: warmer towards the bottom right.
  static LinearGradient paper(Color c) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [c, Color.lerp(c, const Color(0xFFF6DDB4), 0.55)!],
  );

  /// The solid "pressed into the page" shadow under every control.
  static List<BoxShadow> drop([double y = 4]) => [
    BoxShadow(color: ink, offset: Offset(0, y)),
  ];
}
