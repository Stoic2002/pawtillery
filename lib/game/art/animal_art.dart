import 'dart:math' as math;
import 'dart:ui' as ui;

import '../../config/breeds.dart';
import 'paint_kit.dart';

enum AnimalPose { idle, walkA, walkB, air }

/// Procedural, softly shaded side-view animals (semi-realistic rather than
/// cartoon): each family is built from anatomical parts lit from the
/// top-left, with darker far-side legs for depth, a contact shadow, the
/// breed's coat pattern clipped to the body, and a collar in the team
/// colour.
///
/// Drawn facing right with the feet at (0, 0), at the size of a standard
/// unit (24 px hit circle). Callers flip and scale. Every (breed, team,
/// pose) is recorded once into a [ui.Picture] and replayed.
abstract final class AnimalArt {
  static final Map<(String?, String?, int, AnimalPose), ui.Picture> _cache = {};

  /// Visual height of a standard unit, for placing labels above it.
  static const double height = 36;

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
    final canvas = ui.Canvas(recorder);
    final breed = breedId == null ? null : Breeds.byId(breedId);
    final a = _Animal(canvas, breed, teamArgb, pose);
    switch (familyId) {
      case 'cat':
        a.cat();
      case 'dog':
        a.dog();
      case 'rabbit':
        a.rabbit();
      case 'bird':
        a.bird();
      case 'hamster':
        a.hamster();
      case 'duck':
        a.duck();
      case 'chicken':
        a.chicken();
      case 'turtle':
        a.turtle();
      case 'goat':
        a.goat();
      case 'monkey':
        a.monkey();
      default:
        a.blob();
    }
    return recorder.endRecording();
  }
}

class _Animal {
  _Animal(this.canvas, BreedDef? breed, this.team, this.pose)
    : fur = breed?.primaryArgb ?? 0xFFC8B49A,
      light = breed?.secondaryArgb ?? 0xFFEDE3D2,
      mark = breed?.markingArgb ?? 0xFF8A7458,
      pattern = breed?.pattern ?? CoatPattern.solid,
      longFur = breed?.longFur ?? false;

  final ui.Canvas canvas;
  final int team;
  final AnimalPose pose;
  final int fur;
  final int light;
  final int mark;
  final CoatPattern pattern;
  final bool longFur;

  static const _eyeDark = 0xFF1B1612;
  static const _pink = 0xFFE7A0A6;
  static const _hoof = 0xFF3A2E26;
  static const _beak = 0xFFE9A93A;

  bool get _dark => PaintKit.c(fur).computeLuminance() < 0.08;

  // ------------------------------------------------------------ primitives

  void oval(
    double cx,
    double cy,
    double rx,
    double ry,
    int argb, {
    double rotate = 0,
    bool edge = true,
    double light = 0.28,
  }) {
    final rect = ui.Rect.fromCenter(
      center: ui.Offset.zero,
      width: rx * 2,
      height: ry * 2,
    );
    canvas
      ..save()
      ..translate(cx, cy)
      ..rotate(rotate)
      ..drawOval(rect, PaintKit.lit(rect, argb, light: light));
    if (edge) canvas.drawOval(rect, PaintKit.edge(argb, 0.7));
    canvas.restore();
  }

  void shape(ui.Path path, int argb, {bool edge = true, double light = 0.25}) {
    final b = path.getBounds();
    canvas.drawPath(path, PaintKit.lit(b, argb, light: light));
    if (edge) canvas.drawPath(path, PaintKit.edge(argb, 0.7));
  }

  /// A leg from the body down to the ground, swinging with the pose.
  /// [far] legs are darker and slightly behind for depth.
  void leg(
    double x,
    double top,
    double width,
    int argb, {
    bool far = false,
    double swing = 0,
    int? foot,
  }) {
    final dx = switch (pose) {
      AnimalPose.walkA => swing,
      AnimalPose.walkB => -swing,
      _ => 0.0,
    };
    final lift = pose == AnimalPose.air ? 3.0 : 0.0;
    final color = far ? PaintKit.toneArgb(argb, -0.28) : argb;
    // A leg that tapers from a muscled top to a slim lower leg, with a
    // slight joint halfway down.
    final knee = top * 0.45;
    final path = ui.Path()
      ..moveTo(x - width * 0.6, top)
      ..quadraticBezierTo(
        x - width * 0.55,
        knee,
        x + dx * 0.5 - width * 0.3,
        knee * 0.6,
      )
      ..lineTo(x + dx - width * 0.26, -lift)
      ..lineTo(x + dx + width * 0.26, -lift)
      ..lineTo(x + dx * 0.5 + width * 0.3, knee * 0.6)
      ..quadraticBezierTo(x + width * 0.55, knee, x + width * 0.6, top)
      ..close();
    canvas.drawPath(path, PaintKit.vertical(path.getBounds(), color));
    canvas.drawPath(path, PaintKit.edge(color, 0.5));
    final paw = foot ?? PaintKit.toneArgb(argb, -0.08);
    final f = far ? PaintKit.toneArgb(paw, -0.25) : paw;
    oval(x + dx + width * 0.18, -lift - 0.7, width * 0.5, 0.95, f, edge: false);
  }

