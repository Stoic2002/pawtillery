/// The mark that identifies a team besides its colour, so teams read for
/// colour-blind players too (redesign prototype).
enum TeamSymbol { circle, triangle, square, star, diamond, heart }

/// Default team identities (PRD: Tim). Pure Dart; colours are 0xAARRGGBB.
class TeamStyle {
  const TeamStyle({
    required this.nameKey,
    required this.colorArgb,
    required this.symbol,
  });

  /// ARB key of the default team name.
  final String nameKey;
  final int colorArgb;
  final TeamSymbol symbol;
}

abstract final class Teams {
  /// Team colours and marks; the first four are the defaults for teams
  /// 1–4. Each team needs a different one.
  static const styles = [
    TeamStyle(
      nameKey: 'teamRed',
      colorArgb: 0xFFE5484D,
      symbol: TeamSymbol.circle,
    ),
    TeamStyle(
      nameKey: 'teamBlue',
      colorArgb: 0xFF3B82F6,
      symbol: TeamSymbol.triangle,
    ),
    TeamStyle(
      nameKey: 'teamGreen',
      colorArgb: 0xFF22A559,
      symbol: TeamSymbol.square,
    ),
    TeamStyle(
      nameKey: 'teamPurple',
      colorArgb: 0xFF8B5CF6,
      symbol: TeamSymbol.star,
    ),
    TeamStyle(
      nameKey: 'teamYellow',
      colorArgb: 0xFFF5B700,
      symbol: TeamSymbol.diamond,
    ),
    TeamStyle(
      nameKey: 'teamOrange',
      colorArgb: 0xFFFF8A3D,
      symbol: TeamSymbol.heart,
    ),
  ];
}
