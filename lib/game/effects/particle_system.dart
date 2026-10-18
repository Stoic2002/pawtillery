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
  ParticleSystem({this.capacity = 800}) : super(priority: 20) {
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

  /// Blast: bright flash, flying dirt in the terrain colour, sparks and a
  /// little smoke. Scales with the radius.
  void explosion(double x, double y, double radius, {required int dirtArgb}) {
    _spawn(
        x: x, y: y, life: 0.25, size: radius * 0.6, grow: radius * 2.4,
        argb: 0xFFFFE082, kind: _disc);
    final debris = (radius * 0.5).round().clamp(6, 40);
    for (var i = 0; i < debris; i++) {
      final a = _rand(-math.pi, 0); // upward half
      final speed = _rand(120, 420) * (radius / 40);
      _spawn(
        x: x + _rand(-radius, radius) * 0.3,
        y: y + _rand(-radius, radius) * 0.3,
        vx: math.cos(a) * speed,
        vy: math.sin(a) * speed,
        life: _rand(0.5, 1.1),
        size: _rand(1.5, 4),
        gravity: 900,
        argb: dirtArgb,
      );
    }
    for (var i = 0; i < 10; i++) {
      final a = _rand(0, math.pi * 2);
      final speed = _rand(200, 500);
      _spawn(
        x: x, y: y,
        vx: math.cos(a) * speed, vy: math.sin(a) * speed,
        life: _rand(0.15, 0.35), size: 2, gravity: 300,
        argb: 0xFFFFC107,
      );
    }
    final smoke = (radius / 8).round().clamp(3, 10);
    for (var i = 0; i < smoke; i++) {
      _spawn(
        x: x + _rand(-radius, radius) * 0.4,
        y: y + _rand(-radius, radius) * 0.3,
        vx: _rand(-20, 20), vy: _rand(-60, -20),
        life: _rand(0.8, 1.4), size: radius * 0.25, grow: radius * 0.5,
        argb: 0x99616161, kind: _disc,
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

  @override
  void update(double dt) {
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

  @override
  void render(ui.Canvas canvas) {
    for (var i = 0; i < _count; i++) {
      final fade = 1 - _age[i] / _life[i];
      final argb = _color[i];
      final alpha = ((argb >>> 24) * fade).round();
      final color = ui.Color((alpha << 24) | (argb & 0x00FFFFFF));
      final c = ui.Offset(_x[i], _y[i]);
      if (_kind[i] == _ring) {
        _stroke.color = color;
        canvas.drawCircle(c, _size[i], _stroke);
      } else {
        _fill.color = color;
        canvas.drawCircle(c, _size[i], _fill);
      }
    }
  }
}
