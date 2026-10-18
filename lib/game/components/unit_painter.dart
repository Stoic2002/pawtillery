import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../config/breeds.dart';
import '../../config/families.dart';

/// Draws the placeholder look of a unit (PRD: Aset placeholder): a body in
/// the breed's main colour, the family's feature in its second colour, a
/// team-colour outline, an eye on the facing side and the family's
/// initial. Shared by the arena and Flutter screens (setup, how to play).
class UnitPlaceholderPainter {
  static const neutralArgb = 0xFFF4E4CF;

  final ui.Paint _body = ui.Paint();
  final ui.Paint _feature = ui.Paint();
  final ui.Paint _featureEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = const ui.Color(0x80000000);
  final ui.Paint _outline = ui.Paint()..style = ui.PaintingStyle.stroke;
  final ui.Paint _eye = ui.Paint()..color = const ui.Color(0xFF222222);
  final Map<(String, int), TextPainter> _letters = {};

  void paint(
    ui.Canvas canvas, {
    required ui.Offset center,
    required double radius,
    required int facing,
    required int teamArgb,
    String? familyId,
    String? breedId,
    String? letter,
  }) {
    final breed = breedId == null ? null : Breeds.byId(breedId);
    final family = familyId == null ? null : Families.byId(familyId);
    final c = center;
    final r = radius;
    final f = facing.toDouble();

    _body.color = ui.Color(breed?.primaryArgb ?? neutralArgb);
    _feature.color = ui.Color(breed?.secondaryArgb ?? neutralArgb);
    _outline
      ..color = ui.Color(teamArgb)
      ..strokeWidth = math.max(2, r * 0.22);

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

    if (letter != null && letter.isNotEmpty) {
      final tp = _letters.putIfAbsent(
        (letter, r.round()),
        () => TextPainter(
          text: TextSpan(
            text: letter,
            style: TextStyle(
              fontSize: r * 0.95,
              fontWeight: FontWeight.w900,
              color: const ui.Color(0xCC000000),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
      tp.paint(
        canvas,
        ui.Offset(c.dx - f * r * 0.15 - tp.width / 2,
            c.dy + r * 0.2 - tp.height / 2),
      );
    }
  }

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
