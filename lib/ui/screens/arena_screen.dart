import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../game/pawtillery_game.dart';
import '../../l10n/app_localizations.dart';
import '../hud/arena_hud.dart';

/// Hosts the Flame game. HUD lives here as Flutter widgets on top of it.
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  late final PawtilleryGame _game = PawtilleryGame(seed: 1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(
            game: _game,
            loadingBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
          ),
          FutureBuilder<void>(
            future: _game.loaded,
            builder: (context, snapshot) =>
                snapshot.connectionState == ConnectionState.done
                    ? ArenaHud(game: _game)
                    : const SizedBox.shrink(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: l10n.back,
                    iconSize: 28,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.arenaPlaceholder,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
