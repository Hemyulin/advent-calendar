import 'dart:math';

import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/maze/maze_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/maze/maze_screen.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'support/game_configuration.dart';

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
    'calendar, admin preview and replay use the same distinct map for each difficulty',
    () {
      final signatures = <String>{};
      for (final d in GameDifficulty.values) {
        final canonical = MazeCourse.forDifficulty(d).layouts.single;
        String signature(MazeLayout m) =>
            '${m.cells}:${m.walls.map((w) => '${w.x},${w.y},${w.width},${w.height}').join(';')}';
        signatures.add(signature(canonical));
        final day = [3, 13, 21][d.index];
        final calendar =
            configuredGame(
                  buildDailyChallenge(
                    calendarDays(DateTime(2026, 12, 24), {})[day - 1],
                    () async {},
                  ),
                )
                as MazeScreen;
        for (final route in [
          calendar,
          configuredGame(
                buildMinigame(
                  Minigame.maze,
                  d,
                  () async {},
                  developmentPreview: true,
                ),
              )
              as MazeScreen,
          configuredGame(
                buildMinigame(
                  Minigame.maze,
                  d,
                  () async {},
                  alreadyCompleted: true,
                ),
              )
              as MazeScreen,
          configuredGame(
                buildMinigame(
                  Minigame.maze,
                  d,
                  () async {},
                  skin: GameSkin.hanukkah,
                ),
              )
              as MazeScreen,
        ]) {
          final actual = route.course!.layouts.single;
          expect(signature(actual), signature(canonical));
          expect(
            actual.candies.map((p) => (p.x, p.y)),
            canonical.candies.map((p) => (p.x, p.y)),
          );
          expect(
            actual.pits.map((p) => (p.x, p.y)),
            canonical.pits.map((p) => (p.x, p.y)),
          );
        }
        expect(canonical.cells, [5, 6, 8][d.index]);
        expect(canonical.candies.length, [3, 3, 7][d.index]);
      }
      expect(signatures.length, 3);
    },
  );

  test('the hardest candy objective requires all seven pickups', () {
    final course = MazeCourse.forDifficulty(GameDifficulty.hard);
    final game = MazeGame(course);
    for (var i = 0; i < course.layouts.single.candies.length; i++) {
      game.position = course.layouts.single.candies[i];
      game.advance(.01, Vec2.zero);
      if (i == 2) expect(game.allCandy, isFalse);
    }
    expect(game.collectedCandy.length, 7);
    expect(game.allCandy, isTrue);
    expect(game.falls, 0);
    game.position = game.layout.goal;
    game.advance(.01, Vec2.zero);
    expect(game.won, isTrue);
    expect(game.allCandy, isTrue);
  });

  test(
    'curated difficulty boards keep every candy reachable with ball-sized clearance',
    () {
      for (final (difficulty, seed, count, candies) in [
        (GameDifficulty.easy, 1224, 3, 3),
        (GameDifficulty.normal, 1234, 4, 3),
        (GameDifficulty.hard, 1242, 13, 7),
      ]) {
        final layout = MazeCourse.forDifficulty(
          difficulty,
          seed: seed,
        ).layouts.single;
        expect(layout.candies.length, candies);
        expect(layout.pits.length, count);
        final generated = MazeLayout.generate(
          cells: layout.cells,
          seed: seed,
          pitCount: difficulty.index + 2,
        );
        expect(
          layout.walls.map((w) => (w.x, w.y, w.width, w.height)),
          generated.walls.map((w) => (w.x, w.y, w.width, w.height)),
        );
        for (final pit in layout.pits) {
          for (final wall in layout.walls) {
            expect(
              wallDistance(pit, wall),
              greaterThan(layout.pitRadius),
              reason: '$difficulty pit ${pit.x}, ${pit.y} overlaps a wall',
            );
          }
        }
        // Flood the continuous board with the actual ball radius and pit capture
        // distance, rather than assuming a clear path between abstract maze cells.
        const resolution = 250;
        Vec2 point(int cell) => Vec2(
          (cell % resolution + .5) / resolution,
          (cell ~/ resolution + .5) / resolution,
        );
        bool safe(Vec2 p) =>
            layout.walls.every(
              (w) => wallDistance(p, w) > layout.ballRadius + .002,
            ) &&
            layout.pits.every(
              (pit) => (p - pit).length > layout.pitCaptureRadius + .003,
            );
        final available = List.generate(
          resolution * resolution,
          (cell) => safe(point(cell)),
        );
        final start =
            (layout.start.y * resolution).floor() * resolution +
            (layout.start.x * resolution).floor();
        final visited = <int>{start};
        final queue = [start];
        for (var i = 0; i < queue.length; i++) {
          final cell = queue[i];
          for (final next in [
            if (cell % resolution > 0) cell - 1,
            if (cell % resolution < resolution - 1) cell + 1,
            if (cell >= resolution) cell - resolution,
            if (cell < resolution * (resolution - 1)) cell + resolution,
          ]) {
            if (available[next] && visited.add(next)) queue.add(next);
          }
        }
        for (final target in [...layout.candies, layout.goal]) {
          final cell =
              (target.y * resolution).floor() * resolution +
              (target.x * resolution).floor();
          expect(
            visited.contains(cell),
            isTrue,
            reason:
                '$difficulty target ${target.x}, ${target.y} is unreachable',
          );
        }
        // Drive the actual physics through every pickup and the flag, using
        // continuous clearance instead of a one-hole-per-cell assumption.
        final game = MazeGame(MazeCourse(layouts: [layout]));
        int cellAt(Vec2 p) =>
            (p.y * resolution).floor() * resolution +
            (p.x * resolution).floor();
        for (final destination in [...layout.candies, layout.goal]) {
          final from = cellAt(game.position), to = cellAt(destination);
          final parents = <int, int?>{from: null};
          final frontier = [from];
          for (
            var i = 0;
            i < frontier.length && !parents.containsKey(to);
            i++
          ) {
            final cell = frontier[i];
            for (final next in [
              if (cell % resolution > 0) cell - 1,
              if (cell % resolution < resolution - 1) cell + 1,
              if (cell >= resolution) cell - resolution,
              if (cell < resolution * (resolution - 1)) cell + resolution,
            ]) {
              if (!available[next] || parents.containsKey(next)) continue;
              if (destination != layout.goal &&
                  (point(next) - layout.goal).length <
                      layout.goalRadius + .003) {
                continue;
              }
              parents[next] = cell;
              frontier.add(next);
            }
          }
          expect(parents.containsKey(to), isTrue);
          final path = <int>[];
          int? cursor = to;
          while (cursor != null) {
            path.add(cursor);
            cursor = parents[cursor];
          }
          for (final step in path.reversed.skip(1)) {
            if (game.won) break;
            final target = point(step);
            for (
              var tick = 0;
              tick < 300 &&
                  (game.position - target).length > .0015 &&
                  !game.won;
              tick++
            ) {
              game.advance(
                1 / 120,
                (target - game.position) * 12 - game.velocity * 6,
              );
            }
            expect(
              game.falls,
              0,
              reason: '$difficulty lost a life along the clearance path',
            );
            expect(
              (game.position - target).length,
              lessThan(game.won ? layout.goalRadius : .002),
            );
          }
        }
        expect(game.won, isTrue);
        expect(game.allCandy, isTrue);
      }
    },
  );

  test(
    'hazards affect the actual route, have passing space, and avoid corners across seeds',
    () {
      for (final seed in [7, 42, 86, 1224, 2026]) {
        for (final difficulty in GameDifficulty.values) {
          final course = MazeCourse(
            layouts: [
              MazeLayout.generate(
                cells: [5, 6, 8][difficulty.index],
                seed: seed,
                pitCount: difficulty.index + 2,
              ),
            ],
          );
          for (var stage = 0; stage < course.layouts.length; stage++) {
            final layout = course.layouts[stage];
            final n = layout.cells;
            final route = routeToFlag(layout);
            final indices = <int>[];
            expect(
              layout.pits.length,
              difficulty.index + 2,
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
