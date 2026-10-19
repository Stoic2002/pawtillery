// Synthesizes every sound in assets/audio from code (no samples, no
// third-party audio): the seven sound effects and the two music loops.
//   fvm dart run tool/audio/generate_audio.dart
// Effects are written as 16-bit WAV (short, low latency); the music loops
// are rendered to WAV in build/audio and encoded to Ogg with ffmpeg (see
// _encodeMusic). Everything is deterministic: same code, same files.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sr = 44100;
const String outDir = 'assets/audio';
const String tmpDir = 'build/audio';

void main() {
  Directory(outDir).createSync(recursive: true);
  Directory(tmpDir).createSync(recursive: true);

  // Each effect with its loudness: the RMS of its loudest 50 ms. Peaks
  // are then capped, so short hits and sustained tones sit together.
  final sfx = <String, (Buf Function(), double)>{
    'sfx_fire': (fire, 0.36),
    'sfx_explosion': (explosion, 0.7),
    'sfx_jump': (jump, 0.24),
    'sfx_hit': (hit, 0.3),
    'sfx_death': (death, 0.16),
    'sfx_turn': (turn, 0.2),
    'sfx_ui': (ui, 0.16),
  };
  for (final MapEntry(:key, value: (make, level)) in sfx.entries) {
    final buf = make()
      ..fadeEdges()
      ..level(level, maxPeak: 0.89);
    _writeWav('$outDir/$key.wav', buf, stereo: false);
    stdout.writeln('$key.wav  ${buf.seconds.toStringAsFixed(2)} s');
  }

  for (final MapEntry(:key, :value) in {
    'music_menu': menuMusic,
    'music_match': matchMusic,
  }.entries) {
    // Music sits well under the effects.
    final buf = value()..normalize(0.5);
    _writeWav('$tmpDir/$key.wav', buf, stereo: true);
    _encodeMusic(key);
    stdout.writeln('$key  ${buf.seconds.toStringAsFixed(1)} s');
  }
}

// ---------------------------------------------------------------------------
// Buffer and building blocks

/// A stereo float buffer. When [loop] is set, writes past the end wrap to
/// the start so note tails carry over the loop point seamlessly.
class Buf {
  Buf(double seconds, {this.loop = false})
    : l = Float64List((seconds * sr).round()),
      r = Float64List((seconds * sr).round());

  final Float64List l, r;
  final bool loop;

  int get n => l.length;
  double get seconds => n / sr;

  void add(int i, double v, [double pan = 0]) {
    if (loop) {
      i %= n;
    } else if (i < 0 || i >= n) {
      return;
    }
    // Constant-power pan, unity in the middle.
    final a = (pan.clamp(-1.0, 1.0) + 1) * math.pi / 4;
    l[i] += v * math.cos(a) * math.sqrt2;
    r[i] += v * math.sin(a) * math.sqrt2;
  }

  void fadeEdges({double inMs = 2, double outMs = 12}) {
    final a = (inMs / 1000 * sr).round();
    final b = (outMs / 1000 * sr).round();
    for (var i = 0; i < a && i < n; i++) {
      l[i] *= i / a;
      r[i] *= i / a;
    }
    for (var i = 0; i < b && i < n; i++) {
      final k = i / b;
      l[n - 1 - i] *= k;
      r[n - 1 - i] *= k;
    }
  }

  void normalize(double peak) {
    var m = 1e-9;
    for (var i = 0; i < n; i++) {
      m = math.max(m, math.max(l[i].abs(), r[i].abs()));
    }
    final g = peak / m;
    for (var i = 0; i < n; i++) {
      l[i] *= g;
      r[i] *= g;
    }
  }

  /// Scales so the loudest 50 ms window has RMS [rms], unless that would
  /// push a peak past [maxPeak].
  void level(double rms, {required double maxPeak}) {
    final w = (0.05 * sr).round();
    var sum = 0.0, best = 0.0, peak = 1e-9;
    for (var i = 0; i < n; i++) {
      sum += l[i] * l[i];
      if (i >= w) sum -= l[i - w] * l[i - w];
      best = math.max(best, sum);
      peak = math.max(peak, l[i].abs());
    }
    final now = math.sqrt(best / math.min(w, n));
    final g = math.min(rms / now, maxPeak / peak);
    for (var i = 0; i < n; i++) {
      l[i] *= g;
      r[i] *= g;
    }
  }

