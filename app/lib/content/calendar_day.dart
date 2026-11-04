import 'daily_content.dart';

enum DayState { future, today, available, completed }

class CalendarDay {
  const CalendarDay({
    required this.content,
    required this.state,
    required this.isToday,
  });

  final DailyContent content;
  final DayState state;
  final bool isToday;

  int get number => content.day;
  bool get isAvailable => state != DayState.future;
}

/// Availability always takes priority over mock completion data.
List<CalendarDay> calendarDays(DateTime now, Set<String> completedIds) {
  final today = DateTime(now.year, now.month, now.day);
  return List.generate(24, (index) {
    final day = index + 1;
    final content = DailyContent(day: day, challengeId: 'day-$day');
    final date = DateTime(now.year, 12, day);
    final state = date.isAfter(today)
        ? DayState.future
        : completedIds.contains(content.challengeId)
        ? DayState.completed
        : date == today
        ? DayState.today
        : DayState.available;
    return CalendarDay(content: content, state: state, isToday: date == today);
  });
}
