import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../config/breeds.dart';

enum AnimalPose { idle, walkA, walkB, air }

/// The chibi pets of the approved redesign (redesign/PetSoft.dc.html): a
/// round softly shaded body, family features (ears, horns, beak, shell...),
/// two glossy eyes, blushing cheeks, and a collar in the team colour with
/// a gold tag. Breeds change the coat colour and add a light pattern.
///
/// Built in the prototype's 100 × 100 box and scaled so the feet sit at
/// (0, 0) and a standard unit is [height] tall, facing right. Callers flip
/// and scale. Every (breed, team, pose) is recorded once into a
/// [ui.Picture] and replayed.
abstract final class AnimalArt {
  static final Map<(String?, String?, int, AnimalPose), ui.Picture> _cache = {};

  /// Visual height of a standard unit, for placing labels above it.
  static const double height = 37;

  /// World pixels per prototype unit.
  static const double _k = 0.4;

  static void draw(
    ui.Canvas canvas, {
    required String? familyId,
    required String? breedId,
    required int teamArgb,
    required AnimalPose pose,
  }) {
    final picture = _cache.putIfAbsent((
      familyId,
      breedId,
      teamArgb,
      pose,
    ), () => _record(familyId, breedId, teamArgb, pose));
    canvas.drawPicture(picture);
  }

  static ui.Picture _record(
    String? familyId,
    String? breedId,
    int teamArgb,
    AnimalPose pose,
  ) {
    final recorder = ui.PictureRecorder();
    // Feet (the bottom of the body) on the origin.
    final canvas = ui.Canvas(recorder)
      ..scale(_k)
      ..translate(-50, -95);
    final breed = breedId == null ? null : Breeds.byId(breedId);
    _Pet(canvas, familyId ?? 'cat', breed, teamArgb, pose).draw();
    return recorder.endRecording();
  }
}

class _Pet {
  _Pet(this.c, this.family, BreedDef? breed, this.team, this.pose)
    : color = breed?.primaryArgb ?? 0xFFF2A65A,
      mark = breed?.markingArgb ?? 0xFF8A7458,
      second = breed?.secondaryArgb ?? 0xFFF7EEDD,
      pattern = breed?.pattern ?? CoatPattern.solid;

  final ui.Canvas c;
  final String family;
  final int color;
  final int mark;
  final int second;
  final CoatPattern pattern;
  final int team;
  final AnimalPose pose;

  static const _line = ui.Color(0xFF3A2A1E);
  static const _eye = ui.Color(0xFF22170F);
  static const _pink = ui.Color(0xFFF2A39A);

  ui.Color get base => ui.Color(color);

  /// The prototype's mix(): k > 1 lightens towards white, k < 1 darkens.
  ui.Color mix(double k) {
    final b = base;
    double ch(double v) =>
        (k > 1 ? v + (1 - v) * (k - 1) : v * k).clamp(0.0, 1.0);
    return ui.Color.from(alpha: 1, red: ch(b.r), green: ch(b.g), blue: ch(b.b));
  }

  ui.Color get light => mix(1.35);
  ui.Color get dark => mix(0.68);

  ui.Paint stroke([double w = 2.5]) => ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = ui.StrokeJoin.round
    ..strokeCap = ui.StrokeCap.round
    ..color = _line;

  ui.Paint fill(ui.Color color) => ui.Paint()..color = color;

  /// The body's radial gradient, lit from the top left.
  ui.Paint get bodyFill => ui.Paint()
    ..shader = ui.Gradient.radial(
      const ui.Offset(26 + 68 * 0.36, 26 + 68 * 0.3),
      68 * 0.8,
      [light, base, dark],
      const [0, 0.5, 1],
    );