  /// Gentle tanh saturation, for loud hits.
  void saturate(double drive) {
    final k = 1 / _tanh(drive);
    for (var i = 0; i < n; i++) {
      l[i] = _tanh(l[i] * drive) * k;
      r[i] = _tanh(r[i] * drive) * k;
    }
  }

  /// A ping-pong echo (feedback delay), wrapped when looping.
  void echo({double ms = 180, double feedback = 0.3, double mix = 0.25}) {
    final d = (ms / 1000 * sr).round();
    final el = Float64List(n), er = Float64List(n);
    // Two passes when looping so the wrapped tail feeds the loop start.
    for (var pass = 0; pass < (loop ? 2 : 1); pass++) {
      for (var i = 0; i < n; i++) {
        var j = i - d;
        if (j < 0) {
          if (!loop) continue;
          j += n;
        }
        el[i] = r[j] * 0.5 + er[j] * feedback;
        er[i] = l[j] * 0.5 + el[j] * feedback;
      }
    }
    for (var i = 0; i < n; i++) {
      l[i] += el[i] * mix;
      r[i] += er[i] * mix;
    }
  }
}

double _tanh(double x) {
  final e = math.exp(2 * x);
  return (e - 1) / (e + 1);
}

final _rng = math.Random(7);
double noise() => _rng.nextDouble() * 2 - 1;

/// Frequency of a MIDI note.
double hz(num midi) => 440 * math.pow(2, (midi - 69) / 12).toDouble();

/// Exponential sweep from [a] to [b] Hz over [t] (0..1).
double sweep(double a, double b, double t) => a * math.pow(b / a, t);

/// Simple one-pole low-pass, used on noise.
class OnePole {
  OnePole(double cutoff) : _a = math.exp(-2 * math.pi * cutoff / sr);
  double _a;
  double _y = 0;
  set cutoff(double c) => _a = math.exp(-2 * math.pi * c / sr);
  double lp(double x) => _y = x + (_y - x) * _a;
  double hp(double x) => x - lp(x);
}

/// Renders a voice from [start] seconds for [dur] seconds. The callback gets
/// the time since the start and the running phase source.
void voice(
  Buf b,
  double start,
  double dur,
  double Function(double t) fn, {
  double gain = 1,
  double pan = 0,
}) {
  final s = (start * sr).round();
  final len = (dur * sr).round();
  for (var i = 0; i < len; i++) {
    b.add(s + i, fn(i / sr) * gain, pan);
  }
}

/// A phase accumulator, so pitch can glide without clicks.
class Osc {
  double phase = 0;
  double sine(double f) => math.sin(_step(f));
  double tri(double f) {
    final p = (_step(f) / (2 * math.pi)) % 1;
    return 4 * (p < 0.5 ? p : 1 - p) - 1;
  }

  /// A soft square: a few odd harmonics, no harsh aliasing.
  double square(double f, {int harmonics = 5}) {
    final p = _step(f);
    var v = 0.0;
    for (var k = 1; k <= harmonics * 2; k += 2) {
      if (f * k > 12000) break;
      v += math.sin(p * k) / k;
    }
    return v * 4 / math.pi;
  }

  double _step(double f) {
    phase += 2 * math.pi * f / sr;
    if (phase > 2 * math.pi * 1000) phase -= 2 * math.pi * 1000;
    return phase;
  }
}

double env(double t, double attack, double decay) =>
    t < attack ? t / attack : math.exp(-(t - attack) / decay);

// ---------------------------------------------------------------------------
// Sound effects: toy-like and bouncy, to match the pets.

/// A cartoon cannon "thoomp": a pitch-dropping body, a puff of air and a
/// little pop on top.
Buf fire() {
  final b = Buf(0.5);
  final body = Osc();
  voice(b, 0, 0.45, (t) {
    final f = sweep(220, 55, math.min(1.0, t / 0.18));
    return body.sine(f) * env(t, 0.003, 0.11);
  });
  final air = OnePole(1800);
  voice(b, 0, 0.35, (t) => air.lp(noise()) * env(t, 0.004, 0.07) * 0.9);
  final pop = Osc();
  voice(
    b,
    0,
    0.06,
    (t) => pop.sine(sweep(900, 400, t / 0.06)) * env(t, 0.001, 0.015) * 0.5,
  );
  return b;
}

