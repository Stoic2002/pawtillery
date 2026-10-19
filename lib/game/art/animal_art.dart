import 'dart:math' as math;
import 'dart:ui' as ui;

import '../../config/breeds.dart';
import 'paint_kit.dart';

enum AnimalPose { idle, walkA, walkB, air }

/// Painted-cartoon animals (docs/art_style_guide.md "Sunny Brawl"): big
/// heads, big expressive eyes, chunky bodies, a dark outline around every
/// part, two-step cel shading (a shadow crescent at the bottom right and a
/// soft highlight at the top left), the breed's coat pattern, and a
/// bandana in the team colour.
///
/// Drawn facing right with the feet at (0, 0), at the size of a standard
/// unit (24 px hit circle). Callers flip and scale. Every (breed, team,
/// pose) is recorded once into a [ui.Picture] and replayed.
abstract final class AnimalArt {
  static final Map<(String?, String?, int, AnimalPose), ui.Picture> _cache =
      {};

  /// Visual height of a standard unit, for placing labels above it.
  static const double height = 37;

  static void draw(
    ui.Canvas canvas, {
    required String? familyId,
    required String? breedId,
    required int teamArgb,
    required AnimalPose pose,
  }) {
    final picture = _cache.putIfAbsent(
      (familyId, breedId, teamArgb, pose),
      () => _record(familyId, breedId, teamArgb, pose),
    );
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

  static const _ink = 0xFF2A1A12;
  static const _pink = 0xFFF29AA6;
  static const _hoof = 0xFF4A3A2E;
  static const _beak = 0xFFF5B43A;
  static const _line = 1.15;

  bool get _dark => PaintKit.c(fur).computeLuminance() < 0.08;
  int get headColor => pattern == CoatPattern.headColor ? mark : fur;

  final ui.Paint _outline = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = _line
    ..strokeJoin = ui.StrokeJoin.round
    ..strokeCap = ui.StrokeCap.round
    ..color = const ui.Color(_ink);

  ui.Paint ink(double width) => ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round
    ..color = const ui.Color(_ink);

  // ------------------------------------------------------------ primitives

  /// One painted part: flat base, optional [inside] details clipped to it,
  /// a shadow crescent where the part is turned away from the light
  /// (bottom right), a soft highlight (top left), and the outline.
  void part(
    ui.Path p,
    int argb, {
    bool line = true,
    double shade = 0.24,
    void Function()? inside,
  }) {
    final b = p.getBounds();
    canvas.drawPath(p, PaintKit.solid(argb));
    canvas
      ..save()
      ..clipPath(p);
    inside?.call();
    final lit = p.shift(ui.Offset(-b.width * 0.11, -b.height * 0.15));
    canvas
      ..drawPath(
        ui.Path.combine(ui.PathOperation.difference, p, lit),
        ui.Paint()..color = const ui.Color(0xFF2A1408).withValues(alpha: shade),
      )
      ..drawOval(
        ui.Rect.fromCenter(
          center: ui.Offset(
            b.left + b.width * 0.34,
            b.top + b.height * 0.27,
          ),
          width: b.width * 0.38,
          height: b.height * 0.24,
        ),
        ui.Paint()..color = const ui.Color(0x40FFFFFF),
      )
      ..restore();
    if (line) canvas.drawPath(p, _outline);
  }

  ui.Path ovalPath(double cx, double cy, double rx, double ry) =>
      ui.Path()..addOval(
        ui.Rect.fromCenter(
          center: ui.Offset(cx, cy),
          width: rx * 2,
          height: ry * 2,
        ),
      );

  void oval(
    double cx,
    double cy,
    double rx,
    double ry,
    int argb, {
    double rotate = 0,
    bool line = true,
    void Function()? inside,
  }) {
    if (rotate == 0) {
      part(ovalPath(cx, cy, rx, ry), argb, line: line, inside: inside);
      return;
    }
    canvas
      ..save()
      ..translate(cx, cy)
      ..rotate(rotate);
    part(ovalPath(0, 0, rx, ry), argb, line: line, inside: inside);
    canvas.restore();
  }

  /// Flat fill with no shading or outline (inner ears, muzzles' patches).
  void flat(ui.Path p, int argb) => canvas.drawPath(p, PaintKit.solid(argb));

  double get _swing => switch (pose) {
    AnimalPose.walkA => 1,
    AnimalPose.walkB => -1,
    _ => 0,
  };

  /// A stubby leg from the body down to the ground with a rounded foot,
  /// swinging with the pose. [far] legs are darker.
  void leg(
    double x,
    double top,
    double width,
    int argb, {
    bool far = false,
    double swing = 0,
    int? foot,
  }) {
    final dx = swing * _swing;
    final lift = pose == AnimalPose.air ? 3.0 : 0.0;
    final color = far ? PaintKit.toneArgb(argb, -0.3) : argb;
    final bottom = -lift - 1;
    final path = ui.Path()
      ..moveTo(x - width / 2, top)
      ..lineTo(x + width / 2, top)
      ..lineTo(x + dx + width * 0.42, bottom)
      ..lineTo(x + dx - width * 0.42, bottom)
      ..close();
    part(path, color);
    final paw = foot ?? PaintKit.toneArgb(argb, -0.05);
    oval(
      x + dx + width * 0.2,
      -lift - 1.1,
      width * 0.72,
      1.4,
      far ? PaintKit.toneArgb(paw, -0.3) : paw,
    );
  }

  /// A pair of cartoon eyes seen from the side: the far eye just in front
  /// and a little smaller, the near eye big; white, coloured iris, pupil
  /// and two highlights, looking forward.
  void eyes(double x, double y, double r, {int iris = 0xFF5A3A1E, bool pair = true}) {
    if (pair) _eye(x + r * 1.25, y - r * 0.05, r * 0.85, iris);
    _eye(x, y, r, iris);
  }

  void _eye(double x, double y, double r, int iris) {
    final white = ovalPath(x, y, r * 0.84, r);
    canvas
      ..drawPath(white, PaintKit.solid(0xFFFFFFFF))
      ..save()
      ..clipPath(white)
      ..drawCircle(
        ui.Offset(x + r * 0.26, y + r * 0.1),
        r * 0.62,
        PaintKit.solid(iris),
      )
      ..drawCircle(
        ui.Offset(x + r * 0.32, y + r * 0.12),
        r * 0.36,
        PaintKit.solid(_ink),
      )
      ..drawCircle(
        ui.Offset(x + r * 0.08, y - r * 0.22),
        r * 0.22,
        PaintKit.solid(0xFFFFFFFF),
      )
      ..drawCircle(
        ui.Offset(x + r * 0.5, y + r * 0.42),
        r * 0.1,
        PaintKit.solid(0xCCFFFFFF),
      )
      ..restore()
      ..drawPath(white, ink(0.9));
  }

  /// A determined brow over the near eye, low at the front.
  void brow(double x, double y, double r) => canvas.drawLine(
    ui.Offset(x - r * 0.7, y - r * 1.35),
    ui.Offset(x + r * 1.5, y - r * 1.0),
    ink(1.1),
  );

  /// A small smile under the muzzle.
  void smile(double x, double y, double w) => canvas.drawPath(
    ui.Path()
      ..moveTo(x - w / 2, y)
      ..quadraticBezierTo(x, y + w * 0.45, x + w / 2, y - w * 0.1),
    ink(0.8),
  );

  /// The team bandana: a band around the neck (rotated by [tilt]) knotted
  /// at the front, with the triangle hanging down.
  void bandana(double x, double y, double width, double tilt) {
    canvas
      ..save()
      ..translate(x, y)
      ..rotate(tilt);
    final tip = ui.Path()
      ..moveTo(width * 0.5 - 4.8, 0.6)
      ..lineTo(width * 0.5 + 0.6, 0.6)
      ..lineTo(width * 0.5 - 1.6, 6.8)
      ..close();
    part(tip, PaintKit.toneArgb(team, -0.1));
    part(
      ui.Path()..addRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromCenter(center: ui.Offset.zero, width: width, height: 3.6),
          const ui.Radius.circular(1.8),
        ),
      ),
      team,
    );
    // Polka dots: a team bandana reads at a glance.
    final dot = PaintKit.solid(0xCCFFFFFF);
    for (final dx in [-0.3, 0.05, 0.4]) {
      canvas.drawCircle(ui.Offset(width * dx, 0), 0.55, dot);
    }
    canvas.restore();
  }

  /// Fluffy rim for long-furred breeds: outlined bumps around a shape.
  void fluff(double cx, double cy, double rx, double ry, int argb) {
    if (!longFur) return;
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      oval(
        cx + math.cos(a) * rx,
        cy + math.sin(a) * ry,
        2.4,
        2.4,
        PaintKit.toneArgb(argb, -0.04),
      );
    }
  }

  /// Coat markings, drawn inside a part (already clipped to it).
  void markings(ui.Rect body) {
    final m = PaintKit.solid(mark);
    switch (pattern) {
      case CoatPattern.tabby:
        final stroke = ui.Paint()
          ..color = PaintKit.c(mark)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.7
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
          (0.2, 0.3, 1.6),
          (0.4, 0.2, 1.9),
          (0.58, 0.38, 1.5),
          (0.75, 0.25, 1.7),
          (0.32, 0.55, 1.4),
          (0.66, 0.6, 1.6),
          (0.5, 0.46, 1.2),
        ]) {
          canvas.drawCircle(
            ui.Offset(
              body.left + body.width * fx,
              body.top + body.height * fy,
            ),
            r,
            m,
          );
        }
      case CoatPattern.patches:
        canvas
          ..drawOval(
            ui.Rect.fromLTWH(
              body.left + body.width * 0.08,
              body.top - 1,
              body.width * 0.38,
              body.height * 0.62,
            ),
            m,
          )
          ..drawOval(
            ui.Rect.fromLTWH(
              body.left + body.width * 0.55,
              body.top + body.height * 0.1,
              body.width * 0.26,
              body.height * 0.45,
            ),
            m,
          );
      case CoatPattern.saddle:
        canvas.drawOval(
          ui.Rect.fromLTWH(
            body.left + body.width * 0.05,
            body.top - body.height * 0.25,
            body.width * 0.75,
            body.height * 0.72,
          ),
          m,
        );
      case CoatPattern.stripe:
        canvas.drawRect(
          ui.Rect.fromLTWH(body.left, body.top, body.width, body.height * 0.2),
          m,
        );
      default:
        break;
    }
  }

  /// Torso with a lighter belly and the coat pattern.
  void torso(double cx, double cy, double rx, double ry) {
    fluff(cx, cy, rx, ry, fur);
    final rect = ui.Rect.fromCenter(
      center: ui.Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    );
    oval(
      cx,
      cy,
      rx,
      ry,
      fur,
      inside: () {
        markings(rect);
        canvas.drawOval(
          ui.Rect.fromCenter(
            center: ui.Offset(cx + rx * 0.15, cy + ry * 0.85),
            width: rx * 1.5,
            height: ry * 1.1,
          ),
          PaintKit.solid(light),
        );
      },
    );
  }

  void shadow(double rx) =>
      PaintKit.groundShadow(canvas, const ui.Offset(0, 0.5), rx, 2.8);

  /// A pointy ear with a pink inside.
  void pointyEar(double bx, double by, double tipX, double tipY, double w, int argb) {
    final ear = ui.Path()
      ..moveTo(bx - w / 2, by)
      ..quadraticBezierTo(tipX - w * 0.3, tipY + 2, tipX, tipY)
      ..quadraticBezierTo(tipX + w * 0.25, tipY + 2.5, bx + w / 2, by)
      ..close();
    part(
      ear,
      argb,
      inside: () => flat(
        ui.Path()
          ..moveTo(bx - w * 0.25, by)
          ..lineTo(tipX, tipY + 2.6)
          ..lineTo(bx + w * 0.25, by)
          ..close(),
        _pink,
      ),
    );
  }

  // ---------------------------------------------------------------- family

  void cat() {
    shadow(12);
    final tail = ui.Path()
      ..moveTo(-9, -11)
      ..cubicTo(-16, -12, -18, -22, -14, -28)
      ..cubicTo(-12.5, -30, -10, -29, -11, -27)
      ..cubicTo(-14, -22, -13, -16, -7.5, -14)
      ..close();
    part(tail, pattern == CoatPattern.tabby ? mark : fur);
    leg(-6, -8, 3.4, fur, far: true, swing: 2.2);
    leg(4.5, -8, 3.4, fur, far: true, swing: 2.2);
    torso(-1.5, -10.5, 9.5, 6.3);
    leg(-7.5, -8, 3.6, fur, swing: -2.2);
    leg(3.5, -8, 3.6, fur, swing: -2.2);
    const hx = 8.0;
    const hy = -21.5;
    bandana(hx - 3.5, hy + 7.2, 9, 0.55);
    pointyEar(hx - 3.6, hy - 5, hx - 4.5, hy - 13.5, 6, headColor);
    pointyEar(hx + 2.4, hy - 5.8, hx + 3.8, hy - 13.8, 6, headColor);
    fluff(hx, hy, 7, 6.4, headColor);
    oval(
      hx,
      hy,
      7.8,
      7,
      headColor,
      inside: () => canvas.drawOval(
        ui.Rect.fromCenter(
          center: const ui.Offset(hx + 4.2, hy + 3.4),
          width: 7.2,
          height: 5,
        ),
        PaintKit.solid(light),
      ),
    );
    flat(
      ui.Path()
        ..moveTo(hx + 6.4, hy + 0.9)
        ..lineTo(hx + 8.3, hy + 0.9)
        ..lineTo(hx + 7.35, hy + 2.2)
        ..close(),
      _pink,
    );
    smile(hx + 6.4, hy + 3.4, 2.4);
    eyes(hx + 1.6, hy - 1.6, 2.3, iris: 0xFF8BC34A);
    brow(hx + 1.6, hy - 1.6, 2.3);
    final whisker = ink(0.35);
    for (final dy in [-0.8, 0.8]) {
      canvas.drawLine(
        const ui.Offset(hx + 7, hy + 2.6),
        ui.Offset(hx + 12, hy + 2.6 + dy * 2),
        whisker,
      );
    }
  }

  void dog() {
    shadow(13);
    final tail = ui.Path()
      ..moveTo(-10, -14)
      ..quadraticBezierTo(-17, -18, -15, -26)
      ..quadraticBezierTo(-12.5, -26, -12.5, -23)
      ..quadraticBezierTo(-13, -18, -8.5, -12)
      ..close();
    part(tail, fur);
    leg(-6.5, -8, 3.9, fur, far: true, swing: 2.2);
    leg(5, -8, 3.9, fur, far: true, swing: 2.2);
    torso(-1, -11, 10.5, 7);
    leg(-8, -8, 4.1, fur, swing: -2.2);
    leg(4, -8, 4.1, fur, swing: -2.2);
    const hx = 8.5;
    const hy = -21.0;
    bandana(hx - 3.8, hy + 7.4, 10, 0.5);
    fluff(hx, hy, 7, 6.6, headColor);
    oval(hx, hy, 7.6, 7, headColor);
    // Muzzle, nose, tongue.
    oval(
      hx + 5.6,
      hy + 2.6,
      4.8,
      3.4,
      pattern == CoatPattern.tuxedo ? light : PaintKit.toneArgb(fur, 0.14),
    );
    oval(hx + 10, hy + 0.6, 1.9, 1.5, 0xFF22160F);
    part(
      ui.Path()
        ..moveTo(hx + 6, hy + 4.6)
        ..quadraticBezierTo(hx + 6.4, hy + 8, hx + 8, hy + 7.4)
        ..quadraticBezierTo(hx + 8.8, hy + 6, hx + 8.2, hy + 4.6)
        ..close(),
      0xFFEF6F7E,
    );
    smile(hx + 7.6, hy + 4.4, 3.4);
    eyes(hx + 1.4, hy - 2.2, 2.2, iris: 0xFF7A4A22);
    brow(hx + 1.4, hy - 2.2, 2.2);
    // Floppy ear behind the eye.
    final ear = ui.Path()
      ..moveTo(hx - 3.5, hy - 5.5)
      ..quadraticBezierTo(hx - 9, hy - 3.5, hx - 6.5, hy + 4.5)
      ..quadraticBezierTo(hx - 3.6, hy + 4.2, hx - 1, hy - 4.5)
      ..close();
    part(ear, PaintKit.toneArgb(headColor == fur ? mark : headColor, -0.05));
  }

  void rabbit() {
    shadow(11);
    oval(-10, -9.5, 2.8, 2.8, light); // cotton tail
    leg(4.5, -6, 2.6, fur, far: true, swing: 1.5);
    torso(-2, -9, 8.6, 6.8);
    // Big hind leg.
    oval(-6, -4.6, 5.2, 4, fur);
    oval(-2.8, -1.2, 4.6, 1.5, PaintKit.toneArgb(fur, -0.08));
    leg(3.5, -6, 2.8, fur, swing: -1.5);
    const hx = 6.5;
    const hy = -18.0;
    for (final (ex, tilt) in [(hx - 3.2, -0.3), (hx + 0.6, -0.1)]) {
      oval(
        ex,
        hy - 10,
        2.6,
        8,
        headColor,
        rotate: tilt,
        inside: () =>
            canvas.drawOval(
              ui.Rect.fromCenter(
                center: const ui.Offset(0.3, 0),
                width: 2.2,
                height: 11,
              ),
              PaintKit.solid(_pink),
            ),
      );
    }
    bandana(hx - 3, hy + 6.4, 8, 0.45);
    fluff(hx, hy, 6, 5.6, headColor);
    oval(hx, hy, 6.8, 6.2, headColor);
    oval(hx + 4, hy + 2.6, 3, 2.3, light, line: false);
    oval(hx + 6.2, hy + 1.2, 1, 0.8, _pink, line: false);
    // Buck teeth.
    final teeth = ui.Rect.fromLTWH(hx + 4.4, hy + 3.8, 1.8, 2);
    canvas
      ..drawRect(teeth, PaintKit.solid(0xFFFFFFFF))
      ..drawRect(teeth, ink(0.6));
    eyes(hx + 1.2, hy - 1.4, 2.4, iris: 0xFF4A2E1C);
  }

  void bird() {
    shadow(9);
    for (final x in [-1.5, 2.0]) {
      leg(x, -5, 1.2, 0xFFD39B5A, far: x < 0, swing: 1, foot: 0xFFD39B5A);
    }
    final tail = ui.Path()
      ..moveTo(-5, -9)
      ..lineTo(-15, -4)
      ..lineTo(-13.5, -1.5)
      ..lineTo(-4, -6)
      ..close();
    part(tail, PaintKit.toneArgb(fur, -0.15));
    torso(0, -11, 7.4, 7.6);
    final wing = ui.Path()
      ..moveTo(-5, -14)
      ..quadraticBezierTo(2, -16.5, 4, -10)
      ..quadraticBezierTo(-1, -5.5, -9, -6.5)
      ..close();
    part(wing, PaintKit.toneArgb(fur, -0.12));
    const hx = 3.5;
    const hy = -22.0;
    if (pattern == CoatPattern.crest) {
      for (final (dx, h) in [(-2.5, 6.0), (-0.8, 8.0), (1.0, 6.5)]) {
        oval(hx + dx - 1, hy - 5 - h / 2, 1.3, h / 2, mark, rotate: -0.5);
      }
    }
    bandana(hx - 1.5, hy + 6.4, 7, 0.25);
    oval(
      hx,
      hy,
      6.2,
      5.8,
      headColor,
      inside: pattern == CoatPattern.crest
          ? () => canvas.drawCircle(
              const ui.Offset(hx + 2.4, hy - 0.5),
              3,
              PaintKit.solid(PaintKit.toneArgb(mark, 0.15)),
            )
          : null,
    );
    final beak = ui.Path()
      ..moveTo(hx + 4.8, hy - 1.6)
      ..quadraticBezierTo(hx + 10, hy - 0.5, hx + 10, hy + 1.6)
      ..lineTo(hx + 4.8, hy + 2.4)
      ..close();
    part(beak, _dark ? 0xFFF08A2C : _beak);
    eyes(hx + 1.2, hy - 1.2, 2.2, iris: 0xFF2A1C14, pair: false);
  }

  void hamster() {
    shadow(11);
    for (final (x, far) in [
      (-5.0, true),
      (4.0, true),
      (-6.0, false),
      (3.0, false),
    ]) {
      oval(x, -1.3, 2.3, 1.5, far ? PaintKit.toneArgb(_pink, -0.2) : _pink);
    }
    torso(-1.5, -8.5, 10, 7.8);
    const hx = 6.0;
    const hy = -13.5;
    oval(hx - 3.6, hy - 6.4, 2.4, 2.2, fur);
    oval(hx - 3.6, hy - 6.4, 1.2, 1.1, _pink, line: false);
    bandana(hx - 4.5, hy + 5.6, 7, 0.3);
    oval(hx, hy, 7.4, 6.6, fur);
    oval(hx + 2, hy + 2.8, 4, 3, light); // cheek pouch
    oval(hx + 7.2, hy + 0.4, 1, 0.8, _pink, line: false);
    smile(hx + 6, hy + 2.6, 2);
    eyes(hx + 2.2, hy - 1.8, 2.1, iris: 0xFF1E140E);
  }

  void duck() {
    shadow(12);
    for (final x in [-2.0, 2.5]) {
      leg(x, -4.5, 1.7, 0xFFF0912C, far: x < 0, swing: 1.5, foot: 0xFFF0912C);
    }
    final body = ui.Path()
      ..moveTo(-13, -12)
      ..quadraticBezierTo(-10, -3, 0, -3.5)
      ..quadraticBezierTo(9, -4, 10, -10)
      ..quadraticBezierTo(4, -15.5, -6, -14.5)
      ..quadraticBezierTo(-10, -14.5, -13, -12)
      ..close();
    part(body, fur);
    final wing = ui.Path()
      ..moveTo(-8, -12)
      ..quadraticBezierTo(0, -14.5, 5, -9)
      ..quadraticBezierTo(-2, -6, -9, -8)
      ..close();
    part(wing, PaintKit.toneArgb(fur, -0.15));
    final neck = ui.Path()
      ..moveTo(3.5, -11)
      ..quadraticBezierTo(4.5, -17, 6.5, -20)
      ..lineTo(10.5, -19)
      ..quadraticBezierTo(9.5, -15, 9.5, -10)
      ..close();
    part(neck, headColor);
    bandana(7, -14, 7.5, 0.2);
    oval(8.5, -23, 6, 5.6, headColor);
    final bill = ui.Path()
      ..addRRect(
        ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(12.4, -23.2, 7, 3.2),
          const ui.Radius.circular(1.6),
        ),
      );
    part(bill, 0xFFF5A43A);
    eyes(9.6, -24.6, 2, iris: 0xFF1E140C, pair: false);
  }

  void chicken() {
    shadow(10);
    for (final x in [-1.5, 2.5]) {
      leg(x, -6, 1.4, 0xFFE8B83C, far: x < 0, swing: 1.5, foot: 0xFFE8B83C);
    }
    final tailColor = pattern == CoatPattern.tail
        ? mark
        : PaintKit.toneArgb(fur, -0.15);
    for (final (dx, dy, rot) in [
      (-9.0, -19.0, -0.9),
      (-10.5, -16.0, -0.5),
      (-10.0, -13.0, -0.2),
    ]) {
      oval(dx, dy, 2.2, 6, tailColor, rotate: rot);
    }
    torso(-1, -12, 8.6, 7.6);
    final wing = ui.Path()
      ..moveTo(-6, -14)
      ..quadraticBezierTo(2, -16.5, 4, -10)
      ..quadraticBezierTo(-2, -6.5, -8, -9)
      ..close();
    part(wing, PaintKit.toneArgb(fur, -0.1));
    const hx = 5.0;
    const hy = -23.5;
    final comb = _dark ? 0xFF3A2430 : 0xFFE0352F;
    for (final (dx, r) in [(-2.4, 1.7), (0.0, 2.1), (2.4, 1.7)]) {
      oval(hx + dx, hy - 5.6, r, r * 1.2, comb);
    }
    bandana(hx - 1.5, hy + 6.6, 7, 0.25);
    fluff(hx, hy, 5, 5, fur);
    oval(hx, hy, 5.8, 5.6, fur);
    oval(hx + 4, hy + 4.2, 1.4, 2.1, comb); // wattle
    final beak = ui.Path()
      ..moveTo(hx + 4.6, hy - 0.8)
      ..lineTo(hx + 8.6, hy + 0.9)
      ..lineTo(hx + 4.6, hy + 2.2)
      ..close();
    part(beak, 0xFFF0B43A);
    eyes(hx + 1.4, hy - 1.2, 2, iris: 0xFFD9802C, pair: false);
  }

  void turtle() {
    shadow(13);
    final skin = fur;
    final shell = pattern == CoatPattern.shell || pattern == CoatPattern.spotted
        ? mark
        : PaintKit.toneArgb(fur, -0.2);
    leg(-7, -4, 3.8, skin, far: true, swing: 1.2);
    leg(6, -4, 3.8, skin, far: true, swing: 1.2);
    final neck = ui.Path()
      ..moveTo(7, -7)
      ..quadraticBezierTo(10.5, -12, 14, -13)
      ..lineTo(15.5, -8.5)
      ..quadraticBezierTo(11, -5.5, 7, -4)
      ..close();
    part(neck, skin);
    bandana(10.5, -8.5, 6.5, 0.9);
    oval(16, -13, 5.4, 4.6, skin);
    smile(19.2, -10.6, 2.4);
    eyes(16.6, -14.4, 1.9, iris: 0xFF2A1C10);
    oval(-12.5, -4.5, 2.4, 1.3, skin); // tail
    final dome = ui.Path()
      ..moveTo(-13.5, -4.5)
      ..quadraticBezierTo(-12.5, -20, 0, -20.5)
      ..quadraticBezierTo(12.5, -20, 12.5, -4.5)
      ..close();
    part(
      dome,
      shell,
      inside: () {
        final scute = ink(0.8)..color = PaintKit.tone(shell, -0.5);
        for (final (x, y) in const [
          (-6.0, -13.0),
          (0.0, -15.5),
          (6.0, -12.5),
          (-3.0, -7.5),
          (3.5, -7.5),
        ]) {
          canvas.drawCircle(ui.Offset(x, y), 3.3, scute);
          if (pattern == CoatPattern.spotted) {
            canvas.drawCircle(
              ui.Offset(x, y),
              1.4,
              PaintKit.solid(PaintKit.toneArgb(shell, -0.55)),
            );
          }
        }
      },
    );
    part(
      ui.Path()..addRRect(
        ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(-14.5, -6, 28, 2.8),
          const ui.Radius.circular(1.4),
        ),
      ),
      light,
    );
    leg(-8, -4.5, 4, skin, swing: -1.2);
    leg(5, -4.5, 4, skin, swing: -1.2);
  }

  void goat() {
    shadow(12);
    oval(-11.5, -17.5, 1.8, 2.8, fur, rotate: -0.6); // short tail
    leg(-6.5, -10, 3, fur, far: true, swing: 2.2, foot: _hoof);
    leg(5.5, -10, 3, fur, far: true, swing: 2.2, foot: _hoof);
    torso(-1, -13.5, 10.5, 6.8);
    leg(-7.5, -10, 3.2, fur, swing: -2.2, foot: _hoof);
    leg(4.5, -10, 3.2, fur, swing: -2.2, foot: _hoof);
    const hx = 10.5;
    const hy = -25.0;
    final neck = ui.Path()
      ..moveTo(4, -18)
      ..lineTo(7.5, -25)
      ..lineTo(12.5, -23)
      ..lineTo(9, -15)
      ..close();
    part(neck, headColor);
    bandana(7.5, -18.5, 8, 0.6);
    final horn = ui.Path()
      ..moveTo(hx - 2, hy - 4)
      ..quadraticBezierTo(hx - 6, hy - 11, hx - 11, hy - 7.5)
      ..quadraticBezierTo(hx - 6, hy - 8, hx + 0.5, hy - 3)
      ..close();
    part(horn, 0xFFB8A27E);
    oval(hx, hy, 6.4, 5.2, headColor, rotate: 0.3);
    oval(hx + 5, hy + 2.6, 3, 2.3, PaintKit.toneArgb(headColor, 0.12), rotate: 0.3);
    oval(hx - 3.6, hy + 0.2, 3.2, 1.4, headColor, rotate: 0.4); // ear
    part(
      ui.Path()
        ..moveTo(hx + 3.5, hy + 3.8)
        ..lineTo(hx + 2.6, hy + 8.6)
        ..lineTo(hx + 5.4, hy + 4.4)
        ..close(),
      light,
    );
    oval(hx + 7.4, hy + 1.6, 0.7, 0.6, _ink, line: false);
    eyes(hx + 1, hy - 1.4, 2, iris: 0xFFD9A93A);
    brow(hx + 1, hy - 1.4, 2);
  }

  void monkey() {
    shadow(10);
    final face = light;
    final tail = ui.Path()
      ..moveTo(-4, -7)
      ..cubicTo(-14, -5, -16, -19, -10, -21)
      ..cubicTo(-7, -22, -6.5, -18, -8.8, -18)
      ..cubicTo(-12, -17, -11, -9.5, -3, -9.5)
      ..close();
    part(tail, fur);
    leg(-2.5, -7, 3.2, fur, far: true, swing: 1.5);
    torso(0, -12, 6.6, 7.8);
    leg(2.5, -7, 3.4, fur, swing: -1.5);
    oval(5, -10.5, 2, 5.6, PaintKit.toneArgb(fur, -0.05), rotate: -0.3); // arm
    const hx = 2.5;
    const hy = -25.0;
    bandana(hx, hy + 7.6, 8, 0.15);
    oval(hx - 6.2, hy, 2.8, 3, fur); // ear
    oval(hx - 6.2, hy, 1.4, 1.6, face, line: false);
    fluff(hx, hy, 6.4, 6.6, fur);
    oval(
      hx,
      hy,
      7.4,
      7.4,
      fur,
      inside: () => canvas.drawOval(
        ui.Rect.fromCenter(
          center: const ui.Offset(hx + 2.8, hy + 1),
          width: 9.6,
          height: 10.4,
        ),
        PaintKit.solid(face),
      ),
    );
    oval(hx + 6, hy + 2.6, 0.8, 0.6, PaintKit.toneArgb(face, -0.5), line: false);
    smile(hx + 5, hy + 4.4, 3);
    eyes(hx + 1.4, hy - 1.4, 2.2, iris: 0xFF5A3A1E);
    brow(hx + 1.4, hy - 1.4, 2.2);
  }

  void blob() {
    shadow(11);
    torso(0, -12, 11, 11);
    eyes(4, -15, 2.4);
    bandana(0, -3, 12, 0);
  }
}
