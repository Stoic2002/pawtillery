import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/app/app.dart';
import 'package:pawtillery/app/app_services.dart';
import 'package:pawtillery/app/match_config.dart';
import 'package:pawtillery/l10n/app_localizations.dart';
import 'package:pawtillery/services/audio_service.dart';
import 'package:pawtillery/services/settings_store.dart';
import 'package:pawtillery/ui/hud/pause_dialog.dart';
import 'package:pawtillery/ui/screens/results_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Landscape phone, like the real target.
Future<void> _landscape(WidgetTester tester) async {
  tester.view.physicalSize = const Size(2400, 1080);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

/// The Android back gesture (works in any language, unlike pageBack()).
Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<SettingsStore> _settings() async {
  SharedPreferences.setMockInitialValues({});
  return SettingsStore.load();
}

Widget _wrap(SettingsStore settings, Widget child, {Locale? locale}) =>
    AppServices(
      settings: settings,
      audio: AudioService.silent(settings),
      child: MaterialApp(
        locale: locale ?? const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('main menu opens every screen and comes back', (tester) async {
    await _landscape(tester);
    final settings = await _settings();
    await tester.pumpWidget(
        PawtilleryApp(locale: const Locale('en'), settings: settings));
    await tester.pumpAndSettle();

    for (final (button, title) in [
      ('HOW TO PLAY', 'MOVE'),
      ('SETTINGS', 'Language'),
      ('ABOUT', 'PRIVACY POLICY'),
      ('PLAY', 'NEW MATCH'),
    ]) {
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets, reason: button);
      await _back(tester);
      expect(find.text('PLAY'), findsOneWidget);
    }
  });

  testWidgets('setup: team count, Random, and the setup is saved on start',
      (tester) async {
    await _landscape(tester);
    final settings = await _settings();
    await tester.pumpWidget(
        PawtilleryApp(locale: const Locale('en'), settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();

    // Team tabs in capitals.
    expect(find.text('RED TEAM'), findsOneWidget);
    expect(find.text('BLUE TEAM'), findsOneWidget);
    expect(find.text('YELLOW TEAM'), findsNothing);
    await tester.tap(find.text('4').first);
    await tester.pumpAndSettle();
    expect(find.text('YELLOW TEAM'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('RANDOM').first); // the header button
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(settings.lastMatch(const []), isNull);
    await tester.tap(find.text('START'));
    await tester.pump();
    final saved = settings.lastMatch(const [])!;
    expect(saved.teams, hasLength(4), reason: 'the setup on screen is saved');
    // Leave before the arena finishes loading its map.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('settings: switching language updates the whole app',
      (tester) async {
    await _landscape(tester);
    final settings = await _settings();
    await tester.pumpWidget(PawtilleryApp(settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bahasa Indonesia'));
    await tester.pumpAndSettle();
    expect(settings.languageCode, 'id');
    expect(find.text('Bahasa'), findsOneWidget);
    await _back(tester);
    expect(find.text('MAIN'), findsOneWidget);
    expect(find.text('CARA BERMAIN'), findsOneWidget);
  });

  testWidgets('pause dialog: resume, and exit asks first', (tester) async {
    await _landscape(tester);
    final settings = await _settings();
    PauseChoice? choice;
    bool? leave;
    await tester.pumpWidget(_wrap(
      settings,
      Builder(
        builder: (context) => Column(
          children: [
            TextButton(
              onPressed: () async => choice = await showPauseDialog(context),
              child: const Text('pause'),
            ),
            TextButton(
              onPressed: () async => leave = await confirmExit(context),
              child: const Text('exit'),
            ),
          ],
        ),
      ),
    ));
    await tester.tap(find.text('pause'));
    await tester.pumpAndSettle();
    expect(find.text('PAUSED'), findsOneWidget);
    await tester.tap(find.text('RESUME'));
    await tester.pumpAndSettle();
    expect(choice, PauseChoice.resume);

    await tester.tap(find.text('exit'));
    await tester.pumpAndSettle();
    expect(find.text('LEAVE THE MATCH?'), findsOneWidget);
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(leave, isFalse);
  });

  testWidgets('results: winner, most damage and knockouts', (tester) async {
    await _landscape(tester);
    final settings = await _settings();
    await tester.pumpWidget(_wrap(
      settings,
      ResultsScreen(
        config: MatchConfig.defaults(const ['Milo']),
        result: const MatchResult(
          winnerTeam: 1,
          teamNames: ['Kucing Garong', 'Blue Team'],
          teamColors: [0xFFE53935, 0xFF1E88E5],
          knockouts: [1, 3],
          turns: 17,
          topUnitName: 'Milo',
          topUnitTeam: 1,
          topDamage: 142,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('BLUE TEAM WINS'), findsOneWidget);
    expect(find.text('Milo (Blue Team): 142 HP'), findsOneWidget);
    expect(find.text('Kucing Garong'), findsOneWidget);
    expect(find.text('Over 17 turns'), findsOneWidget);
  });

  testWidgets('every screen fits in Indonesian without overflow',
      (tester) async {
    await _landscape(tester);
    final settings = await _settings()..languageCode = 'id';
    await tester.pumpWidget(PawtilleryApp(settings: settings));
    await tester.pumpAndSettle();
    for (final button in ['MAIN', 'CARA BERMAIN', 'PENGATURAN', 'TENTANG']) {
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: button);
      await _back(tester);
    }
  });
}
