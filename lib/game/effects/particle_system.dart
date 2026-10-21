import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

/// Pooled particles for explosions, dust and splashes (PRD: object pooling
/// so chained explosions don't cause garbage-collection hitches).
///
/// All particles live in fixed-size typed arrays; spawning reuses a slot,
/// dying swaps the last live particle into the gap. Nothing is allocated
/// per particle or per frame. When full, new particles are dropped.
///
/// Purely visual: uses its own unseeded RNG and never touches the sim.
class ParticleSystem extends Component {
  ParticleSystem({this.capacity = 1400}) : super(priority: 20) {
    _x = Float32List(capacity);
    _y = Float32List(capacity);
    _vx = Float32List(capacity);
    _vy = Float32List(capacity);
    _age = Float32List(capacity);
    _life = Float32List(capacity);
    _size = Float32List(capacity);
    _grow = Float32List(capacity);
    _gravity = Float32List(capacity);
    _color = Uint32List(capacity);
    _kind = Uint8List(capacity);
  }

  final int capacity;

  static const _dot = 0;
  static const _disc = 1;
  static const _ring = 2;

  /// Fireball puff: colour runs yellow → orange → dark red over its life;
  /// drawn additively.
  static const _fire = 3;

  /// Glowing ember or flash, drawn additively.
  static const _glow = 4;

  /// Terrain chunk with a dark cartoon outline.
  static const _chunk = 5;

  /// Smoke puff: soft, with a lighter top.
  static const _smoke = 6;

  late final Float32List _x, _y, _vx, _vy, _age, _life, _size, _grow, _gravity;
  late final Uint32List _color;
  late final Uint8List _kind;
  int _count = 0;

  int get liveCount => _count;

  final math.Random _rng = math.Random();
  final ui.Paint _fill = ui.Paint();
  final ui.Paint _stroke = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 4;

  void _spawn({
    required double x,
    required double y,
    double vx = 0,
    double vy = 0,
    required double life,
    required double size,
    double grow = 0,
    double gravity = 0,
    required int argb,
    int kind = _dot,
  }) {
    if (_count >= capacity) return;
    final i = _count++;
    _x[i] = x;
    _y[i] = y;
    _vx[i] = vx;
    _vy[i] = vy;
    _age[i] = 0;
    _life[i] = life;
    _size[i] = size;
    _grow[i] = grow;
    _gravity[i] = gravity;
    _color[i] = argb;
    _kind[i] = kind;
  }

  double _rand(double min, double max) => min + _rng.nextDouble() * (max - min);

