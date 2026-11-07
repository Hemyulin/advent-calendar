import '../games/difficulty.dart';
import 'bell_melodies.dart';

enum BellsPhase { ready, listening, answering, mistake, roundWon, won }

class BellsLevel {
  const BellsLevel({
    this.rounds = const [
      BellRound(0, 4),
      BellRound(1, 5),
      BellRound(2, 6),
      BellRound(3, 7),
      BellRound(4, 8),
      BellRound(0, 10),
    ],
    this.beatMilliseconds = 620,
  });
  final List<BellRound> rounds;
  final int beatMilliseconds;

  factory BellsLevel.forDifficulty(GameDifficulty difficulty) => BellsLevel(
    rounds: switch (difficulty) {
      GameDifficulty.easy => bellRounds.take(5).toList(growable: false),
      GameDifficulty.normal => const BellsLevel().rounds,
      GameDifficulty.hard => bellRounds,
    },
  );
}

/// No timers or audio: only pitch order is evaluated. Attempts are unlimited.
class BellsGame {
  BellsGame(this.level) {
    if (level.rounds.isEmpty ||
        level.beatMilliseconds < 200 ||
        level.rounds.any(
          (r) =>
              r.melodyIndex < 0 ||
              r.melodyIndex >= bellMelodies.length ||
              r.length < 1 ||
              r.length > r.melody.notes.length,
        )) {
      throw ArgumentError('Invalid bell level');
    }
  }
  final BellsLevel level;
  int round = 0;
  int entered = 0;
  BellsPhase phase = BellsPhase.ready;
  BellRound get current => level.rounds[round];

  bool listen() {
    if (phase == BellsPhase.listening ||
        phase == BellsPhase.won ||
        phase == BellsPhase.roundWon) {
      return false;
    }
    entered = 0;
    phase = BellsPhase.listening;
    return true;
  }

  void finishListening() {
    if (phase == BellsPhase.listening) phase = BellsPhase.answering;
  }

  void interrupt() {
    if (phase == BellsPhase.won || phase == BellsPhase.roundWon) return;
    entered = 0;
    phase = BellsPhase.ready;
  }

  bool tap(BellNote note) {
    if (phase != BellsPhase.answering) return false;
    if (note != current.notes[entered].pitch) {
      entered = 0;
      phase = BellsPhase.mistake;
      return false;
    }
    entered++;
    if (entered == current.length) {
      phase = round == level.rounds.length - 1
          ? BellsPhase.won
          : BellsPhase.roundWon;
    }
    return true;
  }

  void retry() {
    if (phase == BellsPhase.mistake) phase = BellsPhase.answering;
  }

  void nextRound() {
    if (phase != BellsPhase.roundWon) return;
    round++;
    entered = 0;
    phase = BellsPhase.ready;
  }
}