  /// A natural eye seen from the side: an almond with a dark rim, the
  /// iris, a large pupil, one wet highlight, and a fine upper lid line.
  void eye(double x, double y, double r, {int iris = 0xFF3B2A1A}) {
    r *= 1.1;
    final almond = ui.Path()
      ..moveTo(x - r * 1.15, y + r * 0.05)
      ..cubicTo(
        x - r * 0.8,
        y - r * 1.2,
        x + r * 0.8,
        y - r * 1.15,
        x + r * 1.1,
        y - r * 0.05,
      )
      ..cubicTo(
        x + r * 0.8,
        y + r * 1.05,
        x - r * 0.8,
        y + r * 1.1,
        x - r * 1.15,
        y + r * 0.05,
      )
      ..close();
    canvas
      ..drawPath(almond, PaintKit.solid(PaintKit.toneArgb(iris, -0.15)))
      ..save()
      ..clipPath(almond)
      ..drawCircle(
        ui.Offset(x + r * 0.2, y),
        r * 0.62,
        PaintKit.solid(_eyeDark),
      )
      ..restore()
      ..drawPath(
        almond,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 0.35
          ..color = const ui.Color(0xCC120C08),
      )
      ..drawCircle(
        ui.Offset(x - r * 0.15, y - r * 0.3),
        r * 0.22,
        PaintKit.solid(0xEEFFFFFF),
      )
      ..drawPath(
        ui.Path()
          ..moveTo(x - r * 1.2, y - r * 0.2)
          ..quadraticBezierTo(
            x - r * 0.1,
            y - r * 1.35,
            x + r * 1.05,
            y - r * 0.55,
          ),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 0.35
          ..color = PaintKit.tone(headColor, -0.45).withValues(alpha: 0.55),
      );
  }

  void nose(double x, double y, double r, int argb) =>
      oval(x, y, r * 1.2, r, argb, edge: false, light: 0.35);

