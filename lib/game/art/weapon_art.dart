import 'dart:math' as math;
import 'dart:ui' as ui;

import 'animal_art.dart';
import 'paint_kit.dart';
import 'sprites.dart';

/// A projectile drawn from a painted sprite: its longest side in px, the
/// turn (degrees clockwise) that points its nose right (+x) — for the
/// firecracker, its fuse up — and how far it sits back along -x so its
/// heavy end (a meteor's rock, not its tail) is at the origin.
class _Painted {
  const _Painted(this.sprite, this.size, {this.turn = 0, this.back = 0});
  final String sprite;
  final double size;
  final double turn;
  final double back;
}

/// Weapon art: the projectiles in flight, aircraft, mines on the ground,
/// and the icons in the weapon menu, from the painted sprites ([Sprites])
/// where there is one, else procedural and softly shaded. Everything is
/// drawn centred on the origin; callers rotate and place it. Static
/// shapes are recorded once into pictures.
abstract final class WeaponArt {
  // Sizes are in proportion to a pet (about 44 px high): a stone fits in its
  // paw, a missile is as long as it is tall. What points along its flight
  // sits back so that its nose is where the sim says it is, and so where it
  // goes off.
  static const Map<String, _Painted> _painted = {
    'rock': _Painted('icon_rock', 16),
    'twinSling': _Painted('icon_rock', 10),
    'grenade': _Painted('icon_grenade', 20),
    'cluster': _Painted('icon_cluster', 26),
    'clusterBomblet': _Painted('obj_bomblet', 13),
    'hairball': _Painted('icon_hairball', 20),
    'hairballBomb': _Painted('obj_hairballBomb', 14),
    'boneBoomerang': _Painted('icon_boneBoomerang', 30),
    'drillCarrot': _Painted('icon_drillCarrot', 34, turn: -8, back: 12),
    'egg': _Painted('craft_egg', 16),
    'seedMines': _Painted('obj_seedMine', 14),
    'coconut': _Painted('icon_coconut', 22),
    'bottleRocket': _Painted('icon_bottleRocket', 38, turn: 30, back: 14),
    'snifferRocket': _Painted('icon_snifferRocket', 38, turn: 28, back: 14),
    'firecracker': _Painted('icon_firecracker', 26, turn: -44),
    'flowerpot': _Painted('craft_flowerpot', 26),
    'missile': _Painted('craft_missile', 52, back: 22),
    'blackHole': _Painted('icon_blackHole', 28),
    'stickyBomb': _Painted('icon_stickyBomb', 22),
    'clay': _Painted('icon_clay', 20),
    'bomberBomb': _Painted('craft_bomb', 38, turn: -90, back: 15),
    'meteor': _Painted('craft_meteor', 78, turn: -40, back: 17),
    'napalm': _Painted('icon_napalm', 26),
    'poisonGas': _Painted('obj_gas', 22),
    'gasBomb': _Painted('obj_gas', 28, turn: -90, back: 8),
    'miniNuke': _Painted('icon_miniNuke', 46, back: 18),
    'iceBomb': _Painted('icon_iceBomb', 22),
  };

  static final Map<String, ui.Picture> _cache = {};

  static ui.Picture _cached(String key, void Function(ui.Canvas) draw) =>
      _cache.putIfAbsent(key, () {
        final recorder = ui.PictureRecorder();
        draw(ui.Canvas(recorder));
        return recorder.endRecording();
      });

  /// A projectile of weapon [id] in flight, about 8–14 px across.
  static void projectile(ui.Canvas canvas, String id) {
    final painted = _painted[id];
    final sprite = painted == null ? null : Sprites.of(painted.sprite);
    if (painted != null && sprite != null) {
      Sprites.draw(
        canvas,
        sprite,
        painted.size,
        turnDeg: painted.turn,
        center: ui.Offset(-painted.back, 0),
      );
      return;
    }
    canvas.drawPicture(_cached('p:$id', (c) => _projectile(c, id)));
  }

  /// The bomber plane (Pesawat Pengebom), much bigger than a pet, centred on the
  /// origin and flying right; mirrored when [facingLeft].
  static void bomberPlane(ui.Canvas canvas, {required bool facingLeft}) {
    canvas.save();
    if (facingLeft) canvas.scale(-1, 1);
    if (Sprites.of('craft_plane') case final sprite?) {
      Sprites.draw(canvas, sprite, 240);
    } else {
      canvas.drawPicture(_cached('plane', _plane));
    }
    canvas.restore();
  }

  /// A fighter jet, about [jetLength] px long, centred on the origin and flying
  /// right; mirrored when [facingLeft].
  static void fighterJet(ui.Canvas canvas, {required bool facingLeft}) {
    canvas.save();
    if (facingLeft) canvas.scale(-1, 1);
    if (Sprites.of('craft_jet') case final sprite?) {
      Sprites.draw(canvas, sprite, jetLength);
    } else {
      canvas.drawPicture(_cached('jet', _jet));
    }
    canvas.restore();
  }

  /// The satellite in orbit (no beam), big enough to read from far off, centred, its
  /// dish at (0, 9).
  static void satellite(ui.Canvas canvas) {
    if (Sprites.of('craft_satellite') case final sprite?) {
      Sprites.draw(canvas, sprite, 190, center: const ui.Offset(-6, -33));
      return;
    }
    canvas
      ..save()
      ..scale(3.2);
    canvas.drawPicture(_cached('satellite', _satelliteBody));
    canvas.restore();
  }

  /// A dark storm cloud, far wider than a pet, centred on the origin.
  static void stormCloud(ui.Canvas canvas) {
    if (Sprites.of('craft_cloud') case final sprite?) {
      Sprites.draw(canvas, sprite, 300);
    } else {
      canvas.drawPicture(_cached('storm', _storm));
    }
  }

  /// A three-pronged grappling hook about 16 px long, its points facing
  /// right (+x), the rope tied on at the origin.
  static void grappleHook(ui.Canvas canvas) =>
      canvas.drawPicture(_cached('hook', _hook));

  /// A mine lying on the ground (origin = resting point).
  static void mine(ui.Canvas canvas, {required bool small}) {
    if (Sprites.of(small ? 'obj_seedMine' : 'obj_mine') case final sprite?) {
      final longest = small ? 16.0 : 28.0;
      final size = Sprites.sizeOf(sprite, longest);
      Sprites.draw(
        canvas,
        sprite,
        longest,
        center: ui.Offset(0, -size.height / 2 + 1),
      );
      return;
    }
    canvas.drawPicture(_cached('mine:$small', (c) {
      c.scale(small ? 0.7 : 1);
      _mine(c);
    }));
  }

  /// Menu icon for weapon [id], fitting a [size]-px box centred on the
  /// origin.
  static void icon(ui.Canvas canvas, String id, double size) {
    if (Sprites.of('icon_$id') case final sprite?) {
      Sprites.draw(canvas, sprite, size);
      return;
    }
    canvas
      ..save()
      ..scale(size / 32);
    canvas.drawPicture(_cached('i:$id', (c) => _icon(c, id)));
    canvas.restore();
  }

  // -------------------------------------------------------------- shapes

  static void _projectile(ui.Canvas c, String id) {
    switch (id) {
      case 'rock':
        _rock(c, 6, 0xFF8E8A84);
      case 'twinSling':
        _rock(c, 3.6, 0xFF7C756C);
      case 'grenade':
        _grenade(c);
      case 'cluster':
        _bomb(c, 6.5);
      case 'clusterBomblet':
        _bomb(c, 3.6);
      case 'hairball':
        _hairball(c, 6.5);
      case 'hairballBomb':
        _hairball(c, 4);
      case 'boneBoomerang':
        _bone(c);
      case 'drillCarrot':
        _carrot(c);
      case 'egg':
        _egg(c, 1);
      case 'seedMines':
        _seed(c, 1.2);
      case 'coconut':
        _coconut(c);
      case 'bottleRocket':
        _rocket(c, 0xFF5AA9E6, 0xFFE5484D);
      case 'snifferRocket':
        _sniffer(c);
      case 'seedSpitter':
        _seed(c, 0.55);
      case 'firecracker':
        _firecracker(c, 1);
      case 'flowerpot':
        _flowerpot(c, 1);
      case 'missile':
        _missile(c);
      case 'blackHole':
        _voidOrb(c);
      case 'stickyBomb':
        _sticky(c);
      case 'clay':
        _clayLump(c);
      case 'bomberBomb':
        _aerialBomb(c);
      case 'meteor':
        _meteorRock(c, 9);
      case 'napalm':
        _napalmCan(c);
      case 'poisonGas' || 'gasBomb':
        _gasCan(c);
      case 'miniNuke':
        _nukeBomb(c);
      case 'iceBomb':
        _iceBall(c);
      default:
        _rock(c, 5, 0xFF9E9A94);
    }
  }

  /// Weapons drawn pointing along their flight (the renderer rotates them
  /// to the velocity instead of tumbling them), with a motor flame.
  static bool pointsAlongFlight(String id) =>
      hasMotor(id) ||
      id == 'bomberBomb' ||
      id == 'gasBomb' ||
      // Painted with a tail or a nose.
      ((id == 'meteor' || id == 'miniNuke') &&
          Sprites.of(_painted[id]!.sprite) != null);

