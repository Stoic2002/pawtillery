import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/paw_logo.dart';

/// Shown while settings load at start-up.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PawLogo(size: 96),
            const SizedBox(height: 12),
            Text(l10n.appTitle,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text(l10n.splashLoading),
          ],
        ),
      ),
    );
  }
}
