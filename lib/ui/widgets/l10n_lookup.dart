import '../../config/teams.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';

/// Convenience lookups from config ids to localized text.
extension L10nLookup on AppLocalizations {
  String teamName(int team) => byKey(Teams.styles[team].nameKey);
}
