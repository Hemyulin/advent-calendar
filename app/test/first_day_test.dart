import 'package:advent_calendar/app.dart';
import 'package:advent_calendar/challenges/tutorial/first_day_screen.dart';
import 'package:advent_calendar/presentation/illustrated_door.dart';
import 'package:advent_calendar/progress/mock_progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openTutorial(
    WidgetTester tester,
    MockProgressRepository repository,
  ) async {
    await tester.pumpWidget(
      AdventCalendarApp(
        now: DateTime(2026, 11, 6),
        progressRepository: repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.byType(FirstDayScreen), findsOneWidget);
  }

  testWidgets(
    'one tap reveals the gift, updates the calendar, and allows replay',
    (tester) async {
      final repository = MockProgressRepository(completedIds: {});
      await openTutorial(tester, repository);
      expect(await repository.completedChallengeIds(), isEmpty);
      await tester.ensureVisible(find.text('Überraschung öffnen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Überraschung öffnen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(await repository.completedChallengeIds(), isEmpty);
      expect(find.text('Öffnet …'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.pumpAndSettle();
      expect(find.text('Geschafft!'), findsOneWidget);
      expect(await repository.completedChallengeIds(), {'day-1'});
      await tester.ensureVisible(find.text('Zurück zum Kalender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zurück zum Kalender'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('1. Dezember, Geschafft'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsNWidgets(2));
      await tester.tap(find.byType(IllustratedDoor));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Bereits geschafft'), findsOneWidget);
      await tester.ensureVisible(find.text('Überraschung öffnen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Überraschung öffnen'));
      await tester.pumpAndSettle();
      expect(find.text('Geschafft!'), findsOneWidget);
      expect(await repository.completedChallengeIds(), {'day-1'});
    },
  );

  testWidgets('leaving before or during the reveal does not complete day one', (
    tester,
  ) async {
    final repository = MockProgressRepository(completedIds: {});
    await openTutorial(tester, repository);
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(await repository.completedChallengeIds(), isEmpty);
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Überraschung öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Überraschung öffnen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(await repository.completedChallengeIds(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completion only runs once for repeated taps', (tester) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: FirstDayScreen(
          onComplete: () async {
            completions++;
          },
        ),
      ),
    );
    await tester.ensureVisible(find.text('Überraschung öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Überraschung öffnen'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.pumpAndSettle();
    expect(completions, 1);
  });

  testWidgets('failed progress write allows retry without false success', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: FirstDayScreen(
          onComplete: () async {
            attempts++;
            if (attempts == 1) throw StateError('test storage failure');
          },
        ),
      ),
    );
    await tester.ensureVisible(find.text('Überraschung öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Überraschung öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Geschafft!'), findsNothing);
    expect(
      find.text('Das hat gerade nicht geklappt. Versuch es noch einmal.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Überraschung öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Überraschung öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Geschafft!'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('reduced motion completes immediately without an animated wait', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: FirstDayScreen(
          onComplete: () async {
            completed = true;
          },
        ),
      ),
    );
    await tester.ensureVisible(find.text('Überraschung öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Überraschung öffnen'));
    await tester.pump();
    expect(completed, isTrue);
    expect(find.text('Geschafft!'), findsOneWidget);
  });

  testWidgets('tutorial works on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(home: FirstDayScreen(onComplete: () async {})),
    );
    await tester.ensureVisible(find.text('Überraschung öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Überraschung öffnen'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Zurück zum Kalender')).bottom,
      lessThanOrEqualTo(568),
    );
    expect(find.text('Geschafft!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
