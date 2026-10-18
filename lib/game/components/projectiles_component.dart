import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../sim/world.dart';

/// Draws every projectile currently in the sim. Placeholder: a circle in the
/// weapon's colour with a light outline.
class ProjectilesComponent extends Component {
  ProjectilesComponent(this.sim) : super(priority: 5);

  final SimWorld sim;

  /// Visual radius in world px (larger than the 1 px collision point so it
  /// stays visible when the whole map is in view).
  static const double radius = 12;

  final ui.Paint _fill = ui.Paint();
  final ui.Paint _outline = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const ui.Color(0xFFFFFFFF);

  @override
  void render(ui.Canvas canvas) {
    for (final p in sim.projectiles) {
      final center = ui.Offset(p.x, p.y);
      _fill.color = ui.Color(p.weapon.placeholderArgb);
      canvas
        ..drawCircle(center, radius, _fill)
        ..drawCircle(center, radius, _outline);
    }
  }
}