  /// Blast (docs/art_style_guide.md, Effects): a white flash, a rolling
  /// fireball, embers, chunks in the colours of what was hit ([debris],
  /// at least one), sparks, and a smoke column that lingers. Scales with
  /// the radius.
  void explosion(
    double x,
    double y,
    double radius, {
    required List<int> debris,
  }) {
    final scale = radius / 40;
    _spawn(
      x: x, y: y, life: 0.18, size: radius * 0.7, grow: radius * 3,
      argb: 0xFFFFFFF0, kind: _glow,
    );
    // Fireball: overlapping puffs that billow out and up.
    final puffs = (6 + radius / 6).round().clamp(6, 16);
    for (var i = 0; i < puffs; i++) {
      final a = _rand(0, math.pi * 2);
      final d = _rand(0, radius * 0.55);
      _spawn(
        x: x + math.cos(a) * d,
        y: y + math.sin(a) * d * 0.8,
        vx: math.cos(a) * _rand(20, 70) * scale,
        vy: math.sin(a) * _rand(20, 60) * scale - _rand(20, 60),
        life: _rand(0.35, 0.6),
        size: radius * _rand(0.28, 0.45),
        grow: radius * _rand(0.6, 1.1),
        argb: 0xFFFFFFFF,
        kind: _fire,
      );
    }
    // Chunks of whatever was hit.
    final chunks = (radius * 0.55).round().clamp(8, 44);
    for (var i = 0; i < chunks; i++) {
      final a = _rand(-math.pi * 0.95, -math.pi * 0.05);
      final speed = _rand(140, 460) * scale.clamp(0.7, 1.6);
      _spawn(
        x: x + _rand(-radius, radius) * 0.3,
        y: y + _rand(-radius, radius) * 0.3,
        vx: math.cos(a) * speed,
        vy: math.sin(a) * speed,
        life: _rand(0.7, 1.3),
        size: _rand(1.8, 4.2),
        gravity: 950,
        argb: debris[i % debris.length],
        kind: _chunk,
      );
    }
    // Embers drift up and fade.
    final embers = (radius * 0.4).round().clamp(6, 24);
    for (var i = 0; i < embers; i++) {
      final a = _rand(-math.pi * 0.9, -math.pi * 0.1);
      final speed = _rand(80, 300) * scale.clamp(0.7, 1.5);
      _spawn(
        x: x + _rand(-radius, radius) * 0.3,
        y: y + _rand(-radius, radius) * 0.3,
        vx: math.cos(a) * speed,
        vy: math.sin(a) * speed,
        life: _rand(0.6, 1.4),
        size: _rand(1, 2.2),
        gravity: 120,
        argb: i.isEven ? 0xFFFFD25A : 0xFFFF8A2A,
        kind: _glow,
      );
    }
    // Sparks.
    for (var i = 0; i < 10; i++) {
      final a = _rand(0, math.pi * 2);
      final speed = _rand(240, 560);
      _spawn(
        x: x, y: y,
        vx: math.cos(a) * speed, vy: math.sin(a) * speed,
        life: _rand(0.12, 0.3), size: 1.8, gravity: 300,
        argb: 0xFFFFF0B0, kind: _glow,
      );
    }
    // A smoke column that rises and lingers after the fire.
    final smoke = (radius / 6).round().clamp(4, 14);
    for (var i = 0; i < smoke; i++) {
      _spawn(
        x: x + _rand(-radius, radius) * 0.35,
        y: y + _rand(-radius, radius) * 0.2,
        vx: _rand(-14, 14),
        vy: _rand(-55, -18),
        life: _rand(1.8, 3.4),
        size: radius * _rand(0.2, 0.32),
        grow: radius * _rand(0.25, 0.45),
        argb: i.isEven ? 0xB0584C46 : 0xA0787068,
        kind: _smoke,
      );
    }
  }

  /// Shockwave or punch: an expanding ring, no debris.
  void ring(double x, double y, double radius) => _spawn(
      x: x, y: y, life: 0.3, size: radius * 0.2, grow: radius * 2.6,
      argb: 0xFFFFFFFF, kind: _ring);

  /// Dust kicked up by a landing or by digging.
  void dust(double x, double y, {required double strength}) {
    final n = (strength * 8).round().clamp(2, 14);
    for (var i = 0; i < n; i++) {
      final side = i.isEven ? 1 : -1;
      _spawn(
        x: x, y: y,
        vx: side * _rand(30, 110) * strength, vy: _rand(-60, -10),
        life: _rand(0.3, 0.6), size: _rand(2, 4), grow: 6,
        argb: 0xAABCAAA4, kind: _disc,
      );
    }
  }

  /// Laser: a bright red beam that fades fast, with sparks where it ends.
  void beam(double x0, double y0, double x1, double y1) {
    _streaks.add(_Streak([ui.Offset(x0, y0), ui.Offset(x1, y1)], 0.45,
        0xFFFF4A3D, 7));
    for (var i = 0; i < 12; i++) {
      final a = _rand(0, math.pi * 2);
      final speed = _rand(60, 220);
      _spawn(
        x: x1, y: y1,
        vx: math.cos(a) * speed, vy: math.sin(a) * speed,
        life: _rand(0.2, 0.45), size: 1.6, gravity: 300,
        argb: 0xFFFFB0A0, kind: _glow,
      );
    }
  }

