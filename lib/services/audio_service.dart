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
  AudioService._(this._settings, this._files)
    : _musicOn = _settings.musicOn {
    _settings.addListener(_onSettingsChanged);
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
    // Loading the effects runs in the background: the menu shows at once
    // and a sound that isn't ready yet is just skipped.
    return AudioService._(settings, files)..preloadEffects().ignore();
  }

  /// No sound at all (tests).
  factory AudioService.silent(SettingsStore settings) =>
      AudioService._(settings, const {});

  static const _dir = 'assets/audio/';
  static const _extensions = ['ogg', 'mp3', 'wav'];

  final SettingsStore _settings;
  final Set<String> _files;
  final Map<Sfx, int> _lastPlayedMs = {};
  final Map<Sfx, _Voices> _voices = {};
  final Stopwatch _clock = Stopwatch()..start();
  Music? _music;
  bool _bgmPlaying = false;

  /// Settings' music switch as last applied.
  bool _musicOn;

  static bool _isAudio(String f) => _extensions.any((e) => f.endsWith('.$e'));

  String? _file(String base) {
    for (final ext in _extensions) {
      if (_files.contains('$base.$ext')) return '$base.$ext';
    }
    return null;
  }

  /// How many copies of a sound can ring at once (overlapping blasts).
  static int _voiceCount(Sfx sfx) => switch (sfx) {
        Sfx.explosion || Sfx.hit => 4,
        _ => 2,
      };

  /// Loads every effect once into a few reusable low-latency players, so
  /// playing a sound is a single restart: no asset copy, decode or new
  /// player at the moment of the blast (which made sounds lag behind the
  /// picture), and no player left behind after each sound (low-latency
  /// players never report "completed", so one-shot players leaked).
  Future<void> preloadEffects() async {
    await Future.wait([
      for (final sfx in Sfx.values)
        if (_file('sfx_${sfx.name}') case final String file)
          _loadVoices(sfx, file),
    ]);
  }

  Future<void> _loadVoices(Sfx sfx, String file) async {
    try {
      final players = <AudioPlayer>[];
      for (var i = 0; i < _voiceCount(sfx); i++) {
        final p = AudioPlayer()..audioCache = FlameAudio.audioCache;
        await p.setAudioContext(_effectsContext);
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource(file));
        players.add(p);
      }
      _voices[sfx] = _Voices(players);
    } on Object catch (e) {
      debugPrint('Sound $file not loaded: $e');
    }
  }

  static final AudioContext _effectsContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  /// Plays [sfx]; the same sound at most once per 60 ms, so a cluster
  /// explosion doesn't stack six copies.
  void play(Sfx sfx) {
    final volume = _settings.sfxVolume;
    final voices = _voices[sfx];
    if (voices == null || volume <= 0) return;
    final now = _clock.elapsedMilliseconds;
    if (now - (_lastPlayedMs[sfx] ?? -1000) < 60) return;
    _lastPlayedMs[sfx] = now;
    _restart(voices.next(), volume);
  }

  /// Stop first: a low-latency player still counts as "playing" after its
  /// sound ended, and would ignore a plain resume.
  Future<void> _restart(AudioPlayer player, double volume) async {
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.resume();
    } on Object catch (e) {
      debugPrint('Sound failed: $e');
    }
  }

  /// Switches to [music]; remembered but silent while music is off.
  Future<void> playMusic(Music music) async {
    if (_music == music) return;
    _music = music;
    await _startMusic();
  }

  Future<void> _startMusic() async {
    final music = _music;
    final file = music == null ? null : _file('music_${music.name}');
    try {
      // Only touch the player when there is something to stop or play,
      // so a build without music never talks to the audio plugin.
      await _stopMusic();
      if (file != null && _settings.musicOn) {
        await FlameAudio.bgm.play(file, volume: _settings.musicVolume);
        _bgmPlaying = true;
      }
    } on Object catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  Future<void> _stopMusic() async {
    if (!_bgmPlaying) return;
    _bgmPlaying = false;
    await FlameAudio.bgm.stop();
  }

  /// Applies the music switch and volume from Settings.
  void _onSettingsChanged() {
    final on = _settings.musicOn;
    if (on != _musicOn) {
      _musicOn = on;
      (on ? _startMusic() : _stopMusic()).catchError(
        (Object e) => debugPrint('Music failed: $e'),
      );
      return;
    }
    if (!_bgmPlaying) return;
    FlameAudio.bgm.audioPlayer.setVolume(_settings.musicVolume).ignore();
  }

  /// Which sound a sim event makes, if any.
  static Sfx? sfxFor(SimEvent event) => switch (event) {
        WeaponUsed(weaponId: 'laserPointer') => Sfx.laser,
        WeaponUsed(weaponId: 'grapple') => null,
        WeaponUsed(weaponId: 'shotgun') => null,
        ShotgunFired() => Sfx.fire,
        ShieldPopped(blocked: true) => Sfx.hit,
        GrappleFired() => Sfx.jump,
        IceBurst() => Sfx.hit,
        WeaponUsed() => Sfx.fire,
        LightningStruck() => Sfx.thunder,
        SatelliteStruck() => Sfx.laser,
        CrateCollected() => Sfx.turn,
        ExplosionEvent() => Sfx.explosion,
        UnitJumped() => Sfx.jump,
        UnitDamaged() => Sfx.hit,
        UnitDied() => Sfx.death,
        TurnStarted() => Sfx.turn,
        _ => null,
      };

  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    for (final v in _voices.values) {
      for (final p in v.players) {
        p.dispose().ignore();
      }
    }
    _voices.clear();
  }
}

/// A sound's players, used in turn.
class _Voices {
  _Voices(this.players);
  final List<AudioPlayer> players;
  int _next = 0;

  AudioPlayer next() => players[_next++ % players.length];
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
      case SatelliteStruck():
        _buzz(HapticFeedback.heavyImpact);
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
