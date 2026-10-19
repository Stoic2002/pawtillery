import 'package:flutter/painting.dart';

/// The "Iron & Brass" palette of the dark-fantasy UI
/// (docs/art_style_guide.md). Use these names.
abstract final class IronPalette {
  /// Darkest edge: outer borders, shadows, text on brass.
  static const ink = Color(0xFF0B0B0D);

  /// Panels: forged iron, with a lighter face and a dark rim.
  static const iron = Color(0xFF24262B);
  static const ironShade = Color(0xFF1A1B1F);
  static const ironEdge = Color(0xFF3A3D44);

  /// Trims, borders, the primary action, titles.
  static const brass = Color(0xFFC9A45C);
  static const brassDeep = Color(0xFF7E602C);
  static const brassLight = Color(0xFFEBD49A);

  /// Confirm, healthy.
  static const moss = Color(0xFF6E8E52);
  static const mossDeep = Color(0xFF3C5230);

  /// Secondary actions, selection.
  static const steel = Color(0xFF6E8296);
  static const steelDeep = Color(0xFF3A4654);

  /// Danger, damage, leave, Fire.
  static const blood = Color(0xFFB8442E);
  static const bloodDeep = Color(0xFF5E1A14);

  /// Disabled.
  static const ash = Color(0xFF55555A);
  static const ashDeep = Color(0xFF2E2E32);

  /// HUD panels over the arena (translucent iron).
  static const night = Color(0xD9141518);
  static const nightLine = Color(0xFF050506);

  /// Main text on iron, and secondary text.
  static const parchment = Color(0xFFEDE3CC);
  static const mute = Color(0xFFA39A88);
}

/// A fill colour with its darker partner, for the subtle two-tone metal
/// plates every button and badge uses.
class IronTone {
  const IronTone(this.light, this.deep, {this.text = IronPalette.parchment});
  final Color light;
  final Color deep;

  /// Label colour on this plate.
  final Color text;

  static const brass = IronTone(
    Color(0xFFB8924C),
    Color(0xFF6A4E22),
    text: Color(0xFF1A130A),
  );
  static const moss = IronTone(IronPalette.moss, IronPalette.mossDeep);
  static const steel = IronTone(Color(0xFF3E4652), Color(0xFF23272E));
  static const blood = IronTone(Color(0xFF9A3424), IronPalette.bloodDeep);
  static const iron = IronTone(Color(0xFF2E3036), Color(0xFF1C1D21));
  static const ash = IronTone(IronPalette.ash, IronPalette.ashDeep);

  /// A team colour as a tone: the colour, darkened for metal.
  factory IronTone.of(Color c) => IronTone(
    Color.lerp(c, const Color(0xFF000000), 0.15)!,
    Color.lerp(c, const Color(0xFF000000), 0.55)!,
  );
}
