import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/match_config.dart';
import '../../app/paw_palette.dart';
import '../../config/net.dart';
import '../../l10n/app_localizations.dart';
import '../../net/lan.dart';
import '../../net/lan_room.dart';
import '../../net/protocol.dart';
import '../../net/session.dart';
import '../../services/audio_service.dart';
import '../../services/wifi_lock.dart';
import '../widgets/paw/paw_backdrop.dart';
import '../widgets/paw/paw_widgets.dart';
import 'lobby_screen.dart';

/// Play on Wi-Fi: pick a name, then host a room or join one heard on the
/// network (or typed in by address, for networks that block broadcasts).
class LanScreen extends StatefulWidget {
  const LanScreen({super.key});

  @override
  State<LanScreen> createState() => _LanScreenState();
}

class _LanScreenState extends State<LanScreen> {
  late final TextEditingController _name;
  final _address = TextEditingController();
  LanDiscovery? _discovery;
  StreamSubscription<List<FoundRoom>>? _roomsSub;
  List<FoundRoom> _rooms = const [];
  bool _busy = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final services = AppServices.of(context);
    final pool = unitNamePool(AppLocalizations.of(context));
    _name = TextEditingController(
      text:
          services.settings.playerName ??
          (pool.isEmpty ? 'Player' : pool[Random().nextInt(pool.length)]),
    );
    WifiLock.acquire();
    _listen();
  }

  Future<void> _listen() async {
    try {
      final discovery = await startDiscovery();
      if (!mounted) {
        await discovery.close();
        return;
      }
      _discovery = discovery;
      _roomsSub = discovery.rooms.listen((r) => setState(() => _rooms = r));
    } on Object catch (e) {
      // Port in use or no network: joining by address still works.
      debugPrint('Room discovery unavailable: $e');
    }
  }

  @override
  void dispose() {
    _roomsSub?.cancel();
    _discovery?.close();
    WifiLock.release();
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  String get _playerName {
    final name = _name.text.trim();
    final cut = name.length > NetConfig.maxNameLength
        ? name.substring(0, NetConfig.maxNameLength)
        : name;
    return cut.isEmpty ? 'Player' : cut;
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _stopListening() async {
    await _roomsSub?.cancel();
    _roomsSub = null;
    final discovery = _discovery;
    _discovery = null;
    _rooms = const [];
    await discovery?.close();
  }

  /// Not listening for rooms while in one (frees the port for another copy
  /// of the game on this machine, and saves battery).
  Future<void> _openLobby(NetSession session, {LanRoom? room}) async {
    final nav = Navigator.of(context);
    await _stopListening();
    await nav.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: LobbyScreen.routeName),
        builder: (_) => LobbyScreen(session: session, room: room),
      ),
    );
    if (mounted) _listen();
  }

  Future<void> _host() async {
    final services = AppServices.of(context);
    final l10n = AppLocalizations.of(context);
    services.audio.play(Sfx.ui);
    services.settings.playerName = _playerName;
    final pool = unitNamePool(l10n);
    final session = HostSession(
      name: _playerName,
      // A Wi-Fi match has no CPU teams.
      config: (services.settings.lastMatch(pool) ?? MatchConfig.defaults(pool))
          .withoutCpu(),
    );
    setState(() => _busy = true);
    try {
      final room = await LanRoom.open(session);
      if (!mounted) {
        await room.close();
        return;
      }
      setState(() => _busy = false);
      await _openLobby(session, room: room);
    } on Object catch (e) {
      debugPrint('Could not host: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      _say(l10n.lanErrorHost);
    }
  }

  Future<void> _join(String host, int port) async {
    final services = AppServices.of(context);
    final l10n = AppLocalizations.of(context);
    services.audio.play(Sfx.ui);
    services.settings.playerName = _playerName;
    setState(() => _busy = true);
    String? error;
    GuestSession? session;
    try {
      final link = await connectLan(host, port);
      session = await GuestSession.join(
        link,
        name: _playerName,
        // Rejoins the match if the connection drops mid-match.
        redial: () => connectLan(host, port),
      );
    } on JoinRejected catch (e) {
      error = switch (e.reason) {
        RejectReason.version => l10n.lanErrorVersion,
        RejectReason.full => l10n.lanErrorFull,
        RejectReason.started => l10n.lanErrorStarted,
      };
    } on Object catch (e) {
      debugPrint('Could not join $host:$port: $e');
      error = l10n.lanErrorConnect;
    }
    if (!mounted) {
      await session?.leave();
      return;
    }
    setState(() => _busy = false);
    if (session != null) {
      await _openLobby(session);
    } else if (error != null) {
      _say(error);
    }
  }

  /// "192.168.1.5" or "192.168.1.5:47821".
  void _joinTyped() {
    final text = _address.text.trim();
    if (text.isEmpty) return;
    final colon = text.lastIndexOf(':');
    final port = colon > 0 ? int.tryParse(text.substring(colon + 1)) : null;
    _join(
      port == null ? text : text.substring(0, colon),
      port ?? NetConfig.gamePort,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: PawBackdrop(
        clouds: false,
        child: SafeArea(
          child: Column(
            children: [
              PawHeader(title: l10n.lanTitle, backLabel: l10n.back),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 300,
                        child: PawCard(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: ListView(
                            children: [
                              Text(l10n.lanYourName, style: Paw.title(16)),
                              TextField(
                                controller: _name,
                                maxLength: NetConfig.maxNameLength,
                                style: Paw.text(16),
                                decoration: const InputDecoration(
                                  counterText: '',
                                ),
                              ),
                              const SizedBox(height: 12),
                              PawButton(
                                label: l10n.lanHost,
                                icon: Icons.wifi_tethering_rounded,
                                fill: Paw.orange,
                                display: true,
                                fontSize: 20,
                                height: 56,
                                borderWidth: 3,
                                onPressed: _busy ? null : _host,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.lanHostHint,
                                style: Paw.text(
                                  12,
                                  weight: 700,
                                  color: Paw.muted,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(l10n.lanJoinByAddress, style: Paw.title(16)),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _address,
                                      keyboardType: TextInputType.url,
                                      style: Paw.text(16),
                                      decoration: InputDecoration(
                                        hintText: l10n.lanAddressHint,
                                      ),
                                      onSubmitted: (_) => _joinTyped(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PawButton(
                                    label: l10n.lanJoin,
                                    height: 44,
                                    fontSize: 14,
                                    padding: 14,
                                    shadow: 3,
                                    onPressed: _busy ? null : _joinTyped,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: PawCard(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.lanRooms,
                                      style: Paw.title(18),
                                    ),
                                  ),
                                  if (_busy)
                                    Text(
                                      l10n.lanConnecting,
                                      style: Paw.text(13, color: Paw.muted),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _rooms.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox.square(
                                              dimension: 28,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: Paw.orange,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              l10n.lanSearching,
                                              textAlign: TextAlign.center,
                                              style: Paw.text(
                                                14,
                                                weight: 700,
                                                color: Paw.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView(
                                        children: [
                                          for (final r in _rooms)
                                            _RoomRow(
                                              room: r,
                                              onJoin: _busy || !r.beacon.open
                                                  ? null
                                                  : () => _join(
                                                      r.address,
                                                      r.beacon.port,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.room, required this.onJoin});

  final FoundRoom room;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final b = room.beacon;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Paw.peachLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Paw.ink, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_rounded, color: Paw.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lobbyTitle(b.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Paw.text(15),
                ),
                Text(
                  b.open
                      ? l10n.lanRoomPlayers(b.players, NetConfig.maxPlayers)
                      : l10n.lanRoomBusy,
                  style: Paw.text(12, weight: 700, color: Paw.muted),
                ),
              ],
            ),
          ),
          PawButton(
            label: l10n.lanJoin,
            fill: Paw.green,
            height: 44,
            fontSize: 14,
            padding: 14,
            shadow: 3,
            onPressed: onJoin,
          ),
        ],
      ),
    );
  }
}
