import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../config/sandbox.dart';
import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';

/// M1 test-bench HUD: wind, angle/power fine controls and the fire button.
/// Kept to the screen edges so the middle of the map stays clear.
class ArenaHud extends StatelessWidget {
  const ArenaHud({super.key, required this.game});

  final PawtilleryGame game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ValueListenableBuilder<int>(
                valueListenable: game.wind,
                builder: (context, wind, _) => _WindIndicator(wind: wind),
              ),
            ),
            if (kDebugMode || kProfileMode)
              Align(
                alignment: Alignment.topRight,
                child: ValueListenableBuilder<ExplosionTiming?>(
                  valueListenable: game.explosionTiming,
                  builder: (context, t, _) => t == null
                      ? const SizedBox.shrink()
                      : _Chip(
                          text: l10n.debugExplosionTime(
                            t.lastMs.toStringAsFixed(2),
                            t.maxMs.toStringAsFixed(2),
                          ),
                        ),
                ),
              ),
            Align(
              alignment: Alignment.bottomLeft,
              child: _Chip(text: l10n.hudTapHint),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: _AimControls(game: game),
            ),
          ],
        ),
      ),
    );
  }
}

class _AimControls extends StatelessWidget {
  const _AimControls({required this.game});

  final PawtilleryGame game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: game.angle,
              builder: (context, angle, _) => _Stepper(
                label: l10n.hudAngle(angle),
                onMinus: () => game.adjustAngle(-ControlsConfig.angleStep),
                onPlus: () => game.adjustAngle(ControlsConfig.angleStep),
              ),
            ),
            const SizedBox(height: 4),
            ValueListenableBuilder<int>(
              valueListenable: game.power,
              builder: (context, power, _) => _Stepper(
                label: l10n.hudPower(power),
                onMinus: () => game.adjustPower(-ControlsConfig.powerStep),
                onPlus: () => game.adjustPower(ControlsConfig.powerStep),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        ValueListenableBuilder<bool>(
          valueListenable: game.inFlight,
          builder: (context, inFlight, _) => FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 96),
              shape: const CircleBorder(),
            ),
            onPressed: inFlight ? null : game.fire,
            child: Text(l10n.hudFire, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: l10n.hudDecrease,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: onMinus,
          icon: const Icon(Icons.remove),
        ),
        // Wide enough for the longer Indonesian label ("Kekuatan 100%").
        SizedBox(
          width: 132,
          child: _Chip(text: label, center: true),
        ),
        IconButton.filledTonal(
          tooltip: l10n.hudIncrease,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: onPlus,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _WindIndicator extends StatelessWidget {
  const _WindIndicator({required this.wind});

  final int wind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final icon = wind == 0
        ? Icons.remove
        : (wind > 0 ? Icons.arrow_forward : Icons.arrow_back);
    return DecoratedBox(
      decoration: _chipDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(l10n.hudWind(wind), style: _chipText),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _chipDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: _chipText,
          textAlign: center ? TextAlign.center : TextAlign.start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

const _chipDecoration = BoxDecoration(
  color: Color(0x99000000),
  borderRadius: BorderRadius.all(Radius.circular(8)),
);
const _chipText = TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
