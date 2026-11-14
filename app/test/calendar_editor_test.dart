import 'package:advent_calendar/admin/calendar_editor_screen.dart';
import 'package:advent_calendar/challenges/cookies/cookie_game.dart';
import 'package:advent_calendar/challenges/cookies/cookie_screen.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/content/calendar_schedule.dart';
import 'package:advent_calendar/presentation/calendar_screen.dart';
import 'package:advent_calendar/presentation/illustrated_door.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'edit date, save, reopen editor and launch the assigned difficulty',
    (tester) async {
      final schedule = CalendarSchedule();
      await schedule.ready;
      addTearDown(schedule.dispose);
      await tester.pumpWidget(
        MaterialApp(home: CalendarEditorScreen(schedule: schedule)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('edit-day-12')));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .onChanged!('cookies');
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<GameDifficulty>>(
            find.byType(DropdownButtonFormField<GameDifficulty>),
          )
          .onChanged!(GameDifficulty.hard);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Gespeichert.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('edit-day-6')));
      await tester.pumpAndSettle();
      expect(find.text('Nikolausstiefel'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('edit-day-12')));
      await tester.pumpAndSettle();
      expect(find.text('Plätzchen ausstechen'), findsOneWidget);
      expect(find.text('Knifflig'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarScreen(now: DateTime(2026, 12, 12), schedule: schedule),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(IllustratedDoor));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CookieScreen>(find.byType(CookieScreen)).level.shape,
        CookieShape.snowflake,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('editor fits without scrolling at $scenario', (tester) async {
      tester.view.physicalSize = scenario.$1;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final schedule = CalendarSchedule();
      await schedule.ready;
      addTearDown(schedule.dispose);
      await tester.pumpWidget(
        MaterialApp(home: CalendarEditorScreen(schedule: schedule)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text('Speichern')).bottom,
        lessThan(scenario.$1.height),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
