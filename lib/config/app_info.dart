/// App metadata shown on the About screen.
abstract final class AppInfo {
  /// Keep in sync with `version:` in pubspec.yaml (no package_info plugin:
  /// not in the PRD's package list).
  static const version = '1.0.0';

  /// Public privacy policy page, required by Google Play.
  /// TODO(M6): replace with the real URL before release.
  static const privacyPolicyUrl = 'https://example.com/pawtillery/privacy';

  /// Shown on the About card.
  static const developer = 'Arul Karim';
  static const fonts = 'Baloo 2, Nunito (SIL OFL)';
}
