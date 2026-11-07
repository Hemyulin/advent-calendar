import 'dart:math' as math;

import '../games/difficulty.dart';

enum CookieShape {
  star('Stern'),
  tree('Tannenbaum'),
  snowflake('Schneeflocke');

  const CookieShape(this.label);
  final String label;
}

enum CutDirection {
  up('Oben'),
  down('Unten'),
  left('Links'),
  right('Rechts');

  const CutDirection(this.label);
  final String label;
}

enum CookiePhase { ready, cutting, recovering, won, lost }

enum CutInput { ignored, correct, wrongDirection, wrongTiming }

class CookiePoint {
  const CookiePoint(this.x, this.y);
  final double x, y;
  CookiePoint operator +(CookiePoint other) =>
      CookiePoint(x + other.x, y + other.y);
  CookiePoint operator -(CookiePoint other) =>
      CookiePoint(x - other.x, y - other.y);
  CookiePoint operator *(double value) => CookiePoint(x * value, y * value);
  double get length => math.sqrt(x * x + y * y);
}

/// Closed polygon measured by arc length, shared by movement and rendering.
class CookieOutline {
  CookieOutline(List<CookiePoint> vertices)
    : points = List.unmodifiable(vertices) {
    var length = 0.0;
    lengths = List.unmodifiable(
      List.generate(points.length, (i) {
        length += (points[(i + 1) % points.length] - points[i]).length;
        return length;
      }),
    );
    totalLength = length;
  }
  final List<CookiePoint> points;
  late final List<double> lengths;
  late final double totalLength;

  factory CookieOutline.forShape(CookieShape shape) {
    if (shape == CookieShape.tree) {
      return CookieOutline(const [
        CookiePoint(.5, .1),
        CookiePoint(.7, .35),
        CookiePoint(.61, .35),
        CookiePoint(.8, .56),
        CookiePoint(.67, .56),
        CookiePoint(.88, .8),
        CookiePoint(.57, .8),
        CookiePoint(.57, .91),
        CookiePoint(.43, .91),
        CookiePoint(.43, .8),
        CookiePoint(.12, .8),
        CookiePoint(.33, .56),
        CookiePoint(.2, .56),
        CookiePoint(.39, .35),
        CookiePoint(.3, .35),
      ]);
    }
    final count = shape == CookieShape.star ? 10 : 36;
    return CookieOutline(
      List.generate(count, (i) {
        final radius = shape == CookieShape.star
            ? (i.isEven ? .42 : .2)
            : const [.43, .26, .32, .17, .32, .26][i % 6];
        final angle = -math.pi / 2 + i * 2 * math.pi / count;
        return CookiePoint(
          .5 + math.cos(angle) * radius,
          .5 + math.sin(angle) * radius,
        );
      }),
    );
  }

  int _segment(double fraction) {
    final distance = fraction.clamp(0.0, 1.0) * totalLength;
    final index = lengths.indexWhere((end) => end > distance);
    return index < 0 ? points.length - 1 : index;
  }

  CookiePoint at(double fraction) {
    final index = _segment(fraction);
    final start = index == 0 ? 0.0 : lengths[index - 1];
    final t =
        ((fraction.clamp(0.0, 1.0) * totalLength - start) /
                (lengths[index] - start))
            .clamp(0.0, 1.0);
    return points[index] +
        (points[(index + 1) % points.length] - points[index]) * t;
  }

  CookiePoint tangentAt(double fraction) {
    final index = _segment(fraction);
    final delta = points[(index + 1) % points.length] - points[index];
    return delta * (1 / delta.length);
  }
}

class CookieLevel {
  const CookieLevel({
    this.shape = CookieShape.tree,
    this.speed = .05,
    this.checkpoints = 9,
    this.timingWindowSeconds = .8,
    this.mistakeLimit = 3,
  });
  final CookieShape shape;

  /// Fraction of the full perimeter travelled per second.
  final double speed;

  /// Full timing window, centred on arrival at a checkpoint.
  final double timingWindowSeconds;
  final int checkpoints, mistakeLimit;

  factory CookieLevel.forDifficulty(GameDifficulty difficulty) =>
      switch (difficulty) {
        GameDifficulty.easy => const CookieLevel(
          shape: CookieShape.star,
          speed: .035,
          checkpoints: 6,
          timingWindowSeconds: 1.3,
        ),
        GameDifficulty.normal => const CookieLevel(),
        GameDifficulty.hard => const CookieLevel(
          shape: CookieShape.snowflake,
          speed: .075,
          checkpoints: 12,
          timingWindowSeconds: .46,
        ),
      };
}

