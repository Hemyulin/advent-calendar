import 'package:advent_calendar/challenges/workshop/workshop_game.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/workshop_solutions.dart';

WorkshopDirection direction(String letter) => switch (letter) {
  'U' => WorkshopDirection.up,
  'D' => WorkshopDirection.down,
  'L' => WorkshopDirection.left,
  'R' => WorkshopDirection.right,
  _ => throw ArgumentError(letter),
};

void main() {
  test(
    'all handcrafted levels solve through legal moves with the promised sizes',
    () {
      for (final difficulty in GameDifficulty.values) {
        final game = WorkshopGame(WorkshopLevel.forDifficulty(difficulty));
        expect(game.level.size, [5, 7, 8][difficulty.index]);
        expect(game.presents.length, 2 + difficulty.index);
        expect(game.level.targets.length, game.presents.length);
        final solution = workshopSolutions[difficulty.index];
        for (var i = 0; i < solution.length; i++) {
          expect(game.won, isFalse, reason: 'Won before the last move');
          expect(
            game.move(direction(solution[i])),
            isTrue,
            reason: '$difficulty at move $i',
          );
          expect(game.presents.toSet().length, game.presents.length);
          expect(game.presents.any(game.level.walls.contains), isFalse);
          expect(game.presents.contains(game.elf), isFalse);
        }
        expect(game.won, isTrue);
        expect(game.placed, game.presents.length);
        expect(game.pushes, [2, 6, 12][difficulty.index]);
        expect(game.moves, solution.length);
        expect(game.move(WorkshopDirection.up), isFalse);
      }
    },
  );

  test('walking away never pulls a present', () {
    final game = WorkshopGame(WorkshopLevel.forDifficulty(GameDifficulty.easy));
    final boxes = game.presents;
    game.move(WorkshopDirection.up);
    game.move(WorkshopDirection.down);
    expect(game.presents, boxes);
    expect(game.pushes, 0);
  });

  test('walls and a second present block pushing without recording a move', () {
    final game = WorkshopGame(
      WorkshopLevel(const ['#####', '# ..#', r'#@$$#', '#   #', '#####']),
    );
    expect(game.move(WorkshopDirection.left), isFalse);
    expect(game.move(WorkshopDirection.right), isFalse);
    expect(game.moves, 0);
    expect(game.canUndo, isFalse);
    expect(game.elf, 11);
    expect(game.presents, [12, 13]);
    game.move(WorkshopDirection.down);
    game.move(WorkshopDirection.right);
    // Push the first present upward, then try pushing it into the boundary.
    expect(game.move(WorkshopDirection.up), isTrue);
    final moves = game.moves;
    expect(game.move(WorkshopDirection.up), isFalse);
    expect(game.moves, moves);
  });

  test(
    'undo restores elf, present IDs, counters and facing, including after a win',
    () {
      for (final difficulty in GameDifficulty.values) {
        final game = WorkshopGame(WorkshopLevel.forDifficulty(difficulty));
        final initial = game.presents;
        for (final letter in workshopSolutions[difficulty.index].split('')) {
          game.move(direction(letter));
        }
        expect(game.won, isTrue);
        for (var i = workshopSolutions[difficulty.index].length; i > 0; i--) {
          expect(game.undo(), isTrue);
          expect(game.moves, i - 1);
        }
        expect(game.elf, game.level.start);
        expect(game.presents, initial);
        expect(game.facing, WorkshopDirection.down);
        expect(game.pushes, 0);
        expect(game.won, isFalse);
        expect(game.undo(), isFalse);
      }
    },
  );

  test(
    'easy level requires planning: an early goal can block the other present',
    () {
      final game = WorkshopGame(
        WorkshopLevel.forDifficulty(GameDifficulty.easy),
      );
      game.move(WorkshopDirection.right);
      game.move(WorkshopDirection.up); // Prematurely fills the upper target.
      expect(game.placed, 1);
      expect(game.won, isFalse);
      expect(game.undo(), isTrue);
      expect(game.placed, 0);
      game.undo();
      for (final letter in workshopSolutions[0].split('')) {
        expect(game.move(direction(letter)), isTrue);
      }
      expect(game.won, isTrue);
    },
  );

  test('a legal corner deadlock is recoverable with undo', () {
    final game = WorkshopGame(
      WorkshopLevel(const ['#####', '# . #', r'# $@#', '#   #', '#####']),
    );
    expect(game.move(WorkshopDirection.left), isTrue);
    expect(game.presents, [11]);
    expect(game.won, isFalse);
    expect(game.undo(), isTrue);
    expect(game.presents, [12]);
  });

  test('custom levels accept occupied targets and reject malformed boards', () {
    final solved = WorkshopGame(
      WorkshopLevel(const ['#####', '#*@ #', '#   #', '#   #', '#####']),
    );
    expect(solved.won, isTrue);
    for (final rows in [
      ['###', '#@#', '##'],
      ['###', '#@#', '###'],
      ['#####', '#@x #', r'# $.#', '#   #', '#####'],
      ['#####', '#@@ #', r'# $.#', '#   #', '#####'],
      ['#####', '#@  #', r'# $ #', '#   #', '#####'],
      ['#####', '#@  #', r'# $.#', '#   #', '## ##'],
    ]) {
      expect(() => WorkshopLevel(rows), throwsArgumentError);
    }
    final level = WorkshopLevel.forDifficulty(GameDifficulty.easy);
    expect(() => level.walls.add(1), throwsUnsupportedError);
    expect(() => level.presents.add(1), throwsUnsupportedError);
    expect(() => WorkshopGame(level).presents.add(1), throwsUnsupportedError);
  });
}
