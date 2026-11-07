import 'dart:io';
import 'dart:typed_data';

import 'package:advent_calendar/challenges/bells/bell_melodies.dart';
import 'package:advent_calendar/challenges/bells/bells_game.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('published melody fragments and durations are preserved', () {
    expect(
      bellMelodies.map((m) => m.notes.map((n) => n.pitch.label).join(' ')),
      [
        'C C G G A A G F F E',
        'G A G F E D C D E F',
        'C F F F G A A A A G',
        'E G C D E F F F F F',
        'G E F G A G A G F D',
      ],
    );
    expect(bellMelodies[1].notes.take(4).map((n) => n.beats), [1.5, .5, 1, 1]);
    expect(bellMelodies[2].notes.take(5).map((n) => n.beats), [
      1,
      .75,
      .25,
      1,
      1,
    ]);
    expect(bellMelodies[4].notes.take(8).map((n) => n.beats), [
      2,
      1,
      1,
      .5,
      .5,
      .5,
      .5,
      2,
    ]);
    for (final melody in bellMelodies) {
      expect(
        melody.notes.every(
          (n) => BellNote.values.contains(n.pitch) && n.beats > 0,
        ),
        isTrue,
      );
    }
  });

  test('every difficulty begins with four notes and increases to 8–10', () {
    for (final difficulty in GameDifficulty.values) {
      final level = BellsLevel.forDifficulty(difficulty);
      expect(level.rounds.first.length, 4);
      expect(level.rounds.last.length, inInclusiveRange(8, 10));
      for (var i = 1; i < level.rounds.length; i++) {
        expect(level.rounds[i].length, greaterThan(level.rounds[i - 1].length));
      }
      expect(level.rounds.map((r) => r.melodyIndex).toSet(), {0, 1, 2, 3, 4});
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
      final game = BellsGame(const BellsLevel());
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
    game.tap(BellNote.c);
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
      const BellsLevel(rounds: [BellRound(9, 4)]),
      const BellsLevel(rounds: [BellRound(0, 0)]),
      const BellsLevel(rounds: [BellRound(0, 11)]),
    ]) {
      expect(() => BellsGame(level), throwsArgumentError);
    }
  });

  test(
    'all eight bell assets are distinct audible PCM recordings with a fade',
    () {
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
      expect(hashes, hasLength(8));
    },
  );
}
