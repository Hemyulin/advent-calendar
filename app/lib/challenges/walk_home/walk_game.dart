import 'dart:math' as math;
import '../games/difficulty.dart';

enum WalkPhase { ready, walking, fallen, home }

enum StreetObstacleKind { snowman, bicycle, bin, ice, reveller }

class WalkLevel {
  const WalkLevel({
    this.seconds = 37,
    this.halfWidth = .72,
    this.wobble = .8,
    this.spacing = 3.2,
    this.leanLimit = .72,
    this.fallGrace = .85,
    this.seed,
  });
  final double seconds, halfWidth, wobble, spacing, leanLimit, fallGrace;
  final int? seed;
  factory WalkLevel.forDifficulty(GameDifficulty difficulty) =>
      switch (difficulty) {
        GameDifficulty.easy => const WalkLevel(
          seconds: 32,
          halfWidth: .9,
          wobble: .6,
          spacing: 4.1,
          leanLimit: .8,
          fallGrace: 1.1,
        ),
        GameDifficulty.normal => const WalkLevel(),
        GameDifficulty.hard => const WalkLevel(
          seconds: 42,
          halfWidth: .56,
          wobble: 1.05,
          spacing: 2.8,
          leanLimit: .65,
          fallGrace: .75,
        ),
      };
}

class StreetObstacle {
  StreetObstacle(this.kind, this.at, this.x, this.halfWidth, this.kickSign);
  final StreetObstacleKind kind;

  /// Time along the automatically travelled street; collisions occur at at.
  final double at, x, halfWidth, kickSign;
  bool passed = false, hit = false;
}

/// An unstable, damped balance system with bounded smooth random disturbances.
/// World x is shared with the perspective renderer. The road always leaves a
/// passable gap; collisions destabilize instead of causing an instant loss.
class WalkGame {
  WalkGame(this.level, {math.Random? random})
    : _random = random ?? math.Random(level.seed) {
    if ([
          level.seconds,
          level.halfWidth,
          level.wobble,
          level.spacing,
          level.leanLimit,
          level.fallGrace,
        ].any((v) => !v.isFinite || v <= 0) ||
        level.halfWidth < .45 ||
        level.halfWidth > 1 ||
        level.spacing < 2) {
      throw ArgumentError('Invalid walk level');
    }
    lean = (_random.nextDouble() - .5) * .2;
    final route = <StreetObstacle>[];
    for (var at = 5.5; at < level.seconds - 3; at += level.spacing) {
      final kind = StreetObstacleKind
          .values[route.length % StreetObstacleKind.values.length];
      final lane = _random.nextInt(3) - 1;
      final width = switch (kind) {
        StreetObstacleKind.snowman => .14,
        StreetObstacleKind.bicycle => .2,
        StreetObstacleKind.bin => .12,
        StreetObstacleKind.ice => .22,
        StreetObstacleKind.reveller => .24,
      };
      route.add(
        StreetObstacle(
          kind,
          at,
          lane * level.halfWidth * .58,
          width,
          _random.nextBool() ? 1 : -1,
        ),
      );
    }
    obstacles = List.unmodifiable(route);
  }
  final WalkLevel level;
  final math.Random _random;
  late final List<StreetObstacle> obstacles;
  WalkPhase phase = WalkPhase.ready;
  double elapsed = 0,
      x = 0,
      lean = 0,
      angularVelocity = 0,
      unstableTime = 0,
      slipperyLeft = 0,
      impactLeft = 0;
  double _noise = 0, _noiseTarget = 0, _nextGust = 0;
  int bumps = 0;
  String feedback = '';
  static const characterRadius = .075;
  double get progress => (elapsed / level.seconds).clamp(0.0, 1.0);
  double get danger => (unstableTime / level.fallGrace).clamp(0.0, 1.0);
  double get remaining => math.max(0, level.seconds - elapsed);
  bool get atEdge => x.abs() > level.halfWidth - characterRadius;
  void start() {
    if (phase == WalkPhase.ready) phase = WalkPhase.walking;
  }

  void advance(double seconds, double input) {
    if (phase != WalkPhase.walking ||
        !seconds.isFinite ||
        seconds <= 0 ||
        !input.isFinite) {
      return;
    }
    final dt = math.min(seconds, .1);
    final steps = (dt / (1 / 120)).ceil(), h = dt / steps;
    for (var i = 0; i < steps && phase == WalkPhase.walking; i++) {
      _step(h, input.clamp(-1.0, 1.0));
    }
  }

  void _step(double h, double input) {
    final previous = elapsed;
    elapsed = math.min(level.seconds, elapsed + h);
    if (elapsed >= _nextGust) {
      _noiseTarget = (_random.nextDouble() * 2 - 1) * level.wobble;
      _nextGust = elapsed + .8 + _random.nextDouble() * .9;
    }
    _noise += (_noiseTarget - _noise) * (1 - math.exp(-3 * h));
    final ice = slipperyLeft > 0;
    final acceleration =
        lean * 1.15 +
        _noise +
        math.sin(elapsed * 2.1) * .12 +
        input * (ice ? 2.8 : 4) -
        (ice ? 1.6 : 2.6) * angularVelocity +
        (atEdge ? x.sign * 1.6 : 0);
    angularVelocity = (angularVelocity + acceleration * h).clamp(-2.2, 2.2);
    lean = (lean + angularVelocity * h).clamp(-1.8, 1.8);
    x = (x + (lean * .6 + input * .2) * h).clamp(-1.15, 1.15);
    slipperyLeft = math.max(0, slipperyLeft - h);
    impactLeft = math.max(0, impactLeft - h);
    for (final obstacle in obstacles) {
      if (obstacle.passed || obstacle.at > elapsed || obstacle.at < previous) {
        continue;
      }
      obstacle.passed = true;
      if ((x - obstacle.x).abs() <= obstacle.halfWidth + characterRadius) {
        obstacle.hit = true;
        bumps++;
        impactLeft = 1;
        final sign = (x - obstacle.x).abs() > .03
            ? (x - obstacle.x).sign
            : obstacle.kickSign;
        if (obstacle.kind == StreetObstacleKind.ice) {
          slipperyLeft = 1.7;
          angularVelocity += sign * .2;
          feedback = 'Rutschig!';
        } else {
          lean += sign * .23;
          angularVelocity += sign * .38;
          feedback = 'Hoppla!';
        }
      }
    }
    if (lean.abs() > level.leanLimit || atEdge) {
      unstableTime += h;
    } else {
      unstableTime = math.max(0, unstableTime - h * 1.5);
    }
    if (unstableTime >= level.fallGrace) {
      phase = WalkPhase.fallen;
    } else if (elapsed >= level.seconds) {
      phase = WalkPhase.home;
    }
  }
}
