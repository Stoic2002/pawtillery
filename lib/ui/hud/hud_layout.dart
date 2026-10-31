import 'dart:convert';

import 'package:flutter/widgets.dart';

/// The parts of the match HUD a player can move and resize.
enum HudGroup { topLeft, topCentre, topRight, walk, actions }

/// Where a [HudGroup] was moved to from its corner, and its size.
class HudPlacement {
  const HudPlacement({this.offset = Offset.zero, this.scale = 1});

  final Offset offset;
  final double scale;

  static const double minScale = 0.6;
  static const double maxScale = 1.6;

  HudPlacement copyWith({Offset? offset, double? scale}) => HudPlacement(
    offset: offset ?? this.offset,
    scale: scale ?? this.scale,
  );
}

/// The player's HUD layout, kept as text in the settings. Anything missing or
/// unreadable is the default.
class HudLayout {
  const HudLayout(this.placements);

  final Map<HudGroup, HudPlacement> placements;

  static const standard = HudLayout({});

  HudPlacement of(HudGroup g) => placements[g] ?? const HudPlacement();

  HudLayout withPlacement(HudGroup g, HudPlacement p) =>
      HudLayout({...placements, g: p});

  String encode() => jsonEncode({
    for (final MapEntry(key: g, value: p) in placements.entries)
      g.name: [p.offset.dx, p.offset.dy, p.scale],
  });

  static HudLayout decode(String? text) {
    if (text == null) return standard;
    try {
      final map = jsonDecode(text) as Map<String, dynamic>;
      final names = HudGroup.values.asNameMap();
      return HudLayout({
        for (final MapEntry(:key, :value) in map.entries)
          if (names[key] case final HudGroup g)
            g: HudPlacement(
              offset: Offset(
                (value[0] as num).toDouble(),
                (value[1] as num).toDouble(),
              ),
              scale: (value[2] as num).toDouble().clamp(
                HudPlacement.minScale,
                HudPlacement.maxScale,
              ),
            ),
      });
    } on Object {
      return standard;
    }
  }
}
