import 'dart:io';
import 'dart:typed_data';

import 'package:advent_calendar/challenges/bells/bell_melodies.dart';
import 'package:advent_calendar/challenges/bells/bells_game.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'curated hooks keep recognizable phrases and finish within five seconds',
    () {
      expect(bellMelodies.map((m) => m.notes.length), [
        7,
        6,
        8,
        11,
        8,
        9,
        8,
        8,
      ]);
      final phrases = [
        'C C G G A A G',
        'G A G F E D',
        'C F F F G A A A',
        'A A A A A A A C↑ F G A',
        'G E F G A G A G',
        'H A G E Dis A H A G',
        'F E F D F E F D',
        'H H A E H H C↑ A',
      ];
      for (var i = 0; i < bellMelodies.length; i++) {
        final melody = bellMelodies[i];
        expect(melody.notes.map((n) => n.pitch.label).join(' '), phrases[i]);
        final beats = melody.notes.fold<double>(
          0,
          (sum, n) => sum + n.beats + n.restBeats,
        );
        expect(
          beats * const BellsLevel().beatMilliseconds,
          lessThanOrEqualTo(5000),
        );
        expect(
          melody.notes.every(
            (n) =>
                melody.bells.contains(n.pitch) &&
                n.beats > 0 &&
                n.restBeats >= 0,
          ),
          isTrue,
        );
        expect(melody.bells.toSet().length, melody.bells.length);
        expect(melody.bells.length, inInclusiveRange(6, 8));
      }
    },
  );
  test('difficulty uses trickier patterns, not a growing song-length ladder', () {
    final levels = GameDifficulty.values.map(BellsLevel.forDifficulty).toList();
    expect(levels.map((l) => l.guidance), BellGuidance.values);
    expect(levels.map((l) => l.rounds.single.length), [8, 8, 9]);
    expect(levels.map((l) => l.rounds.single.melody.id), [
      'carol',
      'last-christmas',
      'all-i-want',
    ]);
    expect(
      levels[1].rounds.single.notes.map((n) => n.pitch).toSet().length,
      greaterThan(
        levels[0].rounds.single.notes.map((n) => n.pitch).toSet().length,
      ),
    );
    // The hard hook repeatedly changes direction, rather than repeating one note.
    final hard = levels[2].rounds.single.notes;
    var turns = 0;
    for (var i = 2; i < hard.length; i++) {
      if ((hard[i].pitch.midi - hard[i - 1].pitch.midi).sign !=
          (hard[i - 1].pitch.midi - hard[i - 2].pitch.midi).sign) {
        turns++;
      }
    }
    expect(turns, greaterThanOrEqualTo(2));
    expect(hard.any((n) => n.pitch == BellNote.dSharp), isTrue);
    for (var i = 0; i < 100; i++) {
      expect(levels[0].showsDemonstrationNote(i), isTrue);
      expect(levels[1].showsDemonstrationNote(i), i == 0);
      expect(levels[2].showsDemonstrationNote(i), isFalse);
    }
    for (final round in bellRounds) {
      expect(round.length, round.melody.notes.length);
    }
  });

  test('only note order matters; every melody can complete a preview', () {
    for (final round in bellRounds) {
      final game = BellsGame(BellsLevel(rounds: [round]));
      expect(game.tap(round.notes.first.pitch), isFalse);
      expect(game.listen(), isTrue);
      expect(game.listen(), isFalse);
      expect(game.tap(round.notes.first.pitch), isFalse);
      game.finishListening();
      for (final note in round.notes) {
        expect(game.tap(note.pitch), isTrue);
      }
      expect(game.phase, BellsPhase.won);
      expect(game.listen(), isFalse);
      expect(game.tap(round.notes.last.pitch), isFalse);
    }
  });

  test(
    'wrong notes reset only the current attempt, with unlimited retries',
    () {
      final game = BellsGame(
        const BellsLevel(rounds: [BellRound(0, 4), BellRound(1, 5)]),
      );
      game.listen();
      game.finishListening();
      for (final note in game.current.notes) {
        game.tap(note.pitch);
      }
      expect(game.phase, BellsPhase.roundWon);
      game.nextRound();
      for (var attempt = 0; attempt < 15; attempt++) {
        game.listen();
        game.finishListening();
        game.tap(BellNote.highC);
        expect(game.phase, BellsPhase.mistake);
        expect(game.round, 1);
        expect(game.entered, 0);
        game.retry();
        expect(game.phase, BellsPhase.answering);
      }
    },
  );

  test('listening again and interruptions clear partial answers', () {
    final game = BellsGame(const BellsLevel());
    game.listen();
    game.finishListening();
    game.tap(game.current.notes.first.pitch);
    expect(game.entered, 1);
    game.listen();
    expect(game.entered, 0);
    game.interrupt();
    expect(game.phase, BellsPhase.ready);
    game.finishListening();
    expect(game.phase, BellsPhase.ready);
  });

  test(
    'completes only after every configured round; interrupt preserves wins',
    () {
      final game = BellsGame(const BellsLevel());
      for (var i = 0; i < game.level.rounds.length; i++) {
        game.listen();
        game.finishListening();
        for (final note in game.current.notes) {
          game.tap(note.pitch);
        }
        expect(
          game.phase,
          i == game.level.rounds.length - 1
              ? BellsPhase.won
              : BellsPhase.roundWon,
        );
        game.interrupt();
        game.nextRound();
      }
      expect(game.phase, BellsPhase.won);
    },
  );

  test('invalid levels are rejected', () {
    for (final level in [
      const BellsLevel(rounds: []),
      const BellsLevel(beatMilliseconds: 0),
      const BellsLevel(rounds: [BellRound(-1, 4)]),
      const BellsLevel(rounds: [BellRound(99, 4)]),
      const BellsLevel(rounds: [BellRound(0, 0)]),
      const BellsLevel(rounds: [BellRound(0, 1000)]),
    ]) {
      expect(() => BellsGame(level), throwsArgumentError);
    }
  });

  test('all bell assets are distinct audible PCM recordings with a fade', () {
    final hashes = <int>{};
    for (final note in BellNote.values) {
      final bytes = File(
        'assets/audio/bells/${note.asset}.wav',
      ).readAsBytesSync();
      final header = ByteData.sublistView(bytes);
      expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
      expect(header.getUint16(22, Endian.little), 1);
      expect(header.getUint32(24, Endian.little), 32000);
      expect(header.getUint16(34, Endian.little), 16);
      expect(bytes.length, greaterThan(64000));
      var energy = 0.0;
      var peak = 0;
      var hash = 17;
      for (var i = 44; i < bytes.length - 1; i += 2) {
        final sample = header.getInt16(i, Endian.little);
        energy += sample * sample;
        if (sample.abs() > peak) peak = sample.abs();
        hash = (hash * 31 + sample) & 0x7fffffff;
      }
      expect(peak, inInclusiveRange(10000, 24000));
      expect(energy / (bytes.length / 2), greaterThan(10000));
      expect(header.getInt16(bytes.length - 2, Endian.little), 0);
      hashes.add(hash);
    }
    expect(hashes, hasLength(BellNote.values.length));
  });
}
