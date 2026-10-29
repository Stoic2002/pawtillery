import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../sim/events.dart';
import 'settings_store.dart';

enum Sfx {
  fire,
  explosion,
  jump,
  hit,
  death,
  turn,
  ui,
  laser,
  thunder,
  shotgun,
  nuke,
  gas,
  freeze,
  shieldUp,
  shieldPop,
  heal,
  ignite,
  grapple,
  meteor,
}

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

  /// On Android the effects play from the app's own SoundPool on a
  /// background thread (`SoundEffects.kt`): the audio plugin ran every
  /// call on the main thread, and bursts of blasts stalled it for up to a
  /// second, holding up the sounds themselves and touches. Elsewhere (the
  /// iOS simulators used to test Wi-Fi) the plugin is used.
  static final bool _native =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static const _sfx = MethodChannel('pawtillery/sfx');
  final Set<Sfx> _nativeLoaded = {};

  /// Loads every effect once, so playing a sound needs no copy or decode
  /// at the moment of the blast. With the plugin: into a few reusable
  /// low-latency players (one-shot players leaked, as low-latency players
  /// never report "completed").
  Future<void> preloadEffects() async {
    await Future.wait([
      for (final sfx in Sfx.values)
        if (_file('sfx_${sfx.name}') case final String file)
          _native ? _loadNative(sfx, file) : _loadVoices(sfx, file),
    ]);
  }

  Future<void> _loadNative(Sfx sfx, String file) async {
    try {
      await _sfx.invokeMethod<void>('load', {'asset': '$_dir$file'});
      _nativeLoaded.add(sfx);
    } on Object catch (e) {
      debugPrint('Sound $file not loaded: $e');
    }
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

  /// Plays [sfx]; the same sound at most once per 30 ms (one frame or
  /// two), so blasts landing together don't stack copies.
  void play(Sfx sfx) {
    final volume = _settings.sfxVolume;
    final voices = _voices[sfx];
    final native = _nativeLoaded.contains(sfx);
    if ((voices == null && !native) || volume <= 0) return;
    final now = _clock.elapsedMilliseconds;
    if (now - (_lastPlayedMs[sfx] ?? -1000) < 30) return;
    _lastPlayedMs[sfx] = now;
    if (native) {
      final file = _file('sfx_${sfx.name}')!;
      // Not awaited: the sound starts on its own thread.
      _sfx
          .invokeMethod<void>('play', {'asset': '$_dir$file', 'volume': volume})
          .catchError((Object e) => debugPrint('Sound failed: $e'));
    } else {
      voices!.restart(volume);
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
        // These make their own sound when they take effect.
        WeaponUsed(weaponId: 'grapple' || 'shotgun' || 'shield' ||
            'firstAid') =>
          null,
        ShotgunFired() => Sfx.shotgun,
        ShieldRaised() => Sfx.shieldUp,
        ShieldPopped() => Sfx.shieldPop,
        GrappleFired() => Sfx.grapple,
        FireStarted() => Sfx.ignite,
        WeaponUsed(weaponId: 'meteorShower') => Sfx.meteor,
        IceBurst() => Sfx.freeze,
        GasReleased() => Sfx.gas,
        NukeDetonated() => Sfx.nuke,
        UnitHealed() || CrateCollected(health: true) => Sfx.heal,
        WeaponUsed() => Sfx.fire,
        LightningStruck() => Sfx.thunder,
        SatelliteStruck() => Sfx.laser,
        CrateCollected() => Sfx.turn,
        ExplosionEvent() || GroundCrumbled() => Sfx.explosion,
        UnitJumped() => Sfx.jump,
        // Gas bites every second while a pet stays in it: no thud each time.
        UnitDamaged(cause: DamageCause.poison) => null,
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
  _Voices(this.players) : _volumes = List.filled(players.length, -1);
  final List<AudioPlayer> players;
  final List<double> _volumes;
  int _next = 0;

  /// Plays the next copy from the start. The calls are sent one after the
  /// other without waiting for each answer (the platform channel keeps
  /// their order), so the sound starts a few round trips sooner, in step
  /// with the blast on screen. Stop first: a low-latency player still
  /// counts as "playing" after its sound ended and would ignore a resume.
  void restart(double volume) {
    final i = _next++ % players.length;
    final p = players[i];
    void quiet(Future<void> f) =>
        f.catchError((Object e) => debugPrint('Sound failed: $e'));
    quiet(p.stop());
    if (_volumes[i] != volume) {
      _volumes[i] = volume;
      quiet(p.setVolume(volume));
    }
    quiet(p.resume());
  }
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
