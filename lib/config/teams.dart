/// Default team identities (PRD: Tim). Pure Dart; colours are 0xAARRGGBB.
class TeamStyle {
  const TeamStyle({required this.nameKey, required this.colorArgb});

  /// ARB key of the default team name.
  final String nameKey;
  final int colorArgb;
}

abstract final class Teams {
  static const styles = [
    TeamStyle(nameKey: 'teamRed', colorArgb: 0xFFE53935),
    TeamStyle(nameKey: 'teamBlue', colorArgb: 0xFF1E88E5),
    TeamStyle(nameKey: 'teamGreen', colorArgb: 0xFF43A047),
    TeamStyle(nameKey: 'teamYellow', colorArgb: 0xFFFDD835),
  ];
}
