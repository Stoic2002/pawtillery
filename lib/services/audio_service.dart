import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../sim/events.dart';
import 'settings_store.dart';

enum Sfx { fire, explosion, jump, hit, death, turn, ui, laser, thunder }

enum Music { menu, match }

/// Sound effects and music (PRD: Audio). Every call is safe without audio
/// files: missing sounds are silent, so assets can be added later by just
/// dropping files into `assets/audio/` (see the README there).
class AudioService {
  AudioService._(this._settings, this._files) {
    _settings.addListener(_applyMusicVolume);
  }

  /// Finds which audio files are bundled.
  static Future<AudioService> create(SettingsStore settings) async {
    var files = <String>{};
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      files = manifest
          .listAssets()
          .where((a) => a.startsWith(_dir))
          .map((a) => a.substring(_dir.length))
          .toSet();
      if (files.any(_isAudio)) await FlameAudio.bgm.initialize();
    } on Object catch (e) {
      debugPrint('Audio disabled: $e');
    }
    return AudioService._(settings, files);
  }

  /// No sound at all (tests).
  factory AudioService.silent(SettingsStore settings) =>
      AudioService._(settings, const {});

  static const _dir = 'assets/audio/';
  static const _extensions = ['ogg', 'mp3', 'wav'];

  final SettingsStore _settings;
  final Set<String> _files;
  final Map<Sfx, int> _lastPlayedMs = {};
  final Stopwatch _clock = Stopwatch()..start();
  Music? _music;
  bool _bgmPlaying = false;

  static bool _isAudio(String f) => _extensions.any((e) => f.endsWith('.$e'));

  String? _file(String base) {
    for (final ext in _extensions) {
      if (_files.contains('$base.$ext')) return '$base.$ext';
    }
    return null;
  }

  /// Plays [sfx]; the same sound at most once per 60 ms, so a cluster
  /// explosion doesn't stack six copies.
  void play(Sfx sfx) {
    final volume = _settings.sfxVolume;
    final file = _file('sfx_${sfx.name}');
    if (file == null || volume <= 0) return;
    final now = _clock.elapsedMilliseconds;
    if (now - (_lastPlayedMs[sfx] ?? -1000) < 60) return;
    _lastPlayedMs[sfx] = now;
    _playSafely(file, volume);
  }

  Future<void> _playSafely(String file, double volume) async {
    try {
      await FlameAudio.play(file, volume: volume);
    } on Object catch (e) {
      debugPrint('Sound failed: $e');
    }
  }

  Future<void> playMusic(Music music) async {
    if (_music == music) return;
    _music = music;
    final file = _file('music_${music.name}');
    try {
      // Only touch the player when there is something to stop or play,
      // so a build without music never talks to the audio plugin.
      if (_bgmPlaying) {
        await FlameAudio.bgm.stop();
        _bgmPlaying = false;
      }
      if (file != null) {
        await FlameAudio.bgm.play(file, volume: _settings.musicVolume);
        _bgmPlaying = true;
      }
    } on Object catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  void _applyMusicVolume() {
    if (!_bgmPlaying) return;
    FlameAudio.bgm.audioPlayer.setVolume(_settings.musicVolume).ignore();
  }

  /// Which sound a sim event makes, if any.
  static Sfx? sfxFor(SimEvent event) => switch (event) {
        WeaponUsed(weaponId: 'laserPointer') => Sfx.laser,
        WeaponUsed() => Sfx.fire,
        LightningStruck() => Sfx.thunder,
        ExplosionEvent() => Sfx.explosion,
        UnitJumped() => Sfx.jump,
        UnitDamaged() => Sfx.hit,
        UnitDied() => Sfx.death,
        TurnStarted() => Sfx.turn,
        _ => null,
      };

  void dispose() => _settings.removeListener(_applyMusicVolume);
}

/// Short vibrations (PRD: getaran saat menembak dan ledakan), off when the
/// player disables them in Settings.
class Haptics {
  Haptics(this._settings);

  final SettingsStore _settings;
  final Stopwatch _clock = Stopwatch()..start();
  int _lastMs = -1000;

  void onEvent(SimEvent event) {
    if (!_settings.haptics) return;
    switch (event) {
      case WeaponUsed():
        _buzz(HapticFeedback.lightImpact);
      case ExplosionEvent(:final radius):
        _buzz(radius >= 50
            ? HapticFeedback.heavyImpact
            : HapticFeedback.mediumImpact);
      default:
        break;
    }
  }

  /// At most one buzz per 80 ms: chained blasts feel like one rumble.
  void _buzz(Future<void> Function() feedback) {
    final now = _clock.elapsedMilliseconds;
    if (now - _lastMs < 80) return;
    _lastMs = now;
    feedback().ignore();
  }
}