  ui.Paint earFill(ui.Rect r) => ui.Paint()
    ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [light, dark]);

  void shape(ui.Path p, ui.Paint paint, {double line = 2.5}) {
    c.drawPath(p, paint);
    if (line > 0) c.drawPath(p, stroke(line));
  }

  ui.Path circle(double x, double y, double r) =>
      ui.Path()
        ..addOval(ui.Rect.fromCircle(center: ui.Offset(x, y), radius: r));

  /// An ellipse rotated by [deg] about its centre.
  ui.Path oval(double cx, double cy, double rx, double ry, [double deg = 0]) {
    final a = deg * math.pi / 180;
    final cs = math.cos(a);
    final sn = math.sin(a);
    return (ui.Path()..addOval(
          ui.Rect.fromCenter(
            center: ui.Offset.zero,
            width: rx * 2,
            height: ry * 2,
          ),
        ))
        .transform(
          Float64List.fromList([
            cs, sn, 0, 0, //
            -sn, cs, 0, 0, //
            0, 0, 1, 0, //
            cx, cy, 0, 1,
          ]),
        );
  }

  void draw() {
    // Ground shadow stays flat while the body moves.
    c.drawOval(
      ui.Rect.fromCenter(
        center: const ui.Offset(50, 96),
        width: 60,
        height: 10,
      ),
      fill(const ui.Color(0xFF1E140C).withValues(alpha: 0.28)),
    );
    c.save();
    // Poses: a waddle when walking, a stretch in the air.
    switch (pose) {
      case AnimalPose.walkA || AnimalPose.walkB:
        final s = pose == AnimalPose.walkA ? 1 : -1;
        c
          ..translate(50, 94)
          ..rotate(s * 0.1)
          ..translate(-50, -96);
      case AnimalPose.air:
        c
          ..translate(50, 94)
          ..scale(0.95, 1.06)
          ..translate(-50, -96);
      case AnimalPose.idle:
        break;
    }
    _tail();
    _feet();
    _behind();
    final body = circle(50, 60, 34);
    c.drawPath(body, bodyFill);
    _pattern(body);
    c
      ..drawPath(body, stroke())
      ..save()
      ..translate(40, 42)
      ..rotate(-25 * math.pi / 180)
      ..drawOval(
        ui.Rect.fromCenter(center: ui.Offset.zero, width: 26, height: 16),
        fill(const ui.Color(0x47FFFFFF)),
      )
      ..restore();
    _front();
    _face();
    _collar();
    c.restore();
  }

  /// Two little feet peeking out under the body (drawn behind it), stepping
  /// when walking. Birds get orange toes.
  void _feet() {
    final step = switch (pose) {
      AnimalPose.walkA => 1.8,
      AnimalPose.walkB => -1.8,
      _ => 0.0,
    };
    final birdish = const ['bird', 'chicken', 'duck'].contains(family);
    final foot = birdish
        ? fill(const ui.Color(0xFFF2A33A))
        : fill(family == 'turtle' ? mix(0.82) : dark);
    for (final (x, lift) in [(36.0, step), (64.0, -step)]) {
      final y = 94.5 - math.max(0, lift);
      if (birdish) {
        final toes = ui.Path()
          ..moveTo(x - 6, y + 3)
          ..lineTo(x, y - 3)
          ..lineTo(x + 6, y + 3)
          ..quadraticBezierTo(x, y + 5, x - 6, y + 3)
          ..close();
        shape(toes, foot, line: 2);
      } else {
        shape(oval(x, y, 8.5, 5.2), foot, line: 2.2);
        // Toe lines.
        final toe = stroke(1.2);
        c
          ..drawLine(ui.Offset(x - 2.5, y + 1.5), ui.Offset(x - 2.5, y + 4.2), toe)
          ..drawLine(ui.Offset(x + 2.5, y + 1.5), ui.Offset(x + 2.5, y + 4.2), toe);
      }
    }
  }

  /// The tail, behind the body on the side away from the face.
  void _tail() {
    switch (family) {
      case 'cat':
        final tail = ui.Path()
          ..moveTo(26, 78)
          ..cubicTo(4, 80, 2, 54, 12, 44)
          ..cubicTo(15, 41, 19, 43, 17, 47)
          ..cubicTo(10, 57, 14, 72, 30, 70)
          ..close();
        shape(tail, fill(dark));
      case 'dog':
        final wag = pose == AnimalPose.walkA ? -4.0 : 0.0;
        shape(oval(16, 62 + wag, 6, 11, -35), fill(base));
      case 'rabbit' || 'hamster':
        shape(circle(17, 76, family == 'rabbit' ? 8 : 5), fill(light));
      case 'monkey':
        final tail = ui.Path()
          ..moveTo(24, 80)
          ..cubicTo(2, 84, -2, 56, 10, 52)
          ..cubicTo(20, 48, 22, 62, 14, 62)
          ..cubicTo(10, 62, 10, 57, 13, 56)
          ..cubicTo(6, 60, 8, 76, 26, 72)
          ..close();
        shape(tail, fill(dark));
      case 'bird' || 'chicken':
        final feathers = ui.Path()
          ..moveTo(22, 62)
          ..lineTo(4, 50)
          ..lineTo(12, 64)
          ..lineTo(2, 66)
          ..lineTo(14, 72)
          ..lineTo(6, 80)
          ..lineTo(24, 76)
          ..close();
        shape(
          feathers,
          fill(family == 'chicken' ? mix(0.6) : dark),
        );
      case 'duck':
        final tuft = ui.Path()
          ..moveTo(22, 70)
          ..quadraticBezierTo(8, 66, 10, 54)
          ..quadraticBezierTo(16, 62, 26, 62)
          ..close();
        shape(tuft, fill(base));
      case 'goat':
        shape(oval(18, 58, 5, 8, -30), fill(light));
      case 'turtle':
        final tail = ui.Path()
          ..moveTo(22, 78)
          ..lineTo(8, 82)
          ..lineTo(22, 86)
          ..close();
        shape(tail, fill(mix(0.82)), line: 2);
    }
  }

  /// Ears, horns and other parts behind the body.
  void _behind() {
    switch (family) {
      case 'cat':
        final ears = ui.Path()
          ..moveTo(24, 46)
          ..lineTo(27, 8)
          ..lineTo(52, 30)
          ..close()
          ..moveTo(76, 46)
          ..lineTo(73, 8)
          ..lineTo(48, 30)
          ..close();
        shape(ears, earFill(const ui.Rect.fromLTRB(24, 8, 76, 46)));
        c.drawPath(
          ui.Path()
            ..moveTo(31, 33)
            ..lineTo(31.5, 19)
            ..lineTo(42, 28)
            ..close()
            ..moveTo(69, 33)
            ..lineTo(68.5, 19)
            ..lineTo(58, 28)
            ..close(),
          fill(_pink.withValues(alpha: 0.85)),
        );
      case 'dog':
        shape(oval(20, 54, 11, 22, 20), fill(dark));
        shape(oval(80, 54, 11, 22, -20), fill(dark));
      case 'rabbit':
        const r = ui.Rect.fromLTRB(29, -2, 71, 42);
        shape(oval(38, 20, 9, 22, -10), earFill(r));
        shape(oval(62, 20, 9, 22, 10), earFill(r));
        c
          ..drawPath(
            oval(38, 22, 3.5, 14, -10),
            fill(_pink.withValues(alpha: 0.8)),
          )
          ..drawPath(
            oval(62, 22, 3.5, 14, 10),
            fill(_pink.withValues(alpha: 0.8)),
          );
      case 'hamster':
        shape(circle(22, 68, 15), bodyFill);
        shape(circle(78, 68, 15), bodyFill);
        shape(circle(34, 34, 8), fill(dark));
        shape(circle(66, 34, 8), fill(dark));
      case 'chicken':
        shape(circle(40, 27, 9), fill(const ui.Color(0xFFD9413F)));
        shape(circle(52, 20, 10), fill(const ui.Color(0xFFE5484D)));
        shape(circle(64, 27, 9), fill(const ui.Color(0xFFD9413F)));
        c.drawCircle(
          const ui.Offset(49, 17),
          3,
          fill(const ui.Color(0x73FFFFFF)),
        );
      case 'goat':
        final horns = ui.Path()
          ..moveTo(36, 34)
          ..quadraticBezierTo(22, 22, 18, 4)
          ..quadraticBezierTo(32, 12, 44, 28)
          ..close()
          ..moveTo(64, 34)
          ..quadraticBezierTo(78, 22, 82, 4)
          ..quadraticBezierTo(68, 12, 56, 28)
          ..close();
        shape(horns, fill(const ui.Color(0xFFD8CCBA)));
        final ridges = ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = ui.StrokeCap.round
          ..color = const ui.Color(0xFF9C8E7A);
        for (final (x1, y1, x2, y2) in const [
          (24.0, 14.0, 30.0, 20.0),
          (28.0, 9.0, 34.0, 17.0),
          (76.0, 14.0, 70.0, 20.0),
          (72.0, 9.0, 66.0, 17.0),
        ]) {
          c.drawLine(ui.Offset(x1, y1), ui.Offset(x2, y2), ridges);
        }
      case 'monkey':
        for (final x in [17.0, 83.0]) {
          shape(circle(x, 54, 14), fill(dark));
          c.drawCircle(ui.Offset(x, 54), 6.5, fill(const ui.Color(0xFFF0D2AA)));
        }
    }
  }

  /// A light breed pattern on the body, clipped to it.
  void _pattern(ui.Path body) {
    final m = fill(ui.Color(mark).withValues(alpha: 0.55));
    c
      ..save()
      ..clipPath(body);
    switch (pattern) {
      case CoatPattern.tabby:
        final s = ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = ui.StrokeCap.round
          ..color = ui.Color(mark).withValues(alpha: 0.5);
        for (final x in [40.0, 50.0, 60.0]) {
          c.drawLine(ui.Offset(x, 27), ui.Offset(x + (x - 50) * 0.15, 38), s);
        }
        c
          ..drawLine(const ui.Offset(18, 60), const ui.Offset(27, 62), s)
          ..drawLine(const ui.Offset(17, 70), const ui.Offset(26, 70), s);
      case CoatPattern.spotted:
        for (final (x, y, r) in const [
          (30.0, 44.0, 5.0),
          (70.0, 40.0, 4.0),
          (24.0, 70.0, 4.5),
          (76.0, 76.0, 3.5),
        ]) {
          c.drawCircle(ui.Offset(x, y), r, m);
        }
      case CoatPattern.patches:
        c.drawOval(
          ui.Rect.fromCenter(
            center: const ui.Offset(66, 52),
            width: 30,
            height: 24,
          ),
          m,
        );
      case CoatPattern.saddle:
        c.drawOval(
          ui.Rect.fromCenter(
            center: const ui.Offset(36, 34),
            width: 52,
            height: 28,
          ),
          m,
        );
      case CoatPattern.stripe:
        c.drawRect(const ui.Rect.fromLTRB(44, 24, 56, 48), m);
      case CoatPattern.headColor:
        c.drawRect(
          const ui.Rect.fromLTRB(0, 0, 100, 50),
          fill(ui.Color(mark).withValues(alpha: 0.6)),
        );
      default:
        break;
    }
    c.restore();
  }

  /// Parts in front of the body: shell, muzzles.
  void _front() {
    if (family == 'turtle') {
      final shell = ui.Path()
        ..moveTo(16, 54)
        ..quadraticBezierTo(18, 14, 50, 14)
        ..quadraticBezierTo(82, 14, 84, 54)
        ..close();
      final shellColor =
          pattern == CoatPattern.shell || pattern == CoatPattern.spotted
          ? ui.Color(mark)
          : const ui.Color(0xFF4E8F52);
      shape(shell, fill(shellColor));
      final scute = ui.Path()
        ..moveTo(38, 23)
        ..lineTo(62, 23)
        ..lineTo(68, 39)
        ..lineTo(50, 47)
        ..lineTo(32, 39)
        ..close();
      c
        ..drawPath(
          scute,
          fill(ui.Color.lerp(shellColor, const ui.Color(0xFFFFFFFF), 0.12)!),
        )
        ..drawPath(
          ui.Path()
            ..addPath(scute, ui.Offset.zero)
            ..moveTo(26, 46)
            ..lineTo(32, 39)
            ..moveTo(74, 46)
            ..lineTo(68, 39)
            ..moveTo(38, 23)
            ..lineTo(32, 17)
            ..moveTo(62, 23)
            ..lineTo(68, 17),
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = ui.Color.lerp(
              shellColor,
              const ui.Color(0xFF000000),
              0.4,
            )!,
        )
        ..drawPath(
          ui.Path()
            ..moveTo(30, 26)
            ..quadraticBezierTo(44, 16, 60, 18),
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = ui.StrokeCap.round
            ..color = const ui.Color(0x4DFFFFFF),
        );
    }
    if (const ['cat', 'dog', 'rabbit', 'hamster', 'goat'].contains(family)) {
      final muzzle = pattern == CoatPattern.tuxedo
          ? ui.Color(second)
          : light.withValues(alpha: 0.75);
      c.drawOval(
        ui.Rect.fromCenter(
          center: const ui.Offset(55, 73),
          width: 34,
          height: 22,
        ),
        fill(muzzle),
      );
    }
    if (family == 'monkey') {
      shape(
        ui.Path()..addOval(
          ui.Rect.fromCenter(
            center: const ui.Offset(54, 72),
            width: 36,
            height: 24,
          ),
        ),
        fill(const ui.Color(0xFFF0D2AA)),
        line: 2,
      );
    }
  }

  void _face() {
    for (final x in [43.0, 63.0]) {
      c
        ..drawCircle(ui.Offset(x, 58), 5, fill(_eye))
        ..drawCircle(
          ui.Offset(x + 1.6, 56.2),
          1.7,
          fill(const ui.Color(0xFFFFFFFF)),
        );
    }
    final blush = fill(const ui.Color(0xFFF27D7D).withValues(alpha: 0.35));
    c
      ..drawCircle(const ui.Offset(35, 70), 5, blush)
      ..drawCircle(const ui.Offset(72, 70), 5, blush);
    final mouth = stroke(1.6);
    // A small "w" mouth under the nose.
    void wMouth(double y) => c.drawPath(
      ui.Path()
        ..moveTo(49, y)
        ..quadraticBezierTo(52, y + 3.5, 55, y)
        ..quadraticBezierTo(58, y + 3.5, 61, y),
      mouth,
    );
    switch (family) {
      case 'cat':
        c.drawOval(
          ui.Rect.fromCenter(
            center: const ui.Offset(55, 68),
            width: 7,
            height: 5,
          ),
          fill(const ui.Color(0xFFE07A7A)),
        );
        wMouth(71);
        final whisker = stroke(1.1);
        for (final dy in [-2.0, 2.0]) {
          c
            ..drawLine(ui.Offset(40, 70 + dy), ui.Offset(28, 68 + dy * 2), whisker)
            ..drawLine(ui.Offset(70, 70 + dy), ui.Offset(82, 68 + dy * 2), whisker);
        }
      case 'dog':
        c.drawOval(
          ui.Rect.fromCenter(
            center: const ui.Offset(55, 68),
            width: 10,
            height: 7,
          ),
          fill(_eye),
        );
        c.drawLine(const ui.Offset(55, 71), const ui.Offset(55, 75), mouth);
        // A little tongue out.
        shape(
          ui.Path()..addRRect(
            ui.RRect.fromLTRBR(52, 75, 58, 82, const ui.Radius.circular(3)),
          ),
          fill(const ui.Color(0xFFE8737A)),
          line: 1.4,
        );
      case 'rabbit':
        c.drawOval(
          ui.Rect.fromCenter(
            center: const ui.Offset(55, 67),
            width: 6,
            height: 4.5,
          ),
          fill(const ui.Color(0xFFE07A7A)),
        );
        wMouth(70);
        // Buck teeth.
        shape(
          ui.Path()..addRRect(
            ui.RRect.fromLTRBR(52, 72, 58, 78, const ui.Radius.circular(1.2)),
          ),
          fill(const ui.Color(0xFFFFFFFF)),
          line: 1.3,
        );
        c.drawLine(const ui.Offset(55, 72.5), const ui.Offset(55, 77.5),
            stroke(0.9));
      case 'hamster':
        c.drawCircle(const ui.Offset(55, 67), 2.6, fill(const ui.Color(0xFFE07A7A)));
        wMouth(70);
        final whisker = stroke(1);
        c
          ..drawLine(const ui.Offset(42, 69), const ui.Offset(32, 67), whisker)
          ..drawLine(const ui.Offset(68, 69), const ui.Offset(78, 67), whisker);
      case 'goat':
        for (final x in [51.5, 58.5]) {
          c.drawOval(
            ui.Rect.fromCenter(center: ui.Offset(x, 69), width: 2.6, height: 3.6),
            fill(_eye),
          );
        }
        c.drawPath(
          ui.Path()
            ..moveTo(50, 75)
            ..quadraticBezierTo(55, 78, 60, 75),
          mouth,
        );
      case 'monkey':
        for (final x in [51.0, 57.0]) {
          c.drawCircle(ui.Offset(x, 68), 1.4, fill(_eye));
        }
        c.drawPath(
          ui.Path()
            ..moveTo(46, 74)
            ..quadraticBezierTo(54, 80, 62, 74),
          mouth,
        );
      case 'bird':
        shape(
          ui.Path()
            ..moveTo(80, 56)
            ..lineTo(98, 64)
            ..lineTo(80, 72)
            ..close(),
          fill(const ui.Color(0xFFF5B700)),
        );
      case 'chicken':
        // Wattle under the beak.
        shape(oval(84, 76, 3.5, 5.5), fill(const ui.Color(0xFFE5484D)), line: 1.6);
        shape(
          ui.Path()
            ..moveTo(81, 60)
            ..lineTo(95, 66)
            ..lineTo(81, 72)
            ..close(),
          fill(const ui.Color(0xFFF5B700)),
        );
      case 'duck':
        shape(
          ui.Path()..addRRect(
            ui.RRect.fromLTRBR(70, 62, 100, 75, const ui.Radius.circular(6.5)),
          ),
          fill(const ui.Color(0xFFFF8A3D)),
        );
        c.drawRRect(
          ui.RRect.fromLTRBR(74, 64, 92, 67, const ui.Radius.circular(1.5)),
          fill(const ui.Color(0x59FFFFFF)),
        );
    }
  }

  /// The team collar: a bib-shaped band under the chin with a gold tag.
  void _collar() {
    final band = ui.Path()
      ..moveTo(24, 84)
      ..quadraticBezierTo(50, 101, 76, 84);
    c
      ..drawPath(
        band,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = ui.StrokeCap.round
          ..color = _line,
      )
      ..drawPath(
        band,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 6.5
          ..strokeCap = ui.StrokeCap.round
          ..color = ui.Color(team),
      );
    shape(circle(50, 94, 5), fill(const ui.Color(0xFFF2C14E)), line: 2);
  }
}
