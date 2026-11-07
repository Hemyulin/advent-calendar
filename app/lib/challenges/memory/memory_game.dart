import 'dart:math';

import '../games/difficulty.dart';

class MemoryLevel {
  const MemoryLevel({this.attempts = 20, this.seed});

  factory MemoryLevel.forDifficulty(GameDifficulty difficulty, {int? seed}) =>
      MemoryLevel(
        attempts: switch (difficulty) {
          GameDifficulty.easy => 26,
          GameDifficulty.normal => 20,
          GameDifficulty.hard => 15,
        },
        seed: seed,
      );

  final int attempts;
  final int? seed;
}

/// One attempt is one pair of cards, whether matched or mismatched.
/// The presentation decides how long a mismatch stays visible.
class MemoryGame {
  MemoryGame(this.level) {
    if (level.attempts < 8) {
      throw ArgumentError('At least eight attempts required');
    }
    cards = List.unmodifiable(
      [
        for (var i = 0; i < 8; i++) ...[i, i],
      ]..shuffle(Random(level.seed)),
    );
  }

  final MemoryLevel level;
  late final List<int> cards;
  final Set<int> _matched = {};
  int? first;
  int? second;
  int attemptsUsed = 0;

  Set<int> get matched => Set.unmodifiable(_matched);
  int get attemptsLeft => level.attempts - attemptsUsed;
  int get pairsFound => _matched.length ~/ 2;
  bool get won => _matched.length == cards.length;
  bool get lost => !won && attemptsLeft == 0 && second == null;
  bool isFaceUp(int index) =>
      _matched.contains(index) || first == index || second == index;

  bool reveal(int index) {
    if (index < 0 ||
        index >= cards.length ||
        won ||
        lost ||
        second != null ||
        isFaceUp(index)) {
      return false;
    }
    if (first == null) {
      first = index;
    } else {
      second = index;
      attemptsUsed++;
      if (cards[first!] == cards[second!]) {
        _matched.addAll([first!, second!]);
        first = second = null;
      }
    }
    return true;
  }

  void hideMismatch() {
    if (second != null) first = second = null;
  }
}