/// A round, punchy boom: sub drop, rumbling filtered noise and a crackle
/// tail, softly saturated.
Buf explosion() {
  final b = Buf(1.6);
  final sub = Osc();
  voice(b, 0, 1.0, (t) {
    final f = sweep(95, 32, math.min(1.0, t / 0.5));
    return sub.sine(f) * env(t, 0.004, 0.32) * 1.2;
  });
  final rumble = OnePole(900);
  voice(b, 0, 1.6, (t) {
    rumble.cutoff = 300 + 2600 * math.exp(-t / 0.12);
    return rumble.lp(noise()) * env(t, 0.006, 0.38) * 1.6;
  });
  // Crackles: sparse short clicks thinning out.
  final crackle = math.Random(3);
  for (var i = 0; i < 46; i++) {
    final at = 0.05 + math.pow(crackle.nextDouble(), 1.8) * 1.2;
    final hpf = OnePole(2500);
    final g = 0.25 * math.exp(-at / 0.5);
    voice(b, at, 0.012, (t) => hpf.hp(noise()) * env(t, 0.0005, 0.003) * g);
  }
  b.saturate(1.6);
  return b;
}

/// A springy "boing": a rising tone with a fast wobble.
Buf jump() {
  final b = Buf(0.3);
  final o = Osc();
  voice(b, 0, 0.3, (t) {
    final f =
        sweep(260, 640, math.min(1.0, t / 0.16)) *
        (1 + 0.04 * math.sin(2 * math.pi * 28 * t));
    return o.tri(f) * 0.7 * env(t, 0.004, 0.09);
  });
  return b;
}

/// A soft "bonk" with a squeak: a damped wood-like tone and a click.
Buf hit() {
  final b = Buf(0.28);
  final body = Osc(), over = Osc();
  voice(b, 0, 0.25, (t) {
    final f = sweep(480, 230, math.min(1.0, t / 0.08));
    return body.sine(f) * env(t, 0.001, 0.06) +
        over.sine(f * 2.76) * env(t, 0.001, 0.025) * 0.4;
  });
  final click = OnePole(3000);
  voice(b, 0, 0.02, (t) => click.hp(noise()) * env(t, 0.0005, 0.004) * 0.7);
  final squeak = Osc();
  voice(
    b,
    0.02,
    0.12,
    (t) => squeak.sine(sweep(1300, 1700, t / 0.12)) * env(t, 0.01, 0.04) * 0.18,
  );
  return b;
}

/// A sad trombone-ish "wah wah wahhh", knocked-out but still cute.
Buf death() {
  final b = Buf(1.35);
  final notes = [(0.0, 0.26, 62), (0.28, 0.26, 61), (0.56, 0.75, 60)];
  for (final (start, dur, midi) in notes) {
    final o = Osc();
    final last = start > 0.5;
    voice(b, start, dur, (t) {
      var f = hz(midi);
      if (last) f *= math.pow(2, -t * 0.55).toDouble(); // droops down
      final vib = 1 + (last ? 0.012 : 0.006) * math.sin(2 * math.pi * 5.5 * t);
      final a = math.min(1.0, t / 0.03) * math.min(1.0, (dur - t) / 0.08);
      return o.square(f * vib, harmonics: 4) * a * 0.55;
    });
  }
  return b;
}

/// A bright two-note chime announcing the next turn.
Buf turn() {
  final b = Buf(0.9);
  for (final (start, midi) in [(0.0, 76), (0.11, 83)]) {
    final o1 = Osc(), o2 = Osc(), o3 = Osc();
    final f = hz(midi);
    voice(b, start, 0.8, (t) {
      return o1.sine(f) * env(t, 0.002, 0.28) +
          o2.sine(f * 2) * env(t, 0.002, 0.09) * 0.35 +
          o3.sine(f * 3.01) * env(t, 0.001, 0.04) * 0.2;
    });
  }
  return b;
}

/// A tiny soft pop for buttons.
Buf ui() {
  final b = Buf(0.08);
  final o = Osc();
  voice(
    b,
    0,
    0.08,
    (t) =>
        o.sine(sweep(700, 1250, math.min(1.0, t / 0.03))) * env(t, 0.001, 0.02),
  );
  return b;
}

// ---------------------------------------------------------------------------
// Music: two seamless loops. Instruments are simple and plucky (marimba,
// round bass, whistle lead, light drums), so the effects stay on top.

