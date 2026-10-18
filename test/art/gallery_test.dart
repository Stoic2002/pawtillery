import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/breeds.dart';
import 'package:pawtillery/config/families.dart';
import 'dart:async';

import 'package:flame/components.dart';
import 'package:pawtillery/config/maps.dart';
import 'package:pawtillery/config/weapons.dart';
import 'package:pawtillery/game/components/backdrop_components.dart';
import 'package:pawtillery/game/components/decor_component.dart';
import 'package:pawtillery/game/components/scenery_component.dart';
import 'package:pawtillery/game/components/terrain_painter.dart';
import 'package:pawtillery/game/map_loader.dart';
import 'package:pawtillery/game/art/animal_art.dart';
import 'package:pawtillery/game/art/weapon_art.dart';

/// Renders every breed in every pose. Always checks the painters don't
/// throw; with RENDER_GALLERY=1 it also writes build/gallery/*.png for
/// eyeballing the art.
void main() {
  final write = Platform.environment['RENDER_GALLERY'] == '1';

  Future<void> save(ui.Picture picture, int w, int h, String name) async {
    final image = await picture.toImage(w, h);
    if (write) {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/gallery/$name.png')..createSync(recursive: true);
      file.writeAsBytesSync(png!.buffer.asUint8List());
    }
    image.dispose();
  }

  testWidgets('animals: every breed, every pose', (tester) async {
    const cell = 84.0;
    const zoom = 2.0;
    final breedsByFamily = {
      for (final f in Families.all) f.id: Breeds.ofFamily(f.id),
    };
    final cols = 8;
    final rows = Families.all.length;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..drawRect(ui.Rect.fromLTWH(0, 0, cols * cell, rows * cell),
          ui.Paint()..color = const ui.Color(0xFFBFE1F2));
    for (var r = 0; r < rows; r++) {
      final family = Families.all[r];
      final breeds = breedsByFamily[family.id]!;
      for (var c = 0; c < cols; c++) {
        final breed = breeds[c % breeds.length];
        final pose = c < breeds.length
            ? AnimalPose.idle
            : AnimalPose.values[(c - breeds.length) % 4];
        canvas
          ..save()
          ..translate(c * cell + cell / 2, r * cell + cell * 0.82)
          ..scale(zoom)
          ..drawRect(const ui.Rect.fromLTWH(-20, 0, 40, 3),
              ui.Paint()..color = const ui.Color(0xFF6E8B4A));
        AnimalArt.draw(canvas,
            familyId: family.id,
            breedId: breed.id,
            teamArgb: r.isEven ? 0xFFE53935 : 0xFF1E88E5,
            pose: pose);
        canvas.restore();
      }
    }
    await tester.runAsync(() => save(recorder.endRecording(),
        (cols * cell).round(), (rows * cell).round(), 'animals'));
  });

  testWidgets('weapons: icons and projectiles', (tester) async {
    const cell = 80.0;
    final menu = Weapons.all.where((w) => !w.hidden).toList();
    final cols = 9;
    final rows = 4;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..drawRect(ui.Rect.fromLTWH(0, 0, cols * cell, rows * cell),
          ui.Paint()..color = const ui.Color(0xFF2B3440));
    for (var i = 0; i < menu.length; i++) {
      final x = (i % cols) * cell + cell / 2;
      final y = (i ~/ cols) * cell + cell / 2;
      canvas
        ..save()
        ..translate(x, y);
      WeaponArt.icon(canvas, menu[i].id, 56);
      canvas.restore();
    }
    final flying = [
      for (final w in Weapons.all)
        if (w.flight != null) w.id,
    ];
    for (var i = 0; i < flying.length; i++) {
      final x = (i % cols) * cell + cell / 2;
      final y = (2 + i ~/ cols) * cell + cell / 2;
      canvas
        ..save()
        ..translate(x, y)
        ..scale(3);
      WeaponArt.projectile(canvas, flying[i]);
      canvas.restore();
    }
    canvas
      ..save()
      ..translate(cols * cell - cell / 2, rows * cell - cell / 3)
      ..scale(3);
    WeaponArt.mine(canvas, small: false);
    canvas.restore();
    await tester.runAsync(() => save(recorder.endRecording(),
        (cols * cell).round(), (rows * cell).round(), 'weapons'));
  });

  testWidgets('maps: scenery, terrain, decorations, water', (tester) async {
    for (final map in Maps.all) {
      await tester.runAsync(() async {
        final data = await loadMapData(map.maskAsset);
        final mask = data.mask;
        final size = Vector2(mask.width.toDouble(), mask.height.toDouble());
        final pixels = buildChunkPixels(
            mask, map, data.materials, 0, 0, mask.width, mask.height)!;
        final done = Completer<ui.Image>();
        ui.decodeImageFromPixels(pixels, mask.width, mask.height,
            ui.PixelFormat.rgba8888, done.complete);
        final terrain = await done.future;
        final decor = DecorComponent(mask: mask, map: map);
        await decor.onLoad();
        const scale = 0.4;
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder)..scale(scale);
        SkyComponent(map: map, worldSize: size).render(canvas);
        SceneryComponent(
          map: map,
          worldSize: size,
          cameraPosition: () => size / 2,
        ).render(canvas);
        canvas.drawImage(terrain, ui.Offset.zero, ui.Paint());
        decor.render(canvas);
        WaterComponent(map: map, worldSize: size, level: () => map.waterLevel)
            .render(canvas);
        await save(recorder.endRecording(), (size.x * scale).round(),
            (size.y * scale).round(), 'map_${map.id}');
        terrain.dispose();
      });
    }
  });
}
