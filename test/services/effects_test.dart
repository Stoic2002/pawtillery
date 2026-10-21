import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/game/effects/particle_system.dart';
import 'package:pawtillery/services/audio_service.dart';
import 'package:pawtillery/services/settings_store.dart';
import 'package:pawtillery/sim/events.dart';
import 'package:pawtillery/ui/hud/tutorial.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('tutorial', () {
    test('advances in order, and a later action skips earlier steps', () {
      final t = TutorialController();
      expect(t.value, TutorialStep.walk);
      t.complete(TutorialStep.walk);
      expect(t.value, TutorialStep.weapons);
      t.complete(TutorialStep.walk); // repeating an old step does nothing
      expect(t.value, TutorialStep.weapons);
      t.complete(TutorialStep.aim); // aimed without opening the menu
      expect(t.value, TutorialStep.fire);
      t.complete(TutorialStep.fire);
      expect(t.isDone, isTrue);
    });

    test('skip ends it', () {
      final t = TutorialController()..skip();
      expect(t.isDone, isTrue);
      t.complete(TutorialStep.walk);
      expect(t.isDone, isTrue);
    });
  });

  group('audio', () {
    test('sim events map to the PRD sound list', () {
      expect(AudioService.sfxFor(const WeaponUsed(0, 'rock')), Sfx.fire);
      expect(
          AudioService.sfxFor(
              const ExplosionEvent(x: 0, y: 0, radius: 1, carved: null)),
          Sfx.explosion);
      expect(AudioService.sfxFor(const UnitJumped(0)), Sfx.jump);
      expect(AudioService.sfxFor(const UnitDamaged(0, 1, DamageCause.fall)),
          Sfx.hit);
      expect(AudioService.sfxFor(const UnitDied(0, DeathCause.hp)), Sfx.death);
      expect(AudioService.sfxFor(const TurnStarted(team: 0, unitId: 0)),
          Sfx.turn);
      expect(AudioService.sfxFor(const WeaponUsed(0, 'laserPointer')),
          Sfx.laser);
      expect(AudioService.sfxFor(const LightningStruck(0, 0)), Sfx.thunder);
      expect(AudioService.sfxFor(const MinePlaced(0)), isNull);
    });

    test('works with no audio files at all', () async {
      SharedPreferences.setMockInitialValues({});
      final audio = AudioService.silent(await SettingsStore.load());
      for (final s in Sfx.values) {
        audio.play(s);
      }
      await audio.playMusic(Music.menu);
    });

    test('music and FPS switches are saved, music on by default', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = await SettingsStore.load();
      final audio = AudioService.silent(settings);
      expect(settings.musicOn, isTrue);
      expect(settings.showFps, isFalse);
      settings
        ..musicOn = false
        ..showFps = true;
      await audio.playMusic(Music.match);
      settings.musicOn = true;
      final reloaded = await SettingsStore.load();
      expect(reloaded.musicOn, isTrue);
      expect(reloaded.showFps, isTrue);
      audio.dispose();
    });
  });

  group('particles', () {
    test('pool never grows past capacity and empties as particles die', () {
      final p = ParticleSystem(capacity: 50);
      for (var i = 0; i < 20; i++) {
        p.explosion(100, 100, 60, debris: const [0xFF7B5232]);
      }
      expect(p.liveCount, 50);
      // Smoke lingers longest (under 4 s).
      for (var i = 0; i < 300; i++) {
        p.update(1 / 60);
      }
      expect(p.liveCount, 0);
    });

    test('splash, dust and ring spawn particles', () {
      final p = ParticleSystem()
        ..splash(10, 10, waterArgb: 0xB0337FD0)
        ..dust(10, 10, strength: 1)
        ..ring(10, 10, 120);
      expect(p.liveCount, greaterThan(10));
    });
  });
}
