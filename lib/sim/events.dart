import 'physics.dart';
import 'terrain_mask.dart';

/// Events emitted by the simulation for rendering, audio and UI to react to.
sealed class SimEvent {
  const SimEvent();
}

/// Terrain within [radius] of ([x], [y]) was removed. [carved] is the
/// touched mask area (null if entirely off-map).
final class ExplosionEvent extends SimEvent {
  const ExplosionEvent({
    required this.x,
    required this.y,
    required this.radius,
    required this.carved,
  });

  final int x;
  final int y;
  final int radius;
  final IntRect? carved;
}

final class ProjectileLaunched extends SimEvent {
  const ProjectileLaunched(this.id);
  final int id;
}

final class ProjectileRemoved extends SimEvent {
  const ProjectileRemoved(this.id, this.outcome);
  final int id;
  final FlightOutcome outcome;
}

final class WindChanged extends SimEvent {
  const WindChanged(this.wind);
  final int wind;
}
