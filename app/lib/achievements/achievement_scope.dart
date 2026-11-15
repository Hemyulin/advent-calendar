import 'package:flutter/widgets.dart';
import 'achievement_store.dart';
import 'run_facts.dart';

class AchievementScope extends InheritedWidget {
  const AchievementScope({
    super.key,
    required this.record,
    required super.child,
  });
  final Future<List<Achievement>> Function(RunFacts facts) record;
  static AchievementScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AchievementScope>();
  @override
  bool updateShouldNotify(AchievementScope oldWidget) =>
      record != oldWidget.record;
}
