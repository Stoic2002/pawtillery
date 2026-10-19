import 'package:flutter/material.dart';

import '../../app/paw_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/paw/paw_backdrop.dart';
import '../widgets/paw/paw_logo.dart';

/// Shown while settings load at start-up: the wordmark over the hills and
/// a loading bar.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: PawBackdrop(
        hills: PawHills.splash,
        clouds: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(child: PawLogo(title: l10n.appTitle, size: 76)),
              const SizedBox(height: 28),
              Semantics(
                label: l10n.splashLoading,
                child: Container(
                  width: 240,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Paw.cream,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Paw.ink, width: 3),
                    boxShadow: Paw.drop(),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Container(color: Paw.orange),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
