import 'dart:math';

import 'package:advent_calendar/challenges/chimney/chimney_game.dart';
import 'package:flutter_test/flutter_test.dart';

void solve(ChimneyGame game) {
  for (final entry in game.puzzle.solution.entries) {
    while (!game.puzzle.tiles[entry.key].ports.containsAll(
      ChimneyTile(game.puzzle.tiles[entry.key].shape, entry.value).ports,
    )) {
      game.rotate(entry.key);
    }
  }
}

void main() {
  test('hundreds of shuffled boards have an actual traversable solution', () {
    for (final size in [3, 4, 5, 6]) {
      for (var seed = 0; seed < 100; seed++) {
        final game = ChimneyGame(ChimneyLevel(size: size, seed: seed));
        expect(game.puzzle.solution.length, greaterThanOrEqualTo(size * 2 - 1));
        for (final entry in game.puzzle.solution.entries) {
          expect(
            game.puzzle.tiles[entry.key].ports,
            isNot(
              ChimneyTile(
                game.puzzle.tiles[entry.key].shape,
                entry.value,
              ).ports,
            ),
          );
        }
        solve(game);
        game.advance(1000);
        expect(game.phase, ChimneyPhase.won, reason: 'size $size seed $seed');
        expect(game.visited.length, game.puzzle.solution.length);
        expect(game.cell, size * size - 1);
        expect(game.outgoing, PipeDirection.south);
      }
    }
  });

  test('preparation lasts exactly ten seconds and consumes excess time', () {
    final game = ChimneyGame(const ChimneyLevel(seed: 4));
    solve(game);
    game.advance(9.9);
    expect(game.phase, ChimneyPhase.preparing);
    game.advance(.3);
    expect(game.phase, ChimneyPhase.moving);
    expect(game.progress, closeTo(.2 / 1.1, 1e-8));
  });

  test('occupied tile locks; future tiles can still be rotated', () {
    final game = ChimneyGame(const ChimneyLevel(seed: 9));
    solve(game);
    game.advance(10.1);
    expect(game.rotate(0), isFalse);
    expect(game.rotate(1), isTrue);
    final startPorts = game.puzzle.tiles[0].ports;
    game.advance(1000);
    expect(game.puzzle.tiles[0].ports, startPorts);
    expect(game.rotate(0), isFalse);
  });

  test('misaligned entrance fails immediately', () {
    final game = ChimneyGame(const ChimneyLevel());
    game.puzzle.tiles[0] = ChimneyTile(PipeShape.straight, 1);
    game.advance(10);
    expect(game.phase, ChimneyPhase.lost);
    expect(game.failedCell, 0);
  });

  test('checks reciprocal connection only when crossing a boundary', () {
    final game = ChimneyGame(const ChimneyLevel(secondsPerTile: 1));
    game.puzzle.tiles[0] = ChimneyTile(PipeShape.straight, 0);
    game.puzzle.tiles[4] = ChimneyTile(PipeShape.straight, 1);
    game.advance(10.9);
    expect(game.phase, ChimneyPhase.moving);
    game.advance(.11);
    expect(game.phase, ChimneyPhase.lost);
    expect(game.failedCell, 4);
  });

  test('a future connection can be repaired while Santa moves', () {
    final game = ChimneyGame(const ChimneyLevel(seed: 22));
    solve(game);
    game.puzzle.tiles[4] = ChimneyTile(PipeShape.straight, 1);
    game.puzzle.tiles[0] = ChimneyTile(PipeShape.straight, 0);
    game.advance(10.5);
    expect(game.rotate(4), isTrue);
    game.advance(.7);
    expect(game.phase, ChimneyPhase.moving);
    expect(game.cell, 4);
  });

  test('exiting another board edge is a loss, not a win', () {
    final game = ChimneyGame(const ChimneyLevel(secondsPerTile: 1));
    game.puzzle.tiles[0] = ChimneyTile(PipeShape.corner, 3); // north -> west
    game.advance(11.01);
    expect(game.phase, ChimneyPhase.lost);
    expect(game.failedCell, 0);
  });

  test(
    'Santa follows an alternate connected route rather than the solution map',
    () {
      final game = ChimneyGame(const ChimneyLevel(size: 3, seed: 7));
      game.puzzle.tiles[0] = ChimneyTile(PipeShape.straight, 0);
      game.puzzle.tiles[3] = ChimneyTile(PipeShape.straight, 0);
      game.puzzle.tiles[6] = ChimneyTile(PipeShape.corner, 0); // north -> east
      game.puzzle.tiles[7] = ChimneyTile(PipeShape.straight, 1);
      game.puzzle.tiles[8] = ChimneyTile(PipeShape.corner, 2); // west -> south
      game.advance(100);
      expect(game.phase, ChimneyPhase.won);
      expect(game.visited, {0, 3, 6, 7, 8});
    },
  );

  test('large time steps and small steps traverse exactly the same route', () {
    final a = ChimneyGame(const ChimneyLevel(seed: 86));
    final b = ChimneyGame(const ChimneyLevel(seed: 86));
    solve(a);
    solve(b);
    a.advance(13.7);
    for (var i = 0; i < 1370; i++) {
      b.advance(.01);
    }
    expect(a.phase, b.phase);
    expect(a.cell, b.cell);
    expect(a.incoming, b.incoming);
    expect(a.progress, closeTo(b.progress, 1e-7));
  });

  test('generation is reproducible and different seeds make fresh boards', () {
    final a = ChimneyPuzzle.generate(4, Random(7));
    final b = ChimneyPuzzle.generate(4, Random(7));
    final c = ChimneyPuzzle.generate(4, Random(8));
    String signature(ChimneyPuzzle p) =>
        p.tiles.map((t) => '${t.shape}:${t.turns}').join(',');
    expect(signature(a), signature(b));
    expect(signature(a), isNot(signature(c)));
  });

  test('invalid settings are rejected; invalid time deltas are ignored', () {
    for (final level in [
      const ChimneyLevel(size: 2),
      const ChimneyLevel(size: 7),
      const ChimneyLevel(preparationSeconds: -1),
      const ChimneyLevel(secondsPerTile: 0),
    ]) {
      expect(() => ChimneyGame(level), throwsArgumentError);
    }
    final game = ChimneyGame(const ChimneyLevel());
    game.advance(double.nan);
    game.advance(double.infinity);
    game.advance(-1);
    expect(game.preparationLeft, 10);
  });
}
