import 'package:advent_calendar/app.dart';
import 'package:advent_calendar/challenges/memory/memory_screen.dart';
import 'support/memory_driver.dart';
import 'package:advent_calendar/presentation/illustrated_door.dart';
import 'package:advent_calendar/progress/mock_progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('day one requires winning a game, then reveals its gift', (
    tester,
  ) async {
    final progress = MockProgressRepository(completedIds: {});
    await tester.pumpWidget(
      AdventCalendarApp(
        now: DateTime(2026, 12, 1),
        progressRepository: progress,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.byType(MemoryScreen), findsOneWidget);
    expect(find.text('0 / 8 Paare · 26 Versuche'), findsOneWidget);
    expect(find.byKey(const ValueKey('completion-gift')), findsNothing);
    expect(await progress.completedChallengeIds(), isEmpty);

    await solveVisibleMemory(tester);
    expect(find.text('Geschafft!'), findsOneWidget);
    expect(await progress.completedChallengeIds(), {'day-1'});
    expect(find.text('Tippe auf dein Geschenk.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('completion-gift')));
    await tester.pumpAndSettle();
    expect(
      find.text('Geschenk geöffnet. Die Box ist noch nicht eingerichtet.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Zurück zum Kalender'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('1. Dezember, Heute, geschafft'),
      findsOneWidget,
    );
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Bereits geschafft'), findsOneWidget);
    expect(find.byType(MemoryScreen), findsOneWidget);
    expect(await progress.completedChallengeIds(), {'day-1'});
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
