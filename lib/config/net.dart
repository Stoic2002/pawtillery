/// Local-network multiplayer (Play on Wi-Fi): ports, timing and limits.
abstract final class NetConfig {
  /// Bumped whenever a message changes shape or the simulation changes
  /// without an app version bump (new weapons); phones with another version
  /// are turned away in the lobby. 2 = bomber, satellite, homing missile;
  /// 3 = jet missile, storm cloud delay, bird flock; 4 = map objects;
  /// 5 = dig mode, black hole, sticky bomb, clay, swap; 14 = random
  /// weapons rule; 15 = rejoining a match; 16 = pet gravity, gas damage,
  /// rebalanced and reworked weapons, crumbling sudden death; 17 =
  /// rejoining after a restart; 18 = eggs arm on their first touch;
  /// 19 = lighter flowerpots, reshaped caves and trees; 20 = painted
  /// maps (3600 x 1200).
  static const int protocolVersion = 22;

  /// UDP port the host's room beacon is sent to.
  static const int discoveryPort = 47820;

  /// TCP port the host listens on (any free port if it is taken).
  static const int gamePort = 47821;

  static const Duration beaconInterval = Duration(seconds: 1);

  /// A room that sent no beacon for this long drops off the list.
  static const Duration roomTimeout = Duration(seconds: 4);

  /// Every link sends a ping this often while it is otherwise quiet...
  static const Duration heartbeat = Duration(seconds: 1);

  /// ...and counts as lost after hearing nothing for this long.
  static const Duration peerTimeout = Duration(seconds: 6);

  static const Duration connectTimeout = Duration(seconds: 4);

  /// A guest that lost its connection mid-match tries to rejoin every
  /// [rejoinRetry] for up to [rejoinWindow] before giving up on the host.
  static const Duration rejoinRetry = Duration(seconds: 2);
  static const Duration rejoinWindow = Duration(seconds: 90);

  /// Host plus up to three guests (the most teams a match can have).
  static const int maxPlayers = 4;

  /// The active phone sends its inputs this many ticks ahead of its own
  /// simulation, so the others usually have them before they need them.
  /// Must stay below the turn banner (90 ticks): the turn can only change
  /// hands while no inputs matter.
  static const int inputDelayTicks = 4;

  /// Phones compare state hashes this often (and once at the end).
  static const int hashIntervalTicks = 60;

  /// A phone with more inputs waiting than this steps faster to catch up.
  static const int catchUpTicks = 12;

  /// With more than this waiting (a phone that rejoined after a restart
  /// replays the whole match so far) it fast-forwards: as many ticks as
  /// fit in [fastForwardBudget] each frame, without sound or particles.
  static const int fastForwardTicks = 240;
  static const Duration fastForwardBudget = Duration(milliseconds: 10);

  static const int maxNameLength = 16;
}
