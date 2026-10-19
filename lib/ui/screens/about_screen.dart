import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/toon_palette.dart';
import '../../config/app_info.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/toon/toon_backdrop.dart';
import '../widgets/toon/toon_button.dart';
import '../widgets/toon/toon_controls.dart';
import '../widgets/toon/toon_icons.dart';
import '../widgets/toon/toon_logo.dart';
import '../widgets/toon/toon_panel.dart';

/// About (PRD: versi, kredit aset, tautan kebijakan privasi). Credits come
/// straight from assets/CREDITS.md.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const soft = TextStyle(fontSize: 15, color: ToonPalette.bark);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 19)),
    );
    return Scaffold(
      body: ToonBackdrop(
        dim: 0.15,
        child: SafeArea(
          child: Column(
            children: [
              ToonHeader(title: l10n.menuAbout),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: ToonPanel(
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: FittedBox(
                                child: ToonLogo(title: l10n.appTitle, size: 36),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                l10n.aboutVersion(AppInfo.version),
                                style: soft,
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
                            heading(l10n.aboutPrivacy.toUpperCase()),
                            Text(l10n.aboutPrivacyNote, style: soft),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const SelectableText(
                                  AppInfo.privacyPolicyUrl,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: ToonPalette.skyDeep,
                                  ),
                                ),
                                ToonButton(
                                  label: l10n.aboutCopyLink,
                                  tone: ToonTone.sky,
                                  icon: ToonGlyph.check,
                                  fontSize: 14,
                                  height: 40,
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      const ClipboardData(
                                        text: AppInfo.privacyPolicyUrl,
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.aboutLinkCopied),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            heading(l10n.aboutCredits.toUpperCase()),
                            FutureBuilder<String>(
                              future: DefaultAssetBundle.of(
                                context,
                              ).loadString('assets/CREDITS.md'),
                              builder: (context, snapshot) => Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ToonPalette.creamShade,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: ToonPalette.creamDeep,
                                    width: 2,
                                  ),
                                ),
                                child: SelectableText(
                                  snapshot.data ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: ToonPalette.bark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
