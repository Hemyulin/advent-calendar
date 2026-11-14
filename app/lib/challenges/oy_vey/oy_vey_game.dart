import 'dart:math' as math;

import '../games/difficulty.dart';

enum FestiveObject {
  sufganiyah('Sufganiyah', true),
  dreidel('Sevivon', true),
  hanukkiah('Chanukkiah', true),
  tree('Weihnachtsbaum', false),
  hat('Weihnachtsmütze', false),
  cane('Zuckerstange', false);

  const FestiveObject(this.label, this.correct);
  final String label;
  final bool correct;
}

class CatchMouth {
  const CatchMouth(this.x, this.y, this.halfWidth, {this.halfHeight = .018});
  final double x, y, halfWidth, halfHeight;
  bool get valid =>
      [x, y, halfWidth, halfHeight].every((v) => v.isFinite) &&
      x >= 0 &&
      x <= 1 &&
      y >= 0 &&
      y <= 1 &&
      halfWidth >= .03 &&
      halfWidth <= .25 &&
      halfHeight > 0 &&
      halfHeight <= .1;
}

class FallingObject {
  FallingObject({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    this.radius = .05,
  });
  final int id;
  final FestiveObject kind;
  final double x, radius;
  double y;
}

class OyVeyLevel {
  const OyVeyLevel({
    this.target = 15,
    this.mistakeLimit = 3,
    this.startSpeed = .16,
    this.spawnSeconds = .95,
    this.seed,
  });
  final int target, mistakeLimit;
  final double startSpeed, spawnSeconds;
  final int? seed;
  factory OyVeyLevel.forDifficulty(GameDifficulty difficulty) =>
      switch (difficulty) {
        GameDifficulty.easy => const OyVeyLevel(
          startSpeed: .13,
          spawnSeconds: 1.05,
        ),
        GameDifficulty.normal => const OyVeyLevel(),
        GameDifficulty.hard => const OyVeyLevel(
          startSpeed: .21,
          spawnSeconds: .8,
        ),
      };
}

/// Position-only collection. Missing tracking disables catches but objects keep
/// falling; reacquisition starts a fresh collision sweep.
class OyVeyGame {
  OyVeyGame(this.level, {math.Random? random})
    : _random = random ?? math.Random(level.seed) {
    if (level.target < 1 ||
        level.mistakeLimit < 1 ||
        !level.startSpeed.isFinite ||
        level.startSpeed <= 0 ||
        !level.spawnSeconds.isFinite ||
        level.spawnSeconds <= 0) {
      throw ArgumentError('Invalid level');
    }
  }
  final OyVeyLevel level;
  final math.Random _random;
  final List<FallingObject> objects = [];
  int collected = 0, mistakes = 0;
  double elapsed = 0, _spawn = 0;
  int _nextId = 0;
  CatchMouth? _previous;
  String feedback = '';
  double feedbackLeft = 0;
  bool get won => collected >= level.target;
  bool get lost => mistakes >= level.mistakeLimit;
  double get speed =>
      level.startSpeed *
      (1 + math.min(.75, collected / level.target * .6 + elapsed / 180));
  double get spawnInterval =>
      math.max(.5, level.spawnSeconds * (1 - collected / level.target * .3));
  void resetTracking() => _previous = null;

  void advance(double seconds, CatchMouth? mouth, {double aspectRatio = .75}) {
    if (won ||
        lost ||
        !seconds.isFinite ||
        seconds <= 0 ||
        !aspectRatio.isFinite ||
        aspectRatio <= 0) {
      return;
    }
    if (mouth != null && !mouth.valid) mouth = null;
    if (mouth == null) resetTracking();
    final dt = math.min(seconds, .1);
    final before = _previous ?? mouth;
    elapsed += dt;
    feedbackLeft = math.max(0, feedbackLeft - dt);
    _spawn += dt;
    if (_spawn >= spawnInterval) {
      _spawn -= spawnInterval;
      final kind = _random.nextDouble() < .7
          ? FestiveObject.values[_random.nextInt(3)]
          : FestiveObject.values[3 + _random.nextInt(3)];
      objects.add(
        FallingObject(
          id: _nextId++,
          kind: kind,
          x: .07 + _random.nextDouble() * .86,
          y: -.05,
        ),
      );
    }
    for (final object in objects.toList()) {
      final oldY = object.y;
      object.y += speed * dt;
      if (mouth != null &&
          _intersects(object, oldY, before!, mouth, aspectRatio)) {
        objects.remove(object);
        if (object.kind.correct) {
          collected++;
          feedback = 'Mazel tov!';
        } else {
          mistakes++;
          feedback = 'Oy vey!';
        }
        feedbackLeft = .9;
        if (won || lost) break;
      } else if (object.y - object.radius > 1) {
        objects.remove(object);
      }
    }
    _previous = mouth;
  }

  bool _intersects(
    FallingObject object,
    double oldY,
    CatchMouth before,
    CatchMouth after,
    double aspectRatio,
  ) {
    // Relative swept ellipse: covers fast objects and lateral head movement.
    final rx = after.halfWidth + object.radius,
        ry = after.halfHeight + object.radius * aspectRatio;
    final ax = (object.x - before.x) / rx, ay = (oldY - before.y) / ry;
    final bx = (object.x - after.x) / rx, by = (object.y - after.y) / ry;
    final dx = bx - ax, dy = by - ay;
    final denom = dx * dx + dy * dy;
    final t = denom == 0 ? 0.0 : (-(ax * dx + ay * dy) / denom).clamp(0.0, 1.0);
    return math.pow(ax + dx * t, 2) + math.pow(ay + dy * t, 2) <= 1;
  }
}
