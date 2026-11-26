import 'package:advent_calendar/content/calendar_access.dart';
import 'package:advent_calendar/content/calendar_schedule.dart';
import 'package:advent_calendar/challenges/games/game_kind.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<CalendarAccess> access(DateTime Function() now) async {
    final schedule = CalendarSchedule();
    final policy = CalendarAccess(schedule: schedule, now: now);
    await policy.ready;
    addTearDown(policy.dispose);
    addTearDown(schedule.dispose);
    return policy;
  }

  test(
    'fresh installs lock every door before December and open only elapsed dates',
    () async {
      var now = DateTime(2026, 11, 26);
      final p = await access(() => now);
      expect(p.unlockAll, isFalse);
      expect([
        for (var day = 1; day <= 24; day++) p.dayAvailable(day),
      ], everyElement(isFalse));
      now = DateTime(2026, 12, 8);
      expect(p.dayAvailable(8), isTrue);
      expect(p.dayAvailable(9), isFalse);
      expect(p.reason(Minigame.walkHome, GameDifficulty.easy), isNotNull);
      expect(p.reason(Minigame.goyVey, GameDifficulty.easy), isNotNull);
    },
  );

  test(
    'first play releases unreserved levels, calendar difficulties require completed doors',
    () async {
      final p = await access(() => DateTime(2026, 12, 9));
      expect(p.reason(Minigame.chimney, GameDifficulty.easy), isNotNull);
      await p.markPlayed(Minigame.chimney);
      expect(p.reason(Minigame.chimney, GameDifficulty.easy), isNull);
      expect(p.reason(Minigame.chimney, GameDifficulty.normal), contains('9'));
      expect(p.reason(Minigame.chimney, GameDifficulty.hard), contains('17'));
      expect(
        p.reason(Minigame.chimney, GameDifficulty.normal, activeDay: 9),
        isNull,
      );
      expect(
        p.reason(Minigame.chimney, GameDifficulty.hard, activeDay: 9),
        isNotNull,
      );
      p.updateCompleted({'day-9'});
      expect(p.reason(Minigame.chimney, GameDifficulty.normal), isNull);
      expect(p.reason(Minigame.chimney, GameDifficulty.hard), isNotNull);
      final reloaded = await access(() => DateTime(2026, 12, 9));
      expect(reloaded.hasPlayed(Minigame.chimney), isTrue);
    },
  );

  test(
    'calendar reservations apply across skins and are not released by the date alone',
    () async {
      final p = await access(() => DateTime(2026, 12, 24));
      await p.markPlayed(Minigame.memory);
      p.updateCompleted({'day-1'});
      expect(p.reason(Minigame.memory, GameDifficulty.easy), isNull);
      expect(p.reason(Minigame.memory, GameDifficulty.normal), contains('5'));
      expect(
        p.reason(
          Minigame.memory,
          GameDifficulty.normal,
          skin: GameSkin.hanukkah,
        ),
        isNotNull,
      );
      expect(p.reason(Minigame.memory, GameDifficulty.hard), contains('16'));
      p.updateCompleted({'day-1', 'day-5', 'day-16'});
      for (final d in GameDifficulty.values) {
        for (final skin in GameSkin.values) {
          expect(p.reason(Minigame.memory, d, skin: skin), isNull);
        }
      }
    },
  );

  test(
    'future preview completions never defeat date locks after the override is off',
    () async {
      final p = await access(() => DateTime(2026, 12, 1));
      await p.markPlayed(Minigame.memory);
      p.updateCompleted({'day-1', 'day-5', 'day-16'});
      expect(p.reason(Minigame.memory, GameDifficulty.hard), isNotNull);
      expect(p.reason(Minigame.memory, GameDifficulty.normal), isNotNull);
      expect(p.dayAvailable(16), isFalse);
    },
  );

  test(
    'songs and difficulties have independent calendar reservations',
    () async {
      var now = DateTime(2026, 12, 10);
      final p = await access(() => now);
      await p.markPlayed(Minigame.bells);
      p.updateCompleted({'day-10'});
      expect(
        p.reason(Minigame.bells, GameDifficulty.easy, melodyId: 'maoz-tzur'),
        isNull,
      );
      expect(
        p.reason(Minigame.bells, GameDifficulty.easy, melodyId: 'sevivon'),
        isNull,
      );
      expect(
        p.reason(Minigame.bells, GameDifficulty.easy, melodyId: 'jingle'),
        contains('15'),
      );
      expect(
        p.reason(Minigame.bells, GameDifficulty.normal, melodyId: 'sevivon'),
        contains('15'),
      );
      expect(
        p.reason(Minigame.bells, GameDifficulty.easy, melodyId: 'all-i-want'),
        contains('24'),
      );
      now = DateTime(2026, 12, 15);
      p.updateCompleted({'day-10', 'day-15'});
      expect(
        p.reason(Minigame.bells, GameDifficulty.normal, melodyId: 'jingle'),
        isNull,
      );
      expect(
        p.reason(Minigame.bells, GameDifficulty.hard, melodyId: 'jingle'),
        contains('24'),
      );
      now = DateTime(2026, 12, 24);
      expect(
        p.reason(Minigame.bells, GameDifficulty.easy, melodyId: 'all-i-want'),
        isNotNull,
      );
      p.updateCompleted({'day-10', 'day-15', 'day-24'});
      expect(
        p.reason(Minigame.bells, GameDifficulty.hard, melodyId: 'all-i-want'),
        isNull,
      );
    },
  );

  test(
    'identical repeated levels stay released after the first matching completed door',
    () async {
      final p = await access(() => DateTime(2026, 12, 1));
      await p.schedule.assign(
        5,
        const DayAssignment(Minigame.memory, GameDifficulty.easy),
      );
      p.updateCompleted({'day-1'});
      expect(p.reason(Minigame.memory, GameDifficulty.easy), isNull);
    },
  );

  test(
    'admin override persists, bypasses locks and returns to date rules without clearing wins',
    () async {
      final p = await access(() => DateTime(2026, 11, 26));
      p.updateCompleted({'day-1'});
      await p.setUnlockAll(true);
      expect(p.dayAvailable(24), isTrue);
      expect(p.reason(Minigame.goyVey, GameDifficulty.hard), isNull);
      expect(
        p.reason(Minigame.bells, GameDifficulty.hard, melodyId: 'all-i-want'),
        isNull,
      );
      final reloaded = await access(() => DateTime(2026, 11, 26));
      expect(reloaded.unlockAll, isTrue);
      await p.setUnlockAll(false);
      expect(p.dayAvailable(1), isFalse);
      expect(p.reason(Minigame.goyVey, GameDifficulty.hard), isNotNull);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          CalendarAccess.overrideKey,
        ),
        isFalse,
      );
    },
  );
}
