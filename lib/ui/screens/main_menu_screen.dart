import 'package:flutter/material.dart';

import '../../config/controls.dart';
import '../../l10n/app_localizations.dart';
import 'arena_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.appTitle,
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ArenaScreen(
                      teamCount: DevMatch.teamCount,
                      unitsPerTeam: DevMatch.unitsPerTeam,
                    ),
                  ),
                ),
                child: Text(l10n.menuPlay),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
