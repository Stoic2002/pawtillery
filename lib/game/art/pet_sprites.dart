import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../config/families.dart';
import 'animal_art.dart';

/// The painted pets, one image per pose
/// (`assets/pets/<family>_<pose>.webp`, lined up by
/// tool/art/convert_art.py so that swapping them moves only the legs),
/// loaded once at start. A pet without them (and every pet in tests) keeps
/// the code-drawn look of [AnimalArt].
abstract final class PetSprites {
  static final Map<String, ui.Image> _images = {};

  static ui.Image? of(String? familyId, AnimalPose pose) =>
      familyId == null ? null : _images['${familyId}_${pose.name}'];

  static Future<void> load() async {
    await Future.wait([
      for (final f in Families.all)
        for (final pose in AnimalPose.values) _load('${f.id}_${pose.name}'),
    ]);
  }

  static Future<void> _load(String name) async {
    try {
      final data = await rootBundle.load('assets/pets/$name.webp');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      _images[name] = (await codec.getNextFrame()).image;
      codec.dispose();
    } on Object catch (e) {
      debugPrint('Pet art $name not loaded: $e');
    }
  }
}
