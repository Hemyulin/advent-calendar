import 'package:advent_calendar/app.dart';
import 'package:advent_calendar/presentation/calendar_screen.dart';
import 'package:advent_calendar/presentation/illustrated_door.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int selected(WidgetTester tester) =>
      tester.widget<IllustratedDoor>(find.byType(IllustratedDoor)).day.number;
  Future<void> swipe(WidgetTester tester, double dx) async {
    await tester.drag(find.byType(IllustratedDoor), Offset(dx, 0));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'main door swipes next and previous without opening a challenge',
    (tester) async {
      await tester.pumpWidget(AdventCalendarApp(now: DateTime(2026, 11, 7)));
      await tester.pumpAndSettle();
      expect(selected(tester), 1);
      await swipe(tester, -200);
      expect(selected(tester), 2);
      expect(find.byType(CalendarScreen), findsOneWidget);
      await swipe(tester, 200);
      expect(selected(tester), 1);
      await swipe(tester, 200);
      expect(selected(tester), 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('swiping respects locked dates and allows completed days', (
    tester,
  ) async {
    await tester.pumpWidget(
      AdventCalendarApp(now: DateTime(2026, 12, 4), previewAllDays: false),
    );
    await tester.pumpAndSettle();
    await swipe(tester, -200);
    expect(selected(tester), 4);
    await swipe(tester, 200);
    expect(selected(tester), 3);
    expect(
      tester
          .widget<IllustratedDoor>(find.byType(IllustratedDoor))
          .day
          .isAvailable,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'carousel still scrolls independently and last-day swipes do not wrap',
    (tester) async {
      await tester.pumpWidget(AdventCalendarApp(now: DateTime(2026, 11, 7)));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(selected(tester), 1);
      await tester.scrollUntilVisible(
        find.bySemanticsLabel('24. Dezember, Noch offen'),
        400,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(
        find.bySemanticsLabel('24. Dezember, Noch offen'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('24. Dezember, Noch offen'));
      await tester.pumpAndSettle();
      expect(selected(tester), 24);
      await swipe(tester, -200);
      expect(selected(tester), 24);
      await swipe(tester, 200);
      expect(selected(tester), 23);
      expect(find.bySemanticsLabel('23. Dezember, Noch offen'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'short drags in whitespace and vertical drags do not select another door',
    (tester) async {
      await tester.pumpWidget(AdventCalendarApp(now: DateTime(2026, 11, 7)));
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(25, 150), const Offset(-10, 0));
      await tester.pumpAndSettle();
      expect(selected(tester), 1);
      await tester.drag(find.byType(IllustratedDoor), const Offset(0, 120));
      await tester.pumpAndSettle();
      expect(selected(tester), 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
