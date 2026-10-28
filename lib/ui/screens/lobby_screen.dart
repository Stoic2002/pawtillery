import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/match_config.dart';
import '../../app/paw_palette.dart';
import '../../config/maps.dart';
import '../../config/teams.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../../net/lan.dart';
import '../../net/lan_room.dart';
import '../../net/protocol.dart';
import '../../net/session.dart';
import '../../services/audio_service.dart';
import '../widgets/paw/paw_backdrop.dart';
import '../widgets/paw/paw_widgets.dart';
import 'arena_screen.dart';
import 'setup_screen.dart';

/// A Wi-Fi room before (and between) matches: the players, which player
/// controls each team, and the host's setup. The host edits the setup,
/// hands teams out and starts; guests watch. Every phone opens the arena
/// when the match starts. Leaving this screen leaves the room.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.session, this.room});

  /// Route name, so the arena and results can come back here.
  static const routeName = '/wifi-lobby';

  final NetSession session;

  /// The host's open room (null on guests).
  final LanRoom? room;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  NetSession get _session => widget.session;
  StartMsg? _opened;
  List<String> _addresses = const [];

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSession);
    // Rejoined after a restart: the match is already on.
    if (_session.inMatch) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onSession());
    }
    if (_session.isHost) {
      localAddresses().then((a) {
        if (mounted) setState(() => _addresses = a);
      });
    }
  }

  void _onSession() {
    if (!mounted) return;
    final match = _session.match;
    if (_session.inMatch && match != null && !identical(match, _opened)) {
      _opened = match;
      final nav = Navigator.of(context)
        ..popUntil(ModalRoute.withName(LobbyScreen.routeName));
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => ArenaScreen(config: match.config, net: _session),
        ),
      );
    } else if (_session.hostLost && !_session.inMatch) {
      // In a match the arena says so itself.
      final messenger = ScaffoldMessenger.of(context);
      final text = AppLocalizations.of(context).netHostLost;
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger.showSnackBar(SnackBar(content: Text(text)));
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    final room = widget.room;
    if (room != null) {
      room.close();
    } else {
      _session.leave();
    }
    super.dispose();
  }

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showPawConfirm(
      context: context,
      title: l10n.lobbyLeaveTitle,
      body: _session.isHost
          ? l10n.lobbyLeaveHostBody
          : l10n.lobbyLeaveGuestBody,
      ok: l10n.lobbyLeave,
      cancel: l10n.dialogCancel,
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _editSetup() async {
    final host = _session as HostSession;
    AppServices.of(context).audio.play(Sfx.ui);
    final config = await Navigator.of(context).push<MatchConfig>(
      MaterialPageRoute(
        builder: (_) => SetupScreen(lobbyConfig: host.lobby.config),
      ),
    );
    if (config != null) host.updateConfig(config);
  }

  /// Host: give the team to the next player in the list.
  void _cycleOwner(int team) {
    final host = _session as HostSession;
    final players = host.lobby.players;
    final i = players.indexWhere((p) => p.id == host.lobby.owners[team]);
    host.setOwner(team, players[(i + 1) % players.length].id);
  }

  String _teamName(AppLocalizations l10n, TeamEntry t) =>
      t.customName ?? l10n.byKey(Teams.styles[t.styleIndex].nameKey);

  String _mapName(AppLocalizations l10n, String id) =>
      id == MatchConfig.randomMap
      ? l10n.setupMapRandom
      : l10n.byKey(Maps.byId(id).nameKey);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lobby = _session.lobby;
    final config = lobby.config;
    final isHost = _session.isHost;
    final host = isHost ? _session as HostSession : null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: PawBackdrop(
          clouds: false,
          child: SafeArea(
            child: Column(
              children: [
                PawHeader(
                  title: l10n.lobbyTitle(lobby.nameOf(0)),
                  backLabel: l10n.back,
                  onBack: _leave,
                  trailing: isHost
                      ? PawButton(
                          label: l10n.lobbyEditSetup,
                          icon: Icons.tune_rounded,
                          height: 44,
                          fontSize: 14,
                          shadow: 3,
                          padding: 14,
                          onPressed: _session.inMatch ? null : _editSetup,
                        )
                      : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 250,
                          child: _PlayersCard(
                            lobby: lobby,
                            myId: _session.myId,
                            addresses: _addresses,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: PawCard(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(l10n.lobbyTeams, style: Paw.title(18)),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: ListView(
                                    children: [
                                      for (
                                        var t = 0;
                                        t < config.teams.length;
                                        t++
                                      )
                                        _TeamRow(
                                          team: config.teams[t],
                                          name: _teamName(
                                            l10n,
                                            config.teams[t],
                                          ),
                                          owner: lobby.nameOf(lobby.owners[t]),
                                          mine:
                                              lobby.owners[t] == _session.myId,
                                          onTap: host == null || host.inMatch
                                              ? null
                                              : () => _cycleOwner(t),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isHost && lobby.players.length > 1)
                                  Text(
                                    l10n.lobbyOwnerHint,
                                    style: Paw.text(
                                      12,
                                      weight: 700,
                                      color: Paw.muted,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.setupSummary(
                                config.teams.length,
                                config.unitsPerTeam,
                                config.turnSeconds,
                                _mapName(l10n, config.mapId),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Paw.text(14, weight: 700),
                            ),
                            Text(
                              host == null
                                  ? l10n.lobbyWaitingHost
                                  : host.canStart || host.inMatch
                                  ? ''
                                  : l10n.lobbyNeedPlayers,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Paw.text(
                                13,
                                weight: 700,
                                color: Paw.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (host != null) ...[
                        const SizedBox(width: 16),
                        PawButton(
                          label: l10n.setupStartMatch,
                          trailingIcon: Icons.arrow_forward_rounded,
                          fill: Paw.orange,
                          display: true,
                          fontSize: 20,
                          borderWidth: 3,
                          onPressed: host.canStart
                              ? () {
                                  AppServices.of(context).audio.play(Sfx.ui);
                                  host.startMatch();
                                }
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayersCard extends StatelessWidget {
  const _PlayersCard({
    required this.lobby,
    required this.myId,
    required this.addresses,
  });

  final LobbyState lobby;
  final int myId;

  /// The host's IP addresses (empty on guests).
  final List<String> addresses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PawCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.lobbyPlayers, style: Paw.title(18)),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              children: [for (final p in lobby.players) _playerRow(l10n, p)],
            ),
          ),
          for (final a in addresses)
            Text(
              l10n.lobbyAddress(a),
              style: Paw.text(12, weight: 700, color: Paw.muted),
            ),
        ],
      ),
    );
  }

  Widget _playerRow(AppLocalizations l10n, NetPlayer p) {
    final teams = [
      for (var t = 0; t < lobby.owners.length; t++)
        if (lobby.owners[t] == p.id) lobby.config.teams[t],
    ];
    final tags = [
      if (p.id == 0) l10n.lobbyHost,
      if (p.id == myId) l10n.lobbyYou,
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: p.id == myId ? Paw.peach : Paw.peachLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Paw.ink, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Paw.text(15),
                ),
                if (tags.isNotEmpty)
                  Text(
                    tags.join(' · '),
                    style: Paw.text(11, weight: 700, color: Paw.muted),
                  ),
              ],
            ),
          ),
          if (teams.isEmpty)
            Text(
              l10n.lobbyWatching,
              style: Paw.text(12, weight: 700, color: Paw.muted),
            ),
          for (final t in teams)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: TeamBadge(
                color: Color(Teams.styles[t.styleIndex].colorArgb),
                symbol: Teams.styles[t.styleIndex].symbol,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.team,
    required this.name,
    required this.owner,
    required this.mine,
    required this.onTap,
  });

  final TeamEntry team;
  final String name;
  final String owner;

  /// Controlled by this phone.
  final bool mine;

  /// Host: pass the team on. Null on guests.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Teams.styles[team.styleIndex];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: mine ? Paw.peach : Paw.peachLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Paw.ink, width: 2),
      ),
      child: Row(
        children: [
          TeamBadge(color: Color(style.colorArgb), symbol: style.symbol),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Paw.text(15),
                ),
                Text(
                  team.units.map((u) => u.name).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Paw.text(12, weight: 700, color: Paw.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (onTap == null)
            // Guests only read who plays the team: a label, not a
            // greyed-out button.
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Paw.cream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Paw.ink, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_rounded, size: 17, color: Paw.ink),
                  const SizedBox(width: 6),
                  Text(owner, style: Paw.text(13)),
                ],
              ),
            )
          else
            PawButton(
              label: owner,
              icon: Icons.person_rounded,
              height: 40,
              fontSize: 13,
              shadow: 3,
              padding: 12,
              fill: Paw.cream,
              onPressed: onTap,
            ),
        ],
      ),
    );
  }
}
