import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/maps.dart';
import '../../sim/terrain_mask.dart';

import '../art/paint_kit.dart';

enum _Kind { tuft, pebble, mushroom, shell, starfish, bones, rubble }

class _Decor {
  _Decor(this.x, this.y, this.kind, this.seed);
  final int x;
  final int y;
  final _Kind kind;
  final int seed;
}

/// Small non-colliding details along the ground surface, chosen by theme
/// and by what the ground is made of (tufts, toadstools and old bones by
/// the castle, shells and starfish on the beach, rubble in the ruins).
/// Each sits on a small contact shadow and takes the map's ambient light,
/// so it belongs to the painted ground. A piece disappears for good once
/// the ground under it is blown away. Purely visual.
class DecorComponent extends Component {
  DecorComponent({required this.mask, required this.map, this.materials})
    : super(priority: 3);

  final TerrainMask mask;
  final MapDef map;

  /// Per-pixel [TerrainMaterial] index, if the map encodes materials.
  final Uint8List? materials;
  final List<_Decor> _items = [];
  double _time = 0;

  @override
  Future<void> onLoad() async {
    final rng = math.Random(map.id.hashCode ^ 0x5eed);
    List<_Kind> kindsAt(int x, int y) {
      final i = materials?[y * mask.width + x];
      final m = i == null ? map.baseMaterial : TerrainMaterial.values[i];
      if (map.cap == CapStyle.snow) {
        return const [_Kind.pebble];
      }
      final natural = m == TerrainMaterial.soil || m == TerrainMaterial.rock;
      return switch (map.theme) {
        MapTheme.backyard when natural => const [
          _Kind.tuft,
          _Kind.tuft,
          _Kind.pebble,
          _Kind.mushroom,
        ],
        MapTheme.castle when natural => const [
          _Kind.tuft,
          _Kind.tuft,
          _Kind.mushroom,
          _Kind.pebble,
          _Kind.bones,
        ],
        MapTheme.wreck when m == TerrainMaterial.sand => const [
          _Kind.shell,
          _Kind.starfish,
          _Kind.pebble,
        ],
        MapTheme.wreck when natural => const [_Kind.tuft, _Kind.pebble],
        MapTheme.ruins when natural => const [
          _Kind.tuft,
          _Kind.rubble,
          _Kind.rubble,
          _Kind.pebble,
        ],
        _ => const [],
      };
    }

    for (var x = 4; x < mask.width - 4; x += 9 + rng.nextInt(26)) {
      // Every exposed top surface in this column (ground with air above).
      for (var y = 1; y < mask.height; y++) {
        if (mask.isSolid(x, y) &&
            !mask.isSolid(x, y - 1) &&
            !mask.isSolid(x, y - 4) &&
            y < map.waterLevel - 4 &&
            rng.nextDouble() < 0.75) {
          final kinds = kindsAt(x, y);
          final pick = rng.nextInt(1 << 20);
          if (kinds.isNotEmpty) {
            _items.add(_Decor(x, y, kinds[pick % kinds.length], pick >> 3));
          }
        }
      }
    }
  }

  @override
  void update(double dt) {
    _time += dt;
    // Drop decorations whose ground is gone.
    _items.removeWhere((d) => !mask.isSolid(d.x, d.y + 1));
  }

  late final ui.Paint _ambient = ui.Paint()
    ..colorFilter = ui.ColorFilter.mode(
      ui.Color(map.ambientArgb),
      ui.BlendMode.modulate,
    );
  final ui.Paint _contact = ui.Paint()..color = const ui.Color(0x55000000);

  @override
  void render(ui.Canvas canvas) {
    canvas.saveLayer(null, _ambient);
    for (final d in _items) {
      // Sunk a pixel into the ground, on a small contact shadow.
      final o = ui.Offset(d.x.toDouble(), d.y.toDouble() + 1.5);
      if (d.kind != _Kind.tuft) {
        canvas.drawOval(
          ui.Rect.fromCenter(
            center: o + const ui.Offset(0, -0.5),
            width: 9,
            height: 2.6,
          ),
          _contact,
        );
      }
      switch (d.kind) {
        case _Kind.tuft:
          _tuft(canvas, o, d.seed);
        case _Kind.pebble:
          _pebble(canvas, o, d.seed);
        case _Kind.mushroom:
          _mushroom(canvas, o, d.seed);
        case _Kind.shell:
          _shell(canvas, o, d.seed);
        case _Kind.starfish:
          _starfish(canvas, o, d.seed);
        case _Kind.bones:
          _bones(canvas, o, d.seed);
        case _Kind.rubble:
          _rubble(canvas, o, d.seed);
      }
    }
    canvas.restore();
  }

