import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// Working title of the game.
  ///
  /// In en, this message translates to:
  /// **'Pawtillery'**
  String get appTitle;

  /// Main menu button that starts a match.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get menuPlay;

  /// Temporary label shown in the arena until gameplay exists.
  ///
  /// In en, this message translates to:
  /// **'Test field'**
  String get arenaPlaceholder;

  /// Generic back button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Current aim angle in degrees.
  ///
  /// In en, this message translates to:
  /// **'Angle {value}°'**
  String hudAngle(int value);

  /// Current shot power in percent.
  ///
  /// In en, this message translates to:
  /// **'Power {value}%'**
  String hudPower(int value);

  /// Wind strength, -10..10.
  ///
  /// In en, this message translates to:
  /// **'Wind {value}'**
  String hudWind(int value);

  /// Fire button.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get hudFire;

  /// Accessibility label for minus buttons.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get hudDecrease;

  /// Accessibility label for plus buttons.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get hudIncrease;

  /// Test-bench hint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to blast a hole'**
  String get hudTapHint;

  /// Debug-only timing readout.
  ///
  /// In en, this message translates to:
  /// **'Explosion {lastMs} ms (max {maxMs} ms)'**
  String debugExplosionTime(String lastMs, String maxMs);

  /// Basic thrown-rock weapon.
  ///
  /// In en, this message translates to:
  /// **'Rock Toss'**
  String get weaponRock;

  /// Name of the test map.
  ///
  /// In en, this message translates to:
  /// **'Test Field'**
  String get mapSandbox;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
