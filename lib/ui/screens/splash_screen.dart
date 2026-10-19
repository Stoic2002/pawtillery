import 'package:flutter/material.dart';

import '../../app/toon_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/toon/toon_backdrop.dart';
import '../widgets/toon/toon_logo.dart';

/// Shown while settings load at start-up: the meadow and the wordmark.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: ToonBackdrop(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(child: ToonLogo(title: l10n.appTitle, size: 56)),
              const SizedBox(height: 14),
              Text(
                l10n.splashLoading,
                style: const TextStyle(fontSize: 18, color: ToonPalette.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
