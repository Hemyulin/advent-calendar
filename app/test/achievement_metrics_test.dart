import 'dart:math' as math;
import 'package:advent_calendar/challenges/walk_home/walk_game.dart';
import 'package:advent_calendar/challenges/memory/memory_game.dart';
import 'package:advent_calendar/challenges/battery/battery_game.dart';
import 'package:advent_calendar/challenges/oy_vey/oy_vey_game.dart';
import 'package:advent_calendar/challenges/workshop/workshop_game.dart';
import 'package:advent_calendar/challenges/cookies/cookie_game.dart';
import 'package:advent_calendar/challenges/maze/maze_game.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/workshop_solutions.dart';
import 'maze_hazard_test.dart' show routeToFlag, wallDistance;

void main() {
  test('Memory only penalizes forgetting an available known twin', () {
    final g = MemoryGame(const MemoryLevel(seed: 42));
    final a = g.cards.indexOf(0), twin = g.cards.lastIndexOf(0);
    final b = g.cards.indexOf(1), c = g.cards.indexOf(2);
    g.reveal(a);
    g.reveal(b);
    g.hideMismatch();
    expect(g.knownPairMistakes, 0);
    g.reveal(c);
    g.reveal(twin);
    g.hideMismatch();
    expect(
      g.knownPairMistakes,
      0,
      reason: 'Discovering a twin as the second card is not forgetting',
    );
    g.reveal(twin);
    g.reveal(b);
    g.hideMismatch();
    expect(g.knownPairMistakes, 1);
    g.reveal(a);
    g.reveal(twin);
    expect(g.pairsFound, 1);
    expect(
      g.knownPairMistakes,
      1,
      reason: 'A later correct pair does not erase the missed opportunity',
    );
    expect(MemoryGame(const MemoryLevel()).knownPairMistakes, 0);
  });

  test('Oy Vey records exactly which correct objects were caught', () {
    final g = OyVeyGame(const OyVeyLevel(target: 2));
    void catchObject(FestiveObject kind) {
      g.objects.add(
        FallingObject(id: g.collected + g.mistakes, kind: kind, x: .5, y: .49),
      );
      g.advance(.01, const CatchMouth(.5, .5, .1));
    }

    catchObject(FestiveObject.hanukkiah);
    expect(g.menorahsCollected, 1);
    catchObject(FestiveObject.sufganiyah);
    expect(g.won, isTrue);
    expect(g.mistakes, 0);
    expect(g.menorahsCollected, lessThan(g.collected));
  });

  test(
    'battery tracks minimum and peak throughout the run, not just at victory',
    () {
      for (final difficulty in GameDifficulty.values) {
        expect(
          BatteryLevel.forDifficulty(difficulty).initialMinimum,
          greaterThan(3),
        );
      }
      final g = BatteryGame(const BatteryLevel(seed: 4))
        ..connect(0)
        ..start();
      g.devices[0].battery = 49.99;
      g.devices[1].battery = 2.9;
      g.advance(.1);
      expect(g.lowestBattery, lessThan(3));
      expect(g.highestBattery, greaterThan(50));
      g.devices[0].battery = 10;
      g.devices[1].battery = 10;
      g.advance(.1);
      expect(g.lowestBattery, lessThan(3));
      expect(g.highestBattery, greaterThan(50));
      final fresh = BatteryGame(const BatteryLevel(seed: 4));
      expect(fresh.lowestBattery, greaterThan(3));
      expect(fresh.highestBattery, lessThan(50));
    },
  );

  test('a 50-percent charge and a five-impact walk are genuinely winnable', () {
    final battery = BatteryGame(
      const BatteryLevel(
        seed: 3,
        drain: .8,
        charge: 7.4,
        eventInterval: 6.5,
        eventBoost: .6,
      ),
    )..start();
    const focus = 1;
    int selected = focus;
    double chargeTo = 50;
    for (
      var frame = 0;
      frame < 1000 && battery.phase == BatteryPhase.playing;
      frame++
    ) {
      final indices = List.generate(5, (i) => i)
        ..sort(
          (a, b) =>
              battery.devices[a].battery.compareTo(battery.devices[b].battery),
        );
      if (battery.highestBattery < 50) {
        if (selected != focus &&
            battery.devices[selected].battery >= chargeTo) {
          selected = focus;
        }
        final urgent = indices.where(
          (i) => i != focus && battery.devices[i].battery < 5.5,
        );
        if (selected == focus && urgent.isNotEmpty) {
          selected = urgent.first;
          chargeTo = 12;
        }
      } else if (battery.devices[selected].battery >= chargeTo ||
          battery.devices[indices.first].battery < 3) {
        selected = indices.first;
        chargeTo = battery.devices[selected].battery + 5;
      }
      battery.connect(selected);
      battery.advance(.05);
    }
    expect(battery.phase, BatteryPhase.won);
    expect(battery.highestBattery, greaterThanOrEqualTo(50));

    var fiveImpactWins = 0;
    for (var seed = 0; seed < 12; seed++) {
      final walk = WalkGame(
        WalkLevel.forDifficulty(GameDifficulty.easy),
        random: math.Random(seed),
      )..start();
      for (
        var frame = 0;
        frame < 4000 && walk.phase == WalkPhase.walking;
        frame++
      ) {
        final upcoming = walk.obstacles.where((o) => !o.passed);
        final target = upcoming.isEmpty ? 0.0 : upcoming.first.x;
        final desired = ((target - walk.x) * 2).clamp(-.45, .45);
        walk.advance(
          1 / 120,
          ((desired - walk.lean) * 2 - walk.angularVelocity * .9).clamp(
            -1.0,
            1.0,
          ),
        );
      }
      if (walk.phase == WalkPhase.home && walk.bumps >= 5) fiveImpactWins++;
    }
    expect(fiveImpactWins, greaterThan(0));
  });

  test(
    'workshop budgets allow only a small detour above independently shortest solutions',
    () {
      const shortest = [18, 38, 65];
      for (final difficulty in GameDifficulty.values) {
        final g = WorkshopGame(WorkshopLevel.forDifficulty(difficulty));
        expect(
          g.level.bonusMoveLimit,
          shortest[difficulty.index] + [2, 2, 3][difficulty.index],
        );
        for (final letter in workshopSolutions[difficulty.index].split('')) {
          final direction = {
            'U': WorkshopDirection.up,
            'D': WorkshopDirection.down,
            'L': WorkshopDirection.left,
            'R': WorkshopDirection.right,
          }[letter]!;
          expect(g.move(direction), isTrue);
        }
        expect(g.won, isTrue);
        expect(g.moves, shortest[difficulty.index]);
        expect(g.moves, lessThanOrEqualTo(g.level.bonusMoveLimit!));
        g.undo();
        expect(g.moves, shortest[difficulty.index] - 1);
      }
    },
  );

  test(
    'cookie recovery retains mistakes so a recovered win is not perfect',
    () {
      final g = CookieGame(const CookieLevel())..start();
      g.advance(g.secondsToTarget + 1);
      expect(g.mistakes, 1);
      g.advance(1);
      while (g.target != null) {
        g.advance(g.secondsToTarget);
        g.press(g.target!.direction);
      }
      g.advance(100);
      expect(g.phase, CookiePhase.won);
      expect(g.mistakes, 1);
    },
  );

  test(
    'all generated candies are in safe reachable side paths, across difficulties and seeds',
    () {
      for (final difficulty in GameDifficulty.values) {
        for (var seed = 0; seed < 60; seed++) {
          final layout = MazeCourse.forDifficulty(
            difficulty,
            seed: seed,
          ).layouts.single;
          final route = routeToFlag(layout);
          expect(
            layout.candies,
            hasLength(3),
            reason: '$difficulty seed $seed',
          );
          final cells = <int>{};
          for (final candy in layout.candies) {
            final cell =
                (candy.y * layout.cells).floor() * layout.cells +
                (candy.x * layout.cells).floor();
            expect(route, isNot(contains(cell)));
            cells.add(cell);
            expect(
              layout.walls.every(
                (w) => wallDistance(candy, w) > layout.ballRadius,
              ),
              isTrue,
            );
            expect(
              layout.pits.every(
                (pit) =>
                    (pit - candy).length > layout.pitRadius + layout.ballRadius,
              ),
              isTrue,
            );
          }
          expect(cells, hasLength(3));
        }
      }
    },
  );

  test(
    'candy collection counts once, is optional for finishing and resets after a fall',
    () {
      final layout = MazeCourse.forDifficulty(
        GameDifficulty.normal,
        seed: 3,
      ).layouts.single;
      final g = MazeGame(MazeCourse(layouts: [layout]));
      for (final candy in layout.candies) {
        g.position = candy;
        g.advance(.01, Vec2.zero);
        g.advance(.01, Vec2.zero);
      }
      expect(g.collectedCandy, hasLength(3));
      expect(g.allCandy, isTrue);
      g.position = layout.pits.first;
      g.advance(.01, Vec2.zero);
      expect(g.collectedCandy, isEmpty);
      expect(g.allCandy, isFalse);
      g.position = layout.goal;
      g.advance(.01, Vec2.zero);
      expect(g.won, isTrue);
      expect(g.allCandy, isFalse);
    },
  );
}
