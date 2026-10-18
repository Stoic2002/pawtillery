import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/match_config.dart';

/// Player settings and the last team setup, kept on the device
/// (PRD: Settings tersimpan; konfigurasi tim terakhir disimpan lokal).
class SettingsStore extends ChangeNotifier {
  SettingsStore._(this._prefs);

  static Future<SettingsStore> load() async =>
      SettingsStore._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _kLanguage = 'language';
  static const _kMusic = 'musicVolume';
  static const _kSfx = 'sfxVolume';
  static const _kHaptics = 'haptics';
  static const _kAimGuide = 'showAimGuide';
  static const _kTutorialDone = 'tutorialDone';
  static const _kMatch = 'lastMatchConfig';

  /// 'en', 'id', or null to follow the device.
  String? get languageCode => _prefs.getString(_kLanguage);
  set languageCode(String? code) => _set(() => code == null
      ? _prefs.remove(_kLanguage)
      : _prefs.setString(_kLanguage, code));

  double get musicVolume => _prefs.getDouble(_kMusic) ?? 0.7;
  set musicVolume(double v) =>
      _set(() => _prefs.setDouble(_kMusic, v.clamp(0, 1)));

  double get sfxVolume => _prefs.getDouble(_kSfx) ?? 0.9;
  set sfxVolume(double v) => _set(() => _prefs.setDouble(_kSfx, v.clamp(0, 1)));

  bool get haptics => _prefs.getBool(_kHaptics) ?? true;
  set haptics(bool v) => _set(() => _prefs.setBool(_kHaptics, v));

  bool get showAimGuide => _prefs.getBool(_kAimGuide) ?? true;
  set showAimGuide(bool v) => _set(() => _prefs.setBool(_kAimGuide, v));

  /// First-match tutorial already seen (M5); Settings can reset it.
  bool get tutorialDone => _prefs.getBool(_kTutorialDone) ?? false;
  set tutorialDone(bool v) => _set(() => _prefs.setBool(_kTutorialDone, v));

  /// Last setup, or null if none was saved or it no longer fits the data.
  MatchConfig? lastMatch(List<String> namePool) {
    final raw = _prefs.getString(_kMatch);
    if (raw == null) return null;
    try {
      return MatchConfig.fromJson(jsonDecode(raw), namePool);
    } on FormatException {
      return null;
    }
  }

  Future<void> saveMatch(MatchConfig config) =>
      _prefs.setString(_kMatch, jsonEncode(config.toJson()));

  void _set(Future<bool> Function() write) {
    write();
    notifyListeners();
  }
}
