import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../sim/world.dart';
import '../art/object_art.dart';
import '../art/weapon_art.dart';

/// Draws the starter barrels and crates (a lit barrel blinks and smokes),
/// and a short pop-up over a unit that picked a crate up: "+25" for health,
/// the weapon's icon and "+1" for a weapon crate.
class MapObjectsComponent extends Component {
  MapObjectsComponent(this.sim) : super(priority: 4);

  final SimWorld sim;

  final List<_Popup> _popups = [];
  final ui.Paint _flame = ui.Paint();
  final TextPaint _heal = TextPaint(
    style: const TextStyle(
      fontFamily: 'Baloo2',
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: Color(0xFF3CCB6C),
      shadows: [Shadow(color: Color(0xFF2B2118), blurRadius: 2)],
    ),
  );
  final TextPaint _plus = TextPaint(
    style: const TextStyle(
      fontFamily: 'Baloo2',
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: Color(0xFFFFE08A),
      shadows: [Shadow(color: Color(0xFF2B2118), blurRadius: 2)],
    ),
  );

  double _time = 0;

  /// A crate was picked up by the unit at ([x], [y]).
  void popup(double x, double y, {int? hp, String? weaponId}) =>
      _popups.add(_Popup(x, y, hp, weaponId));

  @override
  void update(double dt) {
    _time += dt;
    for (final p in _popups) {
      p.age += dt;
    }
    _popups.removeWhere((p) => p.age > 1.4);
  }

  @override
  void render(ui.Canvas canvas) {
    for (final o in sim.objects) {
      final lit = o.fuse != null;
      canvas
        ..save()
        ..translate(o.x, o.y);
      if (lit && (_time * 14).floor().isOdd) {
        // A blinking white-hot barrel about to go.
        canvas.saveLayer(
          const ui.Rect.fromLTRB(-30, -45, 30, 10),
          ui.Paint()
            ..colorFilter = const ui.ColorFilter.mode(
              Color(0x88FFFFFF),
              BlendMode.srcATop,
            ),
        );
        ObjectArt.draw(canvas, o.kind);
        canvas.restore();
      } else {
        ObjectArt.draw(canvas, o.kind);
      }
      if (lit) _drawFlame(canvas);
      canvas.restore();
    }
    for (final p in _popups) {
      final t = p.age / 1.4;
      final y = p.y - 34 - 26 * t;
      final alpha = (1 - math.max(0, t - 0.6) / 0.4).clamp(0.0, 1.0);
      // Bounded to the pop-up: a full-screen layer is costly on phones.
      canvas.saveLayer(
        ui.Rect.fromCenter(center: Offset(p.x, y), width: 90, height: 40),
        ui.Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
      );
      final weapon = p.weaponId;
      if (p.hp != null) {
        _heal.render(
          canvas,
          '+${p.hp}',
          Vector2(p.x, y),
          anchor: Anchor.center,
        );
      } else if (weapon != null) {
        canvas
          ..save()
          ..translate(p.x - 9, y);
        WeaponArt.icon(canvas, weapon, 22);
        canvas.restore();
        _plus.render(canvas, '+1', Vector2(p.x + 10, y), anchor: Anchor.center);
      }
      canvas.restore();
    }
  }

  void _drawFlame(ui.Canvas canvas) {
    final flicker = 0.75 + 0.25 * math.sin(_time * 40);
    final h = 9 * flicker;
    final flame = ui.Path()
      ..moveTo(-3, -30)
      ..quadraticBezierTo(-3.5, -30 - h * 0.6, 0, -30 - h)
      ..quadraticBezierTo(3.5, -30 - h * 0.6, 3, -30)
      ..close();
    _flame.color = const Color(0xDDFF8A2A);
    canvas.drawPath(flame, _flame);
    _flame.color = const Color(0xEEFFE08A);
    canvas.drawCircle(Offset(0, -31 - h * 0.25), 1.6, _flame);
  }
}

class _Popup {
  _Popup(this.x, this.y, this.hp, this.weaponId);
  final double x;
  final double y;
  final int? hp;
  final String? weaponId;
  double age = 0;
}
