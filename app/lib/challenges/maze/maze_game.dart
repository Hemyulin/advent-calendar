import 'dart:math';

import '../games/difficulty.dart';

class Vec2 {
  const Vec2(this.x, this.y);
  static const zero = Vec2(0, 0);
  final double x;
  final double y;
  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator *(double factor) => Vec2(x * factor, y * factor);
  double get length => sqrt(x * x + y * y);
}

class MazeWall {
  const MazeWall(this.x, this.y, this.width, this.height);
  final double x, y, width, height;
}

class MazeLayout {
  const MazeLayout({
    required this.cells,
    required this.walls,
    required this.start,
    required this.goal,
    required this.pits,
  });
  final int cells;
  final List<MazeWall> walls;
  final Vec2 start;
  final Vec2 goal;
  final List<Vec2> pits;
  double get ballRadius => 0.16 / cells;
  double get pitRadius => 0.23 / cells;
  double get pitCaptureRadius => pitRadius * 0.8;
  double get goalRadius => 0.34 / cells;

  /// Pick a seeded maze with a substantial route, turns, and useful forks.
  /// Pits sit on straight sections of the solution route, offset to leave a
  /// navigable passing lane. Start, finish and tight corners stay clear.
  factory MazeLayout.generate({
    required int cells,
    required int seed,
    int pitCount = 2,
  }) {
    if (cells < 3 || cells > 12 || pitCount < 0) {
      throw ArgumentError('Invalid maze');
    }
    final random = Random(seed);
    int edge(int a, int b) => min(a, b) * cells * cells + max(a, b);
    List<int> neighbors(int cell) => [
      if (cell % cells > 0) cell - 1,
      if (cell % cells < cells - 1) cell + 1,
      if (cell >= cells) cell - cells,
      if (cell < cells * (cells - 1)) cell + cells,
    ];
    List<int> hazardIndices(List<int> path) {
      final candidates = <int>[
        for (var i = 2; i < path.length - 2; i++)
          if (path[i] % cells > 0 &&
              path[i] % cells < cells - 1 &&
              path[i] ~/ cells > 0 &&
              path[i] ~/ cells < cells - 1 &&
              path[i] - path[i - 1] == path[i + 1] - path[i])
            i,
      ];
      final selected = <int>[];
      for (var n = 0; n < pitCount; n++) {
        final desired = (n + 1) * (path.length - 1) / (pitCount + 1);
        final available =
            candidates
                .where(
                  (i) => selected.every((chosen) => (i - chosen).abs() >= 4),
                )
                .toList()
              ..sort(
                (a, b) => (a - desired).abs().compareTo((b - desired).abs()),
              );
        if (available.isNotEmpty) selected.add(available.first);
      }
      return selected..sort();
    }

    Set<int> passages = {};
    List<int> route = [];
    var bestScore = double.negativeInfinity;
    for (var attempt = 0; attempt < 40; attempt++) {
      final visited = <int>{0};
      final stack = <int>[0];
      final parent = <int, int>{};
      final candidate = <int>{};
      while (stack.isNotEmpty) {
        final current = stack.last;
        final choices = neighbors(
          current,
        ).where((n) => !visited.contains(n)).toList()..shuffle(random);
        if (choices.isEmpty) {
          stack.removeLast();
          continue;
        }
        final next = choices.first;
        visited.add(next);
        candidate.add(edge(current, next));
        parent[next] = current;
        stack.add(next);
      }
      final path = <int>[];
      int? cursor = cells * cells - 1;
      while (cursor != null) {
        path.add(cursor);
        cursor = parent[cursor];
      }
      var turns = 0;
      for (var i = 2; i < path.length; i++) {
        if (path[i] - path[i - 1] != path[i - 1] - path[i - 2]) turns++;
      }
      final forks = path
          .where(
            (cell) =>
                neighbors(
                  cell,
                ).where((n) => candidate.contains(edge(cell, n))).length >=
                3,
          )
          .length;
      var score = path.length + turns * 0.75 + min(forks, 5) * 2;
      if (path.length < cells * cells * 0.5) score -= 1000;
      if (hazardIndices(path.reversed.toList()).length < pitCount) {
        score -= 1000;
      }
      // Keep room for branching instead of choosing one long, empty corridor.
      if (path.length > cells * cells * 0.8) {
        score -= (path.length - cells * cells * 0.8) * 3;
      }
      if (score > bestScore) {
        bestScore = score;
        passages = candidate;
        route = path;
      }
    }
    const thickness = 0.014;
    final step = 1 / cells;
    final walls = <MazeWall>[
      const MazeWall(0, 0, 1, thickness),
      const MazeWall(0, 1 - thickness, 1, thickness),
      const MazeWall(0, 0, thickness, 1),
      const MazeWall(1 - thickness, 0, thickness, 1),
    ];
    for (var cell = 0; cell < cells * cells; cell++) {
      final x = cell % cells * step;
      final y = cell ~/ cells * step;
      if (cell % cells < cells - 1 &&
          !passages.contains(edge(cell, cell + 1))) {
        walls.add(
          MazeWall(
            x + step - thickness / 2,
            y - thickness / 2,
            thickness,
            step + thickness,
          ),
        );
      }
      if (cell < cells * (cells - 1) &&
          !passages.contains(edge(cell, cell + cells))) {
        walls.add(
          MazeWall(
            x - thickness / 2,
            y + step - thickness / 2,
            step + thickness,
            thickness,
          ),
        );
      }
    }
    Vec2 center(int cell) =>
        Vec2((cell % cells + 0.5) * step, (cell ~/ cells + 0.5) * step);
    final travelRoute = route.reversed.toList();
    final hazards = hazardIndices(travelRoute);
    final pits = <Vec2>[];
    for (var n = 0; n < hazards.length; n++) {
      final index = hazards[n];
      final direction =
          center(travelRoute[index + 1]) - center(travelRoute[index - 1]);
      final normal = Vec2(-direction.y, direction.x) * (1 / direction.length);
      // The central travel line enters the capture radius, so the player must
      // steer. The opposite side has a full ball-width passing lane.
      final side = n.isEven ? 1.0 : -1.0;
      pits.add(center(travelRoute[index]) + normal * (step * 0.16 * side));
    }
    return MazeLayout(
      cells: cells,
      walls: List.unmodifiable(walls),
      start: center(0),
      goal: center(cells * cells - 1),
      pits: List.unmodifiable(pits),
    );
  }
}

