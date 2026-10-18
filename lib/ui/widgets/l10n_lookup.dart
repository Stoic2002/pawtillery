import '../../config/teams.dart';
import '../../l10n/app_localizations.dart';

/// Resolves config `nameKey`s to localized strings. Config stays pure Dart,
/// so it can only refer to ARB entries by key.
extension L10nLookup on AppLocalizations {
  String teamName(int team) => switch (Teams.styles[team].nameKey) {
        'teamRed' => teamRed,
        'teamBlue' => teamBlue,
        'teamGreen' => teamGreen,
        'teamYellow' => teamYellow,
        final key => throw ArgumentError('Unknown team nameKey: $key'),
      };
}
