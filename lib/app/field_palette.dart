import 'package:flutter/painting.dart';

/// The field-guide palette (docs/art_style_guide.md). Use these names.
abstract final class FieldPalette {
  static const paper = Color(0xFFEFE6D2);
  static const paperShade = Color(0xFFE2D5BA);
  static const paperEdge = Color(0xFFC9B48E);
  static const ink = Color(0xFF2B2620);
  static const inkSoft = Color(0xFF5A5146);
  static const pencil = Color(0xFF8E867A);

  /// The one primary action per screen, damage, "Fire".
  static const stamp = Color(0xFFA8342A);
  static const moss = Color(0xFF4F6B3A);
  static const tape = Color(0xB3E8D9A8);
}
