import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/match_config.dart';
import '../../config/breeds.dart';
import '../../config/families.dart';
import '../../config/maps.dart';
import '../../config/match_defaults.dart';
import '../../config/teams.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../services/audio_service.dart';
import '../widgets/unit_avatar.dart';
import 'arena_screen.dart';

/// Match setup (PRD: Setup pertandingan): options on the left, one tab per
/// team on the right. The last setup is restored on the next visit.
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
      appBar: AppBar(
        title: Text(l10n.setupTitle),
        actions: [
          TextButton.icon(
            onPressed: () =>
                _update(config.randomized(_rng, _pool), resetFields: true),
            icon: const Icon(Icons.casino_outlined),
            label: Text(l10n.setupRandomAll),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.setupStart),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 260,
              child: _OptionsPanel(
                config: config,
                onChanged: _update,
                pool: _pool,
              ),
            ),
            const VerticalDivider(width: 1),
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
    );
  }
}

class _OptionsPanel extends StatelessWidget {
  const _OptionsPanel({
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
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
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
        DropdownButtonFormField<String>(
          initialValue: config.mapId,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: MatchConfig.randomMap,
              child: Text(l10n.setupMapRandom),
            ),
            for (final m in Maps.all)
              DropdownMenuItem(value: m.id, child: Text(l10n.byKey(m.nameKey))),
          ],
          onChanged: (v) => onChanged(config.copyWith(mapId: v)),
        ),
        label(l10n.setupSuddenDeath),
        DropdownButtonFormField<int>(
          initialValue: config.suddenDeathMinutes ?? 0,
          isExpanded: true,
          items: [
            for (final m in MatchDefaults.suddenDeathOptions)
              DropdownMenuItem(
                value: m ?? 0,
                child: Text(m == null ? l10n.setupOff : l10n.setupMinutes(m)),
              ),
          ],
          onChanged: (v) => onChanged(
            v == 0
                ? config.copyWith(suddenDeathOff: true)
                : config.copyWith(suddenDeathMinutes: v),
          ),
        ),
      ],
    );
  }
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
                      CircleAvatar(
                        radius: 7,
                        backgroundColor: Color(
                          Teams.styles[t.styleIndex].colorArgb,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          teamName(t),
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
          // Keyed by colour too: an empty name shows the colour's
          // default as a hint.
          key: ValueKey('name$index-${team.styleIndex}'),
          initialValue: team.customName ?? '',
          maxLength: 18,
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
        const SizedBox(height: 8),
        // Colours on their own wrapping row so narrow phones never overflow.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(l10n.setupColor),
            ),
            for (var s = 0; s < Teams.styles.length; s++)
              _ColorDot(
                argb: Teams.styles[s].colorArgb,
                selected: s == team.styleIndex,
                onTap: () => onChanged(config.withTeamStyle(index, s)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var k = 0; k < team.units.length; k++)
          _UnitRow(
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

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.argb,
    required this.selected,
    required this.onTap,
  });

  final int argb;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 48 dp tap target around a 28 dp swatch.
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: SizedBox.square(
        dimension: 48,
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Color(argb),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          UnitAvatar(
            familyId: unit.familyId,
            breedId: unit.breedId,
            teamArgb: teamArgb,
            size: 48,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              key: ValueKey('family-${unit.familyId}'),
              initialValue: unit.familyId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.setupFamily),
              items: [
                for (final f in Families.all)
                  DropdownMenuItem(
                    value: f.id,
                    child: Text(
                      l10n.byKey(f.nameKey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => onChanged(unit.copyWith(familyId: v)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              key: ValueKey('breed-${unit.breedId}'),
              initialValue: unit.breedId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.setupBreed),
              items: [
                for (final b in Breeds.ofFamily(unit.familyId))
                  DropdownMenuItem(
                    value: b.id,
                    child: Text(
                      l10n.byKey(b.nameKey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => onChanged(unit.copyWith(breedId: v)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
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
            icon: const Icon(Icons.casino_outlined),
          ),
        ],
      ),
    );
  }
}
