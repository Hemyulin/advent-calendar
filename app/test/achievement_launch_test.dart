import 'package:advent_calendar/achievements/achievement_scope.dart';
import 'package:advent_calendar/achievements/achievement_store.dart';
import 'package:advent_calendar/achievements/achievements_screen.dart';
import 'package:advent_calendar/achievements/hanukkah_games_screen.dart';
import 'package:advent_calendar/achievements/run_facts.dart';
import 'package:advent_calendar/challenges/bells/bells_game.dart';
import 'package:advent_calendar/challenges/bells/bells_screen.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/games/game_preview_screen.dart';
import 'package:advent_calendar/challenges/games/game_widgets.dart';
import 'package:advent_calendar/challenges/memory/memory_screen.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin_scope.dart';
import 'package:advent_calendar/challenges/workshop/workshop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/memory_driver.dart';

Achievement award(String id) => achievements.firstWhere((a) => a.id == id);
Future<void> openGoal(WidgetTester t, AchievementStore store, String id) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pumpWidget(MaterialApp(home: AchievementsScreen(store: store)));
  await t.pumpAndSettle();
  t
      .widget<PageView>(find.byType(PageView))
      .controller!
      .jumpToPage(
        [...achievements, finalReward].indexWhere((a) => a.id == id) ~/ 4,
      );
  await t.pumpAndSettle();
  await t.tap(find.byKey(ValueKey('achievement-$id')));
  await t.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'every individual game goal is launchable without a prior calendar win',
    (t) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      for (final a in achievements) {
        final game = gameForAchievement(a.id);
        if (game == null) continue;
        await openGoal(t, store, a.id);
        expect(
          find.byKey(const ValueKey('achievement-play-christmas-normal')),
          findsOneWidget,
          reason: a.id,
        );
        expect(
          find.byKey(const ValueKey('achievement-play-hanukkah-normal')),
          supportsHanukkah(game) ? findsOneWidget : findsNothing,
          reason: a.id,
        );
        expect(find.textContaining('Schließe zuerst'), findsNothing);
      }
      expect(store.progress(award('allDays')), 0);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Chanukka memory launches on Klassisch and saves real achievements without a door win',
    (t) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await openGoal(t, store, 'memory');
      await t.tap(
        find.byKey(const ValueKey('achievement-play-hanukkah-normal')),
      );
      await t.pumpAndSettle();
      expect(
        t.widget<MemoryScreen>(find.byType(MemoryScreen)).level.attempts,
        20,
      );
      expect(
        GameSkinScope.isHanukkah(t.element(find.byType(MemoryScreen))),
        isTrue,
      );
      expect(find.byKey(const ValueKey('hanukkah-skin-switch')), findsNothing);
      await solveVisibleMemory(t);
      await t.pumpAndSettle();
      expect(store.progress(award('allGames')), 1);
      expect(store.tokenComplete('skin:memory'), isTrue);
      expect(store.progress(award('allDays')), 0);
      await t.tap(find.byKey(const ValueKey('completion-gift')));
      await t.pumpAndSettle();
      expect(find.byType(CompletionPanel), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('completion-replay')));
      await t.pumpAndSettle();
      expect(
        GameSkinScope.isHanukkah(t.element(find.byType(MemoryScreen))),
        isTrue,
      );
      expect(store.progress(award('hanukkah')), 1);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'multi-difficulty goals expose all three Chanukka levels without a gate',
    (t) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await openGoal(t, store, 'workshop');
      for (final d in GameDifficulty.values) {
        await t.tap(
          find.byKey(ValueKey('achievement-play-hanukkah-${d.name}')),
        );
        await t.pumpAndSettle();
        expect(
          t.widget<WorkshopScreen>(find.byType(WorkshopScreen)).level!.size,
          [6, 7, 8][d.index],
        );
        expect(
          GameSkinScope.isHanukkah(t.element(find.byType(WorkshopScreen))),
          isTrue,
        );
        await t.tap(find.byType(BackButton));
        await t.pumpAndSettle();
      }
      expect(store.progress(award('allDays')), 0);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Chanukka collection defaults to Klassisch', (t) async {
    final store = AchievementStore();
    await store.ready;
    addTearDown(store.dispose);
    await t.pumpWidget(MaterialApp(home: HanukkahGamesScreen(store: store)));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('hanukkah-game-memory')));
    await t.pumpAndSettle();
    expect(
      t.widget<MemoryScreen>(find.byType(MemoryScreen)).level.attempts,
      20,
    );
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Chanukka song selection is explicit and keeps the selected song',
    (t) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await openGoal(t, store, 'bells');
      final song = find.byKey(
        const ValueKey('objective-bonus:bells:maoz-tzur'),
      );
      expect(song, findsOneWidget);
      expect(
        find.byKey(const ValueKey('objective-bonus:bells:last-christmas')),
        findsOneWidget,
      );
      expect(find.text('Teilziele ansehen'), findsNothing);
      await t.ensureVisible(song);
      await t.tap(song);
      await t.pumpAndSettle();
      final level = t.widget<BellsScreen>(find.byType(BellsScreen)).level;
      expect(level.guidance, BellGuidance.firstOnly);
      expect(level.rounds.single.melody.id, 'maoz-tzur');
      await t.tap(find.byKey(const ValueKey('hanukkah-replay')));
      await t.pumpAndSettle();
      expect(
        t
            .widget<BellsScreen>(find.byType(BellsScreen))
            .level
            .rounds
            .single
            .melody
            .id,
        'last-christmas',
      );
      await t.tap(find.byKey(const ValueKey('hanukkah-replay')));
      await t.pumpAndSettle();
      expect(
        t
            .widget<BellsScreen>(find.byType(BellsScreen))
            .level
            .rounds
            .single
            .melody
            .id,
        'maoz-tzur',
      );

      expect(find.byKey(const ValueKey('hanukkah-skin-switch')), findsNothing);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'admin Chanukka preview launches explicitly and has no achievement writer',
    (t) async {
      await t.pumpWidget(const MaterialApp(home: GamePreviewScreen()));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('preview-hanukkah-games')));
      await t.pumpAndSettle();
      await t.tap(find.text('Paare finden'));
      await t.pumpAndSettle();
      final context = t.element(find.byType(MemoryScreen));
      expect(GameSkinScope.isHanukkah(context), isTrue);
      expect(AchievementScope.maybeOf(context), isNull);
      await t.tap(find.byKey(const ValueKey('hanukkah-replay')));
      await t.pumpAndSettle();
      expect(
        GameSkinScope.isHanukkah(t.element(find.byType(MemoryScreen))),
        isFalse,
      );
      await t.tap(find.byKey(const ValueKey('hanukkah-replay')));
      await t.pumpAndSettle();
      expect(
        GameSkinScope.isHanukkah(t.element(find.byType(MemoryScreen))),
        isTrue,
      );
      expect(
        find.byKey(const ValueKey('hanukkah-unlock-dialog')),
        findsNothing,
      );
      expect(
        AchievementScope.maybeOf(t.element(find.byType(MemoryScreen))),
        isNull,
      );
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'Nikolaus practice can earn its badge without completing door six',
    () async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await store.record(
        AchievementRun(
          day: null,
          game: gameForAchievement('shoe')!,
          difficulty: GameDifficulty.normal,
          facts: const RunFacts(),
        ),
      );
      expect(store.earned(award('shoe')), isTrue);
      expect(store.progress(award('allDays')), 0);
    },
  );
}
