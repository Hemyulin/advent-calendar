/// Associates calendar content with a challenge without owning its logic.
class DailyContent {
  const DailyContent({required this.day, required this.challengeId})
    : assert(day >= 1 && day <= 24);

  final int day;
  final String challengeId;
}