class Song {
  Song({required this.bpm, required this.bars}) : beat = 60 / bpm {
    buf = Buf(bars * 4 * beat, loop: true);
  }

  final double bpm;
  final int bars;
  final double beat;
  late final Buf buf;

  double at(num bar, num beatInBar) => (bar * 4 + beatInBar) * beat;

  void marimba(double t, int midi, {double vel = 1, double pan = 0}) {
    final f = hz(midi);
    final a = Osc(), b2 = Osc(), c = Osc();
    voice(
      buf,
      t,
      1.2,
      (x) =>
          (a.sine(f) * env(x, 0.002, 0.32) +
              b2.sine(f * 4) * env(x, 0.001, 0.035) * 0.35 +
              c.sine(f * 10) * env(x, 0.0005, 0.008) * 0.12) *
          vel,
      gain: 0.32,
      pan: pan,
    );
  }

  void bass(double t, int midi, double dur, {double vel = 1}) {
    final f = hz(midi);
    final o = Osc(), sub = Osc();
    voice(buf, t, dur + 0.05, (x) {
      final a =
          math.min(1.0, x / 0.008) *
          math.exp(-x / (dur * 1.4)) *
          math.min(1.0, (dur + 0.05 - x) / 0.04);
      return (o.tri(f) * 0.8 + sub.sine(f) * 0.6) * a * vel;
    }, gain: 0.42);
  }

  void lead(double t, int midi, double dur, {double vel = 1, double pan = 0}) {
    final f = hz(midi);
    final o = Osc(), h = Osc();
    voice(
      buf,
      t,
      dur,
      (x) {
        final vib =
            1 + 0.008 * math.sin(2 * math.pi * 5.2 * x) * math.min(1.0, x * 4);
        final a = math.min(1.0, x / 0.025) * math.min(1.0, (dur - x) / 0.05);
        return (o.sine(f * vib) + h.sine(f * 2 * vib) * 0.18) * a * vel;
      },
      gain: 0.22,
      pan: pan,
    );
  }

  void kick(double t, {double vel = 1}) {
    final o = Osc();
    voice(
      buf,
      t,
      0.3,
      (x) =>
          o.sine(sweep(140, 48, math.min(1.0, x / 0.07))) *
          env(x, 0.001, 0.09) *
          vel,
      gain: 0.55,
    );
  }

  void snare(double t, {double vel = 1}) {
    final o = Osc();
    final f = OnePole(1200);
    voice(
      buf,
      t,
      0.22,
      (x) =>
          (f.hp(noise()) * env(x, 0.001, 0.05) +
              o.sine(190) * env(x, 0.001, 0.03) * 0.5) *
          vel,
      gain: 0.3,
      pan: 0.1,
    );
  }

  void hat(double t, {double vel = 1, double pan = -0.25}) {
    final f = OnePole(7000);
    voice(
      buf,
      t,
      0.05,
      (x) => f.hp(noise()) * env(x, 0.0005, 0.012) * vel,
      gain: 0.16,
      pan: pan,
    );
  }

  void shaker(double t, {double vel = 1}) {
    final f = OnePole(5000);
    voice(
      buf,
      t,
      0.07,
      (x) => f.hp(noise()) * math.sin(math.pi * x / 0.07) * vel,
      gain: 0.07,
      pan: 0.35,
    );
  }
}

// Chord tones as MIDI notes (root position, middle register).
const _c = [60, 64, 67],
    _am = [57, 60, 64],
    _f = [53, 57, 60],
    _g = [55, 59, 62];
const _dm = [62, 65, 69],
    _bb = [58, 62, 65],
    _cM = [60, 64, 67],
    _a = [57, 61, 64];

