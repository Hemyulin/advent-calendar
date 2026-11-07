import 'package:advent_calendar/challenges/bells/bell_audio.dart';
import 'package:advent_calendar/challenges/bells/bell_melodies.dart';
import 'package:advent_calendar/challenges/bells/bells_game.dart';
import 'package:advent_calendar/challenges/bells/bells_screen.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/game_preview_screen.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBellAudio implements BellAudio {
  final played = <BellNote>[];
  bool failPrepare = false, failPlay = false, disposed = false;
  int stops = 0;
  @override
  Future<void> prepare() async {
    if (failPrepare) throw StateError('audio');
  }

  @override
  Future<void> play(BellNote note) async {
    if (failPlay) throw StateError('audio');
    played.add(note);
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

Future<void> hear(
  WidgetTester tester, {
  String label = 'Melodie anhören',
  int frames = 50,
}) async {
  await tester.tap(find.text(label));
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets(
    'listens in order, ignores rhythm, completes once, replay preserves completion',
    (tester) async {
      final audio = FakeBellAudio();
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: BellsScreen(
            audio: audio,
            alreadyCompleted: true,
            level: const BellsLevel(
              rounds: [BellRound(0, 4)],
              beatMilliseconds: 200,
            ),
            onComplete: () async {
              completed++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bell-c')));
      expect(audio.played, isEmpty);
      await hear(tester);
      expect(audio.played, [BellNote.c, BellNote.c, BellNote.g, BellNote.g]);
      expect(find.text('Jetzt bist du dran'), findsOneWidget);
      for (final note in [BellNote.c, BellNote.c, BellNote.g, BellNote.g]) {
        await tester.tap(find.byKey(ValueKey('bell-${note.name}')));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 8)); // No input timeout.
      }
      await tester.pumpAndSettle();
      expect(find.text('Geschafft!'), findsOneWidget);
      expect(completed, 1);
      await tester.tap(find.text('Noch einmal spielen'));
      await tester.pumpAndSettle();
      expect(find.text('Melodie anhören'), findsOneWidget);
      expect(find.byTooltip('Bereits geschafft'), findsOneWidget);
      expect(completed, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(audio.disposed, isTrue);
    },
  );

  testWidgets(
    'wrong note gives gentle retry; listen-again restarts the sequence',
    (tester) async {
      final audio = FakeBellAudio();
      await tester.pumpWidget(
        MaterialApp(
          home: BellsScreen(
            audio: audio,
            level: const BellsLevel(
              rounds: [BellRound(0, 4)],
              beatMilliseconds: 200,
            ),
            onComplete: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await hear(tester);
      await tester.tap(find.byKey(const ValueKey('bell-d')));
      await tester.pump();
      expect(find.text('Noch einmal – du schaffst das.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Jetzt bist du dran'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bell-c')));
      await tester.pump();
      await hear(tester, label: 'Erneut anhören');
      expect(audio.played.skip(audio.played.length - 4), [
        BellNote.c,
        BellNote.c,
        BellNote.g,
        BellNote.g,
      ]);
      expect(find.text('Jetzt bist du dran'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('help and background cancel playback without delayed notes', (
    tester,
  ) async {
    final audio = FakeBellAudio();
    await tester.pumpWidget(
      MaterialApp(
        home: BellsScreen(audio: audio, onComplete: () async {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Melodie anhören'));
    await tester.pump();
    await tester.tap(find.byTooltip('Anleitung'));
    await tester.pump();
    final count = audio.played.length;
    await tester.pump(const Duration(seconds: 10));
    expect(audio.played.length, count);
    await tester.tap(find.text('Verstanden'));
    await tester.pumpAndSettle();
    expect(find.text('Melodie anhören'), findsOneWidget);
    await tester.tap(find.text('Melodie anhören'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    final pausedCount = audio.played.length;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 10));
    expect(audio.played.length, pausedCount);
    expect(find.text('Melodie anhören'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'audio errors are visible and retryable without silent completion',
    (tester) async {
      final audio = FakeBellAudio()..failPrepare = true;
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: BellsScreen(
            audio: audio,
            onComplete: () async {
              completed++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ton erneut laden'), findsOneWidget);
      audio.failPrepare = false;
      await tester.tap(find.text('Ton erneut laden'));
      await tester.pumpAndSettle();
      audio.failPlay = true;
      await tester.tap(find.text('Melodie anhören'));
      await tester.pumpAndSettle();
      expect(find.text('Der Ton konnte nicht geladen werden.'), findsOneWidget);
      expect(completed, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets(
      'bell board and all previews fit without scrolling at $scenario',
      (tester) async {
        tester.view.physicalSize = scenario.$1;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            home: BellsScreen(
              audio: FakeBellAudio(),
              previewControls: true,
              onComplete: () async {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const MaterialApp(home: GamePreviewScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('development selector starts each melody as an isolated preview', (
    tester,
  ) async {
    final audio = FakeBellAudio();
    await tester.pumpWidget(
      MaterialApp(
        home: BellsScreen(
          audio: audio,
          previewControls: true,
          level: const BellsLevel(beatMilliseconds: 200),
          onComplete: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < bellRounds.length; i++) {
      // Exercise the selector callback independently of platform popup sizing.
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byKey(const ValueKey('bell-melody-preview')),
          )
          .onChanged!(i);
      await tester.pumpAndSettle();
      audio.played.clear();
      await hear(tester, frames: 100);
      expect(audio.played, bellRounds[i].notes.map((note) => note.pitch));
      expect(find.text(bellRounds[i].melody.title), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('Day 5 receives the shared completion and replay state', () {
    Future<void> complete() async {}
    final days = calendarDays(DateTime(2026, 12, 24), {'day-5'});
    final screen = buildDailyChallenge(days[4], complete) as BellsScreen;
    expect(screen.onComplete, same(complete));
    expect(screen.alreadyCompleted, isTrue);
  });
}
