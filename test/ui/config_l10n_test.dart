import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/breeds.dart';
import 'package:pawtillery/config/families.dart';
import 'package:pawtillery/config/maps.dart';
import 'package:pawtillery/config/teams.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/l10n/app_localizations.dart';
import 'package:pawtillery/l10n/l10n_lookup.g.dart';

/// Every player-facing name in config must exist in both ARB files.
void main() {
  final keys = <String>{
    for (final f in Families.all) ...[
      f.nameKey,
      f.passive.nameKey,
      f.passive.descriptionKey,
    ],
    for (final b in Breeds.all) b.nameKey,
    for (final w in Weapons.all) w.nameKey,
    for (final t in Teams.styles) t.nameKey,
    for (final m in Maps.all) m.nameKey,
  };

  for (final locale in AppLocalizations.supportedLocales) {
    test('all config keys resolve in ${locale.languageCode}', () async {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final key in keys) {
        expect(l10n.byKey(key), isNotEmpty, reason: key);
      }
    });
  }

  test('every family has at least 4 breeds, and breeds are unique', () {
    for (final f in Families.all) {
      expect(Breeds.ofFamily(f.id).length, greaterThanOrEqualTo(4),
          reason: f.id);
    }
    expect(Breeds.all.map((b) => b.id).toSet(), hasLength(Breeds.all.length));
    expect(Breeds.all, hasLength(52));
  });

  test('Indonesian names differ where the PRD translates them', () async {
    final id = await AppLocalizations.delegate.load(const Locale('id'));
    expect(id.byKey('familyCat'), 'Kucing');
    expect(id.byKey('weaponRock'), 'Batu Lempar');
  });
}
