import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/match_config.dart';
import '../../app/paw_palette.dart';
import '../../config/breeds.dart';
import '../../config/families.dart';
import '../../config/maps.dart';
import '../../config/match_defaults.dart';
import '../../config/teams.dart';
import '../../config/weapons.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../services/audio_service.dart';
import '../widgets/paw/paw_backdrop.dart';
import '../widgets/paw/paw_widgets.dart';
import '../widgets/paw/pet_figure.dart';
import 'arena_screen.dart';

/// Match setup (redesign prototype): a Teams tab with one card per team
/// (and an "Add team" card), a Rules tab with the match options and the map
/// picker, and a bottom bar with a summary and Start. The last setup is
/// restored on the next visit.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

enum _Tab { teams, rules }

class _SetupScreenState extends State<SetupScreen> {
  MatchConfig? _config;
  _Tab _tab = _Tab.teams;

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

  String _mapName(AppLocalizations l10n, String id) =>
      id == MatchConfig.randomMap
      ? l10n.setupMapRandom
      : l10n.byKey(Maps.byId(id).nameKey);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = _config!;
    return Scaffold(
      body: PawBackdrop(
        clouds: false,
        child: SafeArea(
          child: Column(
            children: [
              PawHeader(
                title: l10n.setupTitle,
                backLabel: l10n.back,
                center: PawPillToggle<_Tab>(
                  values: _Tab.values,
                  selected: _tab,
                  background: Paw.cream,
                  shadow: true,
                  label: (t) =>
                      t == _Tab.teams ? l10n.setupTabTeams : l10n.setupTabRules,
                  onSelect: (t) => setState(() => _tab = t),
                ),
                trailing: PawButton(
                  label: l10n.setupRandomAll,
                  icon: Icons.shuffle_rounded,
                  fill: Paw.green,
                  height: 44,
                  fontSize: 14,
                  shadow: 3,
                  padding: 14,
                  onPressed: () {
                    AppServices.of(context).audio.play(Sfx.ui);
                    _update(config.randomized(_rng, _pool), resetFields: true);
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
                  child: _tab == _Tab.teams
                      ? _TeamsTab(
                          config: config,
                          revision: _revision,
                          pool: _pool,
                          rng: _rng,
                          onChanged: _update,
                        )
                      : _RulesTab(
                          config: config,
                          pool: _pool,
                          onChanged: _update,
                        ),
                ),
              ),
              Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  color: Paw.cream,
                  border: Border(top: BorderSide(color: Paw.ink, width: 3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.setupSummary(
                          config.teams.length,
                          config.unitsPerTeam,
                          config.turnSeconds,
                          _mapName(l10n, config.mapId),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Paw.text(14, weight: 700, color: Paw.muted),
                      ),
                    ),
                    const SizedBox(width: 16),
                    PawButton(
                      label: l10n.setupStartMatch,
                      trailingIcon: Icons.arrow_forward_rounded,
                      fill: Paw.orange,
                      display: true,
                      fontSize: 20,
                      borderWidth: 3,
                      onPressed: _start,
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

// ----------------------------------------------------------------- teams

class _TeamsTab extends StatelessWidget {
  const _TeamsTab({
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
    final canAdd = config.teams.length < MatchDefaults.teamCountOptions.last;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < config.teams.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: _TeamCard(
              key: ValueKey('team$i-$revision'),
              config: config,
              index: i,
              pool: pool,
              rng: rng,
              onChanged: onChanged,
            ),
          ),
        ],
        if (canAdd) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              button: true,
              label: l10n.setupAddTeam,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(
                  config.withTeamCount(config.teams.length + 1, pool),
                ),
                child: CustomPaint(
                  painter: _DashedBorder(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Paw.cream,
                          shape: BoxShape.circle,
                          border: Border.all(color: Paw.ink, width: 2),
                          boxShadow: Paw.drop(3),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 28,
                          color: Paw.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.setupAddTeam, style: Paw.text(14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1.5),
      const Radius.circular(20),
    );
    canvas.drawRRect(r, Paint()..color = Paw.cream.withValues(alpha: 0.55));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Paw.muted;
    for (final metric in (Path()..addRRect(r)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 14) {
        canvas.drawPath(metric.extractPath(d, d + 8), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => false;
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    super.key,
    required this.config,
    required this.index,
    required this.pool,
    required this.rng,
    required this.onChanged,
  });

  final MatchConfig config;
  final int index;
  final List<String> pool;
  final Random rng;
  final void Function(MatchConfig, {bool resetFields}) onChanged;

  TeamEntry get team => config.teams[index];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Teams.styles[team.styleIndex];
    final color = Color(style.colorArgb);
    final defaultName = l10n.byKey(style.nameKey);
    return Container(
      decoration: BoxDecoration(
        color: Paw.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Paw.ink, width: 3),
        boxShadow: Paw.drop(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: color,
              border: const Border(
                bottom: BorderSide(color: Paw.ink, width: 2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 2, 4),
            child: Row(
              children: [
                TeamBadge(color: color, symbol: style.symbol),
                const SizedBox(width: 6),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('name$index-${team.styleIndex}'),
                    initialValue: team.customName ?? '',
                    maxLength: 18,
                    style: Paw.title(18),
                    decoration: InputDecoration(
                      hintText: defaultName,
                      hintStyle: Paw.title(18, color: Paw.ink),
                      counterText: '',
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Paw.line, width: 2),
                      ),
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
                PopupMenuButton<int>(
                  tooltip: l10n.setupTeamName,
                  icon: const Icon(Icons.more_vert_rounded, color: Paw.ink),
                  color: Paw.cream,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Paw.ink, width: 3),
                  ),
                  onSelected: (choice) async {
                    if (choice == 0) {
                      onChanged(
                        config.withRandomTeam(index, rng, pool),
                        resetFields: true,
                      );
                    } else if (await showPawConfirm(
                      context: context,
                      title: l10n.setupDeleteTeamTitle,
                      body: l10n.setupDeleteTeamBody,
                      ok: l10n.setupDeleteTeam,
                      cancel: l10n.dialogCancel,
                    )) {
                      onChanged(config.withoutTeam(index), resetFields: true);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 0,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shuffle_rounded,
                            size: 20,
                            color: Paw.ink,
                          ),
                          const SizedBox(width: 8),
                          Text(l10n.setupRandomTeam, style: Paw.text(14)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 1,
                      enabled: config.teams.length > 2,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_rounded,
                            size: 20,
                            color: Paw.redText,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.setupDeleteTeam,
                            style: Paw.text(14, color: Paw.redText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
              children: [
                for (var k = 0; k < team.units.length; k++)
                  _UnitRow(
                    unit: team.units[k],
                    teamArgb: style.colorArgb,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => UnitEditorScreen(
                          unit: team.units[k],
                          teamName: team.customName ?? defaultName,
                          teamStyle: style,
                          pool: pool,
                          onChanged: (u) => onChanged(
                            config.withTeam(
                              index,
                              team.copyWith(units: [...team.units]..[k] = u),
                            ),
                            resetFields: true,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.unit,
    required this.teamArgb,
    required this.onTap,
  });

  final UnitEntry unit;
  final int teamArgb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        hoverColor: Paw.peach,
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              const SizedBox(width: 4),
              PetFigure(
                familyId: unit.familyId,
                breedId: unit.breedId,
                teamArgb: teamArgb,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  unit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Paw.text(14),
                ),
              ),
              _Chip(l10n.byKey(Families.byId(unit.familyId).nameKey)),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    decoration: BoxDecoration(
      color: Paw.peach,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Paw.ink, width: 2),
    ),
    child: Text(text, style: Paw.text(12, weight: 700)),
  );
}

// ----------------------------------------------------------------- rules

class _RulesTab extends StatelessWidget {
  const _RulesTab({
    required this.config,
    required this.pool,
    required this.onChanged,
  });

  final MatchConfig config;
  final List<String> pool;
  final void Function(MatchConfig) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final teamOptions = MatchDefaults.teamCountOptions;
    final unitOptions = MatchDefaults.unitsPerTeamOptions;
    Widget row(String label, Widget control, {bool last = false}) => Container(
      constraints: const BoxConstraints(minHeight: 54),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Paw.peach, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Paw.text(16))),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(fit: BoxFit.scaleDown, child: control),
            ),
          ),
        ],
      ),
    );
    final teams = config.teams.length;
    final units = config.unitsPerTeam;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 115,
          child: PawCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListView(
              children: [
                row(
                  l10n.setupTeamCount,
                  PawStepper(
                    value: teams,
                    decreaseLabel: l10n.hudDecrease,
                    increaseLabel: l10n.hudIncrease,
                    onDecrease: teams > teamOptions.first
                        ? () => onChanged(config.withTeamCount(teams - 1, pool))
                        : null,
                    onIncrease: teams < teamOptions.last
                        ? () => onChanged(config.withTeamCount(teams + 1, pool))
                        : null,
                  ),
                ),
                row(
                  l10n.setupUnitsPerTeam,
                  PawStepper(
                    value: units,
                    decreaseLabel: l10n.hudDecrease,
                    increaseLabel: l10n.hudIncrease,
                    onDecrease: units > unitOptions.first
                        ? () => onChanged(
                            config.withUnitsPerTeam(units - 1, pool),
                          )
                        : null,
                    onIncrease: units < unitOptions.last
                        ? () => onChanged(
                            config.withUnitsPerTeam(units + 1, pool),
                          )
                        : null,
                  ),
                ),
                row(
                  l10n.setupTurnTime,
                  PawPillToggle<int>(
                    values: MatchDefaults.turnSecondsOptions,
                    selected: config.turnSeconds,
                    label: (v) => l10n.hudSeconds(v),
                    onSelect: (v) => onChanged(config.copyWith(turnSeconds: v)),
                  ),
                ),
                row(
                  l10n.setupSuddenDeath,
                  PawPillToggle<int>(
                    values: [
                      for (final m in MatchDefaults.suddenDeathOptions) m ?? 0,
                    ],
                    selected: config.suddenDeathMinutes ?? 0,
                    label: (m) => m == 0 ? l10n.setupOff : l10n.setupMinutes(m),
                    onSelect: (m) => onChanged(
                      m == 0
                          ? config.copyWith(suddenDeathOff: true)
                          : config.copyWith(suddenDeathMinutes: m),
                    ),
                  ),
                  last: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 100,
          child: PawCard(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.setupMap, style: Paw.title(20)),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final ids = [
                        for (final m in Maps.all) m.id,
                        MatchConfig.randomMap,
                      ];
                      final cols = ids.length > 4 ? 3 : 2;
                      final rows = (ids.length / cols).ceil();
                      final cardH = ((box.maxHeight - (rows - 1) * 10) / rows)
                          .clamp(64.0, 140.0);
                      return SingleChildScrollView(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final id in ids)
                              SizedBox(
                                width: (box.maxWidth - 10) / cols,
                                height: cardH,
                                child: _MapCard(
                                  id: id,
                                  selected: config.mapId == id,
                                  onTap: () =>
                                      onChanged(config.copyWith(mapId: id)),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final random = id == MatchConfig.randomMap;
    final name = random
        ? l10n.setupMapRandom
        : l10n.byKey(Maps.byId(id).nameKey);
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? Paw.peach : Paw.cream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Paw.ink, width: selected ? 3 : 2),
            boxShadow: Paw.drop(3),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (random)
                      const CustomPaint(
                        painter: StripesPainter(band: 8),
                        child: Icon(
                          Icons.shuffle_rounded,
                          size: 30,
                          color: Paw.ink,
                        ),
                      )
                    else
                      CustomPaint(painter: _MapThumbPainter(Maps.byId(id))),
                    if (selected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Paw.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Paw.ink, width: 2),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Paw.ink,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Paw.ink, width: 2)),
                ),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Paw.text(13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tiny landscape in the map's own sky and ground colours.
class _MapThumbPainter extends CustomPainter {
  _MapThumbPainter(this.map);
  final MapDef map;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(map.skyTopArgb), Color(map.skyBottomArgb)],
        ).createShader(rect),
    );
    final seed = map.id.codeUnits.fold(0, (a, b) => a + b);
    final ground = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w; x += 4) {
      final t = x / w;
      final y =
          h *
          (0.55 +
              0.12 * sin(t * 6.3 + seed) +
              0.06 * sin(t * 17 + seed * 0.7) +
              (t > 0.42 && t < 0.58 ? 0.25 : 0));
      ground.lineTo(x, y.clamp(h * 0.25, h * 0.95));
    }
    ground
      ..lineTo(w, h)
      ..close();
    canvas
      ..drawRect(
        Rect.fromLTWH(0, h * 0.86, w, h * 0.14),
        Paint()..color = Color(map.waterArgb).withValues(alpha: 1),
      )
      ..drawPath(ground, Paint()..color = Color(map.dirtArgb))
      ..drawPath(
        ground,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..color = Color(map.grassArgb),
      );
  }

  @override
  bool shouldRepaint(_MapThumbPainter old) => old.map != map;
}

// ------------------------------------------------------------ unit editor

/// Edit one unit (redesign prototype): portrait, name and Randomize on the
/// left; family tiles, breed chips, the family's passive and signature
/// weapon, and Done on the right. Changes apply as you make them.
class UnitEditorScreen extends StatefulWidget {
  const UnitEditorScreen({
    super.key,
    required this.unit,
    required this.teamName,
    required this.teamStyle,
    required this.pool,
    required this.onChanged,
  });

  final UnitEntry unit;
  final String teamName;
  final TeamStyle teamStyle;
  final List<String> pool;
  final ValueChanged<UnitEntry> onChanged;

  @override
  State<UnitEditorScreen> createState() => _UnitEditorScreenState();
}

class _UnitEditorScreenState extends State<UnitEditorScreen> {
  late UnitEntry _unit = widget.unit;
  int _revision = 0;
  final _rng = Random();

  void _set(UnitEntry u, {bool resetName = false}) {
    setState(() {
      _unit = u;
      if (resetName) _revision++;
    });
    widget.onChanged(u);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final teamArgb = widget.teamStyle.colorArgb;
    final family = Families.byId(_unit.familyId);
    final signature = Weapons.byId(family.signatureWeaponId);
    return Scaffold(
      body: PawBackdrop(
        clouds: false,
        child: SafeArea(
          child: Column(
            children: [
              PawHeader(
                title: l10n.setupEditUnit,
                backLabel: l10n.back,
                trailing: Container(
                  height: 32,
                  padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
                  decoration: BoxDecoration(
                    color: Paw.cream,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Paw.ink, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TeamBadge(
                        color: Color(teamArgb),
                        symbol: widget.teamStyle.symbol,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(widget.teamName, style: Paw.text(13)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 220,
                        child: PawCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 118,
                                height: 118,
                                decoration: BoxDecoration(
                                  color: Paw.peach,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Paw.ink, width: 3),
                                ),
                                alignment: Alignment.center,
                                child: PetFigure(
                                  familyId: _unit.familyId,
                                  breedId: _unit.breedId,
                                  teamArgb: teamArgb,
                                  size: 92,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                key: ValueKey('unitName$_revision'),
                                initialValue: _unit.name,
                                maxLength: 12,
                                textAlign: TextAlign.center,
                                style: Paw.text(16),
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: l10n.setupUnitName,
                                ),
                                onChanged: (v) =>
                                    _set(_unit.copyWith(name: v.trim())),
                              ),
                              const SizedBox(height: 10),
                              PawButton(
                                label: l10n.setupRandomize,
                                icon: Icons.casino_rounded,
                                fill: Paw.green,
                                height: 44,
                                fontSize: 14,
                                shadow: 3,
                                expand: true,
                                onPressed: () => _set(
                                  MatchConfig.randomUnit(_rng, widget.pool),
                                  resetName: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LayoutBuilder(
                              builder: (context, box) {
                                final tileW = (box.maxWidth - 4 * 8) / 5;
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final f in Families.all)
                                      SizedBox(
                                        width: tileW,
                                        child: _FamilyTile(
                                          family: f,
                                          selected: f.id == _unit.familyId,
                                          onTap: () => _set(
                                            _unit.copyWith(familyId: f.id),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 48,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  for (final b in Breeds.ofFamily(
                                    _unit.familyId,
                                  ))
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8,
                                        bottom: 4,
                                      ),
                                      child: _BreedChip(
                                        breed: b,
                                        selected: b.id == _unit.breedId,
                                        onTap: () =>
                                            _set(_unit.copyWith(breedId: b.id)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: SizedBox.expand(
                                      child: PawCard(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _Note(
                                                icon: Icons.shield_rounded,
                                                fill: Paw.peach,
                                                label: l10n.setupPassive,
                                                name: l10n.byKey(
                                                  family.passive.nameKey,
                                                ),
                                                body: l10n.byKey(
                                                  family.passive.descriptionKey,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              _Note(
                                                icon: Icons.star_rounded,
                                                fill: Paw.yellow,
                                                label:
                                                    l10n.setupSignatureWeapon,
                                                name: l10n.byKey(
                                                  signature.nameKey,
                                                ),
                                                body: l10n.byKey(
                                                  '${signature.nameKey}Desc',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  PawButton(
                                    label: l10n.setupDone,
                                    icon: Icons.check_rounded,
                                    fill: Paw.orange,
                                    display: true,
                                    fontSize: 20,
                                    height: 56,
                                    borderWidth: 3,
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

class _FamilyTile extends StatelessWidget {
  const _FamilyTile({
    required this.family,
    required this.selected,
    required this.onTap,
  });

  final FamilyDef family;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: selected ? Paw.orange : Paw.cream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Paw.ink, width: selected ? 3 : 2),
            boxShadow: Paw.drop(3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PetFigure(
                familyId: family.id,
                breedId: Breeds.ofFamily(family.id).first.id,
                teamArgb: 0xFF2B2118,
                size: 30,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.byKey(family.nameKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Paw.text(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreedChip extends StatelessWidget {
  const _BreedChip({
    required this.breed,
    required this.selected,
    required this.onTap,
  });

  final BreedDef breed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
        decoration: BoxDecoration(
          color: selected ? Paw.peach : Paw.cream,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Paw.ink, width: selected ? 3 : 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Color(breed.primaryArgb),
                shape: BoxShape.circle,
                border: Border.all(color: Paw.ink, width: 2),
              ),
            ),
            const SizedBox(width: 6),
            Text(l10n.byKey(breed.nameKey), style: Paw.text(13)),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.fill,
    required this.label,
    required this.name,
    required this.body,
  });

  final IconData icon;
  final Color fill;
  final String label;
  final String name;
  final String body;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PawIconChip(icon, fill: fill),
      const SizedBox(width: 8),
      Expanded(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label · ',
                style: Paw.text(13, color: Paw.muted),
              ),
              TextSpan(text: name, style: Paw.text(13)),
              TextSpan(text: ': $body', style: Paw.text(13, weight: 600)),
            ],
          ),
          style: const TextStyle(height: 1.35),
        ),
      ),
    ],
  );
}
