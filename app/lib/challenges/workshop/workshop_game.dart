import '../games/difficulty.dart';

enum WorkshopDirection {
  up('Oben', 0, -1),
  down('Unten', 0, 1),
  left('Links', -1, 0),
  right('Rechts', 1, 0);

  const WorkshopDirection(this.label, this.dx, this.dy);
  final String label;
  final int dx, dy;
}

/// Handcrafted Sokoban boards. # wall, . target, $ present, @ elf.
/// * and + allow a present or the elf to start on a target in reusable levels.
class WorkshopLevel {
  WorkshopLevel(List<String> rows) {
    if (rows.length < 3 || rows.any((row) => row.length != rows.length)) {
      throw ArgumentError('The workshop must be a square grid');
    }
    size = rows.length;
    final wallCells = <int>{}, goalCells = <int>{};
    final boxCells = <int>[];
    final players = <int>[];
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final char = rows[y][x], cell = y * size + x;
        if (!r' #.$@*+'.contains(char)) {
          throw ArgumentError('Unknown workshop tile');
        }
        if ((x == 0 || y == 0 || x == size - 1 || y == size - 1) &&
            char != '#') {
          throw ArgumentError('The workshop must have boundary walls');
        }
        if (char == '#') wallCells.add(cell);
        if ('.*+'.contains(char)) goalCells.add(cell);
        if (r'$*'.contains(char)) boxCells.add(cell);
        if ('@+'.contains(char)) players.add(cell);
      }
    }
    if (players.length != 1 ||
        boxCells.isEmpty ||
        boxCells.length != goalCells.length) {
      throw ArgumentError('Expected one elf and matching presents and targets');
    }
    walls = Set.unmodifiable(wallCells);
    targets = Set.unmodifiable(goalCells);
    presents = List.unmodifiable(boxCells);
    start = players.single;
  }
  late final int size, start;
  late final Set<int> walls, targets;
  late final List<int> presents;

  factory WorkshopLevel.forDifficulty(GameDifficulty difficulty) =>
      switch (difficulty) {
        GameDifficulty.easy => WorkshopLevel(const [
          '#####',
          '# . #',
          r'# $$#',
          '#@ .#',
          '#####',
        ]),
        GameDifficulty.normal => WorkshopLevel(const [
          '#######',
          '#. # .#',
          r'# $ $ #',
          '# #@  #',
          r'# $ # #',
          '#  .  #',
          '#######',
        ]),
        GameDifficulty.hard => WorkshopLevel(const [
          '########',
          '#. #  .#',
          r'# $ $  #',
          '# #@#  #',
          r'#  $ $ #',
          '#  #   #',
          '#.    .#',
          '########',
        ]),
      };
}

class _WorkshopSnapshot {
  _WorkshopSnapshot(
    this.elf,
    List<int> presents,
    this.moves,
    this.pushes,
    this.facing,
  ) : presents = List.of(presents);
  final int elf, moves, pushes;
  final List<int> presents;
  final WorkshopDirection facing;
}

/// Rules contain no Flutter, animations, audio, persistence or hardware calls.
/// Present IDs are stable list indices, so rendering can animate a pushed box.
class WorkshopGame {
  WorkshopGame(this.level)
    : elf = level.start,
      _presents = List.of(level.presents);
  final WorkshopLevel level;
  int elf;
  final List<int> _presents;
  List<int> get presents => List.unmodifiable(_presents);
  int moves = 0, pushes = 0;
  WorkshopDirection facing = WorkshopDirection.down;
  final _history = <_WorkshopSnapshot>[];
  bool get canUndo => _history.isNotEmpty;
  int get placed => _presents.where(level.targets.contains).length;
  bool get won => placed == _presents.length;

  int? neighbor(int cell, WorkshopDirection direction) {
    final x = cell % level.size + direction.dx;
    final y = cell ~/ level.size + direction.dy;
    return x < 0 || y < 0 || x >= level.size || y >= level.size
        ? null
        : y * level.size + x;
  }

  bool move(WorkshopDirection direction) {
    if (won) return false;
    final next = neighbor(elf, direction);
    if (next == null || level.walls.contains(next)) return false;
    final present = _presents.indexOf(next);
    final beyond = present < 0 ? null : neighbor(next, direction);
    if (present >= 0 &&
        (beyond == null ||
            level.walls.contains(beyond) ||
            _presents.contains(beyond))) {
      return false;
    }
    _history.add(_WorkshopSnapshot(elf, _presents, moves, pushes, facing));
    if (present >= 0) {
      _presents[present] = beyond!;
      pushes++;
    }
    elf = next;
    facing = direction;
    moves++;
    return true;
  }

  bool undo() {
    if (!canUndo) return false;
    final previous = _history.removeLast();
    elf = previous.elf;
    _presents.setAll(0, previous.presents);
    moves = previous.moves;
    pushes = previous.pushes;
    facing = previous.facing;
    return true;
  }
}
