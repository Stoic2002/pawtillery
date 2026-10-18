import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/field_palette.dart';
import '../../app/match_config.dart';
import '../../config/breeds.dart';
import '../../config/families.dart';
import '../../config/maps.dart';
import '../../config/match_defaults.dart';
import '../../config/teams.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../services/audio_service.dart';
import '../widgets/field/catalogue.dart';
import '../widgets/field/ink_icons.dart';
import '../widgets/field/paper.dart';
import '../widgets/field/plate.dart';
import '../widgets/field/stamp.dart';
import 'arena_screen.dart';

/// Match setup as a field roster (docs/art_style_guide.md): conditions on
/// the left, one index tab per team, one specimen entry per unit. The last
/// setup is restored on the next visit.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  MatchConfig? _config;

  /// Bumped when values change outside the text fields (Random), so the
  /// fields are rebuilt with the new text.
  int _revision = 0;
  final _rng = Random();

  List<String> get _pool => unitNamePool(AppLocalizations.of(context));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _config ??=
        AppServices.of(context).settings.lastMatch(_pool) ??
        MatchConfig.defaults(_pool);
  }

  void _update(MatchConfig c, {bool resetFields = false}) => setState(() {
    _config = c;
    if (resetFields) _revision++;
  });

  Future<void> _start() async {
    final config = _config!;
    AppServices.of(context).audio.play(Sfx.ui);
    await AppServices.of(context).settings.saveMatch(config);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ArenaScreen(config: config)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = _config!;
    return Scaffold(
      body: PaperAtmosphere(
        vignette: 0.35,
        child: SafeArea(
          child: Column(
            children: [
              PageHeader(
                title: l10n.setupTitle,
                actions: [
                  TextButton.icon(
                    onPressed: () {
                      AppServices.of(context).audio.play(Sfx.ui);
                      _update(
                        config.randomized(_rng, _pool),
                        resetFields: true,
                      );
                    },
                    icon: const InkIcon(InkGlyph.dice, size: 20),
                    label: Text(l10n.setupRandomAll),
                  ),
                  const SizedBox(width: 10),
                  StampButton(
                    label: l10n.setupStart,
                    minWidth: 110,
                    fontSize: 16,
                    onPressed: _start,
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 250,
                      child: _Conditions(
                        config: config,
                        onChanged: _update,
                        pool: _pool,
                      ),
                    ),
                    const _VerticalRule(),
                    Expanded(
                      child: _TeamsPanel(
                        key: ValueKey(config.teams.length),
                        config: config,
                        revision: _revision,
                        pool: _pool,
                        rng: _rng,
                        onChanged: _update,
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

class _VerticalRule extends StatelessWidget {
  const _VerticalRule();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Container(width: 1, color: FieldPalette.ink),
        const SizedBox(width: 2),
        Container(width: 0.5, color: FieldPalette.inkSoft),
      ],
    ),
  );
}

class _Conditions extends StatelessWidget {
  const _Conditions({
    required this.config,
    required this.onChanged,
    required this.pool,
  });

  final MatchConfig config;
  final void Function(MatchConfig) onChanged;
  final List<String> pool;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: FieldPalette.inkSoft,
        ),
      ),
    );
    Widget segments<T>(
      List<T> values,
      T selected,
      String Function(T) text,
      void Function(T) onSelect,
    ) => SegmentedButton<T>(
      showSelectedIcon: false,
      segments: [
        for (final v in values) ButtonSegment(value: v, label: Text(text(v))),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onSelect(s.first),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 14, 16),
      children: [
        SpacedTitle(
          l10n.setupConditions,
          size: 12,
          spacing: 3,
          color: FieldPalette.inkSoft,
        ),
        label(l10n.setupTeams),
        segments<int>(
          MatchDefaults.teamCountOptions,
          config.teams.length,
          (v) => '$v',
          (v) => onChanged(config.withTeamCount(v, pool)),
        ),
        label(l10n.setupUnitsPerTeam),
        segments<int>(
          MatchDefaults.unitsPerTeamOptions,
          config.unitsPerTeam,
          (v) => '$v',
          (v) => onChanged(config.withUnitsPerTeam(v, pool)),
        ),
        label(l10n.setupTurnTime),
        segments<int>(
          MatchDefaults.turnSecondsOptions,
          config.turnSeconds,
          (v) => l10n.hudSeconds(v),
          (v) => onChanged(config.copyWith(turnSeconds: v)),
        ),
        label(l10n.setupMap),
        _InkChoices<String>(
          values: [MatchConfig.randomMap, for (final m in Maps.all) m.id],
          selected: config.mapId,
          label: (id) => id == MatchConfig.randomMap
              ? l10n.setupMapRandom
              : l10n.byKey(Maps.byId(id).nameKey),
          onSelect: (id) => onChanged(config.copyWith(mapId: id)),
        ),
        label(l10n.setupSuddenDeath),
        _InkChoices<int>(
          values: [for (final m in MatchDefaults.suddenDeathOptions) m ?? 0],
          selected: config.suddenDeathMinutes ?? 0,
          label: (m) => m == 0 ? l10n.setupOff : l10n.setupMinutes(m),
          onSelect: (m) => onChanged(
            m == 0
                ? config.copyWith(suddenDeathOff: true)
                : config.copyWith(suddenDeathMinutes: m),
          ),
        ),
      ],
    );
  }
}

/// A list of options with inked circles, like a printed form.
class _InkChoices<T> extends StatelessWidget {
  const _InkChoices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final void Function(T) onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final v in values)
        InkWell(
          onTap: () => onSelect(v),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: FieldPalette.ink),
                  ),
                  alignment: Alignment.center,
                  child: v == selected
                      ? Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: FieldPalette.ink,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label(v),
                    style: TextStyle(
                      fontSize: 16,
                      color: v == selected
                          ? FieldPalette.ink
                          : FieldPalette.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _TeamsPanel extends StatelessWidget {
  const _TeamsPanel({
    super.key,
    required this.config,
    required this.revision,
    required this.pool,
    required this.rng,
    required this.onChanged,
  });

  final MatchConfig config;
  final int revision;
  final List<String> pool;
  final Random rng;
  final void Function(MatchConfig, {bool resetFields}) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String teamName(TeamEntry t) =>
        t.customName ?? l10n.byKey(Teams.styles[t.styleIndex].nameKey);

    return DefaultTabController(
      length: config.teams.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final t in config.teams)
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        color: Color(Teams.styles[t.styleIndex].colorArgb),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          teamName(t).toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (var i = 0; i < config.teams.length; i++)
                  _TeamEditor(
                    key: ValueKey('team$i-$revision'),
                    config: config,
                    index: i,
                    defaultName: l10n.byKey(
                      Teams.styles[config.teams[i].styleIndex].nameKey,
                    ),
                    pool: pool,
                    rng: rng,
                    onChanged: onChanged,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamEditor extends StatelessWidget {
  const _TeamEditor({
    super.key,
    required this.config,
    required this.index,
    required this.defaultName,
    required this.pool,
    required this.rng,
    required this.onChanged,
  });

  final MatchConfig config;
  final int index;
  final String defaultName;
  final List<String> pool;
  final Random rng;
  final void Function(MatchConfig, {bool resetFields}) onChanged;

  TeamEntry get team => config.teams[index];

  void _setUnit(int k, UnitEntry u, {bool resetFields = false}) => onChanged(
    config.withTeam(index, team.copyWith(units: [...team.units]..[k] = u)),
    resetFields: resetFields,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final teamArgb = Teams.styles[team.styleIndex].colorArgb;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        TextFormField(
          // Keyed by colour too: an empty name shows the colour's default
          // as a hint.
          key: ValueKey('name$index-${team.styleIndex}'),
          initialValue: team.customName ?? '',
          maxLength: 18,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: l10n.setupTeamName,
            hintText: defaultName,
            counterText: '',
          ),
          onChanged: (v) => onChanged(
            config.withTeam(
              index,
              v.trim().isEmpty
                  ? team.copyWith(clearName: true)
                  : team.copyWith(customName: v.trim()),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Team inks on their own wrapping row so narrow phones never
        // overflow.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                l10n.setupColor,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: FieldPalette.inkSoft,
                ),
              ),
            ),
            for (var s = 0; s < Teams.styles.length; s++)
              _InkSwatch(
                argb: Teams.styles[s].colorArgb,
                selected: s == team.styleIndex,
                onTap: () => onChanged(config.withTeamStyle(index, s)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var k = 0; k < team.units.length; k++)
          _SpecimenEntry(
            key: ValueKey('unit$index-$k'),
            number: k + 1,
            unit: team.units[k],
            teamArgb: teamArgb,
            onChanged: (u) => _setUnit(k, u),
            onRandom: () => _setUnit(
              k,
              MatchConfig.randomUnit(rng, pool),
              resetFields: true,
            ),
          ),
      ],
    );
  }
}

class _InkSwatch extends StatelessWidget {
  const _InkSwatch({
    required this.argb,
    required this.selected,
    required this.onTap,
  });

  final int argb;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox.square(
      dimension: 44,
      child: Center(
        child: Container(
          width: selected ? 28 : 22,
          height: selected ? 28 : 22,
          decoration: BoxDecoration(
            color: Color(argb),
            border: Border.all(
              color: selected ? FieldPalette.ink : FieldPalette.paper,
              width: selected ? 2.5 : 1,
            ),
          ),
        ),
      ),
    ),
  );
}

/// One unit as a specimen entry: number, portrait in a small frame, common
/// and Latin name, breed, and the unit's name written on a line. Tapping
/// the portrait or names opens the catalogue.
class _SpecimenEntry extends StatelessWidget {
  const _SpecimenEntry({
    super.key,
    required this.number,
    required this.unit,
    required this.teamArgb,
    required this.onChanged,
    required this.onRandom,
  });

  final int number;
  final UnitEntry unit;
  final int teamArgb;
  final ValueChanged<UnitEntry> onChanged;
  final VoidCallback onRandom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final family = Families.byId(unit.familyId);
    final breed = Breeds.byId(unit.breedId);
    Future<void> chooseFamily() async {
      final picked = await _pickFamily(context, unit.familyId);
      if (picked != null) onChanged(unit.copyWith(familyId: picked));
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FieldPalette.paperEdge)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$number.',
              style: const TextStyle(color: FieldPalette.inkSoft),
            ),
          ),
          InkWell(
            onTap: chooseFamily,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: FieldPalette.ink, width: 0.8),
              ),
              child: AnimalFigure(
                familyId: unit.familyId,
                breedId: unit.breedId,
                teamArgb: teamArgb,
                size: 52,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: InkWell(
              onTap: chooseFamily,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.byKey(family.nameKey).toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, letterSpacing: 2),
                  ),
                  Text(
                    l10n.byKey(family.latinKey),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: FieldPalette.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: InkWell(
              onTap: () async {
                final picked = await _pickBreed(context, unit, teamArgb);
                if (picked != null) onChanged(unit.copyWith(breedId: picked));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.byKey(breed.nameKey),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                    decorationColor: FieldPalette.pencil,
                    decorationStyle: TextDecorationStyle.dotted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: TextFormField(
              initialValue: unit.name,
              maxLength: 12,
              decoration: InputDecoration(
                labelText: l10n.setupUnitName,
                counterText: '',
              ),
              onChanged: (v) => onChanged(unit.copyWith(name: v.trim())),
            ),
          ),
          IconButton(
            tooltip: l10n.setupRandomUnit,
            onPressed: onRandom,
            icon: const InkIcon(InkGlyph.dice, size: 20),
          ),
        ],
      ),
    );
  }
}

