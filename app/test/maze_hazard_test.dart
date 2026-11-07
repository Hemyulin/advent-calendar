import 'dart:math';

import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/maze/maze_game.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> routeToFlag(MazeLayout layout) {
  final n = layout.cells;
  Vec2 center(int cell) => Vec2((cell % n + 0.5) / n, (cell ~/ n + 0.5) / n);
  bool open(int a, int b) {
    final midpoint = (center(a) + center(b)) * 0.5;
    return layout.walls.every(
      (w) =>
          midpoint.x < w.x ||
          midpoint.x > w.x + w.width ||
          midpoint.y < w.y ||
          midpoint.y > w.y + w.height,
    );
  }

  final parents = <int, int?>{0: null};
  final queue = [0];
  for (var i = 0; i < queue.length; i++) {
    final cell = queue[i];
    for (final next in [
      if (cell % n > 0) cell - 1,
      if (cell % n < n - 1) cell + 1,
      if (cell >= n) cell - n,
      if (cell < n * (n - 1)) cell + n,
    ]) {
      if (!parents.containsKey(next) && open(cell, next)) {
        parents[next] = cell;
        queue.add(next);
      }
    }
  }
  final route = <int>[];
  int? cell = n * n - 1;
  while (cell != null) {
    route.add(cell);
    cell = parents[cell];
  }
  return route.reversed.toList();
}

double wallDistance(Vec2 point, MazeWall wall) =>
    (point -
            Vec2(
              point.x.clamp(wall.x, wall.x + wall.width),
              point.y.clamp(wall.y, wall.y + wall.height),
            ))
        .length;

void main() {
  test(
    'hazards affect the actual route, have passing space, and avoid corners across seeds',
    () {
      for (final seed in [7, 42, 86, 1224, 2026]) {
        for (final difficulty in GameDifficulty.values) {
          final course = MazeCourse.forDifficulty(difficulty, seed: seed);
          for (var stage = 0; stage < course.layouts.length; stage++) {
            final layout = course.layouts[stage];
            final n = layout.cells;
            final route = routeToFlag(layout);
            final indices = <int>[];
            expect(
              layout.pits.length,
              difficulty.index + 1,
              reason: '$seed $difficulty $stage',
            );
            for (final pit in layout.pits) {
              final cell = (pit.y * n).floor() * n + (pit.x * n).floor();
              final index = route.indexOf(cell);
              expect(index, inInclusiveRange(2, route.length - 3));
              expect(
                route[index] - route[index - 1],
                route[index + 1] - route[index],
              );
              indices.add(index);
              final center = Vec2((cell % n + 0.5) / n, (cell ~/ n + 0.5) / n);
              final offset = pit - center;
              expect(offset.length, lessThan(layout.pitCaptureRadius));
              // Actually following the centre of this route cell must encounter
              // the hazard, instead of letting every hole be ignored.
              final straightThrough = MazeGame(MazeCourse(layouts: [layout]));
              straightThrough.position = center;
              straightThrough.advance(1 / 120, Vec2.zero);
              expect(straightThrough.falls, 1);
              final passingPoint =
                  center - offset * ((0.24 / n) / offset.length);
              expect(
                (passingPoint - pit).length,
                greaterThan(layout.pitRadius + layout.ballRadius),
              );
              for (final wall in layout.walls) {
                expect(wallDistance(pit, wall), greaterThan(layout.pitRadius));
                expect(
                  wallDistance(passingPoint, wall),
                  greaterThan(layout.ballRadius + 0.003),
                );
              }
            }
            indices.sort();
            for (var i = 1; i < indices.length; i++) {
              expect(indices[i] - indices[i - 1], greaterThanOrEqualTo(4));
            }
          }
        }
      }
    },
  );

  test(
    'real physics can pass every route hazard and reach the flag for additional seeds',
    () {
      for (final seed in [7, 42, 2026]) {
        for (final layout in MazeCourse.forDifficulty(
          GameDifficulty.normal,
          seed: seed,
        ).layouts) {
          final game = MazeGame(MazeCourse(layouts: [layout]));
          final n = layout.cells;
          for (final cell in routeToFlag(layout).skip(1)) {
            var target = Vec2((cell % n + 0.5) / n, (cell ~/ n + 0.5) / n);
            final hazards = layout.pits.where(
              (p) =>
                  (p.x * n).floor() == cell % n &&
                  (p.y * n).floor() == cell ~/ n,
            );
            if (hazards.isNotEmpty) {
              final offset = hazards.single - target;
              target = target - offset * ((0.24 / n) / offset.length);
            }
            for (
              var step = 0;
              step < 1000 &&
                  (game.position - target).length > 0.008 &&
                  !game.won;
              step++
            ) {
              game.advance(
                1 / 120,
                (target - game.position) * 12 - game.velocity * 5,
              );
            }
            expect(game.falls, 0);
            expect(
              (game.position - target).length,
              lessThan(game.won ? layout.goalRadius : 0.012),
            );
          }
          expect(game.won, isTrue);
        }
      }
    },
  );

  test(
    'zero requested hazards stays supported and generation remains deterministic',
    () {
      final a = MazeLayout.generate(cells: 7, seed: 42, pitCount: 3);
      final b = MazeLayout.generate(cells: 7, seed: 42, pitCount: 3);
      expect(
        a.pits.map((p) => Point(p.x, p.y)),
        b.pits.map((p) => Point(p.x, p.y)),
      );
      expect(MazeLayout.generate(cells: 5, seed: 7, pitCount: 0).pits, isEmpty);
    },
  );
}
