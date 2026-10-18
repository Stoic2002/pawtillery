import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import '../ui/screens/main_menu_screen.dart';

class PawtilleryApp extends StatelessWidget {
  const PawtilleryApp({super.key, this.locale});

  /// Forces a locale (used by tests and, later, by Settings). `null` follows
  /// the device language.
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      localeResolutionCallback: resolveLocale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE08A2E)),
      ),
      home: const MainMenuScreen(),
    );
  }

  /// Indonesian devices get Indonesian; every other language falls back to
  /// English (PRD: Lokalisasi).
  static Locale resolveLocale(Locale? device, Iterable<Locale> supported) {
    if (device?.languageCode == 'id') return const Locale('id');
    return const Locale('en');
  }
}
