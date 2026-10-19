import 'package:flutter/material.dart';

import '../../../app/toon_palette.dart';
import '../../../game/art/animal_art.dart';
import '../../../l10n/app_localizations.dart';
import 'toon_button.dart';
import 'toon_icons.dart';
import 'toon_panel.dart';
import 'toon_text.dart';

/// A row of chunky options, the chosen one raised in [tone]. Replaces
/// Material's SegmentedButton everywhere.
class ToonSegmented<T> extends StatelessWidget {
  const ToonSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
    this.tone = ToonTone.sky,
    this.wrap = false,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;
  final ToonTone tone;

  /// Wrap onto several lines instead of one row (long labels).
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final v in values)
        _Chip(
          label: label(v),
          selected: v == selected,
          tone: tone,
          onTap: () => onSelect(v),
        ),
    ];
    return wrap
        ? Wrap(spacing: 6, runSpacing: 6, children: chips)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, c) in chips.indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                c,
              ],
            ],
          );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.tone,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ToonTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CustomPaint(
        painter: ToonSlabPainter(
          tone: selected ? tone : ToonTone.cream,
          radius: 12,
          depth: selected ? 4 : 3,
          outlineWidth: 2.5,
          gloss: selected,
          pressed: false,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 46, minHeight: 46),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, selected ? 4 : 3),
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: selected
                  ? ToonText(label, size: 17, maxLines: 1)
                  : Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 17,
                        color: ToonPalette.bark,
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// An on/off switch: a pill track with a round knob, green when on.
class ToonSwitch extends StatelessWidget {
  const ToonSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      toggled: value,
      label: l10n.settingsOn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: 76,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 68,
              height: 36,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? ToonPalette.leafDeep : ToonPalette.creamDeep,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ToonPalette.outline, width: 3),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutBack,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: value ? ToonPalette.leaf : ToonPalette.cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: ToonPalette.outline, width: 2.5),
                  ),
                  child: value
                      ? const Center(
                          child: ToonIcon(ToonGlyph.check, size: 16),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A screen header: round back button, the title on a ribbon, actions.
class ToonHeader extends StatelessWidget {
  const ToonHeader({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 4),
      child: Row(
        children: [
          ToonRoundButton(
            glyph: ToonGlyph.back,
            tooltip: l10n.back,
            tone: ToonTone.sky,
            size: 46,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Flexible(child: ToonRibbon(title, fontSize: 22)),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

/// An animal drawn in colour at a given size.
class AnimalFigure extends StatelessWidget {
  const AnimalFigure({
    super.key,
    required this.familyId,
    required this.breedId,
    this.teamArgb = 0xFF2F86E0,
    this.size = 64,
    this.facing = 1,
    this.pose = AnimalPose.idle,
  });

  final String? familyId;
  final String? breedId;
  final int teamArgb;
  final double size;
  final int facing;
  final AnimalPose pose;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _FigurePainter(this)),
  );
}

class _FigurePainter extends CustomPainter {
  _FigurePainter(this.f);
  final AnimalFigure f;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 42;
    canvas
      ..save()
      ..translate(size.width / 2, size.height * 0.92)
      ..scale(s * f.facing, s);
    AnimalArt.draw(
      canvas,
      familyId: f.familyId,
      breedId: f.breedId,
      teamArgb: f.teamArgb,
      pose: f.pose,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.f.familyId != f.familyId ||
      old.f.breedId != f.breedId ||
      old.f.teamArgb != f.teamArgb ||
      old.f.facing != f.facing ||
      old.f.pose != f.pose;
}

/// A picker sheet: ribbon title over a grid of [ToonTile]s.
Future<T?> showToonPicker<T>({
  required BuildContext context,
  required String title,
  required List<Widget> Function(BuildContext) tiles,
  double maxWidth = 760,
}) => showToonDialog<T>(
  context: context,
  title: title,
  maxWidth: maxWidth,
  builder: (context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height - 120,
    ),
    child: SingleChildScrollView(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: tiles(context),
      ),
    ),
  ),
);

/// A card in a picker or grid: cream slab, sun-yellow when selected.
class ToonTile extends StatelessWidget {
  const ToonTile({
    super.key,
    required this.child,
    required this.selected,
    required this.onTap,
    this.width = 116,
    this.tone,
  });

  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final double width;

  /// Overrides the unselected colour (e.g. a "special" card).
  final ToonTone? tone;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: onTap != null,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CustomPaint(
        painter: ToonSlabPainter(
          tone: selected
              ? ToonTone.sun
              : tone ?? const ToonTone(Color(0xFFFFFBF0), ToonPalette.creamShade),
          radius: 14,
          depth: 4,
          outlineWidth: selected ? 3.5 : 2.5,
          gloss: false,
        ),
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
            child: child,
          ),
        ),
      ),
    ),
  );
}