  /// Satellite laser: a cold-white beam from ([x0], [y0]) down to ([x],
  /// [y]), a flash where it ends and sparks along it.
  void orbital(double x0, double y0, double x, double y) {
    _streaks
      ..add(_Streak([ui.Offset(x0, y0), ui.Offset(x, y)], 0.6, 0x887FD3FF, 11))
      ..add(_Streak([ui.Offset(x0, y0), ui.Offset(x, y)], 0.45, 0xFFF4FBFF, 3.5));
    _spawn(
      x: x, y: y, life: 0.3, size: 12, grow: 110,
      argb: 0xFFE6F7FF, kind: _glow,
    );
    for (var i = 0; i < 10; i++) {
      final a = _rand(0, math.pi * 2);
      final speed = _rand(40, 200);
      final t = _rand(0.55, 1);
      _spawn(
        x: x0 + (x - x0) * t, y: y0 + (y - y0) * t,
        vx: math.cos(a) * speed, vy: math.sin(a) * speed,
        life: _rand(0.25, 0.6), size: 1.8, gravity: 250,
        argb: 0xFFBDE9FF, kind: _glow,
      );
    }
  }

  /// A burst of small glowing dots (a crate picked up).
  void sparkle(double x, double y, {required int argb}) {
    for (var i = 0; i < 16; i++) {
      final a = _rand(0, math.pi * 2);
      final speed = _rand(40, 150);
      _spawn(
        x: x, y: y,
        vx: math.cos(a) * speed, vy: math.sin(a) * speed - 60,
        life: _rand(0.35, 0.7), size: 2, gravity: 120,
        argb: argb, kind: _glow,
      );
    }
  }

  /// Lightning: a jagged bolt from [top] (default: far above) down to
  /// ([x], [y]).
  void bolt(double x, double y, {double? top}) {
    final from = top ?? y - 900;
    final h = y - from;
    final points = <ui.Offset>[ui.Offset(x + _rand(-14, 14), from)];
    const segments = 14;
    for (var i = 1; i < segments; i++) {
      final t = i / segments;
      points.add(ui.Offset(x + _rand(-22, 22) * (1 - t), from + h * t));
    }
    points.add(ui.Offset(x, y));
    _streaks
      ..add(_Streak(points, 0.7, 0x66FFF2A8, 16))
      ..add(_Streak(points, 0.7, 0xFFFFF2A8, 6));
    _spawn(
      x: x, y: y, life: 0.25, size: 14, grow: 120,
      argb: 0xFFFFF6C8, kind: _glow,
    );
  }

  /// Something fell into the water.
  void splash(double x, double y, {required int waterArgb}) {
    for (var i = 0; i < 14; i++) {
      final a = _rand(-math.pi * 0.85, -math.pi * 0.15);
      final speed = _rand(140, 320);
      _spawn(
        x: x + _rand(-6, 6), y: y,
        vx: math.cos(a) * speed, vy: math.sin(a) * speed,
        life: _rand(0.4, 0.8), size: _rand(2, 4), gravity: 900,
        argb: (waterArgb & 0x00FFFFFF) | 0xEE000000,
      );
    }
  }

  /// Lines that flash and fade (beams, bolts); few and short-lived, so a
  /// plain list is fine.
  final List<_Streak> _streaks = [];

  @override
  void update(double dt) {
    for (final st in _streaks) {
      st.age += dt;
    }
    _streaks.removeWhere((st) => st.age >= st.life);
    var i = 0;
    while (i < _count) {
      _age[i] += dt;
      if (_age[i] >= _life[i]) {
        _swapOut(i);
        continue;
      }
      _vy[i] += _gravity[i] * dt;
      _x[i] += _vx[i] * dt;
      _y[i] += _vy[i] * dt;
      _size[i] += _grow[i] * dt;
      i++;
    }
  }

  void _swapOut(int i) {
    final last = --_count;
    if (i == last) return;
    _x[i] = _x[last];
    _y[i] = _y[last];
    _vx[i] = _vx[last];
    _vy[i] = _vy[last];
    _age[i] = _age[last];
    _life[i] = _life[last];
    _size[i] = _size[last];
    _grow[i] = _grow[last];
    _gravity[i] = _gravity[last];
    _color[i] = _color[last];
    _kind[i] = _kind[last];
  }