  /// Where a rocket's motor flame starts, along its length; -x is behind.
  static double motorX(String id) {
    final painted = _painted[id];
    if (painted == null || Sprites.of(painted.sprite) == null) return -8;
    return -painted.size / 2 - painted.back + 3;
  }

  /// Painted fighter jet's length, px.
  static const double jetLength = 190;

  /// Rockets: drawn with a motor flame behind them.
  static bool hasMotor(String id) =>
      id == 'bottleRocket' || id == 'snifferRocket' || id == 'missile';

  /// The guided missile, about 22 px long pointing right: a light grey
  /// body with a dark nose, a black band, canards and four tail fins.
  static void _missile(ui.Canvas c) {
    const body = 0xFFC9CDD0;
    const dark = 0xFF3D4246;
    for (final s in [-1.0, 1.0]) {
      final fin = ui.Path()
        ..moveTo(-5, s * 2.4)
        ..lineTo(-10.5, s * 6.5)
        ..lineTo(-10.5, s * 2.2)
        ..close();
      _shaded(c, fin, dark);
      final canard = ui.Path()
        ..moveTo(3, s * 2.4)
        ..lineTo(1, s * 4.6)
        ..lineTo(-0.5, s * 2.4)
        ..close();
      _shaded(c, canard, dark);
    }
    final hull = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-10, -2.6, 16, 5.2), const ui.Radius.circular(1.6));
    c
      ..drawRRect(hull, PaintKit.lit(hull.outerRect, body, light: 0.5))
      ..drawRRect(hull, PaintKit.edge(body, 0.7))
      ..drawRect(const ui.Rect.fromLTWH(-6.5, -2.6, 1.8, 5.2),
          PaintKit.solid(0xFF2B2118));
    final nose = ui.Path()
      ..moveTo(6, -2.6)
      ..quadraticBezierTo(11.5, -1.4, 12, 0)
      ..quadraticBezierTo(11.5, 1.4, 6, 2.6)
      ..close();
    _shaded(c, nose, dark, light: 0.4);
    c.drawLine(const ui.Offset(-9, -1.4), const ui.Offset(5, -1.4),
        PaintKit.solid(0x77FFFFFF)..strokeWidth = 0.8);
  }

  /// An olive aerial bomb pointing right (nose first), about 16 px.
  static void _aerialBomb(ui.Canvas c) {
    const olive = 0xFF56643F;
    for (final s in [-1.0, 1.0]) {
      final fin = ui.Path()
        ..moveTo(-4, s * 1.5)
        ..lineTo(-8.5, s * 4.8)
        ..lineTo(-8.5, s * 1)
        ..close();
      _shaded(c, fin, 0xFF3E4A2C);
    }
    final hull = ui.Path()
      ..moveTo(-5, -1.8)
      ..quadraticBezierTo(1, -4.4, 6, -2.6)
      ..quadraticBezierTo(9, -1.2, 9, 0)
      ..quadraticBezierTo(9, 1.2, 6, 2.6)
      ..quadraticBezierTo(1, 4.4, -5, 1.8)
      ..close();
    _shaded(c, hull, olive, light: 0.4);
    c
      ..drawRect(const ui.Rect.fromLTWH(1.5, -3.6, 1.2, 7.2),
          PaintKit.solid(0xFFF5B700))
      ..drawLine(const ui.Offset(-3.5, -1.6), const ui.Offset(4.5, -2.3),
          PaintKit.solid(0x55FFFFFF)..strokeWidth = 0.8);
  }

  /// Side view of a twin-engine bomber flying right: an olive fuselage with
  /// a glazed nose, a tail fin, a wing with two engines and spinning
  /// propeller discs, and a roundel.
  static void _plane(ui.Canvas c) {
    const hullArgb = 0xFF6B7657;
    const darkArgb = 0xFF4A5340;
    // Far wing, darker, behind the fuselage; then the tail fin.
    final farWing = ui.Path()
      ..moveTo(-4, -4)
      ..lineTo(14, -4)
      ..lineTo(2, -15)
      ..lineTo(-8, -15)
      ..close();
    _shaded(c, farWing, darkArgb);
    final tailFin = ui.Path()
      ..moveTo(-34, -3)
      ..lineTo(-44, -20)
      ..lineTo(-36, -20)
      ..lineTo(-24, -4)
      ..close();
    _shaded(c, tailFin, hullArgb, light: 0.4);
    final hull = ui.Path()
      ..moveTo(-46, -3)
      ..quadraticBezierTo(-40, -8, -20, -8)
      ..lineTo(30, -8)
      ..quadraticBezierTo(46, -7, 48, 0)
      ..quadraticBezierTo(46, 6, 30, 7)
      ..lineTo(-20, 6)
      ..quadraticBezierTo(-40, 5, -46, 1)
      ..close();
    _shaded(c, hull, hullArgb, light: 0.45);
    // Glazed nose and cockpit.
    final glass = ui.Path()
      ..moveTo(36, -7.2)
      ..quadraticBezierTo(46, -6, 47.5, 0)
      ..lineTo(38, 0)
      ..close();
    c
      ..drawPath(glass, PaintKit.solid(0xCC9FD4E8))
      ..drawPath(glass, PaintKit.edge(0xFF9FD4E8, 0.6))
      ..drawRRect(
          ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(22, -11, 10, 4),
              const ui.Radius.circular(2)),
          PaintKit.solid(0xCC9FD4E8));
    // Near tailplane.
    final tailplane = ui.Path()
      ..moveTo(-30, 0)
      ..lineTo(-46, 4)
      ..lineTo(-40, 6)
      ..lineTo(-24, 3)
      ..close();
    _shaded(c, tailplane, darkArgb);
    // Near wing with two engines.
    final wing = ui.Path()
      ..moveTo(-6, 1)
      ..lineTo(18, 1)
      ..lineTo(4, 13)
      ..lineTo(-12, 13)
      ..close();
    _shaded(c, wing, hullArgb, light: 0.35);
    for (final ex in [-2.0, 12.0]) {
      final nacelle = ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(ex - 4, -1, 12, 6), const ui.Radius.circular(3));
      c
        ..drawRRect(
            nacelle, PaintKit.lit(nacelle.outerRect, darkArgb, light: 0.4))
        ..drawRRect(nacelle, PaintKit.edge(darkArgb, 0.6))
        ..drawOval(
            ui.Rect.fromCenter(
                center: ui.Offset(ex + 9, 2), width: 3, height: 15),
            PaintKit.solid(0x553D4246))
        ..drawCircle(ui.Offset(ex + 8.6, 2), 1.4, PaintKit.solid(0xFF2B2118));
    }
    // Roundel and a panel line.
    c
      ..drawCircle(const ui.Offset(-14, -1), 4.2, PaintKit.solid(0xFFF6F2E8))
      ..drawCircle(const ui.Offset(-14, -1), 4.2, PaintKit.edge(0xFF2B2118, 0.5))
      ..drawCircle(const ui.Offset(-14, -1), 2.2, PaintKit.solid(0xFFC0392B))
      ..drawLine(const ui.Offset(-40, -1), const ui.Offset(34, -1),
          PaintKit.solid(0x33000000)..strokeWidth = 0.6);
  }

  /// A satellite firing its beam down (the menu icon).
  static void _satellite(ui.Canvas c) {
    c
      ..drawRect(const ui.Rect.fromLTWH(-1.8, 2, 3.6, 14),
          PaintKit.solid(0x887FD3FF))
      ..drawRect(const ui.Rect.fromLTWH(-0.8, 2, 1.6, 14),
          PaintKit.solid(0xFFF4FBFF));
    _satelliteBody(c);
  }

  /// A gold body between two blue solar panels, with a dish underneath.
  static void _satelliteBody(ui.Canvas c) {
    for (final s in [-1.0, 1.0]) {
      final panel = ui.Rect.fromLTWH(s < 0 ? -15 : 5, -7, 10, 7);
      c
        ..drawRect(panel, PaintKit.lit(panel, 0xFF2F5FA8, light: 0.4))
        ..drawRect(panel, PaintKit.edge(0xFF1E3A66, 0.6))
        ..drawLine(ui.Offset(panel.center.dx, panel.top),
            ui.Offset(panel.center.dx, panel.bottom),
            PaintKit.solid(0x66FFFFFF)..strokeWidth = 0.6)
        ..drawLine(ui.Offset(s * 5, -3.5), ui.Offset(s * 3, -3.5),
            PaintKit.solid(0xFF6B7280)..strokeWidth = 1.2);
    }
    final body = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-3.5, -9, 7, 11), const ui.Radius.circular(1.2));
    c
      ..drawRRect(body, PaintKit.lit(body.outerRect, 0xFFD4A62A, light: 0.45))
      ..drawRRect(body, PaintKit.edge(0xFFD4A62A, 0.6))
      ..drawCircle(const ui.Offset(0, 2.6), 2.2, PaintKit.solid(0xFFB8BEC4))
      ..drawCircle(
          const ui.Offset(0, 2.6), 2.2, PaintKit.edge(0xFF6B7280, 0.5));
  }

  /// Side view of a fighter jet flying right: a grey fuselage with a sharp
  /// nose and a tinted canopy, a swept wing, an intake, a tall tail fin and
  /// the exhaust nozzle at the back.
  static void _jet(ui.Canvas c) {
    const hullArgb = 0xFF8C959C;
    const darkArgb = 0xFF5C656C;
    final farWing = ui.Path()
      ..moveTo(-6, -3)
      ..lineTo(10, -3)
      ..lineTo(-14, -14)
      ..lineTo(-20, -14)
      ..close();
    _shaded(c, farWing, darkArgb);
    final fin = ui.Path()
      ..moveTo(-26, -4)
      ..lineTo(-38, -22)
      ..lineTo(-31, -22)
      ..lineTo(-16, -5)
      ..close();
    _shaded(c, fin, hullArgb, light: 0.4);
    final hull = ui.Path()
      ..moveTo(-40, -4)
      ..lineTo(-12, -6)
      ..quadraticBezierTo(18, -7, 30, -3.5)
      ..lineTo(44, 0)
      ..lineTo(30, 3)
      ..quadraticBezierTo(10, 5, -12, 5)
      ..lineTo(-40, 4)
      ..close();
    _shaded(c, hull, hullArgb, light: 0.5);
    // Canopy.
    final canopy = ui.Path()
      ..moveTo(8, -6)
      ..quadraticBezierTo(18, -12, 28, -4)
      ..close();
    c
      ..drawPath(canopy, PaintKit.solid(0xEE4B6E8A))
      ..drawPath(canopy, PaintKit.edge(0xFF2B3A48, 0.6))
      ..drawLine(const ui.Offset(14, -8.6), const ui.Offset(22, -7.2),
          PaintKit.solid(0x88FFFFFF)..strokeWidth = 0.9);
    // Intake and nozzle.
    c
      ..drawRRect(
          ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(-6, -1, 10, 5),
              const ui.Radius.circular(1.5)),
          PaintKit.solid(0xFF3A4046))
      ..drawRect(const ui.Rect.fromLTWH(-43, -3.5, 4, 7),
          PaintKit.solid(0xFF3A4046));
    final wing = ui.Path()
      ..moveTo(-8, 2)
      ..lineTo(12, 2)
      ..lineTo(-16, 12)
      ..lineTo(-24, 12)
      ..close();
    _shaded(c, wing, hullArgb, light: 0.35);
    final tailplane = ui.Path()
      ..moveTo(-28, 1)
      ..lineTo(-42, 7)
      ..lineTo(-36, 7)
      ..lineTo(-22, 2)
      ..close();
    _shaded(c, tailplane, darkArgb);
    c
      ..drawLine(const ui.Offset(-36, 0), const ui.Offset(30, 0),
          PaintKit.solid(0x33000000)..strokeWidth = 0.6)
      ..drawCircle(const ui.Offset(-28, -1), 2.6, PaintKit.solid(0xFFF6F2E8))
      ..drawCircle(const ui.Offset(-28, -1), 1.3, PaintKit.solid(0xFFC0392B));
  }

  /// A dark, heavy storm cloud: overlapping puffs with a lighter top and a
  /// flat dark underside.
  static void _storm(ui.Canvas c) {
    final puffs = ui.Path()
      ..addOval(ui.Rect.fromCircle(center: const ui.Offset(-46, 6), radius: 24))
      ..addOval(ui.Rect.fromCircle(center: const ui.Offset(-18, -10), radius: 32))
      ..addOval(ui.Rect.fromCircle(center: const ui.Offset(18, -14), radius: 34))
      ..addOval(ui.Rect.fromCircle(center: const ui.Offset(50, 4), radius: 26))
      ..addRRect(ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTRB(-66, 0, 72, 26), const ui.Radius.circular(13)));
    final cloud = ui.Path.combine(ui.PathOperation.union, puffs, ui.Path());
    final bounds = cloud.getBounds();
    c
      ..drawPath(cloud, PaintKit.vertical(bounds, 0xFF4A505C))
      ..drawPath(cloud, PaintKit.edge(0xFF2E323A, 1.4))
      ..drawOval(const ui.Rect.fromLTWH(-30, -36, 50, 20),
          PaintKit.solid(0x22FFFFFF))
      ..drawRRect(
          ui.RRect.fromRectAndRadius(const ui.Rect.fromLTRB(-60, 14, 66, 26),
              const ui.Radius.circular(8)),
          PaintKit.solid(0x552E323A));
  }


  /// A small dark orb with a violet glow ring (black hole in flight).
  static void _voidOrb(ui.Canvas c) {
    c
      ..drawCircle(ui.Offset.zero, 9, PaintKit.solid(0x553B2A5C))
      ..drawCircle(ui.Offset.zero, 6.5, PaintKit.solid(0xFF140C22))
      ..drawCircle(
          ui.Offset.zero,
          6.5,
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = const ui.Color(0xFFB98CFF))
      ..drawCircle(const ui.Offset(-2, -2.2), 1.2, PaintKit.solid(0x88E6D6FF));
  }

  /// A round bomb covered in green goo, with drips and a red light.
  static void _sticky(ui.Canvas c) {
    _ball(c, 6, 0xFF3A3F45, light: 0.4);
    final goo = ui.Path()
      ..moveTo(-6, -1)
      ..quadraticBezierTo(-6, -7, 0, -7)
      ..quadraticBezierTo(6, -7, 6, -1)
      ..quadraticBezierTo(4.5, 1, 3.5, -0.5)
      ..quadraticBezierTo(2.5, 3.5, 1, 0)
      ..quadraticBezierTo(-1, 2, -2.5, -0.5)
      ..quadraticBezierTo(-4.5, 2.5, -6, -1)
      ..close();
    c
      ..drawPath(goo, PaintKit.lit(goo.getBounds(), 0xFF6CBF3A, light: 0.45))
      ..drawPath(goo, PaintKit.edge(0xFF6CBF3A, 0.6))
      ..drawCircle(const ui.Offset(0, 3), 1.6, PaintKit.solid(0xFFE5484D))
      ..drawCircle(const ui.Offset(-2.4, -4.6), 1, PaintKit.solid(0x88FFFFFF));
  }

  /// A lump of brown modelling clay with thumb dents.
  static void _clayLump(ui.Canvas c) {
    final lump = ui.Path()
      ..moveTo(-6, 2)
      ..quadraticBezierTo(-7, -4, -2, -6)
      ..quadraticBezierTo(3, -7.5, 6, -3)
      ..quadraticBezierTo(8, 2, 4, 5)
      ..quadraticBezierTo(-2, 7, -6, 2)
      ..close();
    _shaded(c, lump, 0xFFB0764A, light: 0.35);
    c
      ..drawOval(const ui.Rect.fromLTWH(-3, -3.5, 3.4, 2.4),
          PaintKit.solid(0x33000000))
      ..drawOval(const ui.Rect.fromLTWH(1.4, -0.5, 2.8, 2),
          PaintKit.solid(0x33000000));
  }

  /// Two curved arrows chasing each other (swap places).
  static void _swapArrows(ui.Canvas c) {
    final paint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = ui.StrokeCap.round;
    for (final (start, argb) in [(-2.9, 0xFF9C6ADE), (0.25, 0xFFFF8A3D)]) {
      paint.color = ui.Color(argb);
      final rect = ui.Rect.fromCircle(center: ui.Offset.zero, radius: 10);
      c.drawArc(rect, start, 2.3, false, paint);
      final end = start + 2.3;
      final tip = ui.Offset(math.cos(end) * 10, math.sin(end) * 10);
      final dir = ui.Offset(-math.sin(end), math.cos(end));
      final side = ui.Offset(math.cos(end), math.sin(end));
      final head = ui.Path()
        ..moveTo(tip.dx + dir.dx * 4.5, tip.dy + dir.dy * 4.5)
        ..lineTo(tip.dx + side.dx * 4, tip.dy + side.dy * 4)
        ..lineTo(tip.dx - side.dx * 4, tip.dy - side.dy * 4)
        ..close();
      c.drawPath(head, PaintKit.solid(argb));
    }
  }

  /// A red crosshair ring (the missile icon).
  static void _crosshair(ui.Canvas c, ui.Offset at, double r) {
    final paint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const ui.Color(0xFFE5484D);
    c
      ..drawCircle(at, r, paint)
      ..drawLine(at + ui.Offset(-r - 2, 0), at + ui.Offset(-r + 2.5, 0), paint)
      ..drawLine(at + ui.Offset(r - 2.5, 0), at + ui.Offset(r + 2, 0), paint)
      ..drawLine(at + ui.Offset(0, -r - 2), at + ui.Offset(0, -r + 2.5), paint)
      ..drawLine(at + ui.Offset(0, r - 2.5), at + ui.Offset(0, r + 2), paint);
  }


  /// A small bottle rocket pointing right, about 18 px long: a translucent
  /// bottle body, a coloured nose cone and two fins.
  static void _rocket(ui.Canvas c, int body, int nose) {
    for (final s in [-1.0, 1.0]) {
      final fin = ui.Path()
        ..moveTo(-4, s * 2.5)
        ..lineTo(-9, s * 6)
        ..lineTo(-8.5, s * 2)
        ..close();
      _shaded(c, fin, nose);
    }
    final bottle = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-8, -3.2, 12, 6.4), const ui.Radius.circular(2.4));
    c
      ..drawRRect(bottle, PaintKit.lit(bottle.outerRect, body, light: 0.45))
      ..drawRRect(bottle, PaintKit.edge(body, 0.7))
      ..drawRect(const ui.Rect.fromLTWH(-4, -3.2, 3, 6.4),
          PaintKit.solid(0xCCFFF6E6));
    final cone = ui.Path()
      ..moveTo(3.5, -3.2)
      ..quadraticBezierTo(10, -1.5, 10.5, 0)
      ..quadraticBezierTo(10, 1.5, 3.5, 3.2)
      ..close();
    _shaded(c, cone, nose);
    c.drawLine(const ui.Offset(-6.5, -1.8), const ui.Offset(1.5, -1.8),
        PaintKit.solid(0x66FFFFFF)..strokeWidth = 0.8);
  }

  /// The homing rocket: a round lavender body with a dark sniffing nose and
  /// a little eye, pointing right.
  static void _sniffer(ui.Canvas c) {
    const body = 0xFF9C7BE8;
    for (final s in [-1.0, 1.0]) {
      final fin = ui.Path()
        ..moveTo(-3, s * 3)
        ..lineTo(-8.5, s * 6.5)
        ..lineTo(-7.5, s * 1.5)
        ..close();
      _shaded(c, fin, 0xFFF5B700);
    }
    final hull = ui.Rect.fromCenter(
        center: const ui.Offset(0.5, 0), width: 16, height: 8);
    c
      ..drawOval(hull, PaintKit.lit(hull, body, light: 0.4))
      ..drawOval(hull, PaintKit.edge(body, 0.7))
      ..drawCircle(const ui.Offset(8.4, 0), 2, PaintKit.solid(0xFF2B2118))
      ..drawCircle(const ui.Offset(8.9, -0.6), 0.6, PaintKit.solid(0xAAFFFFFF))
      ..drawCircle(const ui.Offset(3.5, -1.6), 1.3, PaintKit.solid(0xFFFFFFFF))
      ..drawCircle(const ui.Offset(3.8, -1.6), 0.7, PaintKit.solid(0xFF2B2118));
  }

  /// A red paper firecracker with gold bands and a fuse, upright.
  static void _firecracker(ui.Canvas c, double s) {
    const red = 0xFFD63A2F;
    final tube = ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(center: ui.Offset.zero, width: 7 * s, height: 13 * s),
        ui.Radius.circular(1.5 * s));
    c
      ..drawRRect(tube, PaintKit.lit(tube.outerRect, red, light: 0.4))
      ..drawRRect(tube, PaintKit.edge(red, 0.7));
    for (final y in [-4.0, 4.0]) {
      c.drawRect(
          ui.Rect.fromCenter(
              center: ui.Offset(0, y * s), width: 7 * s, height: 1.6 * s),
          PaintKit.solid(0xFFF5C542));
    }
    c.drawPath(
        ui.Path()
          ..moveTo(0, -6.5 * s)
          ..quadraticBezierTo(2 * s, -9 * s, 0.5 * s, -10.5 * s),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 0.9 * s
          ..strokeCap = ui.StrokeCap.round
          ..color = const ui.Color(0xFF5A4636));
  }

  /// A terracotta flowerpot with a little green sprout.
  static void _flowerpot(ui.Canvas c, double s) {
    const clay = 0xFFC0623A;
    for (final a in [-0.5, 0.5]) {
      c
        ..save()
        ..translate(0, -4 * s)
        ..rotate(a);
      final leaf = ui.Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(2.5 * s, -2 * s, 0, -6 * s)
        ..quadraticBezierTo(-2.5 * s, -2 * s, 0, 0);
      _shaded(c, leaf, 0xFF4CA35A);
      c.restore();
    }
    final pot = ui.Path()
      ..moveTo(-5 * s, -3 * s)
      ..lineTo(5 * s, -3 * s)
      ..lineTo(3.6 * s, 6 * s)
      ..lineTo(-3.6 * s, 6 * s)
      ..close();
    _shaded(c, pot, clay);
    final rim = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(-6 * s, -5 * s, 12 * s, 3 * s),
        ui.Radius.circular(1 * s));
    c
      ..drawRRect(rim, PaintKit.lit(rim.outerRect, PaintKit.toneArgb(clay, 0.1)))
      ..drawRRect(rim, PaintKit.edge(clay, 0.6));
  }

  static void _shaded(ui.Canvas c, ui.Path path, int argb,
      {double light = 0.3}) {
    c
      ..drawPath(path, PaintKit.lit(path.getBounds(), argb, light: light))
      ..drawPath(path, PaintKit.edge(argb, 0.7));
  }

  static void _ball(ui.Canvas c, double r, int argb, {double light = 0.35}) {
    final rect = ui.Rect.fromCircle(center: ui.Offset.zero, radius: r);
    c
      ..drawCircle(ui.Offset.zero, r, PaintKit.lit(rect, argb, light: light))
      ..drawCircle(ui.Offset.zero, r, PaintKit.edge(argb, 0.7));
  }

  static void _rock(ui.Canvas c, double r, int argb) {
    // Irregular pebble: uneven radii, smoothed with curves.
    const radii = [1.0, 0.86, 0.94, 0.72, 0.9, 1.0, 0.8, 0.88, 0.76];
    final pts = [
      for (var i = 0; i < radii.length; i++)
        ui.Offset(math.cos(i / radii.length * math.pi * 2 + 0.3) * r * radii[i],
            math.sin(i / radii.length * math.pi * 2 + 0.3) * r * radii[i] * 0.82),
    ];
    final path = ui.Path();
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      final mid = (a + b) / 2;
      if (i == 0) path.moveTo(mid.dx, mid.dy);
      final next = (b + pts[(i + 2) % pts.length]) / 2;
      path.quadraticBezierTo(b.dx, b.dy, next.dx, next.dy);
    }
    path.close();
    _shaded(c, path, argb, light: 0.35);
    c
      ..drawCircle(ui.Offset(-r * 0.3, -r * 0.3), r * 0.2,
          PaintKit.solid(0x40FFFFFF))
      ..drawCircle(ui.Offset(r * 0.25, r * 0.15), r * 0.12,
          PaintKit.solid(0x33000000));
  }

  static void _grenade(ui.Canvas c) {
    const body = 0xFF4E6B3A;
    final rect = ui.Rect.fromCenter(
        center: const ui.Offset(0, 1), width: 11, height: 13);
    c
      ..drawOval(rect, PaintKit.lit(rect, body))
      ..drawOval(rect, PaintKit.edge(body, 0.7));
    final groove = ui.Paint()
      ..color = PaintKit.tone(body, -0.45)
      ..strokeWidth = 0.6;
    for (final y in [-2.5, 1.0, 4.5]) {
      c.drawLine(ui.Offset(-5, y), ui.Offset(5, y), groove);
    }
    for (final x in [-2.2, 2.2]) {
      c.drawLine(ui.Offset(x, -5), ui.Offset(x, 7), groove);
    }
    final cap = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-2.5, -8, 5, 3.2), const ui.Radius.circular(1));
    c
      ..drawRRect(cap, PaintKit.lit(cap.outerRect, 0xFFA8A8A0))
      ..drawLine(
          const ui.Offset(2.5, -7),
          const ui.Offset(5, -2),
          ui.Paint()
            ..color = const ui.Color(0xFF9A9A92)
            ..strokeWidth = 1.2
            ..strokeCap = ui.StrokeCap.round);
  }

  static void _bomb(ui.Canvas c, double r) {
    const body = 0xFF2E3238;
    _ball(c, r, body, light: 0.45);
    c.drawRect(
        ui.Rect.fromCenter(center: ui.Offset.zero, width: r * 2, height: r * 0.4),
        PaintKit.solid(0xCCB3261E));
    final cap = ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(
            center: ui.Offset(0, -r * 1.05), width: r * 0.8, height: r * 0.4),
        const ui.Radius.circular(1));
    c.drawRRect(cap, PaintKit.lit(cap.outerRect, 0xFF8A8A84));
  }

  static void _hairball(ui.Canvas c, double r) {
    const fur = 0xFFBCA48A;
    _ball(c, r, fur, light: 0.25);
    final strand = ui.Paint()
      ..color = PaintKit.tone(fur, -0.3)
      ..strokeWidth = 0.6
      ..strokeCap = ui.StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2;
      final inner = r * 0.55;
      c.drawLine(ui.Offset(math.cos(a) * inner, math.sin(a) * inner),
          ui.Offset(math.cos(a + 0.4) * (r + 1.6), math.sin(a + 0.4) * (r + 1.6)),
          strand);
    }
  }

  static void _bone(ui.Canvas c) {
    const bone = 0xFFF1E9D8;
    final shaft = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-9, -1.8, 18, 3.6), const ui.Radius.circular(1.8));
    c.drawRRect(shaft, PaintKit.lit(shaft.outerRect, bone));
    for (final x in [-9.5, 9.5]) {
      for (final y in [-2.2, 2.2]) {
        final rect = ui.Rect.fromCircle(center: ui.Offset(x, y), radius: 2.6);
        c
          ..drawCircle(ui.Offset(x, y), 2.6, PaintKit.lit(rect, bone))
          ..drawCircle(ui.Offset(x, y), 2.6, PaintKit.edge(bone, 0.6));
      }
    }
    c.drawRRect(shaft, PaintKit.edge(bone, 0.6));
  }

  /// Pointing right.
  static void _carrot(ui.Canvas c) {
    const orange = 0xFFE8742C;
    final body = ui.Path()
      ..moveTo(12, 0)
      ..quadraticBezierTo(2, -4.6, -6, -3.8)
      ..quadraticBezierTo(-8, 0, -6, 3.8)
      ..quadraticBezierTo(2, 4.6, 12, 0)
      ..close();
    _shaded(c, body, orange);
    final ridge = ui.Paint()
      ..color = PaintKit.tone(orange, -0.35)
      ..strokeWidth = 0.6;
    for (final x in [-2.0, 2.0, 6.0]) {
      c.drawLine(ui.Offset(x, -2.6 + x * 0.12), ui.Offset(x + 1, -0.6), ridge);
    }
    const leaf = 0xFF5E9E3A;
    for (final a in [-0.5, 0.0, 0.5]) {
      c
        ..save()
        ..translate(-7, 0)
        ..rotate(math.pi + a);
      final l = ui.Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(3, -1.6, 6, 0)
        ..quadraticBezierTo(3, 1.6, 0, 0);
      c
        ..drawPath(l, PaintKit.lit(l.getBounds(), leaf))
        ..restore();
    }
  }

  static void _egg(ui.Canvas c, double s) {
    const shell = 0xFFF4E9D6;
    final rect = ui.Rect.fromCenter(
        center: ui.Offset.zero, width: 8 * s, height: 10.5 * s);
    c
      ..drawOval(rect, PaintKit.lit(rect, shell, light: 0.4))
      ..drawOval(rect, PaintKit.edge(shell, 0.6));
    for (final (x, y) in [(-1.4, -2.0), (1.6, 1.4), (-0.6, 2.6)]) {
      c.drawCircle(ui.Offset(x * s, y * s), 0.5 * s, PaintKit.solid(0x66A8865A));
    }
  }

  /// Sunflower seed: a dark teardrop with pale lengthwise stripes.
  static void _seed(ui.Canvas c, double s) {
    final path = ui.Path()
      ..moveTo(0, -6.5 * s)
      ..quadraticBezierTo(5 * s, -2 * s, 3.2 * s, 4 * s)
      ..quadraticBezierTo(0, 7 * s, -3.2 * s, 4 * s)
      ..quadraticBezierTo(-5 * s, -2 * s, 0, -6.5 * s)
      ..close();
    _shaded(c, path, 0xFF3A3530, light: 0.4);
    c
      ..save()
      ..clipPath(path);
    final stripe = ui.Paint()
      ..color = const ui.Color(0x99D8D0BC)
      ..strokeWidth = 0.7 * s;
    for (final x in [-2.0, 0.0, 2.0]) {
      c.drawLine(ui.Offset(x * s * 0.6, -5.5 * s), ui.Offset(x * s, 6 * s),
          stripe);
    }
    c.restore();
  }

  static void _coconut(ui.Canvas c) {
    const husk = 0xFF6B4A30;
    _ball(c, 7.5, husk, light: 0.3);
    final fiber = ui.Paint()
      ..color = PaintKit.tone(husk, 0.25)
      ..strokeWidth = 0.5;
    for (var i = 0; i < 10; i++) {
      final a = i * 0.63;
      c.drawLine(ui.Offset(math.cos(a) * 3, math.sin(a) * 3),
          ui.Offset(math.cos(a + 0.3) * 7, math.sin(a + 0.3) * 7), fiber);
    }
    for (final (x, y) in [(-1.6, -2.4), (1.6, -2.4), (0.0, 0.4)]) {
      c.drawCircle(ui.Offset(x, y), 1, PaintKit.solid(0xFF2A1A10));
    }
  }

  static void _mine(ui.Canvas c) {
    const metal = 0xFF4A5056;
    final base = ui.Rect.fromCenter(
        center: const ui.Offset(0, -1.5), width: 15, height: 4);
    c
      ..drawOval(base, PaintKit.lit(base, metal))
      ..drawOval(base, PaintKit.edge(metal, 0.6));
    final dome = ui.Path()
      ..moveTo(-5.5, -2.5)
      ..quadraticBezierTo(0, -9, 5.5, -2.5)
      ..close();
    _shaded(c, dome, 0xFF60686E, light: 0.4);
    c.drawRect(const ui.Rect.fromLTWH(-0.8, -8.5, 1.6, 2),
        PaintKit.solid(0xFF2A2E32));
  }

  // --------------------------------------------------------------- icons

  /// Icons are drawn for a 32 px box.
  static void _icon(ui.Canvas c, String id) {
    void big(void Function() draw, [double s = 2]) {
      c
        ..save()
        ..scale(s);
      draw();
      c.restore();
    }

    switch (id) {
      case 'rock':
        big(() => _rock(c, 6.5, 0xFF8E8A84));
      case 'grenade':
        big(() => _grenade(c), 1.9);
      case 'cluster':
        big(() {
          _bomb(c, 6);
          for (final (x, y) in [(-7.0, 5.0), (7.0, 5.0), (0.0, 8.5)]) {
            c
              ..save()
              ..translate(x, y)
              ..scale(0.5);
            _bomb(c, 4);
            c.restore();
          }
        }, 1.8);
      case 'twinSling':
        _slingshot(c);
      case 'punch':
        _glove(c);
      case 'mine':
        big(() {
          c.translate(0, 4);
          _mine(c);
        }, 1.8);
      case 'teleport':
        _portal(c);
      case 'skip':
        _hourglass(c);
      case 'hairball':
        big(() => _hairball(c, 6));
      case 'boneBoomerang':
        big(() {
          c.rotate(-0.5);
          _bone(c);
        }, 1.4);
      case 'drillCarrot':
        big(() {
          c.rotate(0.6);
          _carrot(c);
        }, 1.4);
      case 'eggStrike':
        for (final (x, y) in [(-7.0, -4.0), (0.0, 2.0), (7.0, -4.0)]) {
          c
            ..save()
            ..translate(x, y)
            ..scale(1.2);
          _egg(c, 1);
          c.restore();
        }
      case 'seedMines':
        for (final (x, y, a) in [(-6.0, 3.0, -0.4), (0.0, -4.0, 0.2), (6.0, 3.0, 0.6)]) {
          c
            ..save()
            ..translate(x, y)
            ..rotate(a);
          _seed(c, 1);
          c.restore();
        }
      case 'boomDuck':
        c
          ..save()
          ..translate(-1, 11)
          ..scale(0.85);
        AnimalArt.draw(c,
            familyId: 'duck',
            teamArgb: 0xFFE53935,
            pose: AnimalPose.idle);
        c.restore();
        c
          ..save()
          ..translate(-5, -2)
          ..scale(0.8);
        _bomb(c, 5);
        c.restore();
      case 'startleCrow':
        _shout(c);
      case 'fortress':
        _bricks(c);
      case 'headbutt':
        _horns(c);
      case 'coconut':
        big(() => _coconut(c), 1.8);
      case 'bottleRocket':
        big(() {
          c.rotate(-0.7);
          _rocket(c, 0xFF5AA9E6, 0xFFE5484D);
        }, 1.45);
      case 'snifferRocket':
        _trail(c, const [ui.Offset(-13, 11), ui.Offset(-8, 2), ui.Offset(-2, -2)]);
        big(() {
          c
            ..translate(2, -2)
            ..rotate(-0.35);
          _sniffer(c);
        }, 1.4);
      case 'laserPointer':
        _laser(c);
      case 'thunderCloud':
        _cloudBolt(c);
      case 'seedSpitter':
        _spitter(c);
      case 'firecracker':
        big(() {
          c.rotate(0.25);
          _firecracker(c, 1);
        }, 1.75);
        _spark(c, const ui.Offset(5, -14), 3.4);
      case 'flowerpotRain':
        for (final (x, y, a) in [(-7.0, -5.0, -0.3), (6.0, -8.0, 0.25), (0.0, 7.0, 0.1)]) {
          c
            ..save()
            ..translate(x, y)
            ..rotate(a)
            ..scale(1.1);
          _flowerpot(c, 1);
          c.restore();
        }
      case 'digClaws':
        _claws(c);
      case 'bomber':
        for (final (x, y) in [(-5.0, 6.0), (2.0, 11.0), (9.0, 6.0)]) {
          c
            ..save()
            ..translate(x, y)
            ..rotate(1.2)
            ..scale(0.75);
          _aerialBomb(c);
          c.restore();
        }
        c
          ..save()
          ..translate(1, -6)
          ..scale(0.33);
        _plane(c);
        c.restore();
      case 'satellite':
        big(() => _satellite(c), 1.15);
      case 'blackHole':
        big(() => _voidOrb(c), 1.7);
      case 'stickyBomb':
        big(() => _sticky(c), 2);
      case 'clay':
        big(() => _clayLump(c), 1.9);
      case 'swap':
        _swapArrows(c);
      case 'meteorShower':
        // One big meteor coming in low right, two small ones behind it.
        const rocks = [(9.0, -9.0, 0.5, 12.0), (-9.0, -2.0, 0.55, 12.0), (3.0, 6.0, 1.0, 26.0)];
        for (final (x, y, s, tail) in rocks) {
          c
            ..save()
            ..translate(x, y)
            ..scale(s);
          _meteorTail(c, tail / s);
          c.restore();
        }
        for (final (x, y, s, _) in rocks) {
          c
            ..save()
            ..translate(x, y)
            ..scale(s);
          _meteorRock(c, 7);
          c.restore();
        }
      case 'napalm':
        big(() {
          c.rotate(-0.35);
          _napalmCan(c);
        }, 1.75);
        for (final (x, s) in [(-9.0, 0.8), (-2.0, 1.0), (6.0, 0.75)]) {
          c
            ..save()
            ..translate(x, 14)
            ..scale(s);
          _flameTongue(c);
          c.restore();
        }
      case 'iceBomb':
        big(() => _iceBall(c), 1.9);
      case 'shotgun':
        _shotgunGun(c);
      case 'poisonGas':
        for (final (x, y, r) in [(-6.0, -8.0, 7.0), (5.0, -10.0, 6.0), (0.0, -4.0, 8.0)]) {
          c.drawCircle(ui.Offset(x, y), r, PaintKit.solid(0x777BC74D));
        }
        big(() {
          c
            ..translate(0, 4)
            ..rotate(-0.4);
          _gasCan(c);
        }, 1.6);
      case 'firstAid':
        _firstAidKit(c);
      case 'miniNuke':
        big(() => _nukeBomb(c), 1.55);
      case 'gasRaid':
        for (final (x, y, r) in [(-6.0, 10.0, 6.0), (6.0, 11.0, 5.0), (0.0, 7.0, 6.5)]) {
          c.drawCircle(ui.Offset(x, y), r, PaintKit.solid(0x887BC74D));
        }
        for (final (x, y) in [(-6.0, 3.0), (5.0, 4.0)]) {
          c
            ..save()
            ..translate(x, y)
            ..rotate(1.3)
            ..scale(0.6);
          _gasCan(c);
          c.restore();
        }
        c
          ..save()
          ..translate(1, -8)
          ..scale(0.33);
        _plane(c);
        c.restore();
      case 'shield':
        _shieldBubble(c);
      case 'grapple':
        final rope = ui.Path()
          ..moveTo(-13, 13)
          ..quadraticBezierTo(-10, 2, -2, 2)
          ..quadraticBezierTo(2, 2, 3, -3);
        c
          ..drawPath(
              rope,
              PaintKit.solid(0xFF6B4A2E)
                ..style = ui.PaintingStyle.stroke
                ..strokeWidth = 3.2
                ..strokeCap = ui.StrokeCap.round)
          ..drawPath(
              rope,
              PaintKit.solid(0xFFC9A66B)
                ..style = ui.PaintingStyle.stroke
                ..strokeWidth = 1.8
                ..strokeCap = ui.StrokeCap.round)
          ..save()
          ..translate(2, -2)
          ..rotate(-0.8)
          ..scale(1.4);
        _hook(c);
        c.restore();
      case 'homingMissile':
        _crosshair(c, const ui.Offset(8, -8), 6);
        big(() {
          c
            ..translate(-2, 3)
            ..rotate(-0.75);
          _missile(c);
        }, 1.2);
      default:
        big(() => _rock(c, 6, 0xFF9E9A94));
    }
  }

  /// Speed dashes behind something moving along [points].
  static void _trail(ui.Canvas c, List<ui.Offset> points) {
    final paint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = ui.StrokeCap.round
      ..color = const ui.Color(0x998B5CF6);
    final path = ui.Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i + 1 < points.length; i += 2) {
      path.quadraticBezierTo(
          points[i].dx, points[i].dy, points[i + 1].dx, points[i + 1].dy);
    }
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 5) {
        c.drawPath(m.extractPath(d, d + 2.6), paint);
      }
    }
  }

  static void _spark(ui.Canvas c, ui.Offset at, double r) {
    final star = ui.Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.42;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = at + ui.Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    c
      ..drawPath(star, PaintKit.solid(0xFFFFD25A))
      ..drawPath(star, PaintKit.edge(0xFFE2681C, 0.6));
  }

  /// A pen-shaped laser pointer firing a red beam at a dot.
  static void _laser(ui.Canvas c) {
    c
      ..drawLine(
          const ui.Offset(1, 3),
          const ui.Offset(13, -9),
          ui.Paint()
            ..color = const ui.Color(0x66FF3B30)
            ..strokeWidth = 4
            ..strokeCap = ui.StrokeCap.round)
      ..drawLine(
          const ui.Offset(1, 3),
          const ui.Offset(13, -9),
          ui.Paint()
            ..color = const ui.Color(0xFFFF5A4E)
            ..strokeWidth = 1.4
            ..strokeCap = ui.StrokeCap.round)
      ..drawCircle(const ui.Offset(13, -9), 3.2, PaintKit.solid(0x88FF3B30))
      ..drawCircle(const ui.Offset(13, -9), 1.6, PaintKit.solid(0xFFFFE0DC));
    c
      ..save()
      ..translate(-5, 9)
      ..rotate(-math.pi / 4);
    final body = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-9, -2.6, 16, 5.2), const ui.Radius.circular(2.4));
    c
      ..drawRRect(body, PaintKit.lit(body.outerRect, 0xFF4A5560, light: 0.4))
      ..drawRRect(body, PaintKit.edge(0xFF4A5560, 0.7))
      ..drawRect(const ui.Rect.fromLTWH(5, -2.6, 2.4, 5.2),
          PaintKit.solid(0xFFC9CED4))
      ..drawCircle(const ui.Offset(-1, -2.6), 1.3, PaintKit.solid(0xFFE5484D))
      ..restore();
  }

  /// A grey storm cloud with a yellow bolt.
  static void _cloudBolt(ui.Canvas c) {
    final bolt = ui.Path()
      ..moveTo(1, -1)
      ..lineTo(-5, 8)
      ..lineTo(0, 8)
      ..lineTo(-3, 15)
      ..lineTo(6, 4)
      ..lineTo(1, 4)
      ..lineTo(5, -1)
      ..close();
    c
      ..drawPath(bolt, PaintKit.solid(0xFFF5C542))
      ..drawPath(bolt, PaintKit.edge(0xFFB8860B, 0.7));
    final cloud = ui.Path()
      ..addOval(ui.Rect.fromCircle(center: const ui.Offset(-7, -4), radius: 6))
      ..addOval(ui.Rect.fromCircle(center: const ui.Offset(1, -8), radius: 8))
      ..addOval(ui.Rect.fromCircle(center: const ui.Offset(9, -3), radius: 6))
      ..addRRect(ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTRB(-13, -4, 15, 3), const ui.Radius.circular(3.5)));
    final merged = ui.Path.combine(ui.PathOperation.union, cloud, ui.Path());
    _shaded(c, merged, 0xFF8C96A4, light: 0.35);
  }

  /// A green pod tube spitting a fan of seeds.
  static void _spitter(ui.Canvas c) {
    for (final (dy, a) in [(-7.0, -0.35), (0.0, 0.0), (7.0, 0.35)]) {
      c
        ..save()
        ..translate(9, dy)
        ..rotate(math.pi / 2 + a);
      _seed(c, 0.6);
      c.restore();
    }
    c
      ..save()
      ..rotate(-0.15);
    final pod = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-14, -4.5, 17, 9), const ui.Radius.circular(4.5));
    c
      ..drawRRect(pod, PaintKit.lit(pod.outerRect, 0xFF6FAE45, light: 0.4))
      ..drawRRect(pod, PaintKit.edge(0xFF6FAE45, 0.7))
      ..drawOval(const ui.Rect.fromLTWH(0.5, -3.2, 3.6, 6.4),
          PaintKit.solid(0xFF2E4A1E))
      ..restore();
  }

  /// A burning space rock of radius [r]: a dark crust split by glowing
  /// orange cracks, in a faint heat haze.
  static void _meteorRock(ui.Canvas c, double r) {
    c.drawCircle(ui.Offset.zero, r * 1.35, PaintKit.solid(0x33FFB04A));
    _rock(c, r, 0xFF4A3530);
    final crack = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = r * 0.15
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round
      ..color = const ui.Color(0xFFFF9A3A);
    final path = ui.Path()
      ..moveTo(-r * 0.55, -r * 0.2)
      ..lineTo(-r * 0.1, r * 0.1)
      ..lineTo(r * 0.5, -r * 0.25)
      ..moveTo(-r * 0.1, r * 0.1)
      ..lineTo(r * 0.05, r * 0.5);
    c
      ..drawPath(path, crack)
      ..drawPath(
          path,
          crack
            ..strokeWidth = r * 0.06
            ..color = const ui.Color(0xFFFFE08A));
  }

  /// A fiery tail [length] px long trailing up and to the left of a
  /// meteor at the origin (icons only; in flight the renderer draws it).
  static void _meteorTail(ui.Canvas c, double length) {
    final tail = ui.Path()
      ..moveTo(-4, 4)
      ..quadraticBezierTo(-length * 0.6, -length * 0.5, -length * 0.75, -length * 0.75)
      ..quadraticBezierTo(-length * 0.45, -length * 0.65, 4, -4)
      ..close();
    c
      ..drawPath(tail, PaintKit.solid(0xAAFF8A2A))
      ..drawPath(
          ui.Path()
            ..moveTo(-2, 2)
            ..quadraticBezierTo(-length * 0.4, -length * 0.35, -length * 0.5, -length * 0.5)
            ..quadraticBezierTo(-length * 0.3, -length * 0.42, 2, -2)
            ..close(),
          PaintKit.solid(0xDDFFE08A));
  }

  /// A napalm canister about 14 px long lying along x: a dented olive
  /// can with a red band and a burning fuse cap.
  static void _napalmCan(ui.Canvas c) {
    const can = 0xFF6B7A3A;
    final body = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-7, -4.2, 13, 8.4), const ui.Radius.circular(3));
    c
      ..drawRRect(body, PaintKit.lit(body.outerRect, can, light: 0.4))
      ..drawRRect(body, PaintKit.edge(can, 0.7))
      ..drawRect(const ui.Rect.fromLTWH(-2.5, -4.2, 2.6, 8.4),
          PaintKit.solid(0xFFD8452B))
      ..drawRRect(
          ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(5.5, -2.4, 3, 4.8),
              const ui.Radius.circular(1)),
          PaintKit.solid(0xFF3D4246))
      ..drawCircle(const ui.Offset(10, 0), 2.6, PaintKit.solid(0xCCFF8A2A))
      ..drawCircle(const ui.Offset(10, 0), 1.3, PaintKit.solid(0xFFFFE08A));
  }

  /// A small flame (icons), base at the origin, about 10 px tall.
  static void _flameTongue(ui.Canvas c) {
    for (final (h, w, argb) in const [
      (11.0, 4.2, 0xFFFF6A1A),
      (7.0, 2.6, 0xFFFFC23A),
      (3.5, 1.4, 0xFFFFF2B0),
    ]) {
      c.drawPath(
          ui.Path()
            ..moveTo(-w, 0)
            ..quadraticBezierTo(-w * 1.1, -h * 0.55, 0.6, -h)
            ..quadraticBezierTo(w * 1.1, -h * 0.55, w, 0)
            ..close(),
          PaintKit.solid(argb));
    }
  }

  /// The ice bomb, about 13 px across: a frosted pale-blue ball with
  /// crystal facets, a steel cap and a frost glint.
  static void _iceBall(ui.Canvas c) {
    const ice = 0xFF8FD8FF;
    final rect = ui.Rect.fromCircle(center: const ui.Offset(0, 1), radius: 6.2);
    c
      ..drawOval(rect, PaintKit.lit(rect, ice, light: 0.55))
      ..drawOval(rect, PaintKit.edge(ice, 0.8));
    final facet = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const ui.Color(0xCCFFFFFF);
    c
      ..drawPath(
          ui.Path()
            ..moveTo(-4, -1)
            ..lineTo(0, 2)
            ..lineTo(4, -1.5)
            ..moveTo(0, 2)
            ..lineTo(0.5, 6),
          facet)
      ..drawRRect(
          ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(-2.2, -7.4, 4.4, 2.8),
              const ui.Radius.circular(1)),
          PaintKit.solid(0xFF7D868B))
      ..drawCircle(const ui.Offset(-2.4, -1.8), 1.3, PaintKit.solid(0xEEFFFFFF));
    // A small snowflake glint.
    final flake = ui.Paint()
      ..strokeWidth = 0.7
      ..strokeCap = ui.StrokeCap.round
      ..color = const ui.Color(0xFFFFFFFF);
    for (var i = 0; i < 3; i++) {
      final a = i * math.pi / 3;
      final d = ui.Offset(math.cos(a) * 1.8, math.sin(a) * 1.8);
      c.drawLine(const ui.Offset(3, 3) - d, const ui.Offset(3, 3) + d, flake);
    }
  }

  /// A double-barrelled shotgun (icon, 32 px box) pointing right, with a
  /// wooden stock and a muzzle flash.
  static void _shotgunGun(ui.Canvas c) {
    c
      ..save()
      ..rotate(-0.3);
    const wood = 0xFF8A5A34;
    const steel = 0xFF5C6266;
    final stock = ui.Path()
      ..moveTo(-15, -1)
      ..lineTo(-4, -2.5)
      ..lineTo(-2, 2.5)
      ..lineTo(-6, 3)
      ..lineTo(-14, 6.5)
      ..quadraticBezierTo(-16.5, 6, -16, 2)
      ..close();
    _shaded(c, stock, wood);
    for (final y in [-3.6, -1.2]) {
      final barrel = ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(-4, y, 19, 2.6), const ui.Radius.circular(1));
      c
        ..drawRRect(barrel, PaintKit.lit(barrel.outerRect, steel, light: 0.5))
        ..drawRRect(barrel, PaintKit.edge(steel, 0.5));
    }
    final grip = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(1, 1.2, 8, 3), const ui.Radius.circular(1.2));
    c
      ..drawRRect(grip, PaintKit.lit(grip.outerRect, wood))
      ..drawCircle(const ui.Offset(18, -2.3), 3.2, PaintKit.solid(0xCCFFB04A))
      ..drawCircle(const ui.Offset(18, -2.3), 1.6, PaintKit.solid(0xFFFFF2B0))
      ..restore();
  }

  /// A shield bubble (icon): a translucent sphere with a rainbow-tinted
  /// rim, a shine, and a small shield crest inside.
  static void _shieldBubble(ui.Canvas c) {
    const center = ui.Offset(0, 1);
    final rect = ui.Rect.fromCircle(center: center, radius: 13);
    c
      ..drawCircle(
          center,
          13,
          ui.Paint()
            ..shader = ui.Gradient.radial(center + const ui.Offset(-4, -5), 16,
                const [ui.Color(0x55E6F9FF), ui.Color(0x449FE3FF), ui.Color(0x88B79CFF)],
                const [0, 0.7, 1]))
      ..drawOval(
          rect,
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = const ui.Color(0xDD9FE3FF));
    final crest = ui.Path()
      ..moveTo(0, -5)
      ..lineTo(6, -3)
      ..quadraticBezierTo(6, 4, 0, 8)
      ..quadraticBezierTo(-6, 4, -6, -3)
      ..close();
    _shaded(c, crest, 0xFF4C8FD6);
    c
      ..drawLine(const ui.Offset(0, -3), const ui.Offset(0, 6),
          PaintKit.solid(0x99FFFFFF)..strokeWidth = 1.2)
      ..drawArc(ui.Rect.fromCircle(center: center, radius: 9.5), math.pi * 1.1,
          math.pi * 0.35, false,
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = ui.StrokeCap.round
            ..color = const ui.Color(0xEEFFFFFF));
  }

  /// A gas canister about 14 px long lying along x: a green bottle with a
  /// skull label and a valve wisping gas.
  static void _gasCan(ui.Canvas c) {
    const body = 0xFF5E9E3A;
    final can = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-7, -4.4, 12, 8.8), const ui.Radius.circular(4));
    c
      ..drawRRect(can, PaintKit.lit(can.outerRect, body, light: 0.45))
      ..drawRRect(can, PaintKit.edge(body, 0.7))
      ..drawRRect(
          ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(5, -1.8, 3.2, 3.6),
              const ui.Radius.circular(0.8)),
          PaintKit.solid(0xFF3D4246))
      ..drawCircle(const ui.Offset(-1.2, -0.6), 2.4, PaintKit.solid(0xFFF2FFE6))
      ..drawRect(const ui.Rect.fromLTWH(-2.3, 1.2, 2.2, 1.4),
          PaintKit.solid(0xFFF2FFE6))
      ..drawCircle(const ui.Offset(-2, -0.9), 0.6, PaintKit.solid(0xFF2B2118))
      ..drawCircle(const ui.Offset(-0.4, -0.9), 0.6, PaintKit.solid(0xFF2B2118))
      ..drawCircle(const ui.Offset(10, -1), 2, PaintKit.solid(0x887BC74D));
  }

  /// A mini nuke about 18 px long lying along x: a fat yellow bomb with a
  /// black-and-yellow radiation trefoil and stubby tail fins.
  static void _nukeBomb(ui.Canvas c) {
    const body = 0xFFF5B700;
    for (final s in [-1.0, 1.0]) {
      final fin = ui.Path()
        ..moveTo(-6, s * 2.5)
        ..lineTo(-11, s * 6.5)
        ..lineTo(-11.5, s * 2)
        ..close();
      _shaded(c, fin, 0xFF4A4F55);
    }
    final shell = ui.Rect.fromCenter(
        center: const ui.Offset(1, 0), width: 17, height: 11);
    c
      ..drawOval(shell, PaintKit.lit(shell, body, light: 0.45))
      ..drawOval(shell, PaintKit.edge(body, 0.8))
      ..drawCircle(const ui.Offset(1.5, 0), 3.8, PaintKit.solid(0xFF2B2118));
    for (var i = 0; i < 3; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 3;
      c.drawArc(
          ui.Rect.fromCircle(center: const ui.Offset(1.5, 0), radius: 2.6),
          a - 0.45,
          0.9,
          true,
          PaintKit.solid(body));
    }
    c
      ..drawCircle(const ui.Offset(1.5, 0), 0.9, PaintKit.solid(0xFF2B2118))
      ..drawCircle(const ui.Offset(-2.5, -3), 1.4, PaintKit.solid(0x88FFFFFF));
  }

  /// A first-aid kit (icon): a white case with a red cross and a handle.
  static void _firstAidKit(ui.Canvas c) {
    final handle = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-5, -12, 10, 6), const ui.Radius.circular(3));
    c.drawRRect(
        handle,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = const ui.Color(0xFF7D868B));
    final box = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-13, -8, 26, 20), const ui.Radius.circular(4));
    c
      ..drawRRect(box, PaintKit.lit(box.outerRect, 0xFFF4F1EA, light: 0.3))
      ..drawRRect(box, PaintKit.edge(0xFFB8B2A6, 0.9))
      ..drawRect(const ui.Rect.fromLTWH(-2.6, -4.5, 5.2, 13), PaintKit.solid(0xFFE5484D))
      ..drawRect(const ui.Rect.fromLTWH(-6.5, -0.6, 13, 5.2), PaintKit.solid(0xFFE5484D));
  }

  /// See [grappleHook].
  static void _hook(ui.Canvas c) {
    const steel = 0xFF9AA3A8;
    final shank = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-1, -1.4, 11, 2.8), const ui.Radius.circular(1.4));
    c
      ..drawCircle(ui.Offset.zero, 2.4, PaintKit.edge(0xFF5C6266, 1.4))
      ..drawRRect(shank, PaintKit.lit(shank.outerRect, steel))
      ..drawRRect(shank, PaintKit.edge(0xFF5C6266, 0.6));
    final prong = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = ui.StrokeCap.round
      ..color = const ui.Color(0xFF7D868B);
    for (final s in [-1.0, 1.0]) {
      c.drawPath(
          ui.Path()
            ..moveTo(9, 0)
            ..quadraticBezierTo(13, s * 1, 13, s * 5)
            ..quadraticBezierTo(12.5, s * 7, 9.5, s * 6.5),
          prong);
    }
    c.drawLine(const ui.Offset(9, 0), const ui.Offset(15, 0), prong);
    final tip = ui.Path()
      ..moveTo(15, -2)
      ..lineTo(18, 0)
      ..lineTo(15, 2)
      ..close();
    c.drawPath(tip, PaintKit.solid(0xFFB8C0C4));
  }

  /// A paw with three long claws and dug-up earth.
  static void _claws(ui.Canvas c) {
    const pad = 0xFF8D6E63;
    const claw = 0xFFEDE3D2;
    for (final (x, a) in [(-6.0, -0.35), (0.0, 0.0), (6.0, 0.35)]) {
      c
        ..save()
        ..translate(x, -4)
        ..rotate(a);
      final path = ui.Path()
        ..moveTo(-1.8, 0)
        ..quadraticBezierTo(-1.5, -9, 2.5, -12)
        ..quadraticBezierTo(1.5, -6, 1.8, 0)
        ..close();
      _shaded(c, path, claw, light: 0.4);
      c.restore();
    }
    final palm = ui.Rect.fromCenter(
        center: const ui.Offset(0, 4), width: 20, height: 13);
    c
      ..drawOval(palm, PaintKit.lit(palm, pad))
      ..drawOval(palm, PaintKit.edge(pad, 0.7));
    for (final (x, y) in [(-9.0, 12.0), (-4.0, 13.5), (8.0, 12.5)]) {
      c.drawCircle(ui.Offset(x, y), 1.8, PaintKit.solid(0xFF7A5A3A));
    }
  }

  static void _slingshot(ui.Canvas c) {
    const wood = 0xFF8A5A34;
    final fork = ui.Path()
      ..moveTo(-2, 14)
      ..lineTo(2, 14)
      ..lineTo(2, 2)
      ..lineTo(8, -10)
      ..lineTo(5, -11)
      ..lineTo(0, -1)
      ..lineTo(-5, -11)
      ..lineTo(-8, -10)
      ..lineTo(-2, 2)
      ..close();
    _shaded(c, fork, wood);
    c.drawLine(
        const ui.Offset(-6.5, -10),
        const ui.Offset(6.5, -10),
        ui.Paint()
          ..color = const ui.Color(0xFF5A3A26)
          ..strokeWidth = 1.2);
    for (final x in [-3.0, 3.0]) {
      c
        ..save()
        ..translate(x, -12);
      _rock(c, 2.6, 0xFF7C756C);
      c.restore();
    }
  }

  static void _glove(ui.Canvas c) {
    const red = 0xFFC8342C;
    final glove = ui.Path()
      ..moveTo(-10, 4)
      ..quadraticBezierTo(-12, -10, 0, -11)
      ..quadraticBezierTo(12, -11, 11, 1)
      ..quadraticBezierTo(10, 9, 0, 8)
      ..lineTo(-10, 8)
      ..close();
    _shaded(c, glove, red);
    final thumb = ui.Path()
      ..moveTo(-4, 1)
      ..quadraticBezierTo(2, -3, 6, 2)
      ..quadraticBezierTo(2, 5, -4, 3)
      ..close();
    _shaded(c, thumb, PaintKit.toneArgb(red, -0.08));
    final cuff = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-12, 7, 14, 6), const ui.Radius.circular(2));
    c.drawRRect(cuff, PaintKit.lit(cuff.outerRect, 0xFFF2F0EA));
  }

  static void _portal(ui.Canvas c) {
    for (var i = 0; i < 4; i++) {
      final r = 13.0 - i * 3;
      c.drawCircle(
          ui.Offset.zero,
          r,
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = ui.Color.lerp(const ui.Color(0xFF7E57C2),
                const ui.Color(0xFFE1BEE7), i / 3)!);
    }
    c.drawCircle(ui.Offset.zero, 2.5, PaintKit.solid(0xFFFFFFFF));
  }

  static void _hourglass(ui.Canvas c) {
    const wood = 0xFF8A5A34;
    final glass = ui.Path()
      ..moveTo(-7, -11)
      ..lineTo(7, -11)
      ..lineTo(1, 0)
      ..lineTo(7, 11)
      ..lineTo(-7, 11)
      ..lineTo(-1, 0)
      ..close();
    c
      ..drawPath(glass, PaintKit.solid(0x55BFE3F2))
      ..drawPath(glass, PaintKit.edge(0xFF9AB8C4, 1));
    final sand = ui.Path()
      ..moveTo(-5, 10)
      ..lineTo(5, 10)
      ..lineTo(0, 4)
      ..close();
    c.drawPath(sand, PaintKit.solid(0xFFE0B860));
    for (final y in [-13.0, 11.0]) {
      final bar = ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(-10, y, 20, 2.6), const ui.Radius.circular(1.2));
      c.drawRRect(bar, PaintKit.lit(bar.outerRect, wood));
    }
  }

  static void _shout(ui.Canvas c) {
    c
      ..save()
      ..translate(-6, 12)
      ..scale(0.8);
    AnimalArt.draw(c,
        familyId: 'chicken',
        teamArgb: 0xFFE53935,
        pose: AnimalPose.idle);
    c.restore();
    final wave = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = ui.StrokeCap.round
      ..color = const ui.Color(0xFFFFC107);
    for (final r in [5.0, 9.0, 13.0]) {
      c.drawArc(ui.Rect.fromCircle(center: const ui.Offset(2, -9), radius: r),
          -0.7, 1.4, false, wave);
    }
  }

  static void _bricks(ui.Canvas c) {
    const brick = 0xFFA0522D;
    for (var row = 0; row < 4; row++) {
      final offset = row.isEven ? 0.0 : 4.0;
      for (var col = 0; col < 3; col++) {
        final rect = ui.Rect.fromLTWH(
            -12 + col * 8 + offset - (row.isEven ? 0 : 4), -10 + row * 5.5, 7.4, 4.8);
        if (rect.right > 13) continue;
        c
          ..drawRect(rect, PaintKit.lit(rect, brick))
          ..drawRect(rect, PaintKit.edge(brick, 0.5));
      }
    }
  }

  static void _horns(ui.Canvas c) {
    const horn = 0xFF9C8C74;
    for (final s in [-1.0, 1.0]) {
      final path = ui.Path()
        ..moveTo(s * 2, 8)
        ..quadraticBezierTo(s * 4, -8, s * 13, -10)
        ..quadraticBezierTo(s * 7, -4, s * 6, 9)
        ..close();
      _shaded(c, path, horn);
    }
    final dash = ui.Paint()
      ..color = const ui.Color(0xAAFFFFFF)
      ..strokeWidth = 1.4
      ..strokeCap = ui.StrokeCap.round;
    for (final y in [-2.0, 3.0, 8.0]) {
      c.drawLine(ui.Offset(-15, y), ui.Offset(-10, y), dash);
    }
  }
}
