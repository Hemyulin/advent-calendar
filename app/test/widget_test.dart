import 'package:advent_calendar/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the iOS-generated scaffold starts the actual Advent calendar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      AdventCalendarApp(now: DateTime(2026, 12, 1), previewAllDays: false),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Willkommen in deinem Adventskalender, Schlizi!'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('welcome-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Dein Adventskalender'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
