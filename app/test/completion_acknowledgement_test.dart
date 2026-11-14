import 'dart:async';
import 'support/memory_driver.dart';
import 'package:advent_calendar/admin/admin_screen.dart';
import 'package:advent_calendar/admin/pico_connection_screen.dart';
import 'package:advent_calendar/challenges/memory/memory_screen.dart';
import 'package:advent_calendar/hardware/pico_service.dart';
import 'package:advent_calendar/presentation/calendar_screen.dart';
import 'package:advent_calendar/presentation/illustrated_door.dart';
import 'package:advent_calendar/progress/mock_progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const ready = PicoResponse(
  200,
  '{"device":"DoorZero","status":"ready","mode":"connected","ip":"192.168.178.68"}',
);
void main() {
  testWidgets(
    'daily completion and replay remain usable while the POST is pending',
    (t) async {
      final pending = Completer<PicoResponse>();
      var posts = 0;
      final progress = MockProgressRepository(completedIds: {});
      final pico = PicoService(
        baseUrl: 'http://pico',
        timeout: const Duration(seconds: 30),
        request: (_, _) async => ready,
        postRequest: (_, _) async {
          posts++;
          return pending.future;
        },
      );
      await t.pumpWidget(
        MaterialApp(
          home: CalendarScreen(
            now: DateTime(2026, 12, 1),
            progressRepository: progress,
            picoService: pico,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byType(IllustratedDoor));
      await t.pumpAndSettle();
      await solveVisibleMemory(t);
      await t.pumpAndSettle();
      expect(find.text('Geschafft!'), findsOneWidget);
      expect(posts, 1);
      expect(pending.isCompleted, isFalse);
      expect(await progress.completedChallengeIds(), contains('day-1'));
      final replay = find.widgetWithText(OutlinedButton, 'Noch einmal spielen');
      expect(t.widget<OutlinedButton>(replay).onPressed, isNotNull);
      await t.tap(replay);
      await t.pumpAndSettle();
      await solveVisibleMemory(t);
      await t.pumpAndSettle();
      expect(posts, 1);
      pending.complete(const PicoResponse(204));
      await t.pumpAndSettle();
      await t.pumpWidget(const SizedBox());
      pico.dispose();
    },
  );
  testWidgets(
    'preview completion does not notify Pico or save daily progress',
    (t) async {
      var requests = 0;
      final progress = MockProgressRepository(completedIds: {});
      final pico = PicoService(
        request: (_, _) async {
          requests++;
          return ready;
        },
        postRequest: (_, _) async {
          requests++;
          return const PicoResponse(204);
        },
      );
      await t.pumpWidget(
        MaterialApp(
          home: CalendarScreen(
            now: DateTime(2026, 11, 14),
            showGamePreview: true,
            progressRepository: progress,
            picoService: pico,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Spiele ausprobieren'));
      await t.pumpAndSettle();
      await t.tap(find.text('Paare finden'));
      await t.pumpAndSettle();
      await t.widget<MemoryScreen>(find.byType(MemoryScreen)).onComplete();
      await t.pump();
      expect(requests, 0);
      expect(await progress.completedChallengeIds(), isEmpty);
      await t.pumpWidget(const SizedBox());
      pico.dispose();
    },
  );
  testWidgets('admin reuses the calendar connection manager', (t) async {
    final pico = PicoService(
      baseUrl: 'http://pico',
      request: (_, _) async => ready,
    );
    await t.pumpWidget(
      MaterialApp(
        home: CalendarScreen(now: DateTime(2026, 11, 14), picoService: pico),
      ),
    );
    await t.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await t.tap(find.byKey(const ValueKey('admin-title-entry')));
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('admin-pin')), '0542');
    await t.pump();
    await t.tap(find.text('Öffnen'));
    await t.pumpAndSettle();
    expect(
      t.widget<AdminScreen>(find.byType(AdminScreen)).picoService,
      same(pico),
    );
    await t.tap(find.text('Box-Steuerung'));
    await t.pumpAndSettle();
    expect(
      t.widget<PicoConnectionScreen>(find.byType(PicoConnectionScreen)).service,
      same(pico),
    );
    await t.pumpWidget(const SizedBox());
    pico.dispose();
  });
}
