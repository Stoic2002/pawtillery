import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/components.dart';

import '../../config/controls.dart';

/// Camera behaviour for the arena: manual pan and pinch-zoom, smooth
/// focusing on a target, and clamping to the map (plus some sky).
class ArenaCamera {
  ArenaCamera({required this.camera, required this.worldSize});

  final CameraComponent camera;
  final Vector2 worldSize;

  Viewfinder get _vf => camera.viewfinder;

  /// Point the camera eases towards; null = stay put.
  Vector2? _target;

  double get zoom => _vf.zoom;
  Vector2 get position => _vf.position;

  void init({required Vector2 center}) {
    _vf
      ..anchor = Anchor.center
      ..zoom = ControlsConfig.defaultZoom
      ..position = center.clone();
    _clamp();
  }

  /// Eases towards [point] until it is reached or the user takes over.
  void focusOn(Vector2 point) => _target = point.clone();

  /// Like [focusOn], but re-aimed every frame by the caller (e.g. a
  /// projectile in flight).
  void follow(Vector2 point) => _target = point.clone();

  /// Pan by a screen-space delta (logical px), as dragging the map would.
  void panByScreen(Vector2 delta) {
    _target = null;
    _vf.position = _vf.position - delta / _vf.zoom;
    _clamp();
  }

  /// Zoom to [newZoom] keeping the world point under [screenFocal] fixed.
  void zoomAt(Vector2 screenFocal, double newZoom) {
    _target = null;
    final before = camera.globalToLocal(screenFocal);
    _vf.zoom = newZoom.clamp(ControlsConfig.minZoom, ControlsConfig.maxZoom);
    final after = camera.globalToLocal(screenFocal);
    _vf.position = _vf.position + (before - after);
    _clamp();
  }

  void update(double dt) {
    final target = _target;
    if (target == null) return;
    final t = math.min(1.0, ControlsConfig.cameraFollowRate * dt);
    _vf.position = _vf.position + (target - _vf.position) * t;
    if (_vf.position.distanceToSquared(target) < 1) _target = null;
    _clamp();
  }

  /// Keeps the view inside the map, allowing extra room at the sides and
  /// above for high shots. Centres an axis the view is wider than.
  void _clamp() {
    final view = camera.viewport.virtualSize / _vf.zoom;
    const side = ControlsConfig.cameraMarginSide;
    const top = ControlsConfig.cameraMarginTop;
    _vf.position = Vector2(
      _clampAxis(_vf.position.x, -side, worldSize.x + side, view.x),
      _clampAxis(_vf.position.y, -top, worldSize.y, view.y),
    );
  }

  static double _clampAxis(double p, double min, double max, double view) {
    if (max - min <= view) return (min + max) / 2;
    return p.clamp(min + view / 2, max - view / 2);
  }
}
