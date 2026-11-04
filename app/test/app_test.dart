import 'package:advent_calendar/app.dart';
import 'package:advent_calendar/presentation/challenge_screen.dart';
import 'package:advent_calendar/presentation/illustrated_door.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> start(WidgetTester tester, DateTime date) async {
    await tester.pumpWidget(AdventCalendarApp(now: date));
    await tester.pumpAndSettle();
  }

  testWidgets('before December all doors are locked', (tester) async {
    await start(tester, DateTime(2026, 11, 4));
    expect(find.text('Dein Adventskalender'), findsOneWidget);
    expect(find.text('Öffnet am 1. Dezember'), findsOneWidget);
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.byType(ChallengeScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('today opens a German placeholder and can return', (
    tester,
  ) async {
    await start(tester, DateTime(2026, 12, 8));
    expect(find.text('Dein Moment für heute'), findsOneWidget);
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.text('Türchen 8'), findsOneWidget);
    expect(find.byTooltip('Zurück'), findsOneWidget);
    await tester.tap(find.text('Zurück zum Kalender'));
    await tester.pumpAndSettle();
    expect(find.byType(IllustratedDoor), findsOneWidget);
  });

  testWidgets('carousel selects unfinished and completed days, blocks future', (
    tester,
  ) async {
    await start(tester, DateTime(2026, 12, 4));
    await tester.tap(find.bySemanticsLabel('2. Dezember, Noch offen'));
    await tester.pumpAndSettle();
    expect(find.text('Ein Türchen wartet noch auf dich'), findsOneWidget);
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.text('Türchen 2'), findsOneWidget);
    await tester.tap(find.text('Zurück zum Kalender'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('3. Dezember, Geschafft'));
    await tester.pumpAndSettle();
    expect(find.text('Schon geöffnet. Noch einmal entdecken?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('5. Dezember, Gesperrt'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<IllustratedDoor>(find.byType(IllustratedDoor)).day.number,
      3,
    );
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.text('Türchen 3'), findsOneWidget);
    expect(
      find.text('Bereits geschafft · jederzeit wieder entdecken'),
      findsOneWidget,
    );
  });

  testWidgets('carousel scrolls to day 24', (tester) async {
    await start(tester, DateTime(2026, 12, 24));
    expect(find.bySemanticsLabel('24. Dezember, Heute'), findsOneWidget);
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.text('Türchen 24'), findsOneWidget);
  });

  testWidgets(
    'small screen and large type remain scrollable without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await start(tester, DateTime(2026, 12, 8));
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byType(IllustratedDoor),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(IllustratedDoor));
      await tester.pumpAndSettle();
      expect(find.byType(ChallengeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