/// Menu: a relaxed, sunny backyard tune in C major at 100 BPM, 16 bars.
Buf menuMusic() {
  final s = Song(bpm: 100, bars: 16);
  final chords = [_c, _am, _f, _g, _c, _am, _f, _g];
  // Melody, eight bars of (beat, midi, beats); played twice, the second
  // time an octave up for the first half.
  const melody = [
    [(0.0, 72, 1.0), (1.0, 76, 0.5), (1.5, 79, 1.0), (3.0, 76, 1.0)],
    [(0.0, 77, 0.5), (0.5, 76, 0.5), (1.0, 72, 1.5), (3.0, 69, 1.0)],
    [
      (0.0, 72, 1.0),
      (1.0, 74, 0.5),
      (1.5, 76, 1.0),
      (3.0, 77, 0.5),
      (3.5, 76, 0.5),
    ],
    [(0.0, 74, 2.5), (3.0, 71, 0.5), (3.5, 74, 0.5)],
    [
      (0.0, 72, 0.5),
      (0.5, 76, 0.5),
      (1.0, 79, 1.0),
      (2.0, 81, 1.0),
      (3.0, 79, 1.0),
    ],
    [(0.0, 76, 1.0), (1.0, 72, 1.0), (2.0, 69, 1.5)],
    [(0.0, 77, 1.0), (1.0, 76, 0.5), (1.5, 74, 1.0), (3.0, 72, 1.0)],
    [(0.0, 74, 1.5), (2.0, 79, 0.5), (2.5, 74, 0.5), (3.0, 71, 1.0)],
  ];
  for (var bar = 0; bar < s.bars; bar++) {
    final chord = chords[bar % 8];
    final second = bar >= 8;
    // Bass: root on 1, fifth on 3, a pickup on the "and" of 4.
    s
      ..bass(s.at(bar, 0), chord[0] - 24, s.beat * 1.6)
      ..bass(s.at(bar, 2), chord[2] - 24, s.beat * 1.2, vel: 0.8)
      ..bass(s.at(bar, 3.5), chord[0] - 24, s.beat * 0.45, vel: 0.6);
    // Marimba: off-beat broken chords.
    for (var e = 0; e < 8; e++) {
      if (e.isEven && e != 0) continue;
      s.marimba(
        s.at(bar, e / 2),
        chord[e % 3] + (e == 0 ? 0 : 12),
        vel: e == 0 ? 0.7 : 0.55,
        pan: e.isOdd ? 0.3 : -0.2,
      );
    }
    // Light groove from bar 2: kick on 1 and 3, rim-like snare on 2 and 4.
    if (bar >= 1) {
      s
        ..kick(s.at(bar, 0))
        ..kick(s.at(bar, 2), vel: 0.8)
        ..snare(s.at(bar, 1), vel: 0.6)
        ..snare(s.at(bar, 3), vel: 0.6);
      for (var e = 0; e < 8; e++) {
        s.shaker(s.at(bar, e / 2), vel: e.isOdd ? 1 : 0.6);
      }
    }
    // Melody enters at bar 1 of each half.
    for (final (b, midi, len) in melody[bar % 8]) {
      final up = second && bar % 8 < 4 ? 12 : 0;
      s.lead(s.at(bar, b), midi + up, len * s.beat * 0.95, pan: -0.1);
    }
  }
  s.buf.echo(ms: s.beat * 750, feedback: 0.35, mix: 0.18);
  return s.buf;
}

