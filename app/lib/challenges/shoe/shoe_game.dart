import 'dart:math';

import '../games/difficulty.dart';

enum ShoePhase { cleaning, polishing, finished }

class ShoePoint {
  const ShoePoint(this.x, this.y);
  final double x, y;
}

/// The same normalized outline is used for hit testing and illustration.
const shoeOutline = [
  ShoePoint(0.26, 0.13),
  ShoePoint(0.57, 0.13),
  ShoePoint(0.59, 0.51),
  ShoePoint(0.70, 0.54),
  ShoePoint(0.84, 0.61),
  ShoePoint(0.91, 0.72),
  ShoePoint(0.90, 0.82),
  ShoePoint(0.83, 0.88),
  ShoePoint(0.23, 0.88),
  ShoePoint(0.17, 0.82),
  ShoePoint(0.17, 0.73),
  ShoePoint(0.25, 0.60),
];

bool insideShoe(ShoePoint point) {
  var inside = false;
  for (var i = 0, j = shoeOutline.length - 1; i < shoeOutline.length; j = i++) {
    final a = shoeOutline[i], b = shoeOutline[j];
    if ((a.y > point.y) != (b.y > point.y) &&
        point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x) {
      inside = !inside;
    }
  }
  return inside;
}

class ShoeLevel {
  const ShoeLevel({
    this.columns = 11,
    this.rows = 10,
    this.brushRadius = 0.095,
    this.toughness = 1.25,
    this.seed = 1206,
  });
  factory ShoeLevel.forDifficulty(GameDifficulty difficulty) =>
      switch (difficulty) {
        GameDifficulty.easy => const ShoeLevel(
          columns: 9,
          rows: 8,
          brushRadius: 0.12,
          toughness: 0.85,
        ),
        GameDifficulty.normal => const ShoeLevel(),
        GameDifficulty.hard => const ShoeLevel(
          columns: 13,
          rows: 12,
          brushRadius: 0.08,
          toughness: 1.6,
        ),
      };
  final int columns, rows, seed;
  final double brushRadius, toughness;
}

class ShoePatch {
  ShoePatch(this.center, this.initialDirt) : dirt = initialDirt;
  final ShoePoint center;
  final double initialDirt;
  double dirt;
  double polish = 0;
}

/// Gesture-driven cleaning. Taps and stationary rubbing do not remove dirt.
/// Segment/brush overlap makes fast strokes independent of pointer event rate.
class ShoeGame {
  ShoeGame(this.level) {
    if (level.columns < 3 ||
        level.rows < 3 ||
        level.brushRadius <= 0 ||
        level.toughness <= 0) {
      throw ArgumentError('Invalid shoe level');
    }
    final random = Random(level.seed);
    _patches = [
      for (var y = 0; y < level.rows; y++)
        for (var x = 0; x < level.columns; x++)
          if (insideShoe(
            ShoePoint((x + 0.5) / level.columns, (y + 0.5) / level.rows),
          ))
            ShoePatch(
              ShoePoint((x + 0.5) / level.columns, (y + 0.5) / level.rows),
              level.toughness * (0.8 + random.nextDouble() * 0.4),
            ),
    ];
    if (_patches.isEmpty) throw ArgumentError('Empty shoe mask');
  }
  final ShoeLevel level;
  late final List<ShoePatch> _patches;
  List<ShoePatch> get patches => List.unmodifiable(_patches);
  ShoePhase phase = ShoePhase.cleaning;
  bool get won => phase == ShoePhase.finished;
  double get cleanProgress =>
      1 -
      _patches.fold<double>(0, (sum, p) => sum + p.dirt / p.initialDirt) /
          _patches.length;
  double get polishProgress =>
      _patches.fold<double>(0, (sum, p) => sum + p.polish) / _patches.length;
  double get progress =>
      phase == ShoePhase.cleaning ? cleanProgress : polishProgress;

  bool stroke(ShoePoint from, ShoePoint to) {
    if (won ||
        !from.x.isFinite ||
        !from.y.isFinite ||
        !to.x.isFinite ||
        !to.y.isFinite) {
      return false;
    }
    final dx = to.x - from.x, dy = to.y - from.y;
    final length = sqrt(dx * dx + dy * dy);
    if (length < 0.002) return false;
    var changed = false;
    for (final patch in _patches) {
      final t =
          (((patch.center.x - from.x) * dx + (patch.center.y - from.y) * dy) /
                  (length * length))
              .clamp(0.0, 1.0);
      final ex = patch.center.x - from.x - dx * t;
      final ey = patch.center.y - from.y - dy * t;
      final distanceSquared = ex * ex + ey * ey;
      final radius = level.brushRadius;
      if (distanceSquared >= radius * radius) continue;
      final overlap = min(length, 2 * sqrt(radius * radius - distanceSquared));
      if (phase == ShoePhase.cleaning && patch.dirt > 0) {
        patch.dirt = max(0.0, patch.dirt - overlap * 4.8);
        changed = true;
      } else if (phase == ShoePhase.polishing && patch.polish < 1) {
        patch.polish = min(1.0, patch.polish + overlap * 6);
        changed = true;
      }
    }
    if (phase == ShoePhase.cleaning && _patches.every((p) => p.dirt == 0)) {
      phase = ShoePhase.polishing;
    } else if (phase == ShoePhase.polishing &&
        _patches.every((p) => p.polish == 1)) {
      phase = ShoePhase.finished;
    }
    return changed;
  }

  /// Equivalent small brush stroke for assistive technologies.
  void brushNextPatch() {
    if (won) return;
    final target = _patches.firstWhere(
      (p) => phase == ShoePhase.cleaning ? p.dirt > 0 : p.polish < 1,
    );
    stroke(
      ShoePoint(target.center.x - level.brushRadius, target.center.y),
      ShoePoint(target.center.x + level.brushRadius, target.center.y),
    );
  }
}
