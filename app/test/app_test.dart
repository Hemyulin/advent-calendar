import 'package:advent_calendar/app.dart';
import 'package:advent_calendar/presentation/calendar_awards_button.dart';
import 'package:advent_calendar/progress/mock_progress_repository.dart';
import 'package:advent_calendar/challenges/memory/memory_screen.dart';
import 'package:advent_calendar/challenges/bells/bells_screen.dart';
import 'package:advent_calendar/presentation/challenge_screen.dart';
import 'package:advent_calendar/presentation/illustrated_door.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> start(WidgetTester tester, DateTime date) async {
    await tester.pumpWidget(
      AdventCalendarApp(
        now: date,
        previewAllDays: false,
        progressRepository: MockProgressRepository(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('before December all doors are locked', (tester) async {
    await start(tester, DateTime(2026, 11, 4));
    expect(find.text('Dein Adventskalender'), findsOneWidget);
    expect(
      tester
          .widget<IllustratedDoor>(find.byType(IllustratedDoor))
          .day
          .isAvailable,
      isFalse,
    );
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.byType(ChallengeScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview unlocks the entire carousel before December', (
    tester,
  ) async {
    await tester.pumpWidget(AdventCalendarApp(now: DateTime(2026, 11, 4)));
    await tester.pumpAndSettle();
    expect(find.text('Vorschau'), findsNothing);
    expect(find.byTooltip('Spiele ausprobieren'), findsNothing);
    expect(find.text('DEZEMBER'), findsNothing);
    expect(find.byTooltip('Erfolge'), findsOneWidget);
    expect(
      tester
          .widget<IllustratedDoor>(find.byType(IllustratedDoor))
          .day
          .isAvailable,
      isTrue,
    );
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('24. Dezember, Noch offen'),
      400,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.bySemanticsLabel('24. Dezember, Noch offen'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<IllustratedDoor>(find.byType(IllustratedDoor)).day.number,
      24,
    );
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.byType(BellsScreen), findsOneWidget);
  });

  testWidgets(
    'door swings before navigation, ignores repeated taps, and resets',
    (tester) async {
      await start(tester, DateTime(2026, 12, 16));
      await tester.tap(find.byType(IllustratedDoor));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(ChallengeScreen), findsNothing);
      final transform = find.descendant(
        of: find.byType(IllustratedDoor),
        matching: find.byType(Transform),
      );
      expect(
        tester.widget<Transform>(transform).transform.storage[0],
        lessThan(0.99),
      );
      await tester.tap(find.byType(IllustratedDoor));
      await tester.pumpAndSettle();
      expect(find.byType(MemoryScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Transform>(transform).transform.storage[0],
        closeTo(1, 0.001),
      );
      await tester.tap(find.byType(IllustratedDoor));
      await tester.pumpAndSettle();
      expect(find.byType(MemoryScreen), findsOneWidget);
    },
  );

  testWidgets('reduced motion opens without a door swing', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await start(tester, DateTime(2026, 12, 16));
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pump();
    await tester.pump();
    expect(find.byType(MemoryScreen), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('today opens its assigned game and can return', (tester) async {
    await start(tester, DateTime(2026, 12, 16));
    expect(find.bySemanticsLabel('16. Dezember, Heute'), findsOneWidget);
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.byType(MemoryScreen), findsOneWidget);
    expect(find.byTooltip('Zurück'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(IllustratedDoor), findsOneWidget);
  });

  testWidgets('carousel selects unfinished and completed days, blocks future', (
    tester,
  ) async {
    await start(tester, DateTime(2026, 12, 4));
    await tester.tap(find.bySemanticsLabel('2. Dezember, Noch offen'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<IllustratedDoor>(find.byType(IllustratedDoor)).day.number,
      2,
    );
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.text('Plätzchen ausstechen'), findsOneWidget);
    await tester.ensureVisible(find.byType(BackButton));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('3. Dezember, Geschafft'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<IllustratedDoor>(find.byType(IllustratedDoor)).day.number,
      3,
    );
    await tester.tap(find.bySemanticsLabel('5. Dezember, Gesperrt'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<IllustratedDoor>(find.byType(IllustratedDoor)).day.number,
      3,
    );
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.text('Kugellabyrinth'), findsOneWidget);
    expect(find.byTooltip('Bereits geschafft'), findsOneWidget);
  });

  testWidgets('carousel scrolls to day 24', (tester) async {
    await start(tester, DateTime(2026, 12, 24));
    expect(find.bySemanticsLabel('24. Dezember, Heute'), findsOneWidget);
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.byType(BellsScreen), findsOneWidget);
  });

  testWidgets('small screen and large type fit without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await start(tester, DateTime(2026, 12, 16));
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(CalendarAwardsButton)).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getRect(find.byType(IllustratedDoor)).bottom,
      lessThanOrEqualTo(568),
    );
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.byType(MemoryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
