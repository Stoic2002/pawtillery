import '../config/cpu.dart';
import '../config/weapons.dart';
import '../sim/inputs.dart';
import '../sim/turn_manager.dart';
import '../sim/unit.dart';
import '../sim/world.dart';
import 'cpu_planner.dart';

/// What a CPU turn shows on screen: the weapon it holds and where it aims.
class CpuAim {
  const CpuAim({
    required this.weaponId,
    required this.angle,
    required this.power,
    this.targetX,
    this.targetY,
  });

  final String weaponId;
  final int angle;
  final int power;
  final int? targetX;
  final int? targetY;
}

/// Plays the turns of computer-controlled teams in a hotseat match. Called
/// once per sim tick, it returns that tick's inputs: it plans while the
/// turn banner shows, walks towards an enemy first if nothing is in reach,
/// swings the aim into place so the players see the shot coming, then
/// fires. Pure Dart; reads the world, never changes it.
class CpuPlayer {
  CpuPlayer({required this.levels, required this.seed});

  /// Level of each CPU team (sim team index); other teams are players.
  final Map<int, CpuLevel> levels;
  final int seed;

  _CpuTurn? _turn;

  /// The active team is a CPU team.
  bool controls(SimWorld w) => levels.containsKey(w.turn.activeTeam);

  /// The aim to show, while the CPU is aiming; null otherwise.
  CpuAim? get aim => _turn?.aim;

  /// This tick's inputs for [w] (none on a player's turn).
  List<SimInput> step(SimWorld w) {
    final level = levels[w.turn.activeTeam];
    final unit = w.activeUnit;
    if (level == null || unit == null || !unit.alive) {
      _turn = null;
      return const [];
    }
    var turn = _turn;
    if (turn == null || turn.number != w.turn.turnNumber) {
      turn = _turn = _CpuTurn(
        w.turn.turnNumber,
        CpuTuning.of(level),
        seed ^ (w.turn.turnNumber * 0x9E3779B1),
      );
    }
    return turn.step(w, unit);
  }
}

enum _Stage { planning, walking, aiming }

class _CpuTurn {
  _CpuTurn(this.number, this.tuning, this.seed);

  final int number;
  final CpuTuning tuning;
  final int seed;

  _Stage _stage = _Stage.planning;
  CpuPlanner? _planner;
  CpuPlan? _plan;
  bool _walked = false;
  int _walkDir = 0;
  int _walkLeft = 0;
  int _actionTicks = 0;
  int _aimTicks = 0;
  int _shots = 0;
  CpuAim? aim;

  List<SimInput> step(SimWorld w, Unit me) {
    final phase = w.turn.phase;
    if (phase == TurnPhase.action) _actionTicks++;
    if (phase != TurnPhase.turnStart && !w.turn.allowsFire) {
      aim = null;
      return const [];
    }
    final clock = w.turn.clockTicks;
    final hurry = clock != null && clock < CpuConfig.hurryTicks;

    switch (_stage) {
      case _Stage.walking:
        if (_walkLeft > 0 && !hurry && _safeAhead(w, me, _walkDir)) {
          _walkLeft--;
          return [Walk(_walkDir)];
        }
        // Wait for the unit to come to rest before planning again.
        if (!me.grounded) return const [];
        _stage = _Stage.planning;
        return const [];

      case _Stage.planning:
        // Plan from where the unit stands once it has landed.
        if (!me.grounded) return const [];
        final planner = _planner ??=
            CpuPlanner(w, tuning, seed: seed + _shots * 7 + (_walked ? 1 : 0));
        if (hurry) planner.finish();
        if (!planner.work()) return const [];
        final plan = planner.result;
        if (phase != TurnPhase.action || plan == null) return const [];
        _planner = null;
        if (!_walked &&
            !hurry &&
            _shots == 0 &&
            plan.score < CpuConfig.walkIfBelow) {
          _walked = true;
          _walkDir = _towardsNearestEnemy(w, me);
          if (_walkDir != 0 && _safeAhead(w, me, _walkDir)) {
            _walkLeft = CpuConfig.walkTicks;
            _stage = _Stage.walking;
            return const [];
          }
        }
        _plan = plan;
        _aimTicks = 0;
        _stage = _Stage.aiming;
        return const [];

      case _Stage.aiming:
        final plan = _plan!;
        final weapon = Weapons.byId(plan.fire.weaponId);
        final think = _shots == 0 ? tuning.thinkTicks : 10;
        if (_actionTicks < think && !hurry) return const [];
        _aimTicks++;
        final total = switch (weapon.aim) {
          AimMode.target => CpuConfig.targetTicks,
          AimMode.none => 15,
          _ => CpuConfig.aimTicks,
        };
        aim = _aimAt(me, plan.fire, weapon, (_aimTicks / total).clamp(0, 1));
        if (_aimTicks < total && !hurry) return const [];
        _shots++;
        _plan = null;
        aim = null;
        // A weapon that leaves the turn open (shotgun) gets a new plan.
        _stage = _Stage.planning;
        return [plan.fire];
    }
  }

  /// The aim on screen [t] (0–1) of the way to the planned [fire].
  CpuAim _aimAt(Unit me, Fire fire, WeaponDef weapon, double t) {
    if (weapon.aim == AimMode.target) {
      return CpuAim(
        weaponId: fire.weaponId,
        angle: 0,
        power: 0,
        targetX: fire.targetX,
        targetY: fire.targetY,
      );
    }
    final from = me.facing > 0 ? 45 : 135;
    var delta = (fire.angleDeg - from) % 360;
    if (delta > 180) delta -= 360;
    final eased = t * t * (3 - 2 * t);
    return CpuAim(
      weaponId: fire.weaponId,
      angle: (from + delta * eased).round() % 360,
      power: (50 + (fire.powerPercent - 50) * eased).round(),
    );
  }

  static int _towardsNearestEnemy(SimWorld w, Unit me) {
    Unit? nearest;
    for (final u in w.units) {
      if (!u.alive || u.team == me.team) continue;
      if (nearest == null ||
          (u.centerX - me.centerX).abs() < (nearest.centerX - me.centerX).abs()) {
        nearest = u;
      }
    }
    if (nearest == null) return 0;
    return nearest.centerX >= me.centerX ? 1 : -1;
  }

  /// Ground a few px ahead, not far below the feet and above the water.
  static bool _safeAhead(SimWorld w, Unit me, int dir) {
    final x = me.x.round() + dir * 10;
    if (x < 2 || x >= w.terrain.width - 2) return false;
    final top = me.y.round() - me.stats.maxClimb - me.stats.bodyHeight;
    for (var y = top < 0 ? 0 : top; y < w.waterLevel; y++) {
      if (w.terrain.isSolid(x, y)) return y - me.y < 60;
    }
    return false;
  }
}
