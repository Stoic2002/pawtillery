// Renders the code-drawn launcher icon (tool/icon/app_icon_art.dart) to
// 1024 px PNG masters in build/icon:
//   fvm flutter test tool/icon/render_icon_test.dart
// then scales them into the Android and iOS icon sets:
//   sh tool/icon/make_icons.sh
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_icon_art.dart';

void main() {
  test('render icon masters', () async {
    Directory('build/icon').createSync(recursive: true);
    for (final layer in AppIconLayer.values) {
      const size = Size(1024, 1024);
      final recorder = ui.PictureRecorder();
      paintAppIcon(Canvas(recorder), size, layer: layer);
      final image = await recorder.endRecording().toImage(1024, 1024);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/icon/icon_${layer.name}.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
