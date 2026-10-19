import 'package:flutter/painting.dart';

/// The "Sunny Brawl" palette (docs/art_style_guide.md). Use these names.
abstract final class ToonPalette {
  /// Every outline, the solid drop shadow, text on light panels.
  static const outline = Color(0xFF2A1A12);

  /// Light panels and cards.
  static const cream = Color(0xFFFFF4DC);
  static const creamShade = Color(0xFFF1DDB4);
  static const creamDeep = Color(0xFFD9B98A);

  /// Primary action ("Play", "Fire"): sunflower yellow into orange.
  static const sun = Color(0xFFFFC928);
  static const sunDeep = Color(0xFFF07C0C);

  /// Go / confirm / healthy.
  static const leaf = Color(0xFF8BD645);
  static const leafDeep = Color(0xFF3E9420);

  /// Secondary actions, selection.
  static const sky = Color(0xFF5CC8F5);
  static const skyDeep = Color(0xFF1C76C4);

  /// Danger, damage, leave.
  static const tomato = Color(0xFFFF6A47);
  static const tomatoDeep = Color(0xFFC6281A);

  /// Disabled.
  static const stone = Color(0xFFC9C2B6);
  static const stoneDeep = Color(0xFF8A8276);

  /// HUD panels over the arena (translucent).
  static const night = Color(0xE0182230);
  static const nightLine = Color(0xFF0B1118);

  /// Secondary text on light panels.
  static const bark = Color(0xFF6B4A33);

  static const white = Color(0xFFFFFFFF);
}

/// A fill colour with its darker partner, for the two-tone gradient every
/// button and badge uses.
class ToonTone {
  const ToonTone(this.light, this.deep);
  final Color light;
  final Color deep;

  static const sun = ToonTone(ToonPalette.sun, ToonPalette.sunDeep);
  static const leaf = ToonTone(ToonPalette.leaf, ToonPalette.leafDeep);
  static const sky = ToonTone(ToonPalette.sky, ToonPalette.skyDeep);
  static const tomato = ToonTone(ToonPalette.tomato, ToonPalette.tomatoDeep);
  static const cream = ToonTone(ToonPalette.cream, ToonPalette.creamShade);
  static const stone = ToonTone(ToonPalette.stone, ToonPalette.stoneDeep);

  /// A team colour as a tone: the colour itself and a darker shade.
  factory ToonTone.of(Color c) => ToonTone(
    Color.lerp(c, const Color(0xFFFFFFFF), 0.18)!,
    Color.lerp(c, const Color(0xFF000000), 0.28)!,
  );
}
