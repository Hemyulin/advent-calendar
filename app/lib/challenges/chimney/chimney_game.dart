import 'dart:math';

import '../games/difficulty.dart';

enum PipeDirection {
  north,
  east,
  south,
  west;

  PipeDirection get opposite => values[(index + 2) % 4];
  PipeDirection rotated(int turns) => values[(index + turns) % 4];
  int get dx => switch (this) {
    east => 1,
    west => -1,
    _ => 0,
  };
  int get dy => switch (this) {
    south => 1,
    north => -1,
    _ => 0,
  };
}

enum PipeShape { straight, corner }

enum ChimneyPhase { preparing, moving, won, lost }

class ChimneyLevel {
  const ChimneyLevel({
    this.size = 4,
    this.preparationSeconds = 10,
    this.secondsPerTile = 1.1,
    this.seed,
  });
  final int size;
  final int? seed;
  final double preparationSeconds, secondsPerTile;

  factory ChimneyLevel.forDifficulty(GameDifficulty difficulty) =>
      switch (difficulty) {
        GameDifficulty.easy => const ChimneyLevel(
          size: 3,
          preparationSeconds: 12,
          secondsPerTile: 1.5,
        ),
        GameDifficulty.normal => const ChimneyLevel(),
        GameDifficulty.hard => const ChimneyLevel(
          size: 5,
          preparationSeconds: 10,
          secondsPerTile: 0.9,
        ),
      };
}

class ChimneyTile {
  ChimneyTile(this.shape, this.turns);
  final PipeShape shape;
  int turns;
  Set<PipeDirection> get ports => {
    PipeDirection.north.rotated(turns),
    (shape == PipeShape.straight ? PipeDirection.south : PipeDirection.east)
        .rotated(turns),
  };
}

/// A guaranteed route is carved first, then all pipe orientations are shuffled.
/// Two-port pipes make travel unambiguous, even when the player builds a detour.
class ChimneyPuzzle {
  ChimneyPuzzle._(this.size, this.tiles, this.solution);
  final int size;
  final List<ChimneyTile> tiles;
  final Map<int, int> solution;

  factory ChimneyPuzzle.generate(int size, Random random) {
    if (size < 3 || size > 6) throw ArgumentError.value(size, 'size');
    List<int> best = [];
    for (var attempt = 0; attempt < 80; attempt++) {
      final parent = <int, int>{};
      final visited = <int>{0};
      final stack = [0];
      while (stack.isNotEmpty && !visited.contains(size * size - 1)) {
        final current = stack.last;
        final choices = <int>[
          for (final direction in PipeDirection.values)
            if (current % size + direction.dx >= 0 &&
                current % size + direction.dx < size &&
                current ~/ size + direction.dy >= 0 &&
                current ~/ size + direction.dy < size)
              current + direction.dx + direction.dy * size,
        ].where((cell) => !visited.contains(cell)).toList()..shuffle(random);
        if (choices.isEmpty) {
          stack.removeLast();
          continue;
        }
        final next = choices.first;
        parent[next] = current;
        visited.add(next);
        stack.add(next);
      }
      final route = <int>[];
      int? cell = size * size - 1;
      while (cell != null) {
        route.add(cell);
        cell = parent[cell];
      }
      if (route.length > best.length) best = route.reversed.toList();
      if (best.length >= size * 2 + 1) break;
    }
    final tiles = List.generate(
      size * size,
      (_) => ChimneyTile(
        random.nextBool() ? PipeShape.straight : PipeShape.corner,
        random.nextInt(4),
      ),
    );
    final solution = <int, int>{};
    PipeDirection toward(int from, int to) => PipeDirection.values.firstWhere(
      (d) =>
          from % size + d.dx == to % size && from ~/ size + d.dy == to ~/ size,
    );
    for (var i = 0; i < best.length; i++) {
      final cell = best[i];
      final ports = {
        i == 0 ? PipeDirection.north : toward(cell, best[i - 1]),
        i == best.length - 1 ? PipeDirection.south : toward(cell, best[i + 1]),
      };
      final shape = ports.first.opposite == ports.last
          ? PipeShape.straight
          : PipeShape.corner;
      final tile = ChimneyTile(shape, 0);
      while (!tile.ports.containsAll(ports)) {
        tile.turns++;
      }
      solution[cell] = tile.turns;
      // Every route tile initially needs attention; random quarter turns keep
      // the known solution out of the playable state.
      tile.turns += shape == PipeShape.straight ? 1 : 1 + random.nextInt(3);
      tiles[cell] = tile;
    }
    return ChimneyPuzzle._(size, tiles, Map.unmodifiable(solution));
  }
}

class ChimneyGame {
  ChimneyGame(this.level, {Random? random}) {
    if (!level.preparationSeconds.isFinite ||
        level.preparationSeconds < 0 ||
        !level.secondsPerTile.isFinite ||
        level.secondsPerTile <= 0) {
      throw ArgumentError('Invalid timing');
    }
    puzzle = ChimneyPuzzle.generate(level.size, random ?? Random(level.seed));
    preparationLeft = level.preparationSeconds;
  }
  final ChimneyLevel level;
  late final ChimneyPuzzle puzzle;
  late double preparationLeft;
  ChimneyPhase phase = ChimneyPhase.preparing;
  int cell = 0;
  PipeDirection incoming = PipeDirection.north;
  PipeDirection? outgoing;
  double progress = 0;
  int? failedCell;
  final Set<int> visited = {};

  bool rotate(int index) {
    if (index < 0 ||
        index >= puzzle.tiles.length ||
        phase == ChimneyPhase.won ||
        phase == ChimneyPhase.lost ||
        (phase == ChimneyPhase.moving && index == cell)) {
      return false;
    }
    puzzle.tiles[index].turns++;
    return true;
  }

  void _enter() {
    final ports = puzzle.tiles[cell].ports;
    if (!ports.contains(incoming)) {
      failedCell = cell;
      phase = ChimneyPhase.lost;
      return;
    }
    outgoing = ports.firstWhere((port) => port != incoming);
    visited.add(cell);
  }

  /// Consume elapsed time across preparation and any number of tile boundaries.
  /// Connections are checked when Santa actually crosses each boundary.
  void advance(double seconds) {
    if (!seconds.isFinite || seconds <= 0) return;
    if (phase == ChimneyPhase.preparing) {
      final used = min(seconds, preparationLeft);
      preparationLeft -= used;
      seconds -= used;
      if (preparationLeft > 0) return;
      phase = ChimneyPhase.moving;
      _enter();
    }
    while (phase == ChimneyPhase.moving && seconds > 0) {
      final used = min(seconds, (1 - progress) * level.secondsPerTile);
      progress = min(1, progress + used / level.secondsPerTile);
      seconds -= used;
      if (progress < 1 - 1e-9) break;
      if (cell == puzzle.tiles.length - 1 && outgoing == PipeDirection.south) {
        phase = ChimneyPhase.won;
        break;
      }
      final direction = outgoing!;
      final x = cell % level.size + direction.dx;
      final y = cell ~/ level.size + direction.dy;
      if (x < 0 || x >= level.size || y < 0 || y >= level.size) {
        failedCell = cell;
        phase = ChimneyPhase.lost;
        break;
      }
      cell = y * level.size + x;
      incoming = direction.opposite;
      progress = 0;
      _enter();
    }
  }
}
