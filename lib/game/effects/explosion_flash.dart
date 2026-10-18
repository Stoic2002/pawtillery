import 'dart:ui' as ui;

import 'package:flame/components.dart';

/// Short expanding, fading disc at an explosion. Placeholder for the
/// particle effects in M5.
class ExplosionFlash extends Component {
  ExplosionFlash({required this.x, required this.y, required this.radius})
      : super(priority: 20);

  final double x;
  final double y;
  final double radius;

  static const double _lifetime = 0.3;
  double _age = 0;
  final ui.Paint _paint = ui.Paint();

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= _lifetime) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    final t = (_age / _lifetime).clamp(0.0, 1.0);
    _paint.color = ui.Color.fromARGB((220 * (1 - t)).round(), 255, 200, 80);
    canvas.drawCircle(ui.Offset(x, y), radius * (0.6 + 0.6 * t), _paint);
  }
}
