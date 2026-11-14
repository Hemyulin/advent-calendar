import 'dart:convert';
import 'package:advent_calendar/content/calendar_schedule.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/battery/battery_screen.dart';
import 'package:advent_calendar/challenges/battery/battery_game.dart';
import 'package:advent_calendar/challenges/memory/memory_screen.dart';
import 'package:advent_calendar/presentation/challenge_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'all 24 doors have playable defaults, including easy Memory and Nikolaus',
    () {
      final days = calendarDays(DateTime(2026, 12, 24), {});
      expect(defaultAssignments, hasLength(24));
      expect(defaultAssignments.first.game, Minigame.memory);
      expect(defaultAssignments.first.difficulty, GameDifficulty.easy);
      expect(defaultAssignments[1].game, Minigame.cookies);
      expect(defaultAssignments[1].difficulty, GameDifficulty.easy);
      expect(defaultAssignments[5].game, Minigame.shoe);
      for (final day in days) {
        expect(
          buildDailyChallenge(day, () async {}),
          isNot(isA<ChallengeScreen>()),
        );
      }
    },
  );

  test('game and difficulty persist across new schedule instances', () async {
    final schedule = CalendarSchedule();
    await schedule.ready;
    await schedule.assign(
      24,
      const DayAssignment(Minigame.battery, GameDifficulty.hard),
    );
    final reloaded = CalendarSchedule();
    await reloaded.ready;
    expect(reloaded.forDay(24).game, Minigame.battery);
    expect(reloaded.forDay(24).difficulty, GameDifficulty.hard);
    expect(reloaded.forDay(6).game, Minigame.shoe);
    expect(() => schedule.forDay(25), throwsRangeError);
    schedule.dispose();
    reloaded.dispose();
  });

  test('routing honors overrides on day 1 and keeps completion by door', () {
    Future<void> complete() async {}
    final day = calendarDays(DateTime(2026, 12, 24), {'day-1'}).first;
    final screen =
        buildDailyChallenge(
              day,
              complete,
              assignment: const DayAssignment(
                Minigame.battery,
                GameDifficulty.hard,
              ),
            )
            as BatteryScreen;
    expect(screen.onComplete, same(complete));
    expect(screen.alreadyCompleted, isTrue);
    expect(
      screen.level.duration,
      BatteryLevel.forDifficulty(GameDifficulty.hard).duration,
    );
  });

  test(
    'unknown entries fall back individually; malformed storage stays usable',
    () async {
      SharedPreferences.setMockInitialValues({
        CalendarSchedule.storageKey: jsonEncode({
          '2': {'game': 'removed-game', 'difficulty': 'hard'},
          '6': {'game': 'bells', 'difficulty': 'hard'},
          '7': {'game': 'battery', 'difficulty': 'unknown'},
        }),
      });
      final schedule = CalendarSchedule();
      await schedule.ready;
      expect(schedule.forDay(2).game, Minigame.cookies);
      expect(schedule.forDay(6).game, Minigame.bells);
      expect(schedule.forDay(7).game, Minigame.cookies);
      schedule.dispose();
      SharedPreferences.setMockInitialValues({
        CalendarSchedule.storageKey: '{bad',
      });
      final broken = CalendarSchedule();
      await broken.ready;
      expect(broken.loaded, isTrue);
      expect(broken.error, isNotNull);
      expect(broken.forDay(6).game, Minigame.shoe);
      await broken.assign(6, const DayAssignment(Minigame.memory));
      expect(broken.error, isNull);
      broken.dispose();
    },
  );

  test('old present-only assignments migrate to easy Memory', () async {
    SharedPreferences.setMockInitialValues({
      CalendarSchedule.storageKey: jsonEncode({
        '1': {'game': 'tutorial', 'difficulty': 'normal'},
      }),
    });
    final schedule = CalendarSchedule();
    await schedule.ready;
    expect(schedule.forDay(1).game, Minigame.memory);
    expect(schedule.forDay(1).difficulty, GameDifficulty.easy);
    final day = calendarDays(DateTime(2026, 12, 1), {}).first;
    expect(
      buildDailyChallenge(day, () async {}, assignment: schedule.forDay(1)),
      isA<MemoryScreen>(),
    );
    schedule.dispose();
  });

  test(
    'legacy day-two default upgrades while explicit new assignments persist',
    () async {
      SharedPreferences.setMockInitialValues({
        CalendarSchedule.legacyStorageKey: jsonEncode({
          '2': {'game': 'memory', 'difficulty': 'normal'},
          '6': {'game': 'bells', 'difficulty': 'hard'},
        }),
      });
      final schedule = CalendarSchedule();
      await schedule.ready;
      expect(schedule.forDay(2).game, Minigame.cookies);
      expect(schedule.forDay(2).difficulty, GameDifficulty.easy);
      expect(schedule.forDay(6).game, Minigame.bells);
      await schedule.assign(2, const DayAssignment(Minigame.memory));
      final reloaded = CalendarSchedule();
      await reloaded.ready;
      expect(reloaded.forDay(2).game, Minigame.memory);
      expect(reloaded.forDay(6).game, Minigame.bells);
      schedule.dispose();
      reloaded.dispose();
    },
  );

  test(
    'legacy custom day-two games and difficulties remain assigned',
    () async {
      for (final assignment in [
        const DayAssignment(Minigame.battery),
        const DayAssignment(Minigame.memory, GameDifficulty.hard),
      ]) {
        SharedPreferences.setMockInitialValues({
          CalendarSchedule.legacyStorageKey: jsonEncode({
            '2': {
              'game': assignment.game.name,
              'difficulty': assignment.difficulty.name,
            },
          }),
        });
        final schedule = CalendarSchedule();
        await schedule.ready;
        expect(schedule.forDay(2).game, assignment.game);
        expect(schedule.forDay(2).difficulty, assignment.difficulty);
        schedule.dispose();
      }
    },
  );

  test('storage failures leave the previous assignment in effect', () async {
    final schedule = CalendarSchedule(
      preferences: () async => throw StateError('unavailable'),
    );
    await schedule.ready;
    expect(schedule.error, isNotNull);
    await expectLater(
      schedule.assign(6, const DayAssignment(Minigame.memory)),
      throwsStateError,
    );
    expect(schedule.forDay(6).game, Minigame.shoe);
    schedule.dispose();
  });
}
