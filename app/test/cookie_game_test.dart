import 'package:advent_calendar/challenges/cookies/cookie_game.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('difficulty selects shape, speed, checkpoints and timing windows', () {
    final levels = GameDifficulty.values
        .map(CookieLevel.forDifficulty)
        .toList();
    expect(levels.map((l) => l.shape), CookieShape.values);
    expect(levels.map((l) => l.checkpoints), [6, 9, 12]);
    for (var i = 0; i < 2; i++) {
      expect(levels[i].speed, lessThan(levels[i + 1].speed));
      expect(
        levels[i].timingWindowSeconds,
        greaterThan(levels[i + 1].timingWindowSeconds),
      );
    }
    expect(levels.every((l) => l.mistakeLimit == 3), isTrue);
  });

  test(
    'all outlines are closed, continuous and measured at a constant arc speed',
    () {
      for (final shape in CookieShape.values) {
        final outline = CookieOutline.forShape(shape);
        expect((outline.at(0) - outline.at(1)).length, closeTo(0, 1e-9));
        expect(outline.totalLength, greaterThan(2));
        for (var i = 0; i < 1000; i++) {
          final p = outline.at(i / 1000);
          expect(p.x, inInclusiveRange(.05, .95));
          expect(p.y, inInclusiveRange(.05, .95));
          expect(outline.tangentAt(i / 1000).length, closeTo(1, 1e-9));
          // Chord distance can only shorten near polygon corners.
          expect(
            (outline.at((i + 1) / 1000) - p).length,
            lessThanOrEqualTo(outline.totalLength / 1000 + 1e-9),
          );
        }
      }
    },
  );

  test('every checkpoint direction follows the actual outline tangent', () {
    for (final difficulty in GameDifficulty.values) {
      final game = CookieGame(CookieLevel.forDifficulty(difficulty));
      for (final checkpoint in game.checkpoints) {
        final tangent = game.outline.tangentAt(checkpoint.fraction);
        expect(
          checkpoint.direction,
          tangent.x.abs() > tangent.y.abs()
              ? (tangent.x > 0 ? CutDirection.right : CutDirection.left)
              : (tangent.y > 0 ? CutDirection.down : CutDirection.up),
        );
      }
    }
  });

  test(
    'every level is winnable and requires every checkpoint plus the final cut',
    () {
      for (final difficulty in GameDifficulty.values) {
        final game = CookieGame(CookieLevel.forDifficulty(difficulty));
        expect(game.press(CutDirection.up), CutInput.ignored);
        game.advance(10);
        expect(game.progress, 0);
        game.start();
        while (game.target != null) {
          final target = game.target!;
          game.advance((target.fraction - game.progress) / game.level.speed);
          expect(game.inWindow, isTrue);
          expect(game.press(target.direction), CutInput.correct);
          expect(game.cutUntil, target.fraction);
        }
        expect(game.phase, CookiePhase.cutting);
        game.advance((1 - game.progress) / game.level.speed + .001);
        expect(game.phase, CookiePhase.won);
        expect(game.cutUntil, 1);
        expect(game.mistakes, 0);
        expect(game.press(CutDirection.up), CutInput.ignored);
      }
    },
  );

  test(
    'both timing boundaries are accepted; outside them counts as a mistake',
    () {
      for (final edge in [-1.0, 1.0]) {
        final game = CookieGame(const CookieLevel());
        game.start();
        final target = game.target!;
        game.advance(
          (target.fraction + edge * game.halfWindow) / game.level.speed,
        );
        expect(game.press(target.direction), CutInput.correct);
      }
      for (final edge in [-1.0, 1.0]) {
        final game = CookieGame(const CookieLevel());
        game.start();
        final target = game.target!;
        game.advance(
          (target.fraction + edge * (game.halfWindow + .0001)) /
              game.level.speed,
        );
        if (edge < 0) {
          expect(game.press(target.direction), CutInput.wrongTiming);
        }
        expect(game.mistakes, 1);
        expect(game.next, 0);
        expect(game.cutUntil, 0);
      }
    },
  );

  test(
    'wrong direction and three missed windows lose without advancing cuts',
    () {
      final game = CookieGame(const CookieLevel());
      game.start();
      game.advance(game.secondsToTarget);
      final wrong = CutDirection.values.firstWhere(
        (d) => d != game.target!.direction,
      );
      expect(game.press(wrong), CutInput.wrongDirection);
      expect(game.mistakes, 1);
      expect(game.press(wrong), CutInput.ignored);
      game.advance(.6);
      game.advance(game.secondsToTarget + 1);
      expect(game.mistakes, 2);
      game.advance(.6);
      game.advance(game.secondsToTarget + 1);
      expect(game.mistakes, 3);
      expect(game.phase, CookiePhase.lost);
      expect(game.next, 0);
      expect(game.cutUntil, 0);
      game.advance(100);
      expect(game.mistakes, 3);
    },
  );

  test(
    'recovery retries the same point, retains earlier cuts and allows a win',
    () {
      final game = CookieGame(const CookieLevel());
      game.start();
      game.advance(game.secondsToTarget);
      game.press(game.target!.direction);
      final cut = game.cutUntil;
      game.advance(game.secondsToTarget + 1);
      expect(game.next, 1);
      expect(game.cutUntil, cut);
      game.advance(.59);
      expect(game.phase, CookiePhase.recovering);
      game.advance(.02);
      expect(game.phase, CookiePhase.cutting);
      expect(
        game.secondsToTarget,
        greaterThan(game.level.timingWindowSeconds / 2),
      );
      while (game.target != null) {
        game.advance(game.secondsToTarget);
        game.press(game.target!.direction);
      }
      game.advance(100);
      expect(game.phase, CookiePhase.won);
      expect(game.mistakes, 1);
    },
  );

  test(
    'frame partitioning is consistent; long gaps cannot consume multiple lives',
    () {
      final a = CookieGame(const CookieLevel())..start();
      final b = CookieGame(const CookieLevel())..start();
      a.advance(.7);
      for (var i = 0; i < 70; i++) {
        b.advance(.01);
      }
      expect(a.progress, closeTo(b.progress, 1e-9));
      a.advance(1000);
      expect(a.mistakes, 1);
      a.advance(1000);
      expect(a.mistakes, 1);
      expect(a.phase, CookiePhase.cutting);
    },
  );

  test('custom speed, checkpoint count and mistake limit are honored', () {
    final game = CookieGame(
      const CookieLevel(
        shape: CookieShape.star,
        speed: .1,
        checkpoints: 4,
        mistakeLimit: 1,
      ),
    );
    game.start();
    game.advance(.5);
    expect(game.progress, .05);
    expect(game.checkpoints, hasLength(4));
    game.press(CutDirection.up);
    expect(game.phase, CookiePhase.lost);
  });

  test('invalid configurations and invalid elapsed time are handled', () {
    for (final level in [
      const CookieLevel(speed: 0),
      const CookieLevel(speed: double.nan),
      const CookieLevel(timingWindowSeconds: 0),
      const CookieLevel(timingWindowSeconds: 100),
      const CookieLevel(checkpoints: 0),
      const CookieLevel(checkpoints: 33),
      const CookieLevel(mistakeLimit: 0),
    ]) {
      expect(() => CookieGame(level), throwsArgumentError);
    }
    final game = CookieGame(const CookieLevel())..start();
    game.advance(double.nan);
    game.advance(double.infinity);
    game.advance(-1);
    expect(game.progress, 0);
  });
}