class MazeCourse {
  const MazeCourse({required this.layouts, this.lives = 6});
  final List<MazeLayout> layouts;
  final int lives;

  factory MazeCourse.forDifficulty(
    GameDifficulty difficulty, {
    int seed = 1224,
  }) {
    final base = switch (difficulty) {
      GameDifficulty.easy => 4,
      GameDifficulty.normal => 5,
      GameDifficulty.hard => 6,
    };
    return MazeCourse(
      lives: switch (difficulty) {
        GameDifficulty.easy => 8,
        GameDifficulty.normal => 6,
        GameDifficulty.hard => 4,
      },
      layouts: [
        MazeLayout.generate(
          cells: base,
          seed: seed,
          pitCount: difficulty.index + 1,
        ),
      ],
    );
  }
}

/// Fixed, small physics steps avoid tunnelling and frame-rate-dependent motion.
/// Positions and geometry are normalized so physics is independent of pixels.
class MazeGame {
  MazeGame(this.course) {
    if (course.layouts.length != 1 || course.lives < 1) {
      throw ArgumentError('Invalid course');
    }
    position = layout.start;
  }
  final MazeCourse course;
  int falls = 0;
  bool won = false;
  late Vec2 position;
  Vec2 velocity = Vec2.zero;
  MazeLayout get layout => course.layouts.single;
  int get livesLeft => course.lives - falls;
  bool get lost => livesLeft == 0;
  void stop() => velocity = Vec2.zero;

  void advance(double elapsed, Vec2 tilt) {
    if (won ||
        lost ||
        elapsed <= 0 ||
        !elapsed.isFinite ||
        !tilt.x.isFinite ||
        !tilt.y.isFinite) {
      return;
    }
    final dt = min(elapsed, 0.05);
    final steps = (dt / (1 / 120)).ceil();
    final h = dt / steps;
    final input = tilt.length > 1 ? tilt * (1 / tilt.length) : tilt;
    for (var i = 0; i < steps; i++) {
      velocity = (velocity + input * (2.8 * h)) * exp(-3.2 * h);
      if (velocity.length > 0.65) {
        velocity = velocity * (0.65 / velocity.length);
      }
      position = position + velocity * h;
      for (final wall in layout.walls) {
        _collide(wall);
      }
      if (layout.pits.any(
        (pit) => (position - pit).length < layout.pitCaptureRadius,
      )) {
        falls++;
        position = layout.start;
        velocity = Vec2.zero;
        break;
      }
      if ((position - layout.goal).length < layout.goalRadius) {
        position = layout.goal;
        velocity = Vec2.zero;
        won = true;
        break;
      }
    }
  }

  void _collide(MazeWall wall) {
    final closest = Vec2(
      position.x.clamp(wall.x, wall.x + wall.width),
      position.y.clamp(wall.y, wall.y + wall.height),
    );
    var delta = position - closest;
    var distance = delta.length;
    if (distance >= layout.ballRadius) return;
    if (distance < 0.0000001) {
      final distances = [
        position.x - wall.x,
        wall.x + wall.width - position.x,
        position.y - wall.y,
        wall.y + wall.height - position.y,
      ];
      final face = distances.indexOf(distances.reduce(min));
      delta = [
        const Vec2(-1, 0),
        const Vec2(1, 0),
        const Vec2(0, -1),
        const Vec2(0, 1),
      ][face];
      distance = -distances[face];
    } else {
      delta = delta * (1 / distance);
    }
    position = position + delta * (layout.ballRadius - distance);
    final normalSpeed = velocity.x * delta.x + velocity.y * delta.y;
    if (normalSpeed < 0) velocity = velocity - delta * (1.18 * normalSpeed);
  }
}