/// Match: an upbeat, slightly mischievous tune in D minor at 120 BPM,
/// 16 bars, busier drums to keep the turns moving.
Buf matchMusic() {
  final s = Song(bpm: 120, bars: 16);
  final chords = [_dm, _bb, _cM, _a, _dm, _bb, _cM, _a];
  const riff = [0, 12, 7, 12, 0, 12, 7, 10]; // bass eighths above the root
  const melody = [
    [
      (0.0, 74, 0.5),
      (0.5, 77, 0.5),
      (1.0, 81, 1.0),
      (2.5, 79, 0.5),
      (3.0, 77, 1.0),
    ],
    [(0.0, 77, 0.5), (0.5, 74, 0.5), (1.0, 70, 1.5), (3.0, 74, 1.0)],
    [
      (0.0, 76, 0.5),
      (0.5, 79, 0.5),
      (1.0, 84, 1.0),
      (2.5, 82, 0.5),
      (3.0, 79, 1.0),
    ],
    [(0.0, 76, 1.5), (2.0, 73, 0.5), (2.5, 76, 0.5), (3.0, 81, 1.0)],
    [
      (0.0, 86, 0.5),
      (0.5, 84, 0.5),
      (1.0, 81, 0.5),
      (1.5, 77, 0.5),
      (2.0, 81, 1.0),
      (3.0, 74, 1.0),
    ],
    [(0.0, 77, 1.0), (1.0, 74, 0.5), (1.5, 70, 0.5), (2.0, 74, 2.0)],
    [
      (0.0, 79, 0.5),
      (0.5, 76, 0.5),
      (1.0, 72, 1.0),
      (2.0, 76, 0.5),
      (2.5, 79, 0.5),
      (3.0, 84, 1.0),
    ],
    [(0.0, 81, 2.0), (2.5, 76, 0.5), (3.0, 73, 1.0)],
  ];
  for (var bar = 0; bar < s.bars; bar++) {
    final chord = chords[bar % 8];
    final root = chord[0] - 24;
    for (var e = 0; e < 8; e++) {
      s.bass(
        s.at(bar, e / 2),
        root + riff[e],
        s.beat * 0.42,
        vel: e.isEven ? 1 : 0.7,
      );
    }
    // Marimba stabs on the off-beats.
    for (final e in [1, 3, 5, 7]) {
      for (final (i, n) in chord.indexed) {
        s.marimba(s.at(bar, e / 2), n + 12, vel: 0.35, pan: (i - 1) * 0.4);
      }
    }
    s
      ..kick(s.at(bar, 0))
      ..kick(s.at(bar, 1.5), vel: 0.7)
      ..kick(s.at(bar, 2))
      ..snare(s.at(bar, 1))
      ..snare(s.at(bar, 3));
    if (bar % 4 == 3) {
      // A little fill into the next phrase.
      for (final b in [3.25, 3.5, 3.75]) {
        s.snare(s.at(bar, b), vel: 0.5);
      }
    }
    for (var e = 0; e < 8; e++) {
      s.hat(s.at(bar, e / 2), vel: e.isOdd ? 1 : 0.55);
    }
    // Melody only in the second half, so the loop breathes.
    if (bar >= 8) {
      for (final (b, midi, len) in melody[bar % 8]) {
        s.lead(s.at(bar, b), midi, len * s.beat * 0.9, pan: 0.1, vel: 0.9);
      }
    } else if (bar % 2 == 1) {
      // First half: a short call on the marimba instead.
      s
        ..marimba(s.at(bar, 2), chord[2] + 12, vel: 0.8, pan: -0.3)
        ..marimba(s.at(bar, 2.5), chord[1] + 12, vel: 0.7, pan: -0.3)
        ..marimba(s.at(bar, 3), chord[0] + 12, vel: 0.8, pan: -0.3);
    }
  }
  s.buf.echo(ms: s.beat * 750, feedback: 0.3, mix: 0.12);
  return s.buf;
}

// ---------------------------------------------------------------------------
// Output

void _writeWav(String path, Buf b, {required bool stereo}) {
  final ch = stereo ? 2 : 1;
  final data = ByteData(b.n * ch * 2);
  var o = 0;
  int pcm(double v) => (v.clamp(-1.0, 1.0) * 32767).round();
  for (var i = 0; i < b.n; i++) {
    if (stereo) {
      data
        ..setInt16(o, pcm(b.l[i]), Endian.little)
        ..setInt16(o + 2, pcm(b.r[i]), Endian.little);
      o += 4;
    } else {
      // Effects are rendered centred, so either side is the signal.
      data.setInt16(o, pcm(b.l[i]), Endian.little);
      o += 2;
    }
  }
  final h = ByteData(44);
  void str(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      h.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  h.setUint32(4, 36 + data.lengthInBytes, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  h
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, ch, Endian.little)
    ..setUint32(24, sr, Endian.little)
    ..setUint32(28, sr * ch * 2, Endian.little)
    ..setUint16(32, ch * 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  str(36, 'data');
  h.setUint32(40, data.lengthInBytes, Endian.little);
  File(
    path,
  ).writeAsBytesSync([...h.buffer.asUint8List(), ...data.buffer.asUint8List()]);
}

/// Encodes a rendered loop into assets/audio as Ogg Vorbis, which Android
/// loops without a gap (MP3 frames pad the ends). ffmpeg's built-in Vorbis
/// encoder is marked experimental; at 160 kbit/s it measured as close to
/// the source as LAME MP3 did.
void _encodeMusic(String name) {
  final r = Process.runSync('ffmpeg', [
    '-y', '-loglevel', 'error', //
    '-i', '$tmpDir/$name.wav',
    '-c:a', 'vorbis', '-strict', '-2', '-b:a', '160k',
    '$outDir/$name.ogg',
  ]);
  if (r.exitCode != 0) {
    stderr.writeln('ffmpeg failed for $name: ${r.stderr}');
    exitCode = 1;
  }
}
