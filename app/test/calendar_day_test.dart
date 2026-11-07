import 'package:advent_calendar/content/calendar_day.dart';
import 'package:advent_calendar/progress/mock_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'explicit preview unlocks every day without completing unsolved days',
    () {
      final days = calendarDays(DateTime(2026, 11, 4), {
        'day-1',
      }, unlockAll: true);
      expect(days, hasLength(24));
      expect(days.every((day) => day.isAvailable), isTrue);
      expect(days.first.state, DayState.completed);
      expect(
        days.skip(1).every((day) => day.state == DayState.available),
        isTrue,
      );
    },
  );
  test(
    'all 24 days are locked before December, including mock completions',
    () {
      final days = calendarDays(DateTime(2026, 11, 30), {'day-1'});
      expect(days, hasLength(24));
      expect(
        days.map((day) => day.number),
        orderedEquals(List.generate(24, (i) => i + 1)),
      );
      expect(days.every((day) => day.state == DayState.future), isTrue);
    },
  );

  test(
    'availability changes at local midnight independently of completion',
    () {
      final before = calendarDays(DateTime(2026, 12, 7, 23, 59), {
        'day-1',
        'day-8',
      });
      expect(before[0].state, DayState.completed);
      expect(before[1].state, DayState.available);
      expect(before[6].state, DayState.today);
      expect(before[7].state, DayState.future);
      final after = calendarDays(DateTime(2026, 12, 8), {'day-8'});
      expect(after[7].state, DayState.completed);
      expect(after[7].isToday, isTrue);
      expect(after[8].isAvailable, isFalse);
    },
  );

  test('all days open after Christmas; a new year resets availability', () {
    expect(
      calendarDays(DateTime(2026, 12, 31), {}).every((d) => d.isAvailable),
      isTrue,
    );
    expect(
      calendarDays(DateTime(2027, 1, 1), {}).every((d) => !d.isAvailable),
      isTrue,
    );
  });

  test(
    'mock progress returns a defensive copy and supports completion',
    () async {
      final repository = MockProgressRepository(completedIds: {'day-2'});
      final copy = await repository.completedChallengeIds();
      copy.clear();
      await repository.markCompleted('day-4');
      expect(await repository.completedChallengeIds(), {'day-2', 'day-4'});
    },
  );
}
