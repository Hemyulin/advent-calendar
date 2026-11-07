import 'dart:math';

import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/memory/memory_game.dart';
import 'package:advent_calendar/challenges/maze/maze_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Memory', () {
    test(
      'all difficulties contain eight shuffled pairs and configured attempts',
      () {
        for (final difficulty in GameDifficulty.values) {
          final a = MemoryGame(MemoryLevel.forDifficulty(difficulty, seed: 42));
          final b = MemoryGame(MemoryLevel.forDifficulty(difficulty, seed: 42));
          expect(a.cards, b.cards);
          expect(a.cards, hasLength(16));
          for (var i = 0; i < 8; i++) {
            expect(a.cards.where((v) => v == i), hasLength(2));
          }
          expect(
            a.cards,
            isNot([
              for (var i = 0; i < 8; i++) ...[i, i],
            ]),
          );
        }
      },
    );
    test('mismatches block extra input and consume exactly one attempt', () {
      final game = MemoryGame(const MemoryLevel(seed: 7));
      final other = game.cards.indexWhere((v) => v != game.cards.first);
      expect(game.reveal(0), isTrue);
      expect(game.reveal(0), isFalse);
      expect(game.attemptsLeft, 20);
      game.reveal(other);
      expect(game.attemptsLeft, 19);
      expect(game.reveal(15), isFalse);
      game.hideMismatch();
      expect(game.first, isNull);
      expect(game.matched, isEmpty);
    });
    test(
      'win is possible on the final allowed attempt; matched cards stay up',
      () {
        final game = MemoryGame(const MemoryLevel(seed: 7, attempts: 8));
        for (var symbol = 0; symbol < 8; symbol++) {
          for (var i = 0; i < 16; i++) {
            if (game.cards[i] == symbol) game.reveal(i);
          }
        }
        expect(game.won, isTrue);
        expect(game.lost, isFalse);
        expect(game.attemptsLeft, 0);
        expect(game.pairsFound, 8);
        expect(game.reveal(0), isFalse);
      },
    );
    test('loss waits until the last mismatch has been shown', () {
      final game = MemoryGame(const MemoryLevel(seed: 7, attempts: 8));
      final other = game.cards.indexWhere((v) => v != game.cards.first);
      for (var i = 0; i < 8; i++) {
        game.reveal(0);
        game.reveal(other);
        if (i < 7) game.hideMismatch();
      }
      expect(game.lost, isFalse);
      game.hideMismatch();
      expect(game.lost, isTrue);
      expect(game.reveal(0), isFalse);
    });
  });

  group('Kugellabyrinth', () {
    test('collision stops tunnelling through walls and reflects velocity', () {
      const layout = MazeLayout(
        cells: 5,
        walls: [MazeWall(0.5, 0, 0.01, 1)],
        start: Vec2(0.3, 0.5),
        goal: Vec2(0.9, 0.9),
        pits: [],
      );
      final game = MazeGame(const MazeCourse(layouts: [layout]));
      for (var i = 0; i < 300; i++) {
        game.advance(1 / 60, const Vec2(1, 0));
      }
      expect(
        game.position.x,
        lessThanOrEqualTo(0.5 - layout.ballRadius + 0.0001),
      );
      expect(game.position.y, closeTo(0.5, 0.001));
    });
    test(
      'pit resets position and costs a life; exhausted course is frozen',
      () {
        const layout = MazeLayout(
          cells: 5,
          walls: [],
          start: Vec2(0.1, 0.1),
          goal: Vec2(0.9, 0.9),
          pits: [Vec2(0.5, 0.5)],
        );
        final game = MazeGame(const MazeCourse(layouts: [layout], lives: 1));
        game.position = const Vec2(0.5, 0.5);
        game.advance(1 / 60, Vec2.zero);
        expect(game.lost, isTrue);
        expect(game.position.x, 0.1);
        game.advance(1, const Vec2(1, 1));
        expect(game.position.x, 0.1);
      },
    );
    test('each difficulty completes its single maze at the flag', () {
      for (final difficulty in GameDifficulty.values) {
        final course = MazeCourse.forDifficulty(difficulty);
        final game = MazeGame(course);
        expect(course.layouts, hasLength(1));
        expect(game.layout.cells, 4 + difficulty.index);
        game.position = game.layout.goal;
        game.advance(1 / 60, Vec2.zero);
        expect(game.won, isTrue);
      }
    });
    test('multi-stage challenges are rejected', () {
      final layout = MazeCourse.forDifficulty(
        GameDifficulty.easy,
      ).layouts.single;
      expect(
        () => MazeGame(MazeCourse(layouts: [layout, layout])),
        throwsArgumentError,
      );
    });
    test(
      'entering the flag zone finishes even while the ball is moving fast',
      () {
        const layout = MazeLayout(
          cells: 5,
          walls: [],
          start: Vec2(0.1, 0.5),
          goal: Vec2(0.8, 0.5),
          pits: [],
        );
        final game = MazeGame(const MazeCourse(layouts: [layout]));
        game.position = const Vec2(0.79, 0.5);
        game.velocity = const Vec2(0.6, 0);
        game.advance(1 / 120, const Vec2(1, 0));
        expect(game.won, isTrue);
        expect(game.position.x, layout.goal.x);
        expect(game.velocity.length, 0);
      },
    );
    test(
      'every generated difficulty has a physically traversable safe route',
      () {
        for (final difficulty in GameDifficulty.values) {
          for (final layout in MazeCourse.forDifficulty(difficulty).layouts) {
            final n = layout.cells;
            Vec2 center(int cell) =>
                Vec2((cell % n + 0.5) / n, (cell ~/ n + 0.5) / n);
            bool clear(int a, int b) {
              final mid = (center(a) + center(b)) * 0.5;
              return !layout.walls.any(
                (w) =>
                    mid.x >= w.x - 0.001 &&
                    mid.x <= w.x + w.width + 0.001 &&
                    mid.y >= w.y - 0.001 &&
                    mid.y <= w.y + w.height + 0.001,
              );
            }

            final parent = <int, int?>{0: null};
            final queue = [0];
            for (var i = 0; i < queue.length; i++) {
              final cell = queue[i];
              final adjacent = [
                if (cell % n > 0) cell - 1,
                if (cell % n < n - 1) cell + 1,
                if (cell >= n) cell - n,
                if (cell < n * (n - 1)) cell + n,
              ];
              for (final next in adjacent) {
                if (!parent.containsKey(next) && clear(cell, next)) {
                  parent[next] = cell;
                  queue.add(next);
                }
              }
            }
            expect(parent.length, n * n);
            final route = <int>[];
            int? cursor = n * n - 1;
            while (cursor != null) {
              route.add(cursor);
              cursor = parent[cursor];
            }
            expect(route.length, greaterThanOrEqualTo((n * n * 0.5).ceil()));
            final game = MazeGame(MazeCourse(layouts: [layout]));
            for (final cell in route.reversed.skip(1)) {
              final cellCenter = center(cell);
              final hazards = layout.pits.where(
                (p) =>
                    (p.x * n).floor() == cell % n &&
                    (p.y * n).floor() == cell ~/ n,
              );
              var target = cellCenter;
              if (hazards.isNotEmpty) {
                final offset = hazards.single - cellCenter;
                target = cellCenter - offset * ((0.24 / n) / offset.length);
              }
              for (
                var tick = 0;
                tick < 1000 &&
                    (game.position - target).length > 0.008 &&
                    !game.won;
                tick++
              ) {
                game.advance(
                  1 / 120,
                  (target - game.position) * 12 - game.velocity * 5,
                );
              }
              expect(
                (game.position - target).length,
                lessThan(game.won ? layout.goalRadius : 0.012),
              );
            }
            expect(game.won, isTrue);
            expect(game.falls, 0);
          }
        }
      },
    );
    test('motion remains finite and boundaries hold under prolonged tilt', () {
      final game = MazeGame(MazeCourse.forDifficulty(GameDifficulty.hard));
      final random = Random(12);
      for (var i = 0; i < 2000; i++) {
        game.advance(
          0.05,
          Vec2(random.nextDouble() * 2 - 1, random.nextDouble() * 2 - 1),
        );
        expect(game.position.x, inInclusiveRange(0.0, 1.0));
        expect(game.position.y, inInclusiveRange(0.0, 1.0));
      }
    });
  });
}
