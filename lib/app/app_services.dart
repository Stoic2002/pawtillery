import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../services/audio_service.dart';
import '../services/settings_store.dart';

/// Makes app-wide services reachable from any screen.
class AppServices extends InheritedWidget {
  const AppServices({
    super.key,
    required this.settings,
    required this.audio,
    required super.child,
  });

  final SettingsStore settings;
  final AudioService audio;

  static AppServices of(BuildContext context) {
    final services =
        context.dependOnInheritedWidgetOfExactType<AppServices>();
    assert(services != null, 'No AppServices above this context');
    return services!;
  }

  @override
  bool updateShouldNotify(AppServices old) =>
      settings != old.settings || audio != old.audio;
}

/// Names the Random button picks from, for the current language.
List<String> unitNamePool(AppLocalizations l10n) => [
      for (final n in l10n.unitNamePool.split(','))
        if (n.trim().isNotEmpty) n.trim(),
    ];
