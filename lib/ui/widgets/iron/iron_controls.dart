import 'package:flutter/material.dart';

import '../../../app/iron_palette.dart';
import '../../../game/art/animal_art.dart';
import '../../../l10n/app_localizations.dart';
import 'iron_button.dart';
import 'iron_icons.dart';
import 'iron_panel.dart';

/// A row of options on iron plates, the chosen one in [tone] with a
/// bright brass trim. Replaces Material's SegmentedButton everywhere.
class IronSegmented<T> extends StatelessWidget {
  const IronSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
    this.tone = IronTone.brass,
    this.wrap = false,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;
  final IronTone tone;

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
  final IronTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CustomPaint(
        painter: IronSlabPainter(
          tone: selected ? tone : IronTone.iron,
          depth: 2,
          outlineWidth: 1.2,
          gloss: false,
          border: selected ? IronPalette.brassLight : IronPalette.ironEdge,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 16,
                  color: selected ? tone.text : IronPalette.mute,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// An on/off switch: a dark slot with a metal knob, brass and moss when on.
class IronSwitch extends StatelessWidget {
  const IronSwitch({super.key, required this.value, required this.onChanged});

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
              width: 58,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? IronPalette.mossDeep : const Color(0xFF111215),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: value ? IronPalette.brass : IronPalette.ironEdge,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.4),
                      colors: value
                          ? const [IronPalette.brassLight, IronPalette.brassDeep]
                          : const [Color(0xFF6A6C72), Color(0xFF2E3036)],
                    ),
                    border: Border.all(color: IronPalette.ink),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A screen header: round back button, the engraved title, actions.
class IronHeader extends StatelessWidget {
  const IronHeader({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 4),
      child: Row(
        children: [
          IronRoundButton(
            glyph: IronGlyph.back,
            tooltip: l10n.back,
            tone: IronTone.steel,
            size: 46,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Flexible(child: IronRibbon(title, fontSize: 22)),
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

/// A picker sheet: ribbon title over a grid of [IronTile]s.
Future<T?> showIronPicker<T>({
  required BuildContext context,
  required String title,
  required List<Widget> Function(BuildContext) tiles,
  double maxWidth = 760,
}) => showIronDialog<T>(
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

/// A card in a picker or grid: an iron plate, brass-trimmed when selected.
class IronTile extends StatelessWidget {
  const IronTile({
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
  final IronTone? tone;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: onTap != null,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CustomPaint(
        painter: IronSlabPainter(
          tone: selected
              ? const IronTone(Color(0xFF3A3326), Color(0xFF1E1B15))
              : tone ?? IronTone.iron,
          depth: 3,
          outlineWidth: selected ? 2 : 1,
          gloss: selected,
          border: selected ? IronPalette.brassLight : IronPalette.ironEdge,
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
