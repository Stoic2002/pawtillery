import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/match_config.dart';
import '../../app/iron_palette.dart';
import '../../config/breeds.dart';
import '../../config/families.dart';
import '../../config/maps.dart';
import '../../config/match_defaults.dart';
import '../../config/teams.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../services/audio_service.dart';
import '../widgets/iron/iron_backdrop.dart';
import '../widgets/iron/iron_button.dart';
import '../widgets/iron/iron_controls.dart';
import '../widgets/iron/iron_icons.dart';
import '../widgets/iron/iron_panel.dart';
import '../widgets/iron/iron_text.dart';
import 'arena_screen.dart';

/// Match setup: match rules on the left, one colour tab per team on the
/// right with a card per unit. The last setup is restored on the next
/// visit.
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
  int _team = 0;
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
    _team = _team.clamp(0, c.teams.length - 1);
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
      body: IronBackdrop(
        dim: 0.2,
        child: SafeArea(
          child: Column(
            children: [
              IronHeader(
                title: l10n.setupTitle.toUpperCase(),
                actions: [
                  IronButton(
                    label: l10n.setupRandomAll,
                    icon: IronGlyph.dice,
                    tone: IronTone.steel,
                    fontSize: 16,
                    height: 44,
                    onPressed: () {
                      AppServices.of(context).audio.play(Sfx.ui);
                      _update(
                        config.randomized(_rng, _pool),
                        resetFields: true,
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  IronButton(
                    label: l10n.setupStart,
                    icon: IronGlyph.play,
                    fontSize: 20,
                    height: 48,
                    onPressed: _start,
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 268,
                        child: IronPanel(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                          child: _Rules(
                            config: config,
                            onChanged: _update,
                            pool: _pool,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TeamsPanel(
                          config: config,
                          selected: _team,
                          onSelect: (t) => setState(() => _team = t),
                          revision: _revision,
                          pool: _pool,
                          rng: _rng,
                          onChanged: _update,
                        ),
                      ),
                    ],
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

class _Rules extends StatelessWidget {
  const _Rules({
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
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        Center(
          child: IronText(
            l10n.setupConditions.toUpperCase(),
            size: 18,
            color: IronPalette.brass,
          ),
        ),
        label(l10n.setupTeams),
        IronSegmented<int>(
          values: MatchDefaults.teamCountOptions,
          selected: config.teams.length,
          label: (v) => '$v',
          onSelect: (v) => onChanged(config.withTeamCount(v, pool)),
        ),
        label(l10n.setupUnitsPerTeam),
        IronSegmented<int>(
          values: MatchDefaults.unitsPerTeamOptions,
          selected: config.unitsPerTeam,
          label: (v) => '$v',
          onSelect: (v) => onChanged(config.withUnitsPerTeam(v, pool)),
        ),
        label(l10n.setupTurnTime),
        IronSegmented<int>(
          values: MatchDefaults.turnSecondsOptions,
          selected: config.turnSeconds,
          label: (v) => l10n.hudSeconds(v),
          onSelect: (v) => onChanged(config.copyWith(turnSeconds: v)),
          wrap: true,
        ),
        label(l10n.setupMap),
        IronSegmented<String>(
          values: [MatchConfig.randomMap, for (final m in Maps.all) m.id],
          selected: config.mapId,
          label: (id) => id == MatchConfig.randomMap
              ? l10n.setupMapRandom
              : l10n.byKey(Maps.byId(id).nameKey),
          onSelect: (id) => onChanged(config.copyWith(mapId: id)),
          tone: IronTone.moss,
          wrap: true,
        ),
        label(l10n.setupSuddenDeath),
        IronSegmented<int>(
          values: [for (final m in MatchDefaults.suddenDeathOptions) m ?? 0],
          selected: config.suddenDeathMinutes ?? 0,
          label: (m) => m == 0 ? l10n.setupOff : l10n.setupMinutes(m),
          onSelect: (m) => onChanged(
            m == 0
                ? config.copyWith(suddenDeathOff: true)
                : config.copyWith(suddenDeathMinutes: m),
          ),
          tone: IronTone.blood,
          wrap: true,
        ),
      ],
    );
  }
}

class _TeamsPanel extends StatelessWidget {
  const _TeamsPanel({
    required this.config,
    required this.selected,
    required this.onSelect,
    required this.revision,
    required this.pool,
    required this.rng,
    required this.onChanged,
  });

  final MatchConfig config;
  final int selected;
  final ValueChanged<int> onSelect;
  final int revision;
  final List<String> pool;
  final Random rng;
  final void Function(MatchConfig, {bool resetFields}) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String teamName(TeamEntry t) =>
        t.customName ?? l10n.byKey(Teams.styles[t.styleIndex].nameKey);
    final team = config.teams[selected];
    final teamColor = Color(Teams.styles[team.styleIndex].colorArgb);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Team tabs: chunky tabs in each team's colour; the chosen one is
        // raised and joins the card below.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, t) in config.teams.indexed)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _TeamTab(
                    label: teamName(t).toUpperCase(),
                    color: Color(Teams.styles[t.styleIndex].colorArgb),
                    selected: i == selected,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: IronPanel(
            accent: Color.lerp(teamColor, IronPalette.ink, 0.45),
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: _TeamEditor(
              key: ValueKey('team$selected-$revision'),
              config: config,
              index: selected,
              defaultName: l10n.byKey(Teams.styles[team.styleIndex].nameKey),
              pool: pool,
              rng: rng,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamTab extends StatelessWidget {
  const _TeamTab({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: selected ? 46 : 40,
        constraints: const BoxConstraints(minWidth: 96, maxWidth: 190),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        margin: EdgeInsets.only(bottom: selected ? 0 : 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(color, Colors.black, selected ? 0.2 : 0.5)!,
              Color.lerp(color, Colors.black, selected ? 0.55 : 0.75)!,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          border: Border.all(
            color: selected ? IronPalette.brass : IronPalette.ironEdge,
          ),
        ),
        alignment: Alignment.center,
        child: IronText(label, size: selected ? 17 : 15, maxLines: 1),
      ),
    ),
  );
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
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextFormField(
                // Keyed by colour too: an empty name shows the colour's
                // default as a hint.
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
            ),
            // Swatches wrap on their own so narrow phones never overflow.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var s = 0; s < Teams.styles.length; s++)
                  _Swatch(
                    argb: Teams.styles[s].colorArgb,
                    selected: s == team.styleIndex,
                    label: l10n.setupColor,
                    onTap: () => onChanged(config.withTeamStyle(index, s)),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var k = 0; k < team.units.length; k++)
          _UnitCard(
            key: ValueKey('unit$index-$k'),
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

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.argb,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final int argb;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox.square(
        dimension: 44,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: selected ? 34 : 26,
            height: selected ? 34 : 26,
            decoration: BoxDecoration(
              color: Color(argb),
              shape: BoxShape.circle,
              border: Border.all(
                color: IronPalette.ink,
                width: selected ? 3.5 : 2.5,
              ),
            ),
            child: selected
                ? const Center(child: IronIcon(IronGlyph.check, size: 18))
                : null,
          ),
        ),
      ),
    ),
  );
}

/// One unit: portrait in a team-coloured badge, family and breed as
/// buttons that open pickers, the unit's name, and a dice.
class _UnitCard extends StatelessWidget {
  const _UnitCard({
    super.key,
    required this.unit,
    required this.teamArgb,
    required this.onChanged,
    required this.onRandom,
  });

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
      final picked = await _pickFamily(context, unit.familyId, teamArgb);
      if (picked != null) onChanged(unit.copyWith(familyId: picked));
    }

    Future<void> chooseBreed() async {
      final picked = await _pickBreed(context, unit, teamArgb);
      if (picked != null) onChanged(unit.copyWith(breedId: picked));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(6, 4, 2, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1C20),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: IronPalette.ironEdge),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: chooseFamily,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.lerp(Color(teamArgb), Colors.black, 0.35)!,
                    Color.lerp(Color(teamArgb), Colors.black, 0.75)!,
                  ],
                ),
                border: Border.all(color: IronPalette.brass, width: 1.5),
              ),
              child: ClipOval(
                child: AnimalFigure(
                  familyId: unit.familyId,
                  breedId: unit.breedId,
                  teamArgb: teamArgb,
                  size: 58,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: _PickField(
              caption: l10n.byKey(family.latinKey),
              value: l10n.byKey(family.nameKey),
              onTap: chooseFamily,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 5,
            child: _PickField(
              caption: l10n.setupChooseBreed,
              value: l10n.byKey(breed.nameKey),
              onTap: chooseBreed,
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
          const SizedBox(width: 4),
          IronRoundButton(
            glyph: IronGlyph.dice,
            tooltip: l10n.setupRandomUnit,
            tone: IronTone.steel,
            size: 42,
            onPressed: onRandom,
          ),
        ],
      ),
    );
  }
}

/// A value with a small caption that opens a picker, with a ▾ hint.
class _PickField extends StatelessWidget {
  const _PickField({
    required this.caption,
    required this.value,
    required this.onTap,
  });

  final String caption;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: IronPalette.mute,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17),
                ),
              ],
            ),
          ),
          const Text(
            '▾',
            style: TextStyle(fontSize: 16, color: IronPalette.steel),
          ),
        ],
      ),
    ),
  );
}