class CutCheckpoint {
  const CutCheckpoint(this.fraction, this.direction);
  final double fraction;
  final CutDirection direction;
}

/// Each checkpoint must be cut correctly. A mistake briefly pauses the cutter,
/// then retries the same checkpoint; earlier successful cuts remain intact.
class CookieGame {
  CookieGame(this.level) {
    if (!level.speed.isFinite ||
        level.speed <= 0 ||
        level.speed > .5 ||
        !level.timingWindowSeconds.isFinite ||
        level.timingWindowSeconds <= 0 ||
        level.checkpoints < 1 ||
        level.checkpoints > 32 ||
        level.mistakeLimit < 1 ||
        level.timingWindowSeconds * level.speed >=
            1 / (level.checkpoints + 1)) {
      throw ArgumentError('Invalid cookie level');
    }
    outline = CookieOutline.forShape(level.shape);
    checkpoints = List.unmodifiable(
      List.generate(level.checkpoints, (i) {
        final fraction = (i + 1) / (level.checkpoints + 1);
        final tangent = outline.tangentAt(fraction);
        final direction = tangent.x.abs() > tangent.y.abs()
            ? (tangent.x > 0 ? CutDirection.right : CutDirection.left)
            : (tangent.y > 0 ? CutDirection.down : CutDirection.up);
        return CutCheckpoint(fraction, direction);
      }),
    );
  }
  final CookieLevel level;
  late final CookieOutline outline;
  late final List<CutCheckpoint> checkpoints;
  CookiePhase phase = CookiePhase.ready;
  double progress = 0;
  double cutUntil = 0;
  int next = 0;
  int mistakes = 0;
  double recoveryLeft = 0;
  CutInput? lastInput;
  CutCheckpoint? get target =>
      next < checkpoints.length ? checkpoints[next] : null;
  double get halfWindow => level.speed * level.timingWindowSeconds / 2;
  bool get inWindow =>
      phase == CookiePhase.cutting &&
      target != null &&
      (progress - target!.fraction).abs() <= halfWindow + 1e-10;
  double get secondsToTarget => target == null
      ? double.infinity
      : (target!.fraction - progress) / level.speed;
  bool get showCue =>
      target != null &&
      secondsToTarget <= math.max(1.35, level.timingWindowSeconds);

  void start() {
    if (phase == CookiePhase.ready) phase = CookiePhase.cutting;
  }

  void _mistake(CutInput input) {
    lastInput = input;
    mistakes++;
    if (mistakes >= level.mistakeLimit) {
      phase = CookiePhase.lost;
      return;
    }
    phase = CookiePhase.recovering;
    recoveryLeft = .6;
  }

  CutInput press(CutDirection direction) {
    if (phase != CookiePhase.cutting || target == null) return CutInput.ignored;
    if (!inWindow) {
      _mistake(CutInput.wrongTiming);
      return CutInput.wrongTiming;
    }
    if (direction != target!.direction) {
      _mistake(CutInput.wrongDirection);
      return CutInput.wrongDirection;
    }
    lastInput = CutInput.correct;
    cutUntil = target!.fraction;
    next++;
    return CutInput.correct;
  }

  void advance(double seconds) {
    if (!seconds.isFinite || seconds <= 0) return;
    if (phase == CookiePhase.recovering) {
      recoveryLeft = math.max(0, recoveryLeft - seconds);
      if (recoveryLeft == 0) {
        final approach = math.max(
          cutUntil,
          target!.fraction - level.speed * 1.35,
        );
        progress = math.min(progress, approach);
        phase = CookiePhase.cutting;
      }
      // Discard excess time so a stalled frame cannot consume multiple lives.
      return;
    }
    if (phase != CookiePhase.cutting) return;
    progress = math.min(1, progress + seconds * level.speed);
    if (target != null && progress > target!.fraction + halfWindow + 1e-10) {
      progress = target!.fraction + halfWindow;
      _mistake(CutInput.wrongTiming);
    } else if (target == null && progress >= 1) {
      cutUntil = 1;
      phase = CookiePhase.won;
    }
  }
}
