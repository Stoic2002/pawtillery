import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/maps.dart';
import '../../sim/terrain_mask.dart';
import 'terrain_painter.dart';

/// Draws the terrain as a grid of chunk images. The sim's [TerrainMask] is
/// the source of truth; explosions only re-render the chunks they touch.
class TerrainComponent extends PositionComponent {
  TerrainComponent({
    required this.mask,
    required this.map,
  }) : super(size: Vector2(mask.width.toDouble(), mask.height.toDouble()));

  static const int chunkSize = 256;

  final TerrainMask mask;
  final MapDef map;

  late final int _cols = (mask.width + chunkSize - 1) ~/ chunkSize;
  late final int _rows = (mask.height + chunkSize - 1) ~/ chunkSize;
  late final List<ui.Image?> _chunks = List.filled(_cols * _rows, null);

  /// Per chunk: version of the latest full rebuild requested, and of the
  /// image currently shown. They differ while a rebuild is decoding.
  late final List<int> _wanted = List.filled(_cols * _rows, 0);
  late final List<int> _shown = List.filled(_cols * _rows, 0);

  // No edge antialiasing: under camera zoom it shows seams between chunks.
  final ui.Paint _paint = ui.Paint()
    ..filterQuality = ui.FilterQuality.none
    ..isAntiAlias = false;
  final ui.Paint _clearPaint = ui.Paint()..blendMode = ui.BlendMode.clear;

  @override
  Future<void> onLoad() async {
    await Future.wait([
      for (var row = 0; row < _rows; row++)
        for (var col = 0; col < _cols; col++) _buildChunk(col, row),
    ]);
  }

  /// Redraws a chunk from the mask. The old image stays on screen until the
  /// new one has decoded; a newer request supersedes an older one.
  Future<void> _buildChunk(int col, int row) async {
    final index = row * _cols + col;
    final version = ++_wanted[index];
    final x0 = col * chunkSize;
    final y0 = row * chunkSize;
    final w = (mask.width - x0).clamp(0, chunkSize);
    final h = (mask.height - y0).clamp(0, chunkSize);
    final pixels = buildChunkPixels(mask, map, x0, y0, w, h);
    ui.Image? image;
    if (pixels != null) {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
          pixels, w, h, ui.PixelFormat.rgba8888, completer.complete);
      image = await completer.future;
    }
    if (version != _wanted[index] || isRemoved) {
      image?.dispose();
      return;
    }
    _chunks[index]?.dispose();
    _chunks[index] = image;
    _shown[index] = version;
  }

  /// Ground was added (Benteng): redraw the touched chunks from the mask.
  void rebuild(IntRect area) {
    for (var row = area.top ~/ chunkSize;
        row <= (area.bottom - 1) ~/ chunkSize;
        row++) {
      for (var col = area.left ~/ chunkSize;
          col <= (area.right - 1) ~/ chunkSize;
          col++) {
        _buildChunk(col, row);
      }
    }
  }

  /// Punches a hole in the chunk images matching a mask carve at (cx, cy).
  /// Only chunks overlapping the circle are re-rendered. `toImageSync`
  /// returns at once and rasterises on the GPU thread, so the old image is
  /// never shown half-updated.
  void carve(int cx, int cy, int radius) {
    final c0 = ((cx - radius) ~/ chunkSize).clamp(0, _cols - 1);
    final c1 = ((cx + radius) ~/ chunkSize).clamp(0, _cols - 1);
    final r0 = ((cy - radius) ~/ chunkSize).clamp(0, _rows - 1);
    final r1 = ((cy + radius) ~/ chunkSize).clamp(0, _rows - 1);
    // Mask pixel (x, y) covers [x, x+1); match its centre and extent.
    final centerX = cx + 0.5;
    final centerY = cy + 0.5;
    final r = radius + 0.5;

    for (var row = r0; row <= r1; row++) {
      for (var col = c0; col <= c1; col++) {
        final index = row * _cols + col;
        if (_wanted[index] != _shown[index]) {
          // A rebuild is still decoding from an older mask; redo it.
          _buildChunk(col, row);
          continue;
        }
        final old = _chunks[index];
        if (old == null) continue;
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder)
          ..drawImage(old, ui.Offset.zero, _paint)
          ..drawCircle(
            ui.Offset(centerX - col * chunkSize, centerY - row * chunkSize),
            r,
            _clearPaint,
          );
        final picture = recorder.endRecording();
        _chunks[index] = picture.toImageSync(old.width, old.height);
        picture.dispose();
        old.dispose();
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    for (var row = 0; row < _rows; row++) {
      for (var col = 0; col < _cols; col++) {
        final image = _chunks[row * _cols + col];
        if (image == null) continue;
        canvas.drawImage(
          image,
          ui.Offset((col * chunkSize).toDouble(), (row * chunkSize).toDouble()),
          _paint,
        );
      }
    }
  }

  @override
  void onRemove() {
    for (final image in _chunks) {
      image?.dispose();
    }
    _chunks.fillRange(0, _chunks.length, null);
    super.onRemove();
  }
}