/// The families, each on a card with its portrait.
Future<String?> _pickFamily(
  BuildContext context,
  String current,
  int teamArgb,
) {
  final l10n = AppLocalizations.of(context);
  return showIronPicker<String>(
    context: context,
    title: l10n.setupChooseFamily.toUpperCase(),
    tiles: (context) => [
      for (final f in Families.all)
        IronTile(
          selected: f.id == current,
          onTap: () => Navigator.of(context).pop(f.id),
          child: Column(
            children: [
              AnimalFigure(
                familyId: f.id,
                breedId: Breeds.ofFamily(f.id).first.id,
                teamArgb: teamArgb,
                size: 76,
              ),
              IronText(l10n.byKey(f.nameKey), size: 16, maxLines: 1),
            ],
          ),
        ),
    ],
  );
}

/// The breeds of one family.
Future<String?> _pickBreed(BuildContext context, UnitEntry unit, int teamArgb) {
  final l10n = AppLocalizations.of(context);
  return showIronPicker<String>(
    context: context,
    title: l10n.setupChooseBreed.toUpperCase(),
    tiles: (context) => [
      for (final b in Breeds.ofFamily(unit.familyId))
        IronTile(
          selected: b.id == unit.breedId,
          onTap: () => Navigator.of(context).pop(b.id),
          child: Column(
            children: [
              AnimalFigure(
                familyId: unit.familyId,
                breedId: b.id,
                teamArgb: teamArgb,
                size: 76,
              ),
              Text(
                l10n.byKey(b.nameKey),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
    ],
  );
}
