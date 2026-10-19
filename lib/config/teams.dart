/// Default team identities (PRD: Tim). Pure Dart; colours are 0xAARRGGBB.
class TeamStyle {
  const TeamStyle({required this.nameKey, required this.colorArgb});

  /// ARB key of the default team name.
  final String nameKey;
  final int colorArgb;
}

abstract final class Teams {
  /// Team colours to choose from (bright, docs/art_style_guide.md);
  /// the first ones are the defaults for teams 1–4. Each team needs a
  /// different one.
  static const styles = [
    TeamStyle(nameKey: 'teamRed', colorArgb: 0xFFE8412C),
    TeamStyle(nameKey: 'teamBlue', colorArgb: 0xFF2F86E0),
    TeamStyle(nameKey: 'teamGreen', colorArgb: 0xFF46B52B),
    TeamStyle(nameKey: 'teamYellow', colorArgb: 0xFFF2B705),
    TeamStyle(nameKey: 'teamPurple', colorArgb: 0xFF9B5DE5),
    TeamStyle(nameKey: 'teamOrange', colorArgb: 0xFFFF7A1A),
  ];
}
