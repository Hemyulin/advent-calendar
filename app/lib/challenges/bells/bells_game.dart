import '../games/difficulty.dart';
import 'bell_melodies.dart';

enum BellsPhase { ready, listening, answering, mistake, roundWon, won }

/// Visual assistance applies only to the demonstration, never to player taps.
enum BellGuidance { all, firstOnly, none }

class BellsLevel {
  const BellsLevel({
    this.rounds = const [BellRound(7)],
    this.beatMilliseconds = 620,
    this.guidance = BellGuidance.firstOnly,
  });
  final List<BellRound> rounds;
  final int beatMilliseconds;
  final BellGuidance guidance;

  bool showsDemonstrationNote(int index) => switch (guidance) {
    BellGuidance.all => true,
    BellGuidance.firstOnly => index == 0,
    BellGuidance.none => false,
  };

  factory BellsLevel.forDifficulty(
    GameDifficulty difficulty, {
    bool hanukkah = false,
  }) {
    if (hanukkah) {
      return BellsLevel(
        rounds: [BellRound(8 + difficulty.index)],
        guidance: BellGuidance.values[difficulty.index],
        beatMilliseconds: difficulty == GameDifficulty.easy ? 700 : 620,
      );
    }
    return switch (difficulty) {
      GameDifficulty.easy => const BellsLevel(
        rounds: [BellRound(6)],
        guidance: BellGuidance.all,
      ),
      GameDifficulty.normal => const BellsLevel(),
      GameDifficulty.hard => const BellsLevel(
        rounds: [BellRound(5)],
        guidance: BellGuidance.none,
      ),
    };
  }
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
              r.length > r.melody.notes.length ||
              r.notes.any((note) => !r.melody.bells.contains(note.pitch)),
        )) {
      throw ArgumentError('Invalid bell level');
    }
  }
  final BellsLevel level;
  final Set<String> _completedMelodies = {};
  Set<String> get completedMelodyIds => Set.unmodifiable(_completedMelodies);
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
      // A shortened tutorial can win its round without completing the song's
      // curated hook. Only the full playable melody counts for the collection.
      if (current.length == current.melody.notes.length) {
        _completedMelodies.add(current.melody.id);
      }
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
