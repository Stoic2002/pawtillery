import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/field_palette.dart';
import '../../config/app_info.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/field/paper.dart';
import '../widgets/field/stamp.dart';
import '../widgets/field/catalogue.dart';

/// About (PRD: versi, kredit aset, tautan kebijakan privasi), set like a
/// book's colophon. Credits come straight from assets/CREDITS.md.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const caption = TextStyle(
      fontStyle: FontStyle.italic,
      color: FieldPalette.inkSoft,
    );
    return Scaffold(
      body: PaperAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              PageHeader(title: l10n.menuAbout),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 56,
                    vertical: 8,
                  ),
                  children: [
                    Center(
                      child: SpacedTitle(l10n.appTitle, size: 28, spacing: 7),
                    ),
                    Center(
                      child: Text(
                        l10n.aboutVersion(AppInfo.version),
                        style: caption,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        l10n.aboutDescription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(child: LeafRule()),
                    const SizedBox(height: 14),
                    SpacedTitle(l10n.aboutPrivacy, size: 14, spacing: 3),
                    const SizedBox(height: 4),
                    Text(l10n.aboutPrivacyNote, style: caption),
                    Row(
                      children: [
                        const Flexible(
                          child: SelectableText(AppInfo.privacyPolicyUrl),
                        ),
                        const SizedBox(width: 12),
                        InkButton(
                          label: l10n.aboutCopyLink,
                          minWidth: 0,
                          onPressed: () async {
                            await Clipboard.setData(
                              const ClipboardData(
                                text: AppInfo.privacyPolicyUrl,
                              ),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.aboutLinkCopied)),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SpacedTitle(l10n.aboutCredits, size: 14, spacing: 3),
                    const SizedBox(height: 6),
                    FutureBuilder<String>(
                      future: DefaultAssetBundle.of(
                        context,
                      ).loadString('assets/CREDITS.md'),
                      builder: (context, snapshot) => PaperPanel(
                        color: FieldPalette.paperShade,
                        child: SelectableText(
                          snapshot.data ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: FieldPalette.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
