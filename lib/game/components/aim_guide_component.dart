import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/sandbox.dart';
import '../../config/weapons.dart';
import '../../sim/physics.dart';
import '../../sim/world.dart';

/// M1 launcher marker plus the aim guide: the first ~25 % of the no-wind
/// path, recomputed only when the aim changes or terrain is carved.
class AimGuideComponent extends Component {
  AimGuideComponent({
    required this.sim,
    required this.angle,
    required this.power,
  }) : super(priority: 6);

  final SimWorld sim;
  final int Function() angle;
  final int Function() power;

  static const double _launcherRadius = 16;
  static const double _barrelLength = 56;

  final ui.Paint _launcher = ui.Paint()..color = const ui.Color(0xFF2D3142);
  final ui.Paint _barrel = ui.Paint()
    ..color = const ui.Color(0xFF2D3142)
    ..strokeWidth = 10
    ..strokeCap = ui.StrokeCap.round;
  final ui.Paint _dot = ui.Paint()..color = const ui.Color(0xCCFFFFFF);

  List<double> _visible = const [];
  int _cachedAngle = -1;
  int _cachedPower = -1;
  bool _dirty = true;

  /// Call after the terrain changes; the path may now end elsewhere.
  void invalidate() => _dirty = true;

  @override
  void update(double dt) {
    final a = angle();
    final p = power();
    if (!_dirty && a == _cachedAngle && p == _cachedPower) return;
    _cachedAngle = a;
    _cachedPower = p;
    _dirty = false;
    final path = ProjectilePhysics.predict(
      weapon: Weapons.rock,
      x: SandboxConfig.launcherX.toDouble(),
      y: SandboxConfig.launcherY.toDouble(),
      angleDeg: a,
      powerPercent: p,
      terrain: sim.terrain,
    );
    final points = path.length ~/ 2;
    final keep = math.max(1, (points * ControlsConfig.aimGuideFraction).ceil());
    _visible = path.sublist(0, keep * 2);
  }

  @override
  void render(ui.Canvas canvas) {
    const origin = ui.Offset(
        SandboxConfig.launcherX + 0.0, SandboxConfig.launcherY + 0.0);
    final rad = _cachedAngle * math.pi / 180;
    canvas
      ..drawLine(
        origin,
        origin +
            ui.Offset(math.cos(rad), -math.sin(rad)) * _barrelLength,
        _barrel,
      )
      ..drawCircle(origin, _launcherRadius, _launcher);

    if (sim.isProjectileInFlight) return;
    // Every 3rd tick, so the dots read as a dotted line.
    for (var i = 0; i < _visible.length; i += 6) {
      canvas.drawCircle(ui.Offset(_visible[i], _visible[i + 1]), 5, _dot);
    }
  }
}
