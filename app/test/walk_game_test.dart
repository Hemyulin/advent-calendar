import 'dart:math' as math;
import 'package:advent_calendar/challenges/walk_home/walk_game.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('three routes last 30–45 seconds and get narrower and wobblier', () {
    final levels = GameDifficulty.values.map(WalkLevel.forDifficulty).toList();
    for (final l in levels) {
      expect(l.seconds, inInclusiveRange(30, 45));
    }
    expect(levels[0].halfWidth, greaterThan(levels[1].halfWidth));
    expect(levels[1].halfWidth, greaterThan(levels[2].halfWidth));
    expect(levels[0].wobble, lessThan(levels[1].wobble));
    expect(levels[1].spacing, greaterThan(levels[2].spacing));
  });
  test('sustained over-lean falls, brief imbalance can be corrected', () {
    final g = WalkGame(const WalkLevel(seed: 1))..start();
    g.lean = 1;
    for (var i = 0; i < 3; i++) {
      g.advance(.1, 0);
    }
    expect(g.phase, WalkPhase.walking);
    expect(g.danger, greaterThan(0));
    for (var i = 0; i < 20; i++) {
      g.advance(.1, 0);
    }
    expect(g.phase, WalkPhase.fallen);
    final recovered = WalkGame(const WalkLevel(seed: 1))..start();
    recovered.unstableTime = .3;
    recovered.advance(.1, 0);
    expect(recovered.unstableTime, lessThan(.3));
  });
  test(
    'objects collide once and ice changes traction rather than instantly ending the walk',
    () {
      final g = WalkGame(const WalkLevel(seed: 2))..start();
      for (final obstacle in g.obstacles) {
        g.elapsed = obstacle.at - .005;
        g.x = obstacle.x;
        g.lean = 0;
        g.angularVelocity = 0;
        g.unstableTime = 0;
        final count = g.bumps;
        g.advance(.01, 0);
        expect(g.bumps, count + 1);
        expect(obstacle.hit, isTrue);
        expect(g.phase, WalkPhase.walking);
        if (obstacle.kind == StreetObstacleKind.ice) {
          expect(g.slipperyLeft, greaterThan(1.6));
        }
        g.advance(.01, 0);
        expect(g.bumps, count + 1);
      }
    },
  );
  test(
    'each obstacle leaves a genuinely passable gap and useful reaction time',
    () {
      for (final difficulty in GameDifficulty.values) {
        final g = WalkGame(WalkLevel.forDifficulty(difficulty));
        expect(g.obstacles.first.at, greaterThanOrEqualTo(5));
        expect(
          g.obstacles.map((o) => o.kind).toSet(),
          containsAll(StreetObstacleKind.values),
        );
        for (final o in g.obstacles) {
          final gap = math.max(
            o.x - o.halfWidth + g.level.halfWidth,
            g.level.halfWidth - o.x - o.halfWidth,
          );
          expect(gap, greaterThan(WalkGame.characterRadius * 2 + .1));
        }
      }
    },
  );
  test(
    'feedback controller can reach home across seeded routes at each difficulty',
    () {
      final failures = <String>[];
      for (final difficulty in GameDifficulty.values) {
        for (var seed = 0; seed < 12; seed++) {
          final base = WalkLevel.forDifficulty(difficulty);
          final g = WalkGame(base, random: math.Random(seed))..start();
          for (
            var frame = 0;
            frame < (base.seconds + 1) * 120 && g.phase == WalkPhase.walking;
            frame++
          ) {
            double target = 0;
            final upcoming = g.obstacles.where(
              (o) => !o.passed && o.at - g.elapsed < 4.5,
            );
            if (upcoming.isNotEmpty) {
              final o = upcoming.first;
              final options =
                  [
                        -base.halfWidth + .13,
                        -base.halfWidth * .5,
                        0.0,
                        base.halfWidth * .5,
                        base.halfWidth - .13,
                      ]
                      .where(
                        (x) =>
                            (x - o.x).abs() >
                            o.halfWidth + WalkGame.characterRadius + .04,
                      )
                      .toList()
                    ..sort(
                      (a, b) => ((a - g.x).abs() + a.abs() * .1).compareTo(
                        (b - g.x).abs() + b.abs() * .1,
                      ),
                    );
              if (options.isNotEmpty) target = options.first;
            }
            final desired = ((target - g.x) * 2).clamp(-.45, .45);
            final input = ((desired - g.lean) * 2 - g.angularVelocity * .9)
                .clamp(-1.0, 1.0);
            g.advance(1 / 120, input);
          }
          if (g.phase != WalkPhase.home) {
            failures.add(
              '$difficulty seed $seed at ${g.elapsed.toStringAsFixed(1)} x=${g.x.toStringAsFixed(2)} lean=${g.lean.toStringAsFixed(2)}',
            );
          }
        }
      }
      expect(failures, isEmpty);
    },
  );
  test('no control requires corrections and invalid deltas do nothing', () {
    final g = WalkGame(const WalkLevel(seed: 3));
    g.advance(1, 0);
    expect(g.elapsed, 0);
    g.start();
    g.advance(double.nan, 0);
    g.advance(1, double.infinity);
    expect(g.elapsed, 0);
    for (var i = 0; i < 450 && g.phase == WalkPhase.walking; i++) {
      g.advance(.1, 0);
    }
    expect(g.phase, WalkPhase.fallen);
    expect(() => WalkGame(const WalkLevel(seconds: 0)), throwsArgumentError);
  });
  test('substepping gives consistent results across frame rates', () {
    final a = WalkGame(const WalkLevel(seed: 8))..start(),
        b = WalkGame(const WalkLevel(seed: 8))..start();
    for (var i = 0; i < 30; i++) {
      a.advance(1 / 30, .1);
    }
    for (var i = 0; i < 120; i++) {
      b.advance(1 / 120, .1);
    }
    expect(a.x, closeTo(b.x, 1e-8));
    expect(a.lean, closeTo(b.lean, 1e-8));
  });
}
