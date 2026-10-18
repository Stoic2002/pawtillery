import 'package:flutter/material.dart';

import '../../app/field_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/field/paper.dart';

/// Shown while settings load at start-up: the journal's title page.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: PaperAtmosphere(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpacedTitle(l10n.appTitle, size: 34, spacing: 8),
              const SizedBox(height: 8),
              const LeafRule(),
              const SizedBox(height: 10),
              Text(
                l10n.splashLoading,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: FieldPalette.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
