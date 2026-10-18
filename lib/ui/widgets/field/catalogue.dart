import 'package:flutter/material.dart';

import '../../../app/field_palette.dart';
import '../../../l10n/app_localizations.dart';
import 'ink_icons.dart';
import 'paper.dart';

/// A page header: back mark, title in spaced capitals, actions.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.back,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const InkIcon(InkGlyph.back),
          ),
          const SizedBox(width: 6),
          Flexible(child: SpacedTitle(title, size: 18, spacing: 4)),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

/// A catalogue sheet: title, leaf rule, a wrap of plates.
class Catalogue extends StatelessWidget {
  const Catalogue({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpacedTitle(title, size: 16, spacing: 4),
            const SizedBox(height: 4),
            const LeafRule(width: 160),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CatalogueTile extends StatelessWidget {
  const CatalogueTile({
    super.key,
    required this.child,
    required this.selected,
    required this.onTap,
    this.width = 120,
  });

  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      width: width,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: selected ? FieldPalette.paperShade : null,
        border: Border.all(
          color: selected ? FieldPalette.ink : Colors.transparent,
        ),
      ),
      child: child,
    ),
  );
}
