/// Default team identities (PRD: Tim). Pure Dart; colours are 0xAARRGGBB.
class TeamStyle {
  const TeamStyle({required this.nameKey, required this.colorArgb});

  /// ARB key of the default team name.
  final String nameKey;
  final int colorArgb;
}

abstract final class Teams {
  /// Team inks to choose from (printer's inks, docs/art_style_guide.md);
  /// the first ones are the defaults for teams 1–4. Each team needs a
  /// different one.
  static const styles = [
    TeamStyle(nameKey: 'teamRed', colorArgb: 0xFFB23A2E),
    TeamStyle(nameKey: 'teamBlue', colorArgb: 0xFF2F4F7F),
    TeamStyle(nameKey: 'teamGreen', colorArgb: 0xFF4F6B3A),
    TeamStyle(nameKey: 'teamYellow', colorArgb: 0xFFB8862B),
    TeamStyle(nameKey: 'teamPurple', colorArgb: 0xFF5E4A78),
    TeamStyle(nameKey: 'teamOrange', colorArgb: 0xFF8A4E2B),
  ];
}
