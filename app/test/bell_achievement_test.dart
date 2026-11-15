import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advent_calendar/achievements/achievement_store.dart';
import 'package:advent_calendar/achievements/run_facts.dart';
import 'package:advent_calendar/achievements/achievement_scope.dart';
import 'package:advent_calendar/achievements/achievements_screen.dart';
import 'package:advent_calendar/achievements/bell_songs_screen.dart';
import 'package:advent_calendar/challenges/bells/bell_audio.dart';
import 'package:advent_calendar/challenges/bells/bell_melodies.dart';
import 'package:advent_calendar/challenges/bells/bells_game.dart';
import 'package:advent_calendar/challenges/bells/bells_screen.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/games/game_kind.dart';

class SilentBells implements BellAudio {
  @override
  Future<void> prepare() async {}
  @override
  Future<void> play(BellNote note) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

Achievement get concert => achievements.firstWhere((a) => a.id == 'bells');
AchievementRun songs(Set<String> ids, {Minigame game = Minigame.bells}) =>
    AchievementRun(
      day: null,
      game: game,
      difficulty: GameDifficulty.normal,
      facts: RunFacts(completedBellSongs: ids),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('only a fully answered curated song adds its stable ID', () {
    for (var index = 0; index < bellMelodies.length; index++) {
      final g = BellsGame(BellsLevel(rounds: [BellRound(index)]));
      g.listen();
      g.finishListening();
      expect(g.completedMelodyIds, isEmpty);
      for (var note = 0; note < g.current.notes.length; note++) {
        expect(g.tap(g.current.notes[note].pitch), isTrue);
        expect(g.completedMelodyIds.isEmpty, note < g.current.notes.length - 1);
      }
      expect(g.completedMelodyIds, {bellMelodies[index].id});
      expect(() => g.completedMelodyIds.add('fake'), throwsUnsupportedError);
    }
    final short = BellsGame(const BellsLevel(rounds: [BellRound(0, 4)]));
    short.listen();
    short.finishListening();
    for (final note in short.current.notes) {
      short.tap(note.pitch);
    }
    expect(short.phase, BellsPhase.won);
    expect(short.completedMelodyIds, isEmpty);
  });

  test(
    'mistakes or repeated listening do not count; a later successful answer does',
    () {
      final g = BellsGame(
        const BellsLevel(rounds: [BellRound(0), BellRound(1)]),
      );
      g.listen();
      g.finishListening();
      g.listen();
      g.finishListening();
      expect(g.completedMelodyIds, isEmpty);
      g.tap(BellNote.highD);
      expect(g.phase, BellsPhase.mistake);
      expect(g.completedMelodyIds, isEmpty);
      g.retry();
      for (final note in g.current.notes) {
        g.tap(note.pitch);
      }
      expect(g.phase, BellsPhase.roundWon);
      g.nextRound();
      g.listen();
      g.finishListening();
      for (final note in g.current.notes) {
        g.tap(note.pitch);
      }
      expect(g.phase, BellsPhase.won);
      expect(g.completedMelodyIds, {bellMelodies[0].id, bellMelodies[1].id});
    },
  );

  test(
    'eight distinct songs persist; repeated, unknown and wrong-game IDs never inflate progress',
    () async {
      final store = AchievementStore();
      await store.ready;
      final all = bellMelodies.map((m) => m.id).toSet();
      await store.record(songs(all, game: Minigame.memory));
      expect(store.progress(concert), 0);
      await store.record(songs({bellMelodies.first.id, 'unknown'}));
      await store.record(songs({bellMelodies.first.id}));
      expect(store.progress(concert), 1);
      expect(store.earned(concert), isFalse);
      final earned = await store.record(songs(all));
      expect(earned.map((a) => a.id), contains('bells'));
      expect(store.progress(concert), bellMelodies.length);
      expect(await store.record(songs(all)), isEmpty);
      final reloaded = AchievementStore();
      await reloaded.ready;
      expect(reloaded.earned(concert), isTrue);
      expect(reloaded.progress(concert), bellMelodies.length);
      expect(
        reloaded.progress(achievements.firstWhere((a) => a.id == 'allDays')),
        0,
      );
      store.dispose();
      reloaded.dispose();
    },
  );

  test(
    'new concert goal re-evaluates the final bonus while preserving badges and received vouchers',
    () async {
      SharedPreferences.setMockInitialValues({
        AchievementStore.storageKey: jsonEncode({
          'rulesVersion': 3,
          'tokens': ['bonus:memory', 'game:bells'],
          'earned': ['memory', 'allExtras', 'allAchievements'],
          'claimed': ['allAchievements'],
          'rewards': {},
        }),
      });
      final store = AchievementStore();
      await store.ready;
      expect(
        store.earned(achievements.firstWhere((a) => a.id == 'memory')),
        isTrue,
      );
      expect(store.earned(concert), isFalse);
      expect(store.earned(finalReward), isFalse);
      expect(store.claimed(finalReward), isTrue);
      store.dispose();
    },
  );

  testWidgets(
    'actually winning the last missing melody unlocks and celebrates the concert',
    (tester) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await store.record(songs(bellMelodies.skip(1).map((m) => m.id).toSet()));
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementScope(
            record: (facts) => store.record(
              AchievementRun(
                day: null,
                game: Minigame.bells,
                difficulty: GameDifficulty.easy,
                facts: facts,
              ),
            ),
            child: BellsScreen(
              audio: SilentBells(),
              level: const BellsLevel(
                rounds: [BellRound(0)],
                beatMilliseconds: 200,
              ),
              onComplete: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Melodie anhören'));
      for (var i = 0; i < 70; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(store.progress(concert), bellMelodies.length - 1);
      for (final note in bellMelodies.first.notes) {
        await tester.tap(find.byKey(ValueKey('bell-${note.pitch.name}')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(store.earned(concert), isTrue);
      expect(
        find.byKey(const ValueKey('achievement-celebration-toast')),
        findsOneWidget,
      );
      expect(find.text(concert.title), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'player song collection opens every full hook with the selected difficulty',
    (tester) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await tester.pumpWidget(MaterialApp(home: BellSongsScreen(store: store)));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<GameDifficulty>>(
            find.byType(DropdownButtonFormField<GameDifficulty>),
          )
          .onChanged!(GameDifficulty.easy);
      await tester.pumpAndSettle();
      for (var i = 0; i < bellMelodies.length; i++) {
        if (i > 0 && i % 8 == 0) {
          await tester.tap(find.byKey(const ValueKey('bell-songs-next')));
          await tester.pumpAndSettle();
        }
        await tester.tap(
          find.byKey(ValueKey('bell-song-${bellMelodies[i].id}')),
        );
        await tester.pumpAndSettle();
        final screen = tester.widget<BellsScreen>(find.byType(BellsScreen));
        expect(screen.level.rounds.single.melody.id, bellMelodies[i].id);
        expect(screen.level.rounds.single.length, bellMelodies[i].notes.length);
        expect(screen.level.guidance, BellGuidance.all);
        expect(screen.previewControls, isFalse);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      expect(store.progress(concert), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'concert detail offers the song collection after completing a bells door',
    (tester) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await store.record(songs({bellMelodies.first.id}));
      await tester.pumpWidget(
        MaterialApp(home: AchievementsScreen(store: store)),
      );
      await tester.pumpAndSettle();
      tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .jumpToPage(achievements.indexOf(concert) ~/ 4);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('achievement-bells')));
      await tester.pumpAndSettle();
      expect(find.text('1 / ${bellMelodies.length}'), findsOneWidget);
      await tester.tap(find.text('Lieder spielen'));
      await tester.pumpAndSettle();
      expect(find.byType(BellSongsScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('song collection fits without scrolling at $scenario', (
      tester,
    ) async {
      tester.view.physicalSize = scenario.$1;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await tester.pumpWidget(MaterialApp(home: BellSongsScreen(store: store)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsNothing);
      for (var i = 0; i < bellMelodies.length; i++) {
        if (i > 0 && i % 8 == 0) {
          await tester.tap(find.byKey(const ValueKey('bell-songs-next')));
          await tester.pumpAndSettle();
        }
        final melody = bellMelodies[i];
        final rect = tester.getRect(
          find.byKey(ValueKey('bell-song-${melody.id}')),
        );
        expect(rect.bottom, lessThanOrEqualTo(scenario.$1.height));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
