/// Colours of the code-drawn animals (tests, or a missing painting; the
/// game draws the paintings in assets/pets/). Colours are 0xAARRGGBB.
library;

/// How a coat's [PetCoat.marking] is used by the code-drawn animal.
enum CoatPattern {
  solid,
  tabby,
  spotted,
  patches,

  /// Dark back (German Shepherd).
  saddle,

  /// Light face, chest and belly (Husky, Corgi).
  tuxedo,

  /// Head in the marking colour (Mallard, Boer goat).
  headColor,

  /// Crest or face feathers in the marking colour (birds).
  crest,

  /// Dark line along the back (hamsters).
  stripe,

  /// Tail feathers in the marking colour (chickens).
  tail,

  /// Shell in the marking colour (turtles).
  shell,
}

class PetCoat {
  const PetCoat(this.primary, this.secondary, this.marking, this.pattern);

  /// Main coat / feathers / skin.
  final int primary;

  /// Belly, muzzle and other light areas.
  final int secondary;

  /// Pattern colour; what it paints depends on [pattern].
  final int marking;
  final CoatPattern pattern;

  static const Map<String, PetCoat> byFamily = {
    'cat': PetCoat(0xFFD39552, 0xFFF3E4CC, 0xFFA2652C, CoatPattern.tabby),
    'dog': PetCoat(0xFFD9A55A, 0xFFEBC98F, 0xFFB9853E, CoatPattern.solid),
    'rabbit': PetCoat(0xFFC9A684, 0xFFF0E6D8, 0xFF8C6A4A, CoatPattern.patches),
    'bird': PetCoat(0xFF9AA3AD, 0xFFC3CAD1, 0xFF4F8C78, CoatPattern.headColor),
    'hamster': PetCoat(0xFFD9A066, 0xFFF4E6D2, 0xFFB27D46, CoatPattern.solid),
    'duck': PetCoat(0xFFF5F3EC, 0xFFFFFFFF, 0xFFE6E0D2, CoatPattern.solid),
    'chicken': PetCoat(0xFF9C5A2E, 0xFFD9A35A, 0xFF233A2C, CoatPattern.tail),
    'turtle': PetCoat(0xFFC9B08A, 0xFFDCC8A4, 0xFFB08A55, CoatPattern.shell),
    'goat': PetCoat(0xFFF2EEE6, 0xFFFFFFFF, 0xFFB07A4E, CoatPattern.headColor),
    'monkey': PetCoat(0xFF9C8466, 0xFFD8B49A, 0xFF7A6448, CoatPattern.solid),
  };
}
