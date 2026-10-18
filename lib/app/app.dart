import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import '../services/audio_service.dart';
import '../services/settings_store.dart';
import '../ui/screens/main_menu_screen.dart';
import '../ui/screens/splash_screen.dart';
import 'app_services.dart';

class PawtilleryApp extends StatefulWidget {
  const PawtilleryApp({super.key, this.locale, this.settings});

  /// Forces a locale (tests). Otherwise Settings decides, falling back to
  /// the device language.
  final Locale? locale;

  /// Injected settings (tests); loaded from the device otherwise.
  final SettingsStore? settings;

  @override
  State<PawtilleryApp> createState() => _PawtilleryAppState();
}

class _PawtilleryAppState extends State<PawtilleryApp> {
  late final Future<(SettingsStore, AudioService)> _services = _load();

  Future<(SettingsStore, AudioService)> _load() async {
    final injected = widget.settings;
    if (injected != null) return (injected, AudioService.silent(injected));
    final settings = await SettingsStore.load();
    final audio = await AudioService.create(settings);
    audio.playMusic(Music.menu).ignore();
    return (settings, audio);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(SettingsStore, AudioService)>(
      future: _services,
      builder: (context, snapshot) {
        final services = snapshot.data;
        if (services == null) {
          return _materialApp(
              locale: widget.locale, home: const SplashScreen());
        }
        final (settings, audio) = services;
        return AppServices(
          settings: settings,
          audio: audio,
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) {
              final code = settings.languageCode;
              return _materialApp(
                locale: widget.locale ?? (code == null ? null : Locale(code)),
                home: const MainMenuScreen(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _materialApp({required Locale? locale, required Widget home}) =>
      MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: resolveAppLocale,
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: const Color(0xFFE08A2E)),
          visualDensity: VisualDensity.standard,
        ),
        home: home,
      );
}

/// Indonesian devices get Indonesian; every other language falls back to
/// English (PRD: Lokalisasi).
Locale resolveAppLocale(Locale? device, Iterable<Locale> supported) {
  if (device?.languageCode == 'id') return const Locale('id');
  return const Locale('en');
}
