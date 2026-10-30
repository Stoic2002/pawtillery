import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/match_config.dart';
import '../../../app/paw_palette.dart';
import '../../../config/maps.dart';
import '../../../config/teams.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_lookup.g.dart';
import 'paw_logo.dart';
import 'pet_figure.dart';

/// What shows while a match loads: the map's painting behind the logo, the
/// pets of this match hopping in a wave, the map's name, a bar and a tip.
class MatchLoading extends StatefulWidget {
  const MatchLoading({super.key, required this.map, required this.config});

  final MapDef map;
  final MatchConfig config;

  @override
  State<MatchLoading> createState() => _MatchLoadingState();
}

class _MatchLoadingState extends State<MatchLoading>
    with SingleTickerProviderStateMixin {
  /// Most pets shown, and the number of tips in the ARB files.
  static const int _maxPets = 6;
  static const int _tips = 6;

  /// The bar can't know how far along the load is: it eases towards the
  /// end, this many seconds to get most of the way there.
  static const double _barSeconds = 1.2;

  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1000),
  )..forward();
  final int _tip = math.Random().nextInt(_tips) + 1;

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final background = widget.map.backgroundAsset;
    final pets = [
      for (final team in widget.config.teams)
        for (final unit in team.units)
          (unit.familyId, Teams.styles[team.styleIndex].colorArgb),
    ].take(_maxPets).toList();
    return ColoredBox(
      color: Paw.ink,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (background != null)
            Image.asset(background, fit: BoxFit.cover, gaplessPlayback: true),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x552B2118), Color(0xCC2B2118)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PawLogo(title: l10n.appTitle, size: 54),
                            const SizedBox(height: 10),
                            Text(
                              l10n.byKey(widget.map.nameKey),
                              style: Paw.title(24, color: Paw.cream),
                            ),
                            const SizedBox(height: 14),
                            AnimatedBuilder(
                              animation: _clock,
                              builder: (context, _) => _hoppingPets(pets),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _clock,
                    builder: (context, _) => _bar(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.byKey('loadingTip$_tip'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: Paw.text(13, color: Paw.cream),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double get _seconds =>
      _clock.value * _clock.duration!.inMilliseconds / 1000;

  Widget _hoppingPets(List<(String, int)> pets) => SizedBox(
    height: 92,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, (family, argb)) in pets.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _hop(i, family, argb),
          ),
      ],
    ),
  );

  /// One pet in the wave: up and down, squashed a little as it lands.
  Widget _hop(int i, String family, int argb) {
    final wave = math.sin(_seconds * 5 - i * 0.7);
    final up = wave > 0 ? wave : 0.0;
    final land = wave > 0 ? 0.0 : -wave;
    return Transform.translate(
      offset: Offset(0, -up * 22),
      child: Transform.scale(
        alignment: Alignment.bottomCenter,
        scaleX: 1 + land * 0.06,
        scaleY: 1 - land * 0.08,
        child: PetFigure(familyId: family, teamArgb: argb, size: 58),
      ),
    );
  }

  Widget _bar() {
    final done = 1 - math.exp(-_seconds / _barSeconds);
    return Container(
      width: 280,
      height: 16,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Paw.cream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Paw.ink, width: 2.5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: done * 0.97,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Paw.orange,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
