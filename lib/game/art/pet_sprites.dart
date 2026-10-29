import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../config/families.dart';

/// The painted pets (`assets/pets/<family>.webp`, cut out by
/// tool/art/convert_art.py), loaded once at start. A family without one
/// (and every pet in tests) keeps the code-drawn look of [AnimalArt].
abstract final class PetSprites {
  static final Map<String, ui.Image> _images = {};

  static ui.Image? of(String? familyId) =>
      familyId == null ? null : _images[familyId];

  static Future<void> load() async {
    await Future.wait([
      for (final f in Families.all) _load(f.id),
    ]);
  }

  static Future<void> _load(String family) async {
    try {
      final data = await rootBundle.load('assets/pets/$family.webp');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      _images[family] = (await codec.getNextFrame()).image;
      codec.dispose();
    } on Object catch (e) {
      debugPrint('Pet art for $family not loaded: $e');
    }
  }
}
