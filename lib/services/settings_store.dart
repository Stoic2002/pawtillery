import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/match_config.dart';
import '../app/match_history.dart';

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
  static const _kMusicOn = 'musicOn';
  static const _kShowFps = 'showFps';
  static const _kTutorialDone = 'tutorialDone';
  static const _kMatch = 'lastMatchConfig';
  static const _kPlayerName = 'playerName';
  static const _kHistory = 'matchHistory';
  static const _kTotals = 'historyTotals';

  /// Matches kept in the history list; the totals count every match.
  static const historyLength = 50;

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

  /// Background music on or off (its volume is kept either way).
  bool get musicOn => _prefs.getBool(_kMusicOn) ?? true;
  set musicOn(bool v) => _set(() => _prefs.setBool(_kMusicOn, v));

  /// Frame rate readout during a match.
  bool get showFps => _prefs.getBool(_kShowFps) ?? false;
  set showFps(bool v) => _set(() => _prefs.setBool(_kShowFps, v));

  bool get showAimGuide => _prefs.getBool(_kAimGuide) ?? true;
  set showAimGuide(bool v) => _set(() => _prefs.setBool(_kAimGuide, v));

  /// First-match tutorial already seen (M5); Settings can reset it.
  bool get tutorialDone => _prefs.getBool(_kTutorialDone) ?? false;
  set tutorialDone(bool v) => _set(() => _prefs.setBool(_kTutorialDone, v));

  /// Name shown to the other phones in a Wi-Fi room; null = not set yet.
  String? get playerName => _prefs.getString(_kPlayerName);
  set playerName(String? name) => _set(() => name == null
      ? _prefs.remove(_kPlayerName)
      : _prefs.setString(_kPlayerName, name));

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

  /// Finished matches, newest first (on this phone only).
  List<MatchRecord> get history {
    final raw = _prefs.getString(_kHistory);
    if (raw == null) return const [];
    try {
      final json = jsonDecode(raw);
      if (json is! List) return const [];
      return [for (final r in json) ?MatchRecord.fromJson(r)];
    } on FormatException {
      return const [];
    }
  }

  HistoryTotals get historyTotals {
    final raw = _prefs.getString(_kTotals);
    if (raw == null) return const HistoryTotals();
    try {
      return HistoryTotals.fromJson(jsonDecode(raw));
    } on FormatException {
      return const HistoryTotals();
    }
  }

  /// Adds a finished match to the history and the totals.
  void recordMatch(
    MatchRecord record, {
    Map<String, int> weaponUses = const {},
    (int, String)? bestHit,
  }) {
    final list = [record, ...history].take(historyLength);
    final totals = historyTotals.add(record, uses: weaponUses, hit: bestHit);
    _prefs.setString(
      _kHistory,
      jsonEncode([for (final r in list) r.toJson()]),
    );
    _set(() => _prefs.setString(_kTotals, jsonEncode(totals.toJson())));
  }

  void clearHistory() => _set(() async {
    await _prefs.remove(_kHistory);
    return _prefs.remove(_kTotals);
  });

  void _set(Future<bool> Function() write) {
    write();
    notifyListeners();
  }
}
