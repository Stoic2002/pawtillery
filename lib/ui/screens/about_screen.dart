import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_info.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/paw_logo.dart';

/// About (PRD: versi, kredit aset, tautan kebijakan privasi). Credits come
/// straight from assets/CREDITS.md so they never drift from the file.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuAbout)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const PawLogo(size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.appTitle, style: text.headlineSmall),
                    Text(l10n.aboutVersion(AppInfo.version)),
                    const SizedBox(height: 4),
                    Text(l10n.aboutDescription),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.aboutPrivacy, style: text.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.aboutPrivacyNote),
          Row(
            children: [
              Flexible(child: SelectableText(AppInfo.privacyPolicyUrl)),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                      const ClipboardData(text: AppInfo.privacyPolicyUrl));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.aboutLinkCopied)));
                },
                icon: const Icon(Icons.copy, size: 18),
                label: Text(l10n.aboutCopyLink),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.aboutCredits, style: text.titleMedium),
          const SizedBox(height: 4),
          FutureBuilder<String>(
            future: DefaultAssetBundle.of(context)
                .loadString('assets/CREDITS.md'),
            builder: (context, snapshot) => SelectableText(
              snapshot.data ?? '',
              style: text.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
