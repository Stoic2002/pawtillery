import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/app/app.dart';
import 'package:pawtillery/app/app_services.dart';
import 'package:pawtillery/app/match_config.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/l10n/app_localizations.dart';
import 'package:pawtillery/services/audio_service.dart';
import 'package:pawtillery/services/settings_store.dart';
import 'package:pawtillery/ui/hud/pause_dialog.dart';
import 'package:pawtillery/ui/screens/results_screen.dart';
import 'package:pawtillery/ui/widgets/paw/paw_widgets.dart';
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
      ('How to Play', 'Move'),
      ('Settings', 'Language'),
      ('Play', 'New Match'),
    ]) {
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets, reason: button);
      await _back(tester);
      expect(find.text('Play'), findsOneWidget);
    }

    // About is a card over the menu.
    await tester.tap(find.byTooltip('About'));
    await tester.pumpAndSettle();
    expect(find.text('Privacy policy'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Privacy policy'), findsNothing);
  });

  testWidgets('back on the main menu asks before quitting', (tester) async {
    await _landscape(tester);
    final settings = await _settings();
    final quits = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') quits.add(call.method);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(
        PawtilleryApp(locale: const Locale('en'), settings: settings));
    await tester.pumpAndSettle();

    await _back(tester);
    expect(find.text('Quit Pawtillery?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Play'), findsOneWidget);
    expect(quits, isEmpty);

    await _back(tester);
    await tester.tap(find.text('Quit'));
    await tester.pumpAndSettle();
    expect(quits, ['SystemNavigator.pop']);
  });

  testWidgets('setup: team count, Random, and the setup is saved on start',
      (tester) async {
    await _landscape(tester);
    final settings = await _settings();
    await tester.pumpWidget(
        PawtilleryApp(locale: const Locale('en'), settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    // One card per team; the name field shows the default name.
    expect(find.text('Red Team'), findsWidgets);
    expect(find.text('Blue Team'), findsWidgets);
    expect(find.text('Purple Team'), findsNothing);

    // Two more teams from the Rules tab.
    await tester.tap(find.text('Rules'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Increase').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Increase').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teams'));
    await tester.pumpAndSettle();
    expect(find.text('Purple Team'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Random').first); // the header button
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(settings.lastMatch(const []), isNull);
    await tester.tap(find.text('Start match'));
    await tester.pump();
    final saved = settings.lastMatch(const [])!;
    expect(saved.teams, hasLength(4), reason: 'the setup on screen is saved');
    // Leave before the arena finishes loading its map.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('setup: weapons tab sets ammo and presets, and is saved',
      (tester) async {
    await _landscape(tester);
    final settings = await _settings();
    await tester.pumpWidget(
        PawtilleryApp(locale: const Locale('en'), settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weapons'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Laser Pointer'), findsOneWidget);
    expect(find.text('Custom'), findsNothing);

    // Rock (unlimited) down to 9, then switch family weapons off.
    await tester.tap(find.byTooltip('Less ammo').first);
    await tester.pumpAndSettle();
    expect(find.text('Custom'), findsOneWidget);
    await tester.ensureVisible(find.byType(PawSwitch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PawSwitch));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start match'));
    await tester.pump();
    final saved = settings.lastMatch(const [])!.weapons;
    expect(saved.ammoOf(Weapons.rock), 9);
    expect(saved.signatures, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('setup: the Classic preset turns the new weapons off',
      (tester) async {
    await _landscape(tester);
    final settings = await _settings();
    await tester.pumpWidget(
        PawtilleryApp(locale: const Locale('en'), settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weapons'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Classic'));
    await tester.pumpAndSettle();
    // Everything added after the original eight: 8 pet-themed weapons, the
    // 3 military ones, the 4 unique ones, Meteor Shower, the Grappling
    // Hook, Napalm, the Ice Bomb, the Shotgun, the Shield Bubble, Poison
    // Gas and the First-Aid Kit.
    expect(find.text('Off'), findsNWidgets(23));
  });

  testWidgets('setup: a unit opens the unit editor', (tester) async {
    await _landscape(tester);
    final settings = await _settings();
    await tester.pumpWidget(
        PawtilleryApp(locale: const Locale('en'), settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cat').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit unit'), findsOneWidget);
    expect(find.text('Passive · '), findsNothing);
    await tester.tap(find.text('Dog'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Dog'), findsWidgets);
  });

  testWidgets('settings: switching language updates the whole app',
      (tester) async {
    await _landscape(tester);
    final settings = await _settings();
    await tester.pumpWidget(PawtilleryApp(settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bahasa Indonesia'));
    await tester.pumpAndSettle();
    expect(settings.languageCode, 'id');
    expect(find.text('Bahasa'), findsOneWidget);
    await _back(tester);
    expect(find.text('Main'), findsOneWidget);
    expect(find.text('Cara Bermain'), findsOneWidget);
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
    expect(find.text('Paused'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(choice, PauseChoice.resume);

    await tester.tap(find.text('exit'));
    await tester.pumpAndSettle();
    expect(find.text('Leave the match?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
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
    expect(find.text('Blue Team wins'), findsWidgets);
    expect(find.text('Milo · 142 damage'), findsOneWidget);
    expect(find.text('Kucing Garong'), findsOneWidget);
    expect(find.text('Over 17 turns'), findsOneWidget);
  });

  testWidgets('every screen fits in Indonesian without overflow',
      (tester) async {
    await _landscape(tester);
    final settings = await _settings()..languageCode = 'id';
    await tester.pumpWidget(PawtilleryApp(settings: settings));
    await tester.pumpAndSettle();
    for (final button in ['Main', 'Cara Bermain', 'Pengaturan']) {
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: button);
      if (button == 'Main') {
        await tester.tap(find.text('Aturan'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Aturan');
        await tester.tap(find.text('Senjata'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Senjata');
      }
      await _back(tester);
    }
    await tester.tap(find.byTooltip('Tentang'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Tentang');
  });
}
