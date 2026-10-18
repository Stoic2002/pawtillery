import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../config/breeds.dart';
import '../../config/families.dart';
import '../../config/teams.dart';
import '../../sim/turn_manager.dart';
import '../../sim/unit.dart';
import '../../sim/world.dart';

/// Placeholder units (PRD: Aset placeholder): a body in the breed's main
/// colour, the family's distinguishing feature in its second colour, a
/// team-colour outline and the family's initial. HP floats above; a
/// bobbing marker shows the active unit. Sprites replace this later.
class UnitsComponent extends Component {
  UnitsComponent(this.sim, {required this.familyLetters})
      : super(priority: 4);

  final SimWorld sim;

  /// Localized first letter of each family name, by family id.
  final Map<String, String> familyLetters;

  static const _neutralArgb = 0xFFF4E4CF;

  final ui.Paint _body = ui.Paint();
  final ui.Paint _feature = ui.Paint();
  final ui.Paint _featureEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = const ui.Color(0x80000000);
  final ui.Paint _outline = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3;
  final ui.Paint _eye = ui.Paint()..color = const ui.Color(0xFF222222);
  final ui.Paint _marker = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
  final ui.Paint _markerEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const ui.Color(0xFF222222);

  late final List<TextPaint> _hpText = [
    for (final style in Teams.styles)
      TextPaint(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: ui.Color(style.colorArgb),
          shadows: const [Shadow(color: ui.Color(0xFF000000), blurRadius: 3)],
        ),
      ),
  ];

  final Map<double, TextPaint> _letterText = {};

  double _time = 0;

  @override
  void update(double dt) => _time += dt;

  @override
  void render(ui.Canvas canvas) {
    final active = sim.activeUnit;
    final showMarker = sim.turn.phase == TurnPhase.turnStart ||
        sim.turn.phase == TurnPhase.action;

    for (final u in sim.units) {
      if (!u.alive) continue;
      _drawUnit(canvas, u);

      final top = u.centerY - u.stats.hitRadius;
      final hpY = top - 12;
      _hpText[u.team].render(
        canvas,
        '${math.max(0, u.hp)}',
        Vector2(u.centerX, hpY),
        anchor: Anchor.bottomCenter,
      );

      if (showMarker && u == active) {
        final bob = math.sin(_time * 6) * 3;
        final tipY = hpY - 22 + bob;
        final cx = u.centerX;
        final path = ui.Path()
          ..moveTo(cx, tipY)
          ..lineTo(cx - 8, tipY - 12)
          ..lineTo(cx + 8, tipY - 12)
          ..close();
        canvas
          ..drawPath(path, _marker)
          ..drawPath(path, _markerEdge);
      }
    }
  }

  void _drawUnit(ui.Canvas canvas, Unit u) {
    final breedId = u.breedId;
    final breed = breedId == null ? null : Breeds.byId(breedId);
    final familyId = u.familyId;
    final family = familyId == null ? null : Families.byId(familyId);
    final c = ui.Offset(u.centerX, u.centerY);
    final r = u.stats.hitRadius;
    final f = u.facing.toDouble();

    _body.color = ui.Color(breed?.primaryArgb ?? _neutralArgb);
    _feature.color = ui.Color(breed?.secondaryArgb ?? _neutralArgb);
    _outline.color = ui.Color(Teams.styles[u.team].colorArgb);

    final feature = family?.feature;
    void featureLayer({required bool back}) {
      if (feature == null) return;
      // A thin dark edge keeps pale breeds readable against the sky.
      _drawFeature(canvas, feature, c, r, f, back: back, paint: _featureEdge);
      _drawFeature(canvas, feature, c, r, f, back: back, paint: _feature);
    }

    featureLayer(back: true);
    canvas
      ..drawCircle(c, r, _body)
      ..drawCircle(c, r, _outline);
    featureLayer(back: false);
    canvas.drawCircle(c + ui.Offset(f * r * 0.45, -r * 0.3), r * 0.16, _eye);

    final letter = family == null ? null : familyLetters[family.id];
    if (letter != null) {
      _letterPaint(r).render(canvas, letter, Vector2(c.dx - f * r * 0.15,
          c.dy + r * 0.2), anchor: Anchor.center);
    }
  }

  TextPaint _letterPaint(double r) => _letterText.putIfAbsent(
        r,
        () => TextPaint(
          style: TextStyle(
            fontSize: r * 0.95,
            fontWeight: FontWeight.w900,
            color: const ui.Color(0xCC000000),
          ),
        ),
      );

  /// Ears, shell, horns and comb sit behind the body; beak and bill in front.
  void _drawFeature(ui.Canvas canvas, PlaceholderFeature feature,
      ui.Offset c, double r, double f,
      {required bool back, required ui.Paint paint}) {
    void ears(ui.Offset left, ui.Offset right, double w, double h) {
      canvas
        ..drawOval(ui.Rect.fromCenter(center: c + left, width: w, height: h),
            paint)
        ..drawOval(ui.Rect.fromCenter(center: c + right, width: w, height: h),
            paint);
    }

    switch (feature) {
      case PlaceholderFeature.pointyEars when back:
        for (final s in const [-1.0, 1.0]) {
          canvas.drawPath(
            ui.Path()
              ..moveTo(c.dx + s * r * 0.85, c.dy - r * 0.35)
              ..lineTo(c.dx + s * r * 0.75, c.dy - r * 1.35)
              ..lineTo(c.dx + s * r * 0.15, c.dy - r * 0.85)
              ..close(),
            paint,
          );
        }
      case PlaceholderFeature.floppyEars when back:
        ears(ui.Offset(-r * 0.95, r * 0.05), ui.Offset(r * 0.95, r * 0.05),
            r * 0.5, r * 1.1);
      case PlaceholderFeature.longEars when back:
        ears(ui.Offset(-r * 0.35, -r * 1.35), ui.Offset(r * 0.35, -r * 1.35),
            r * 0.38, r * 1.3);
      case PlaceholderFeature.roundEars when back:
        canvas
          ..drawCircle(c + ui.Offset(-r * 0.65, -r * 0.75), r * 0.32, paint)
          ..drawCircle(c + ui.Offset(r * 0.65, -r * 0.75), r * 0.32, paint);
      case PlaceholderFeature.sideEars when back:
        canvas
          ..drawCircle(c + ui.Offset(-r * 1.0, -r * 0.15), r * 0.4, paint)
          ..drawCircle(c + ui.Offset(r * 1.0, -r * 0.15), r * 0.4, paint);
      case PlaceholderFeature.comb when back:
        for (final dx in const [-0.32, 0.0, 0.32]) {
          canvas.drawCircle(
              c + ui.Offset(dx * r, -r * 1.05), r * 0.24, paint);
        }
      case PlaceholderFeature.horns when back:
        for (final s in const [-1.0, 1.0]) {
          canvas.drawPath(
            ui.Path()
              ..moveTo(c.dx + s * r * 0.2, c.dy - r * 0.8)
              ..quadraticBezierTo(c.dx + s * r * 0.5, c.dy - r * 1.6,
                  c.dx + s * r * 1.05, c.dy - r * 1.25)
              ..lineTo(c.dx + s * r * 0.55, c.dy - r * 0.75)
              ..close(),
            paint,
          );
        }
      case PlaceholderFeature.shell when back:
        canvas.drawArc(
          ui.Rect.fromCenter(
              center: c + ui.Offset(-f * r * 0.15, r * 0.05),
              width: r * 2.5,
              height: r * 2.2),
          math.pi,
          math.pi,
          true,
          paint,
        );
      case PlaceholderFeature.beak when !back:
        canvas.drawPath(
          ui.Path()
            ..moveTo(c.dx + f * r * 0.75, c.dy - r * 0.3)
            ..lineTo(c.dx + f * r * 1.55, c.dy - r * 0.05)
            ..lineTo(c.dx + f * r * 0.75, c.dy + r * 0.2)
            ..close(),
          paint,
        );
      case PlaceholderFeature.bill when !back:
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(
                f > 0 ? c.dx + r * 0.6 : c.dx - r * 1.5,
                c.dy - r * 0.15,
                r * 0.9,
                r * 0.4),
            ui.Radius.circular(r * 0.2),
          ),
          paint,
        );
      default:
        break;
    }
  }
}