/// The catalogue of families: engraved plates with common and Latin names.
Future<String?> _pickFamily(BuildContext context, String current) {
  final l10n = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (context) => Catalogue(
      title: l10n.setupChooseFamily,
      children: [
        for (final (i, f) in Families.all.indexed)
          CatalogueTile(
            selected: f.id == current,
            onTap: () => Navigator.of(context).pop(f.id),
            child: Plate(
              number: l10n.plateNumber('${i + 1}'),
              caption: l10n.byKey(f.latinKey),
              child: Column(
                children: [
                  AnimalFigure(
                    familyId: f.id,
                    breedId: Breeds.ofFamily(f.id).first.id,
                    size: 70,
                    engraved: true,
                  ),
                  Text(
                    l10n.byKey(f.nameKey).toUpperCase(),
                    style: const TextStyle(fontSize: 12, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

/// The breeds of one family, in colour (colour is what a breed is about).
Future<String?> _pickBreed(BuildContext context, UnitEntry unit, int teamArgb) {
  final l10n = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (context) => Catalogue(
      title: l10n.setupChooseBreed,
      children: [
        for (final b in Breeds.ofFamily(unit.familyId))
          CatalogueTile(
            selected: b.id == unit.breedId,
            onTap: () => Navigator.of(context).pop(b.id),
            child: Column(
              children: [
                AnimalFigure(
                  familyId: unit.familyId,
                  breedId: b.id,
                  teamArgb: teamArgb,
                  size: 70,
                ),
                Text(
                  l10n.byKey(b.nameKey),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
