import 'package:advent_calendar/challenges/chimney/chimney_game.dart';

// Generated 3×3 puzzle, seed 9. This loop revisits tile 4, then returns via 1
// to the rooftop entrance at 0. Tile 4 must be rotated after Santa leaves it.
const rooftopTurns = {0: 0, 1: 2, 3: 1, 4: 0, 5: 2, 6: 0, 7: 1, 8: 3};

void turnPipeTo(ChimneyGame game, int cell, int turns) {
  final target = ChimneyTile(game.puzzle.tiles[cell].shape, turns).ports;
  while (!game.puzzle.tiles[cell].ports.containsAll(target)) {
    if (!game.rotate(cell)) throw StateError('Cannot rotate an occupied pipe');
  }
}

void prepareRooftopLoop(ChimneyGame game) {
  for (final entry in rooftopTurns.entries) {
    turnPipeTo(game, entry.key, entry.value);
  }
}
