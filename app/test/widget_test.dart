import 'package:advent_calendar/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the iOS-generated scaffold starts the actual Advent calendar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      AdventCalendarApp(now: DateTime(2026, 12, 1), previewAllDays: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dein Adventskalender'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
