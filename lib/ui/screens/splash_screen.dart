import 'package:flutter/material.dart';

import '../../app/iron_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/iron/iron_backdrop.dart';
import '../widgets/iron/iron_logo.dart';

/// Shown while settings load at start-up: the meadow and the wordmark.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IronBackdrop(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(child: IronLogo(title: l10n.appTitle, size: 56)),
              const SizedBox(height: 14),
              Text(
                l10n.splashLoading,
                style: const TextStyle(fontSize: 18, color: IronPalette.parchment),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
