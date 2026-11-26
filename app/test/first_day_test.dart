import 'package:advent_calendar/presentation/calendar_screen.dart';
import 'package:advent_calendar/hardware/pico_service.dart';
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
    final posts = <String>[];
    final pico = PicoService(
      baseUrl: 'http://pico',
      request: (_, _) async => const PicoResponse(
        200,
        '{"device":"DoorZero","status":"ready","mode":"connected","ip":"192.168.178.68"}',
      ),
      postRequest: (uri, _) async {
        posts.add(uri.path);
        return uri.path == '/unlock'
            ? const PicoResponse(200, '{"success":true,"duration_ms":200}')
            : const PicoResponse(204);
      },
    );
    addTearDown(pico.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarScreen(
          picoService: pico,
          now: DateTime(2026, 12, 1),
          progressRepository: progress,
        ),
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
    expect(find.byKey(const ValueKey('completion-gift')), findsOneWidget);
    expect(await progress.completedChallengeIds(), {'day-1'});
    expect(find.text('Zum Öffnen tippen'), findsOneWidget);
    expect(posts, ['/game/completed']);
    await tester.tap(find.byKey(const ValueKey('completion-gift')));
    await tester.pumpAndSettle();
    expect(find.text('Die Box wurde entriegelt.'), findsOneWidget);
    expect(posts, ['/game/completed', '/unlock']);
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
    expect(posts, ['/game/completed', '/unlock']);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
