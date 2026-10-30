import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
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
    this.materials,
    this.art,
    this.artScale = 1,
    this.visible,
  }) : super(size: Vector2(mask.width.toDouble(), mask.height.toDouble()));

  /// The painted map (straight RGBA), drawn instead of the materials.
  final Uint8List? art;

  /// The painting is this many times finer than the mask, and so are the
  /// chunk images (a world px is [artScale] image px each way).
  final int artScale;

  /// Image px per world px in the chunk images.
  int get _scale => art == null ? 1 : artScale;

  static const int chunkSize = 256;

  final TerrainMask mask;
  final MapDef map;

  /// The part of the world on screen; chunks outside it are not drawn.
  /// Null draws them all.
  final ui.Rect Function()? visible;

  /// Per-pixel [TerrainMaterial] index (render only).
  final Uint8List? materials;

  late final int _cols = (mask.width + chunkSize - 1) ~/ chunkSize;
  late final int _rows = (mask.height + chunkSize - 1) ~/ chunkSize;
  late final List<ui.Image?> _chunks = List.filled(_cols * _rows, null);

  /// Per chunk: version of the latest full rebuild requested, and of the
  /// image currently shown. They differ while a rebuild is decoding.
  late final List<int> _wanted = List.filled(_cols * _rows, 0);
  late final List<int> _shown = List.filled(_cols * _rows, 0);

  /// Each chunk image carries a [gutter] of the neighbouring pixels on
  /// every side. Drawn with bilinear filtering from the inner rect, the
  /// filter samples real neighbours across chunk borders, so zoomed
  /// terrain is smooth without seams.
  static const int gutter = 2;

  final ui.Paint _paint = ui.Paint()
    ..filterQuality = ui.FilterQuality.low
    ..isAntiAlias = false;
  final ui.Paint _copy = ui.Paint()..filterQuality = ui.FilterQuality.none;
  final ui.Paint _clearPaint = ui.Paint()..blendMode = ui.BlendMode.clear;

  /// Crater edge in the terrain's cartoon style: a dark outline right at
  /// the cut and a burnt band behind it, painted only onto remaining ground
  /// (srcATop), so it never darkens the sky.
  final ui.Paint _scorch = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..color = const ui.Color(0xE62A1A12)
    ..blendMode = ui.BlendMode.srcATop;
  final ui.Paint _scorchSoft = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 10
    ..color = const ui.Color(0x47201208)
    ..blendMode = ui.BlendMode.srcATop;

  @override
  Future<void> onLoad() async {
    // One at a time, so frames (the loading screen) get in between.
    for (var row = 0; row < _rows; row++) {
      for (var col = 0; col < _cols; col++) {
        await _buildChunk(col, row);
      }
    }
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
    const g = gutter;
    final painted = art;
    final s = _scale;
    final pixels = painted != null
        ? buildArtChunkPixels(
            mask,
            map,
            painted,
            x0 - g,
            y0 - g,
            w + 2 * g,
            h + 2 * g,
            scale: s,
          )
        : buildChunkPixels(
            mask,
            map,
            materials,
            x0 - g,
            y0 - g,
            w + 2 * g,
            h + 2 * g,
          );
    ui.Image? image;
    if (pixels != null) {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        pixels,
        (w + 2 * g) * s,
        (h + 2 * g) * s,
        ui.PixelFormat.rgba8888,
        completer.complete,
      );
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

  /// Ground was added (Benteng): redraw the touched chunks from the mask,
  /// drawing the new ground as [material].
  void rebuild(IntRect area, {TerrainMaterial material = TerrainMaterial.stone}) {
    final m = materials;
    if (m != null) {
      for (var y = area.top; y < area.bottom; y++) {
        m.fillRange(y * mask.width + area.left, y * mask.width + area.right,
            material.index);
      }
    }
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
  void carve(int cx, int cy, int radius, {bool scorch = true}) {
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
        _queue(col, row, (c, origin) {
          final local = ui.Offset(centerX, centerY) + origin;
          c.drawCircle(local, r, _clearPaint);
          if (scorch) {
            c
              ..drawCircle(local, r + 5, _scorchSoft)
              ..drawCircle(local, r + 1.2, _scorch);
          }
        });
      }
    }
  }

  /// Edits waiting for [flush], per chunk index. Each gets the chunk's
  /// canvas and the offset from world to chunk-image coordinates.
  final Map<int, List<void Function(ui.Canvas c, ui.Offset origin)>> _pending =
      {};

  void _queue(int col, int row, void Function(ui.Canvas, ui.Offset) edit) {
    final index = row * _cols + col;
    if (_wanted[index] != _shown[index]) {
      // A rebuild is still decoding from an older mask; redo it (the mask
      // already has this edit).
      _buildChunk(col, row);
      return;
    }
    (_pending[index] ??= []).add(edit);
  }

  /// Applies the queued edits: each touched chunk is re-drawn once, however
  /// many blasts, tunnel steps or beams hit it this frame (a cluster bomb
  /// or digging no longer re-renders the same chunk several times).
  void flush() {
    if (_pending.isEmpty) return;
    for (final MapEntry(key: index, value: edits) in _pending.entries) {
      if (_wanted[index] != _shown[index]) {
        _buildChunk(index % _cols, index ~/ _cols);
        continue;
      }
      final old = _chunks[index];
      if (old == null) continue;
      final origin = ui.Offset(
        -(index % _cols) * chunkSize + gutter.toDouble(),
        -(index ~/ _cols) * chunkSize + gutter.toDouble(),
      );
      final recorder = ui.PictureRecorder();
      final c = ui.Canvas(recorder)
        ..drawImage(old, ui.Offset.zero, _copy)
        // Edits are in world px.
        ..scale(_scale.toDouble());
      for (final edit in edits) {
        edit(c, origin);
      }
      final picture = recorder.endRecording();
      _chunks[index] = picture.toImageSync(old.width, old.height);
      picture.dispose();
      old.dispose();
    }
    _pending.clear();
  }

  /// Burns a straight tunnel [radius] wide from (x0, y0) to (x1, y1)
  /// (laser), one stroke per touched chunk, with a thin scorched rim.
  void carveLine(double x0, double y0, double x1, double y1, int radius) {
    final pad = radius + 2;
    final c0 = ((math.min(x0, x1) - pad) ~/ chunkSize).clamp(0, _cols - 1);
    final c1 = ((math.max(x0, x1) + pad) ~/ chunkSize).clamp(0, _cols - 1);
    final r0 = ((math.min(y0, y1) - pad) ~/ chunkSize).clamp(0, _rows - 1);
    final r1 = ((math.max(y0, y1) + pad) ~/ chunkSize).clamp(0, _rows - 1);
    final width = (radius + 0.5) * 2;
    final clear = ui.Paint()
      ..blendMode = ui.BlendMode.clear
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round
      ..strokeWidth = width;
    final scorch = ui.Paint()
      ..blendMode = ui.BlendMode.srcATop
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round
      ..strokeWidth = width + 3
      ..color = const ui.Color(0x99301A10);
    const half = ui.Offset(0.5, 0.5);
    final a = ui.Offset(x0, y0) + half;
    final b = ui.Offset(x1, y1) + half;
    for (var row = r0; row <= r1; row++) {
      for (var col = c0; col <= c1; col++) {
        _queue(col, row, (c, origin) {
          c
            ..drawLine(a + origin, b + origin, scorch)
            ..drawLine(a + origin, b + origin, clear);
        });
      }
    }
  }

  /// Colours of the ground around a crater just carved at (cx, cy), for
  /// the debris: samples the rim (still solid) and maps each material to
  /// its paint colour; the cap colour when a sample is near the top.
  List<int> debrisColors(int cx, int cy, int radius) {
    final colors = <int>{};
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * 6.2832;
      final x = cx + ((radius + 3) * math.cos(a)).round();
      final y = cy + ((radius + 3) * math.sin(a)).round();
      if (!mask.isSolid(x, y)) continue;
      // A painted map: the painting's own colour there.
      if (art case final a?) {
        final i = ((y * mask.width * artScale + x) * artScale) * 4;
        if (a[i + 3] >= 128) {
          colors.add(0xFF000000 | a[i] << 16 | a[i + 1] << 8 | a[i + 2]);
          continue;
        }
      }
      if (!mask.isSolid(x, y - map.grassThickness)) colors.add(map.grassArgb);
      final m = materials?[y * mask.width + x];
      colors.add(materialColor(m == null ? map.baseMaterial : TerrainMaterial.values[m]));
    }
    // Lit like the terrain they came from.
    final light = ui.Color(map.ambientArgb);
    int lit(int argb) {
      final c = ui.Color(argb);
      return ui.Color.from(
        alpha: 1,
        red: c.r * light.r,
        green: c.g * light.g,
        blue: c.b * light.b,
      ).toARGB32();
    }

    return [for (final c in colors.isEmpty ? {map.dirtArgb} : colors) lit(c)];
  }

  int materialColor(TerrainMaterial m) => switch (m) {
    TerrainMaterial.soil ||
    TerrainMaterial.rock ||
    TerrainMaterial.concrete => map.dirtArgb,
    TerrainMaterial.wood => 0xFF8C5E3A,
    TerrainMaterial.leaves => 0xFF3E9B3A,
    TerrainMaterial.stone => 0xFFA6A096,
    TerrainMaterial.metal => 0xFF5C6E80,
    TerrainMaterial.crate => 0xFFB68652,
    TerrainMaterial.hay => 0xFFF2C24A,
    TerrainMaterial.roof => 0xFF8E4036,
    TerrainMaterial.sand => 0xFFEED392,
    TerrainMaterial.ice => 0xFF9EDEF2,
    TerrainMaterial.snow => 0xFFF2F8FF,
    TerrainMaterial.toy => 0xFFD94A45,
    TerrainMaterial.can => 0xFFA9B0B9,
  };

  @override
  void render(ui.Canvas canvas) {
    final view = visible?.call();
    for (var row = 0; row < _rows; row++) {
      for (var col = 0; col < _cols; col++) {
        final image = _chunks[row * _cols + col];
        if (image == null) continue;
        final s = _scale;
        final g = (gutter * s).toDouble();
        final w = image.width - 2 * g;
        final h = image.height - 2 * g;
        final dst = ui.Rect.fromLTWH(
          (col * chunkSize).toDouble(),
          (row * chunkSize).toDouble(),
          w / s,
          h / s,
        );
        if (view != null && !view.overlaps(dst)) continue;
        canvas.drawImageRect(
          image,
          ui.Rect.fromLTWH(g, g, w, h),
          dst,
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