  late final ui.Paint _blade = ui.Paint()
    ..strokeWidth = 1.4
    ..strokeCap = ui.StrokeCap.round;

  void _tuft(ui.Canvas c, ui.Offset o, int seed) {
    final sway = math.sin(_time * 1.6 + o.dx / 40) * 0.8;
    for (var i = 0; i < 5; i++) {
      final dx = (i - 2) * 1.6;
      final h = 5.0 + (seed >> i) % 5;
      _blade.color = PaintKit.tone(map.grassArgb, (i.isEven ? -0.2 : 0.1));
      c.drawLine(
        o + ui.Offset(dx, 0),
        o + ui.Offset(dx * 1.6 + sway, -h),
        _blade,
      );
    }
  }

  void _pebble(ui.Canvas c, ui.Offset o, int seed) {
    final w = 4.0 + seed % 4;
    final rect = ui.Rect.fromCenter(
      center: o + const ui.Offset(0, -1.4),
      width: w,
      height: w * 0.6,
    );
    c.drawOval(rect, PaintKit.lit(rect, 0xFF9A938A, light: 0.35));
  }

  void _mushroom(ui.Canvas c, ui.Offset o, int seed) {
    final stem = ui.Rect.fromLTWH(o.dx - 1, o.dy - 5, 2, 5);
    c.drawRect(stem, ui.Paint()..color = const ui.Color(0xFFF2EAD8));
    final cap = ui.Rect.fromCenter(
      center: o + const ui.Offset(0, -5),
      width: 7,
      height: 4.5,
    );
    c.drawArc(
      cap,
      math.pi,
      math.pi,
      true,
      PaintKit.lit(cap, seed.isEven ? 0xFFC0392B : 0xFFB5895A),
    );
  }

  final ui.Paint _ink = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 0.9
    ..strokeJoin = ui.StrokeJoin.round
    ..color = const ui.Color(0xFF2A1A12);

  void _shell(ui.Canvas c, ui.Offset o, int seed) {
    final w = 5.0 + seed % 3;
    final fan = ui.Path()
      ..moveTo(o.dx - w / 2, o.dy - 0.5)
      ..quadraticBezierTo(o.dx, o.dy - w * 1.2, o.dx + w / 2, o.dy - 0.5)
      ..close();
    c
      ..drawPath(
        fan,
        ui.Paint()..color = ui.Color(seed.isEven ? 0xFFFFD8C8 : 0xFFFFF0D8),
      )
      ..drawPath(fan, _ink);
  }

  void _starfish(ui.Canvas c, ui.Offset o, int seed) {
    final star = ui.Path();
    final center = o + const ui.Offset(0, -2);
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5 + seed % 5 * 0.1;
      final r = i.isEven ? 4.2 : 1.8;
      final p = center + ui.Offset(math.cos(a) * r, math.sin(a) * r * 0.6);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    c
      ..drawPath(
        star,
        ui.Paint()..color = ui.Color(seed.isEven ? 0xFFFF7A4A : 0xFFFFA13A),
      )
      ..drawPath(star, _ink);
  }

  void _bones(ui.Canvas c, ui.Offset o, int seed) {
    final bone = ui.Paint()
      ..color = const ui.Color(0xFFE8E0C8)
      ..strokeWidth = 1.6
      ..strokeCap = ui.StrokeCap.round;
    final tilt = (seed % 5 - 2) * 0.3;
    final d = ui.Offset(math.cos(tilt) * 4, math.sin(tilt) * 4);
    final mid = o + const ui.Offset(0, -1.2);
    c.drawLine(mid - d, mid + d, bone);
    for (final end in [mid - d, mid + d]) {
      c
        ..drawCircle(end + const ui.Offset(0, -0.6), 1.1, bone)
        ..drawCircle(end + const ui.Offset(0, 0.6), 1.1, bone);
    }
  }

  void _rubble(ui.Canvas c, ui.Offset o, int seed) {
    const colors = [0xFF8A7E72, 0xFF9C5A44, 0xFF6E665E];
    for (var i = 0; i < 3; i++) {
      final w = 2.5 + (seed >> i) % 3;
      final r = ui.Rect.fromCenter(
        center: o + ui.Offset((i - 1) * 3.2, -w * 0.4 - (i == 1 ? 1 : 0)),
        width: w,
        height: w * 0.8,
      );
      c
        ..save()
        ..translate(r.center.dx, r.center.dy)
        ..rotate(((seed >> (i * 3)) % 7 - 3) * 0.2)
        ..drawRect(
          ui.Rect.fromCenter(
            center: ui.Offset.zero,
            width: r.width,
            height: r.height,
          ),
          ui.Paint()..color = ui.Color(colors[(seed + i) % colors.length]),
        )
        ..restore();
    }
  }
}
