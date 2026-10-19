import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/app/app.dart';
import 'package:pawtillery/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Injected settings give the app silent audio: the bundled sound files
  // would otherwise be loaded through real I/O the test clock never waits
  // for.
  Future<Widget> app(Locale locale) async =>
      PawtilleryApp(locale: locale, settings: await SettingsStore.load());

  testWidgets('main menu shows English text', (tester) async {
    await tester.pumpWidget(await app(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('main menu shows Indonesian text', (tester) async {
    await tester.pumpWidget(await app(const Locale('id')));
    await tester.pumpAndSettle();
    expect(find.text('Main'), findsOneWidget);
  });

  test('non-Indonesian device languages fall back to English', () {
    const supported = [Locale('en'), Locale('id')];
    expect(resolveAppLocale(const Locale('id', 'ID'), supported),
        const Locale('id'));
    expect(resolveAppLocale(const Locale('fr'), supported),
        const Locale('en'));
    expect(resolveAppLocale(null, supported), const Locale('en'));
  });
}
