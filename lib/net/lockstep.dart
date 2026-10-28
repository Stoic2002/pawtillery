import '../config/net.dart';
import '../sim/events.dart';
import '../sim/inputs.dart';
import '../sim/turn_manager.dart';
import '../sim/world.dart';
import 'protocol.dart';

/// Lockstep for Play on Wi-Fi. Every phone runs the same [SimWorld] and
/// steps it only with the inputs recorded for each tick, so all of them
/// stay identical.
///
/// Only the phone that controls the active team produces those inputs: one
/// frame per tick, [NetConfig.inputDelayTicks] ahead of its own sim, sent
/// to everyone. When the turn passes to a team another phone controls, the
/// producer stops after the frames it has already sent and says so
/// ([TicksMsg.end]); the next phone takes over from the following tick.
/// Every phone knows when that happens because the sim decides it. Inputs
/// do nothing during the turn banner, so the hand-over never delays play.
class Lockstep {
  Lockstep({
    required this.owners,
    required this.me,
    required this.send,
    required this.onHash,
    this.delay = NetConfig.inputDelayTicks,
    this.hashInterval = NetConfig.hashIntervalTicks,
  });

  /// Player id controlling each team.
  final List<int> owners;

  /// This phone's player id.
  final int me;

  /// Frames this phone produced, for everyone else.
  final void Function(TicksMsg message) send;

  /// State hash after every [hashInterval]-th tick and after the last one.
  final void Function(int tick, int hash) onHash;

  final int delay;
  final int hashInterval;

  /// Set once the game has built the world; frames may arrive before that.
  late final SimWorld sim;

  /// Frames not yet stepped, by tick.
  final Map<int, List<SimInput>> _frames = {};

  /// Last tick with a frame (all earlier ones have one too).
  int _known = 0;

  /// The last producer has stopped after [_known]: the next team's phone
  /// may start. True at the start of the match.
  bool _handOver = true;
  bool _producing = false;

  /// Tick this phone may take its own turn back from without a hand-over
  /// (see [resumeOwnTurn]); null otherwise.
  int? _resumeAt;

  /// Stops stepping (a player left, desync). Frames keep arriving.
  bool paused = false;

  /// Time since the last step; the arena shows who it is waiting for.
  final Stopwatch sinceStep = Stopwatch()..start();

  void attach(SimWorld world) => sim = world;

  int ownerOf(int team) =>
      team < 0 || team >= owners.length ? -1 : owners[team];

  /// Player controlling the active team.
  int get activeOwner => ownerOf(sim.turn.activeTeam);

  bool get isMyTurn => activeOwner == me;

  bool get isOver => sim.turn.phase == TurnPhase.matchOver;

  /// Frames received but not yet stepped.
  int get buffered => _known - sim.tick;

  /// This phone came back after its app was closed, maybe in the middle of
  /// its own turn: nobody will hand that turn over, since the phone that
  /// was playing it is gone. Once it has stepped every tick known now, if
  /// the turn is still its own it carries on producing. (No frames of that
  /// old app can still be on their way: it is gone.)
  void resumeOwnTurn() => _resumeAt = _known;

  /// Frames from the producing phone (relayed by the host).
  void receive(TicksMsg message) {
    // TCP keeps order and there is one producer at a time, so anything
    // else is a stale duplicate.
    if (message.from != _known + 1) return;
    for (var i = 0; i < message.frames.length; i++) {
      _frames[message.from + i] = message.frames[i];
    }
    _known += message.frames.length;
    _handOver = message.end;
  }

  /// Called once per tick of real time. If this phone controls the active
  /// team, records frames up to [delay] ticks ahead: [held] (walk, dig
  /// direction) in each, [queued] (jump, fire) in the first. Returns
  /// whether [queued] was used.
  bool produce(List<SimInput> held, List<SimInput> queued) {
    if (isOver) return false;
    // Only once every known tick is stepped: a phone catching up (after
    // rejoining) must not take an old turn of its own for a new one.
    final resume = _resumeAt;
    if (resume != null && sim.tick >= resume) {
      _resumeAt = null;
      if (sim.tick == _known && isMyTurn) _handOver = true;
    }
    if (!_producing && _handOver && isMyTurn && sim.tick >= _known) {
      _producing = true;
      _handOver = false;
    }
    if (!_producing) return false;
    final target = sim.tick + delay;
    if (_known >= target) return false;
    final from = _known + 1;
    final frames = <List<SimInput>>[];
    while (_known < target) {
      final frame = [...held, if (frames.isEmpty) ...queued];
      _known++;
      _frames[_known] = frame;
      frames.add(frame);
    }
    send(TicksMsg(from: from, frames: frames));
    return true;
  }

  /// Steps one tick if its frame is here; null while waiting.
  List<SimEvent>? step() {
    if (paused || isOver) return null;
    final inputs = _frames.remove(sim.tick + 1);
    if (inputs == null) return null;
    final events = sim.step(inputs);
    sinceStep.reset();
    if (sim.tick % hashInterval == 0 || isOver) {
      onHash(sim.tick, sim.stateHash());
    }
    if (_producing && (isOver || !isMyTurn)) {
      _producing = false;
      if (!isOver) {
        send(TicksMsg(from: _known + 1, frames: const [], end: true));
        _handOver = true;
      }
    }
    return events;
  }
}