  static const _fireStops = [0xFFFFF6B0, 0xFFFFB02E, 0xFFF0501E, 0xFF5A2018];

  final ui.Paint _add = ui.Paint()..blendMode = ui.BlendMode.plus;
  final ui.Paint _edge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 0.9
    ..color = const ui.Color(0xFF2A1A12);

  ui.Color _fireColor(double t) {
    final f = t * (_fireStops.length - 1);
    final i = f.floor().clamp(0, _fireStops.length - 2);
    return ui.Color.lerp(
      ui.Color(_fireStops[i]),
      ui.Color(_fireStops[i + 1]),
      f - i,
    )!;
  }

  final ui.Paint _streakPaint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round
    ..blendMode = ui.BlendMode.plus;

  void _renderStreaks(ui.Canvas canvas) {
    for (final st in _streaks) {
      final fade = 1 - st.age / st.life;
      final path = ui.Path()..moveTo(st.points.first.dx, st.points.first.dy);
      for (final p in st.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      // Wide soft glow, then a white-hot core.
      _streakPaint
        ..strokeWidth = st.width * 2.4
        ..color = ui.Color(st.argb).withValues(alpha: 0.35 * fade);
      canvas.drawPath(path, _streakPaint);
      _streakPaint
        ..strokeWidth = st.width
        ..color = ui.Color(st.argb).withValues(alpha: 0.9 * fade);
      canvas.drawPath(path, _streakPaint);
      _streakPaint
        ..strokeWidth = st.width * 0.35
        ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: fade);
      canvas.drawPath(path, _streakPaint);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    _renderStreaks(canvas);
    // Normal pass (smoke, chunks, dust, drops), then additive (fire, glow).
    for (final additive in const [false, true]) {
      for (var i = 0; i < _count; i++) {
        final kind = _kind[i];
        final glows = kind == _fire || kind == _glow;
        if (glows != additive) continue;
        final t = _age[i] / _life[i];
        final fade = 1 - t;
        final c = ui.Offset(_x[i], _y[i]);
        switch (kind) {
          case _fire:
            _add.color = _fireColor(t).withValues(alpha: (1 - t * t) * 0.95);
            canvas.drawCircle(c, _size[i], _add);
          case _glow:
            final argb = _color[i];
            _add.color = ui.Color(argb).withValues(
              alpha: (argb >>> 24) / 255 * fade,
            );
            canvas.drawCircle(c, _size[i], _add);
          case _chunk:
            _fill.color = ui.Color(_color[i]).withValues(alpha: fade.clamp(0, 1) < 0.3 ? fade / 0.3 : 1);
            canvas.drawCircle(c, _size[i], _fill);
            _edge.color = const ui.Color(0xFF2A1A12).withValues(alpha: _fill.color.a);
            canvas.drawCircle(c, _size[i], _edge);
          case _smoke:
            // Fades in quickly, out slowly.
            final a = (t < 0.1 ? t / 0.1 : fade) * ((_color[i] >>> 24) / 255);
            _fill.color = ui.Color(_color[i]).withValues(alpha: a);
            canvas.drawCircle(c, _size[i], _fill);
            _fill.color = const ui.Color(0xFFFFFFFF).withValues(alpha: a * 0.18);
            canvas.drawCircle(
              c.translate(-_size[i] * 0.25, -_size[i] * 0.3),
              _size[i] * 0.55,
              _fill,
            );
          default:
            final argb = _color[i];
            final alpha = ((argb >>> 24) * fade).round();
            final color = ui.Color((alpha << 24) | (argb & 0x00FFFFFF));
            if (kind == _ring) {
              _stroke.color = color;
              canvas.drawCircle(c, _size[i], _stroke);
            } else {
              _fill.color = color;
              canvas.drawCircle(c, _size[i], _fill);
            }
        }
      }
    }
  }
}

class _Streak {
  _Streak(this.points, this.life, this.argb, this.width);
  final List<ui.Offset> points;
  final double life;
  final int argb;
  final double width;
  double age = 0;
}