  /// Team collar around the neck, with a small tag.
  void collar(double x, double y, double length, double angle) {
    canvas
      ..save()
      ..translate(x, y)
      ..rotate(angle);
    final rect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromCenter(center: ui.Offset.zero, width: 3.2, height: length),
      const ui.Radius.circular(1.6),
    );
    canvas
      ..drawRRect(rect, PaintKit.lit(rect.outerRect, team, light: 0.35))
      ..drawCircle(ui.Offset(1, length * 0.42), 1.4, PaintKit.solid(0xFFE8C14A))
      ..restore();
  }

  /// Long fur: pointed tufts all round the silhouette, combed back and
  /// down, in a slightly darker shade (drawn before the part they frame).
  void fluff(double cx, double cy, double rx, double ry, int argb) {
    if (!longFur) return;
    // A soft, fuzzy rim: many small overlapping puffs just outside the
    // silhouette, a touch darker than the coat.
    final p = PaintKit.solid(PaintKit.toneArgb(argb, -0.06));
    for (var i = 0; i < 44; i++) {
      final a = i / 44 * math.pi * 2;
      final wob = 1.02 + (i % 3) * 0.035;
      canvas.drawCircle(
        ui.Offset(
          cx + math.cos(a) * rx * wob - 0.3,
          cy + math.sin(a) * ry * wob,
        ),
        1.25,
        p,
      );
    }
  }

  /// Fine fur strokes clipped to [clip]: short, slightly curved hairs that
  /// lie back along the body, darker and lighter, so the coat reads as
  /// fur rather than a flat fill.
  void furTexture(ui.Path clip, ui.Rect area, int argb) {
    final dark = ui.Paint()
      ..color = PaintKit.tone(argb, -0.3).withValues(alpha: 0.22)
      ..strokeWidth = 0.45
      ..strokeCap = ui.StrokeCap.round;
    final lite = ui.Paint()
      ..color = PaintKit.tone(argb, 0.3).withValues(alpha: 0.2)
      ..strokeWidth = 0.4
      ..strokeCap = ui.StrokeCap.round;
    canvas
      ..save()
      ..clipPath(clip);
    var k = 0;
    for (var y = area.top + 0.8; y < area.bottom; y += 2.1) {
      for (
        var x = area.left + (k.isEven ? 0.4 : 1.6);
        x < area.right;
        x += 2.6
      ) {
        final h = ((x * 12.9898 + y * 78.233).abs() * 43758.5453) % 1;
        final len = 1.6 + h * 1.2;
        final tilt = 0.25 + h * 0.3;
        canvas.drawLine(
          ui.Offset(x, y),
          ui.Offset(x - len, y + len * tilt),
          h > 0.5 ? dark : lite,
        );
      }
      k++;
    }
    canvas.restore();
  }

  /// Coat markings clipped to [clip].
  void markings(ui.Path clip, ui.Rect body) {
    canvas
      ..save()
      ..clipPath(clip);
    final m = PaintKit.solid(
      PaintKit.tone(mark, 0).withValues(alpha: 0.75).toARGB32(),
    );
    switch (pattern) {
      case CoatPattern.tabby:
        final stroke = ui.Paint()
          ..color = PaintKit.c(mark).withValues(alpha: 0.7)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = ui.StrokeCap.round;
        for (var i = 0; i < 5; i++) {
          final x = body.left + body.width * (0.18 + i * 0.16);
          canvas.drawPath(
            ui.Path()
              ..moveTo(x - 1.5, body.top)
              ..quadraticBezierTo(
                x + 1.5,
                body.center.dy - 1,
                x - 0.5,
                body.center.dy + 2,
              ),
            stroke,
          );
        }
      case CoatPattern.spotted:
        for (final (fx, fy, r) in const [
          (0.2, 0.3, 1.5),
          (0.4, 0.22, 1.8),
          (0.58, 0.38, 1.4),
          (0.75, 0.25, 1.6),
          (0.32, 0.55, 1.3),
          (0.66, 0.6, 1.5),
          (0.5, 0.48, 1.1),
        ]) {
          canvas.drawCircle(
            ui.Offset(body.left + body.width * fx, body.top + body.height * fy),
            r,
            m,
          );
        }
      case CoatPattern.patches:
        canvas
          ..drawOval(
            ui.Rect.fromLTWH(
              body.left + body.width * 0.1,
              body.top,
              body.width * 0.35,
              body.height * 0.6,
            ),
            m,
          )
          ..drawOval(
            ui.Rect.fromLTWH(
              body.left + body.width * 0.55,
              body.top + body.height * 0.1,
              body.width * 0.25,
              body.height * 0.45,
            ),
            m,
          );
      case CoatPattern.saddle:
        canvas.drawOval(
          ui.Rect.fromLTWH(
            body.left + body.width * 0.05,
            body.top - body.height * 0.2,
            body.width * 0.75,
            body.height * 0.7,
          ),
          PaintKit.solid(mark),
        );
      case CoatPattern.stripe:
        canvas.drawRect(
          ui.Rect.fromLTWH(body.left, body.top, body.width, body.height * 0.18),
          m,
        );
      default:
        break;
    }
    canvas.restore();
  }

  ui.Path ovalPath(double cx, double cy, double rx, double ry) => ui.Path()
    ..addOval(
      ui.Rect.fromCenter(
        center: ui.Offset(cx, cy),
        width: rx * 2,
        height: ry * 2,
      ),
    );

  /// A quadruped's body seen from the side: a deep, rounded chest at the
  /// front, a gently dipped back, the belly tucking up towards the
  /// haunches, and rounded hindquarters.
  ui.Path bodyPath(double cx, double cy, double rx, double ry) => ui.Path()
    ..moveTo(cx - rx * 0.85, cy - ry * 0.55)
    ..cubicTo(
      cx - rx * 0.3,
      cy - ry * 1.05,
      cx + rx * 0.2,
      cy - ry * 0.95,
      cx + rx * 0.55,
      cy - ry * 0.85,
    )
    ..cubicTo(
      cx + rx * 0.95,
      cy - ry * 0.7,
      cx + rx * 1.05,
      cy - ry * 0.1,
      cx + rx * 0.95,
      cy + ry * 0.2,
    )
    ..cubicTo(
      cx + rx * 0.9,
      cy + ry * 0.75,
      cx + rx * 0.65,
      cy + ry * 1.0,
      cx + rx * 0.35,
      cy + ry * 0.95,
    )
    ..cubicTo(
      cx,
      cy + ry * 0.85,
      cx - rx * 0.3,
      cy + ry * 0.55,
      cx - rx * 0.55,
      cy + ry * 0.6,
    )
    ..cubicTo(
      cx - rx * 1.05,
      cy + ry * 0.7,
      cx - rx * 1.1,
      cy - ry * 0.2,
      cx - rx * 0.85,
      cy - ry * 0.55,
    )
    ..close();

  /// Torso with belly shading and coat pattern; [quad] uses the anatomical
  /// quadruped body instead of an oval.
  void torso(double cx, double cy, double rx, double ry, {bool quad = false}) {
    fluff(cx, cy, rx, ry, fur);
    final clip = quad ? bodyPath(cx, cy, rx, ry) : ovalPath(cx, cy, rx, ry);
    if (quad) {
      shape(clip, fur);
      // Haunch and shoulder masses, as soft lighter shapes.
      canvas
        ..save()
        ..clipPath(clip)
        ..drawOval(
          ui.Rect.fromCenter(
            center: ui.Offset(cx - rx * 0.62, cy - ry * 0.05),
            width: rx * 0.75,
            height: ry * 1.4,
          ),
          PaintKit.solid(
            PaintKit.tone(fur, 0.1).withValues(alpha: 0.35).toARGB32(),
          ),
        )
        ..drawOval(
          ui.Rect.fromCenter(
            center: ui.Offset(cx + rx * 0.55, cy - ry * 0.1),
            width: rx * 0.6,
            height: ry * 1.3,
          ),
          PaintKit.solid(
            PaintKit.tone(fur, 0.08).withValues(alpha: 0.3).toARGB32(),
          ),
        )
        ..restore();
    } else {
      oval(cx, cy, rx, ry, fur);
    }
    canvas
      ..save()
      ..clipPath(clip)
      ..drawOval(
        ui.Rect.fromCenter(
          center: ui.Offset(cx + rx * 0.1, cy + ry * 0.75),
          width: rx * 1.6,
          height: ry * 1.1,
        ),
        PaintKit.solid(PaintKit.toneArgb(light, 0)),
      )
      ..restore();
    final area = ui.Rect.fromCenter(
      center: ui.Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    );
    markings(clip, area);
    furTexture(clip, area, fur);
  }

  /// A neck joining chest and head, in the coat colour, with fur.
  void neck(List<(double, double)> pts) {
    final path = ui.Path()..moveTo(pts.first.$1, pts.first.$2);
    for (final (x, y) in pts.skip(1)) {
      path.lineTo(x, y);
    }
    path.close();
    shape(path, fur, edge: false);
    furTexture(path, path.getBounds(), fur);
  }

  /// A head oval with fur texture.
  void head(double cx, double cy, double rx, double ry) {
    oval(cx, cy, rx, ry, headColor);
    final r = ui.Rect.fromCenter(
      center: ui.Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    );
    furTexture(ovalPath(cx, cy, rx * 0.95, ry * 0.95), r, headColor);
  }

  void shadow(double rx) =>
      PaintKit.groundShadow(canvas, const ui.Offset(0, 0.5), rx, 2.6);

  int get headColor => pattern == CoatPattern.headColor ? mark : fur;

  // ---------------------------------------------------------------- family

  void cat() {
    shadow(13);
    // Tail: a long curve rising behind.
    final tail = ui.Path()
      ..moveTo(-10, -13)
      ..cubicTo(-17, -14, -19, -23, -15, -29)
      ..cubicTo(-14, -30, -12.5, -29, -13, -27.5)
      ..cubicTo(-16, -22, -14, -16, -9, -11)
      ..close();
    shape(tail, fur);
    leg(-7, -10, 3, fur, far: true, swing: 2.2);
    leg(6, -10, 3, fur, far: true, swing: 2.2);
    torso(-1, -12.5, 11, 6.8, quad: true);
    leg(-8, -10, 3.2, fur, swing: -2.2);
    leg(5, -10, 3.2, fur, swing: -2.2);
    // Head.
    final hx = 9.5;
    const hy = -19.0;
    for (final ex in [hx - 3.5, hx + 2]) {
      final ear = ui.Path()
        ..moveTo(ex - 2.4, hy - 3.5)
        ..lineTo(ex + 0.2, hy - 10.5)
        ..lineTo(ex + 2.6, hy - 3)
        ..close();
      shape(ear, headColor);
      canvas.drawPath(
        ui.Path()
          ..moveTo(ex - 1, hy - 4.2)
          ..lineTo(ex + 0.2, hy - 8.2)
          ..lineTo(ex + 1.4, hy - 4)
          ..close(),
        PaintKit.solid(_pink),
      );
    }
    neck(const [(4.0, -17.5), (7.0, -22.5), (11.0, -19.5), (8.5, -11.5)]);
    collar(hx - 4.5, hy + 4, 7, 0.5);
    fluff(hx, hy, 5.6, 5.2, headColor);
    head(hx, hy, 6, 5.4);
    oval(hx + 3.6, hy + 2.4, 3, 2.1, light, edge: false);
    nose(hx + 5.6, hy + 1.2, 0.9, _pink);
    eye(hx + 2.6, hy - 1.2, 1.25, iris: 0xFF8DB84A);
    final whisker = ui.Paint()
      ..color = const ui.Color(0x99FFFFFF)
      ..strokeWidth = 0.35;
    for (final dy in [-0.6, 0.6]) {
      canvas.drawLine(
        ui.Offset(hx + 5, hy + 2.4),
        ui.Offset(hx + 10, hy + 2.4 + dy * 2),
        whisker,
      );
    }
  }

  void dog() {
    shadow(14);
    final tail = ui.Path()
      ..moveTo(-11, -16)
      ..quadraticBezierTo(-17, -20, -15, -27)
      ..quadraticBezierTo(-13, -26, -13, -24)
      ..quadraticBezierTo(-14, -20, -10, -14)
      ..close();
    shape(tail, fur);
    leg(-7, -10, 3.6, fur, far: true, swing: 2.2);
    leg(6, -10, 3.6, fur, far: true, swing: 2.2);
    torso(-1, -13, 12, 7.8, quad: true);
    leg(-8, -10, 3.8, fur, swing: -2.2);
    leg(5.5, -10, 3.8, fur, swing: -2.2);
    const hx = 10.0;
    const hy = -20.5;
    neck(const [(4.5, -18.0), (7.5, -24.0), (12.0, -21.0), (9.5, -11.0)]);
    collar(hx - 4.5, hy + 5, 8, 0.45);
    fluff(hx, hy, 5.8, 5.4, headColor);
    head(hx, hy, 6.2, 5.6);
    // Muzzle and nose.
    oval(
      hx + 5,
      hy + 2,
      4.2,
      2.9,
      pattern == CoatPattern.tuxedo ? light : PaintKit.toneArgb(fur, 0.12),
    );
    nose(hx + 8.6, hy + 1.2, 1.2, 0xFF221A16);
    canvas.drawLine(
      const ui.Offset(hx + 6.5, hy + 3.6),
      const ui.Offset(hx + 8.2, hy + 3.4),
      ui.Paint()
        ..color = const ui.Color(0x88221A16)
        ..strokeWidth = 0.5,
    );
    eye(hx + 1.8, hy - 1.4, 1.2);
    // Floppy ear falling behind the eye.
    final ear = ui.Path()
      ..moveTo(hx - 2.5, hy - 4.5)
      ..quadraticBezierTo(hx - 6.5, hy - 3, hx - 5, hy + 3.5)
      ..quadraticBezierTo(hx - 3, hy + 3, hx - 0.5, hy - 3.5)
      ..close();
    shape(ear, PaintKit.toneArgb(headColor == fur ? mark : headColor, -0.05));
  }

  void rabbit() {
    shadow(12);
    oval(-10.5, -10, 2.4, 2.4, light, edge: false); // cotton tail
    leg(5, -8, 2.4, fur, far: true, swing: 1.5);
    torso(-2, -10, 9.5, 7.5);
    // Big hind leg.
    oval(-6, -5, 5.6, 4.2, fur);
    oval(-2.5, -1, 5, 1.6, PaintKit.toneArgb(fur, -0.1), edge: false);
    leg(4, -8, 2.6, fur, swing: -1.5);
    const hx = 7.5;
    const hy = -17.0;
    for (final (ex, tilt) in [(hx - 2.8, -0.28), (hx + 0.2, -0.12)]) {
      oval(ex, hy - 9, 2.1, 7.4, headColor, rotate: tilt);
      oval(ex + 0.2, hy - 9, 0.9, 5.4, _pink, rotate: tilt, edge: false);
    }
    collar(hx - 3.5, hy + 4.5, 6.5, 0.4);
    fluff(hx, hy, 5, 4.6, headColor);
    oval(hx, hy, 5.4, 4.9, headColor);
    oval(hx + 3.3, hy + 2, 2.6, 2, light, edge: false);
    nose(hx + 5, hy + 1, 0.8, _pink);
    eye(hx + 1.8, hy - 1, 1.5, iris: 0xFF2A1C14);
  }

  void bird() {
    shadow(9);
    // Thin legs with feet.
    for (final x in [-1.5, 2.0]) {
      leg(x, -6, 1.1, 0xFFB5895A, far: x < 0, swing: 1);
    }
    // Tail feathers.
    final tail = ui.Path()
      ..moveTo(-6, -10)
      ..lineTo(-15, -5)
      ..lineTo(-14, -2.5)
      ..lineTo(-5, -7)
      ..close();
    shape(tail, PaintKit.toneArgb(fur, -0.15));
    torso(0, -12, 7.4, 7.6);
    // Wing.
    final wing = ui.Path()
      ..moveTo(-5, -15)
      ..quadraticBezierTo(2, -17, 4, -11)
      ..quadraticBezierTo(-1, -6, -9, -7)
      ..close();
    shape(wing, PaintKit.toneArgb(fur, -0.12));
    const hx = 3.5;
    const hy = -21.5;
    if (pattern == CoatPattern.crest) {
      for (final (dx, h) in [(-2.0, 6.0), (-0.5, 7.5), (1.0, 6.0)]) {
        oval(hx + dx - 1, hy - 4 - h / 2, 1.1, h / 2, mark, rotate: -0.5);
      }
    }
    collar(hx - 2.5, hy + 5, 6, 0.2);
    oval(hx, hy, 5, 4.8, headColor);
    final beak = ui.Path()
      ..moveTo(hx + 4, hy - 1)
      ..lineTo(hx + 8.5, hy + 0.8)
      ..lineTo(hx + 4, hy + 2)
      ..close();
    shape(beak, _dark ? 0xFFF08A2C : _beak);
    if (pattern == CoatPattern.crest) {
      canvas.drawCircle(
        const ui.Offset(hx + 1.8, hy - 0.8),
        2,
        PaintKit.solid(PaintKit.toneArgb(mark, 0.1)),
      );
    }
    eye(hx + 1.8, hy - 0.8, 1.2, iris: 0xFF2A1C14);
  }

  void hamster() {
    shadow(12);
    for (final (x, far) in [
      (-5.0, true),
      (4.0, true),
      (-6.0, false),
      (3.0, false),
    ]) {
      oval(
        x,
        -1.2,
        2.2,
        1.4,
        far ? PaintKit.toneArgb(_pink, -0.2) : _pink,
        edge: false,
      );
    }
    torso(-1, -9, 11, 8.6);
    const hx = 6.5;
    const hy = -12.0;
    oval(hx - 3, hy - 6, 2, 1.8, fur);
    oval(hx - 3, hy - 6, 1, 0.9, _pink, edge: false);
    collar(hx - 4.5, hy + 3, 6, 0.3);
    oval(hx, hy, 6.2, 5.6, fur);
    oval(hx + 1.5, hy + 2.6, 3.6, 2.6, light, edge: false); // cheek pouch
    nose(hx + 6, hy + 0.6, 0.8, _pink);
    eye(hx + 2.4, hy - 1.6, 1.3, iris: 0xFF120C08);
  }

  void duck() {
    shadow(13);
    for (final x in [-2.0, 2.5]) {
      leg(x, -5, 1.6, 0xFFE8862C, far: x < 0, swing: 1.5, foot: 0xFFE8862C);
    }
    // Boat-shaped body with a raised tail.
    final body = ui.Path()
      ..moveTo(-13, -13)
      ..quadraticBezierTo(-10, -4, 0, -4.5)
      ..quadraticBezierTo(9, -5, 10, -11)
      ..quadraticBezierTo(4, -16, -6, -15)
      ..quadraticBezierTo(-10, -15, -13, -13)
      ..close();
    shape(body, fur);
    final wing = ui.Path()
      ..moveTo(-8, -13)
      ..quadraticBezierTo(0, -15, 5, -10)
      ..quadraticBezierTo(-2, -7, -9, -9)
      ..close();
    shape(wing, PaintKit.toneArgb(fur, -0.15));
    // Neck and head.
    final neck = ui.Path()
      ..moveTo(4, -12)
      ..quadraticBezierTo(5, -17, 7, -20)
      ..lineTo(10, -19)
      ..quadraticBezierTo(9, -15, 9, -11)
      ..close();
    shape(neck, headColor, edge: false);
    collar(6.5, -14.5, 5, 0.25);
    oval(9, -21.5, 4.5, 4.1, headColor);
    final bill = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(11.5, -21.5, 6, 2.4),
      const ui.Radius.circular(1.2),
    );
    canvas
      ..drawRRect(bill, PaintKit.lit(bill.outerRect, 0xFFEFA23A))
      ..drawRRect(bill, PaintKit.edge(0xFFEFA23A, 0.5));
    eye(10.5, -22.8, 1, iris: 0xFF1E140C);
  }

  void chicken() {
    shadow(11);
    for (final x in [-1.5, 2.5]) {
      leg(x, -7, 1.3, 0xFFE2B03A, far: x < 0, swing: 1.5);
    }
    final tailColor = pattern == CoatPattern.tail
        ? mark
        : PaintKit.toneArgb(fur, -0.15);
    for (final (dx, dy, rot) in [
      (-9.0, -19.0, -0.9),
      (-10.5, -16.0, -0.5),
      (-10.0, -13.0, -0.2),
    ]) {
      oval(dx, dy, 2, 5.8, tailColor, rotate: rot);
    }
    torso(-1, -13, 9.2, 8);
    final wing = ui.Path()
      ..moveTo(-6, -15)
      ..quadraticBezierTo(2, -17, 4, -11)
      ..quadraticBezierTo(-2, -7, -8, -10)
      ..close();
    shape(wing, PaintKit.toneArgb(fur, -0.1));
    const hx = 5.5;
    const hy = -23.0;
    final comb = _dark ? 0xFF3A2430 : 0xFFD7302C;
    for (final dx in [-2.0, 0.0, 2.0]) {
      oval(hx + dx, hy - 4.6, 1.4, 1.8, comb, edge: false);
    }
    collar(hx - 2.5, hy + 5.5, 6, 0.2);
    fluff(hx, hy, 4.2, 4.2, fur);
    oval(hx, hy, 4.6, 4.4, fur);
    oval(hx + 3.2, hy + 3.4, 1.2, 1.8, comb, edge: false); // wattle
    final beak = ui.Path()
      ..moveTo(hx + 3.6, hy - 0.6)
      ..lineTo(hx + 7.2, hy + 0.8)
      ..lineTo(hx + 3.6, hy + 1.8)
      ..close();
    shape(beak, 0xFFE2B03A);
    eye(hx + 1.6, hy - 0.8, 1.1, iris: 0xFFD9802C);
  }

  void turtle() {
    shadow(14);
    final skin = fur;
    final shell = pattern == CoatPattern.shell || pattern == CoatPattern.spotted
        ? mark
        : PaintKit.toneArgb(fur, -0.2);
    leg(-7, -5, 3.6, skin, far: true, swing: 1.2);
    leg(6, -5, 3.6, skin, far: true, swing: 1.2);
    // Head and neck reaching forward.
    final neck = ui.Path()
      ..moveTo(7, -8)
      ..quadraticBezierTo(11, -12, 14, -12)
      ..lineTo(15, -8)
      ..quadraticBezierTo(11, -6, 7, -5)
      ..close();
    shape(neck, skin);
    collar(9.5, -8.5, 5.5, 0.9);
    oval(16, -11, 4.2, 3.4, skin);
    eye(17.4, -12, 0.95, iris: 0xFF2A1C10);
    canvas.drawLine(
      const ui.Offset(18.5, -9.6),
      const ui.Offset(20, -10.2),
      ui.Paint()
        ..color = const ui.Color(0x88211A10)
        ..strokeWidth = 0.5,
    );
    oval(-12, -5, 2.2, 1.2, skin); // tail
    // Domed shell with scutes and a rim.
    final dome = ui.Path()
      ..moveTo(-13, -5)
      ..quadraticBezierTo(-12, -19, 0, -19.5)
      ..quadraticBezierTo(12, -19, 12, -5)
      ..close();
    shape(dome, shell, light: 0.35);
    final scute = PaintKit.edge(shell, 0.6);
    for (final (x, y) in const [
      (-6.0, -13.0),
      (0.0, -15.0),
      (6.0, -12.5),
      (-3.0, -8.0),
      (3.5, -8.0),
    ]) {
      canvas.drawCircle(ui.Offset(x, y), 3.2, scute);
    }
    if (pattern == CoatPattern.spotted) {
      for (final (x, y) in const [
        (-6.0, -13.0),
        (0.0, -15.0),
        (6.0, -12.5),
        (-3.0, -8.0),
        (3.5, -8.0),
      ]) {
        canvas.drawCircle(
          ui.Offset(x, y),
          1.4,
          PaintKit.solid(PaintKit.toneArgb(shell, -0.55)),
        );
      }
    }
    final rim = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(-14, -6.5, 27, 2.6),
      const ui.Radius.circular(1.3),
    );
    canvas.drawRRect(rim, PaintKit.lit(rim.outerRect, light));
    leg(-8, -5, 3.8, skin, swing: -1.2);
    leg(5, -5, 3.8, skin, swing: -1.2);
  }

  void goat() {
    shadow(13);
    oval(-12, -19, 1.6, 2.6, fur, rotate: -0.6); // short tail
    leg(-7, -12, 2.9, fur, far: true, swing: 2.2, foot: _hoof);
    leg(6, -12, 2.9, fur, far: true, swing: 2.2, foot: _hoof);
    torso(-1, -15.5, 11.5, 7.4, quad: true);
    leg(-8, -12, 3.1, fur, swing: -2.2, foot: _hoof);
    leg(5, -12, 3.1, fur, swing: -2.2, foot: _hoof);
    const hx = 11.0;
    const hy = -24.0;
    // Neck.
    final neck = ui.Path()
      ..moveTo(5, -21)
      ..lineTo(9, -27)
      ..lineTo(13, -25)
      ..lineTo(9, -17)
      ..close();
    shape(neck, headColor, edge: false);
    collar(8.5, -21.5, 6.5, 0.6);
    // Horns sweeping back.
    final horn = ui.Path()
      ..moveTo(hx - 1.5, hy - 3)
      ..quadraticBezierTo(hx - 5, hy - 9, hx - 9, hy - 6)
      ..quadraticBezierTo(hx - 5, hy - 7, hx + 0.5, hy - 2.5)
      ..close();
    shape(horn, 0xFF9C8C74);
    oval(hx, hy, 4.8, 3.8, headColor, rotate: 0.35);
    oval(
      hx + 4,
      hy + 2,
      2.4,
      1.8,
      PaintKit.toneArgb(headColor, 0.1),
      rotate: 0.35,
    );
    oval(hx - 2.5, hy + 0.5, 2.6, 1.1, headColor, rotate: 0.4); // ear
    // Beard.
    shape(
      ui.Path()
        ..moveTo(hx + 3, hy + 3)
        ..lineTo(hx + 2, hy + 7)
        ..lineTo(hx + 4.5, hy + 3.5)
        ..close(),
      light,
      edge: false,
    );
    eye(hx + 1.2, hy - 1, 1, iris: 0xFFC9A23A);
  }

  void monkey() {
    shadow(10);
    final face = light;
    // Curled tail.
    final tail = ui.Path()
      ..moveTo(-4, -8)
      ..cubicTo(-14, -6, -16, -20, -10, -22)
      ..cubicTo(-7, -23, -7, -19, -9, -19)
      ..cubicTo(-12, -18, -11, -10, -3, -10)
      ..close();
    shape(tail, fur);
    leg(-2.5, -8, 3, fur, far: true, swing: 1.5);
    torso(0, -13, 6.5, 8.5);
    leg(2.5, -8, 3.2, fur, swing: -1.5);
    // Arm.
    oval(4.5, -11, 1.8, 5.5, PaintKit.toneArgb(fur, -0.05), rotate: -0.3);
    const hx = 2.5;
    const hy = -25.0;
    collar(hx - 0.5, hy + 6, 7, 1.45);
    oval(hx - 5, hy, 2.4, 2.6, fur); // ear
    oval(hx - 5, hy, 1.2, 1.4, face, edge: false);
    fluff(hx, hy, 5.4, 5.6, fur);
    oval(hx, hy, 6, 6, fur);
    // Face mask.
    oval(hx + 2.2, hy + 0.8, 3.8, 4.2, face, edge: false);
    eye(hx + 2.6, hy - 1, 1.1, iris: 0xFF4A2E1A);
    nose(hx + 5, hy + 1.8, 0.7, PaintKit.toneArgb(face, -0.45));
  }

  void blob() {
    shadow(11);
    torso(0, -12, 11, 11);
    eye(5, -15, 1.4);
    collar(0, -2, 10, 1.57);
  }
}
