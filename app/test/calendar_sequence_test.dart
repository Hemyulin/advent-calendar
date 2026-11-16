import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advent_calendar/content/calendar_schedule.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/game_widgets.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin_scope.dart';
import 'package:advent_calendar/challenges/bells/bells_screen.dart';
import 'package:advent_calendar/challenges/bells/bells_game.dart';
import 'package:advent_calendar/challenges/shoe/shoe_game.dart';
import 'package:advent_calendar/challenges/shoe/shoe_screen.dart';
import 'package:advent_calendar/achievements/achievement_scope.dart';
import 'package:advent_calendar/achievements/achievement_store.dart';
import 'package:advent_calendar/achievements/run_facts.dart';
import 'support/game_configuration.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'the selected sequence introduces mechanics before late difficulty increases',
    () {
      const games = [
        Minigame.memory,
        Minigame.cookies,
        Minigame.maze,
        Minigame.oyVey,
        Minigame.memory,
        Minigame.shoe,
        Minigame.cookies,
        Minigame.battery,
        Minigame.chimney,
        Minigame.bells,
        Minigame.walkHome,
        Minigame.battery,
        Minigame.maze,
        Minigame.workshop,
        Minigame.walkHome,
        Minigame.memory,
        Minigame.chimney,
        Minigame.workshop,
        Minigame.walkHome,
        Minigame.cookies,
        Minigame.maze,
        Minigame.battery,
        Minigame.workshop,
        Minigame.bells,
      ];
      expect(defaultAssignments.map((a) => a.game), games);
      expect(
        defaultAssignments
            .map((a) => a.skin == GameSkin.hanukkah)
            .indexed
            .where((e) => e.$2)
            .map((e) => e.$1 + 1),
        [5, 7, 9, 10, 11, 12],
      );
      final first = <Minigame>{};
      for (final a in defaultAssignments) {
        if (first.add(a.game) &&
            !{
              Minigame.shoe,
              Minigame.chimney,
              Minigame.walkHome,
            }.contains(a.game)) {
          expect(a.difficulty, GameDifficulty.easy);
        }
      }
      expect(first, Minigame.values.toSet());
      expect(defaultAssignments[8].difficulty, GameDifficulty.normal);
      expect(defaultAssignments[10].difficulty, GameDifficulty.normal);
      final lastSeen = <Minigame, int>{};
      final lastDifficulty = <Minigame, GameDifficulty>{};
      for (final (index, assignment) in defaultAssignments.indexed) {
        final previous = lastSeen[assignment.game];
        if (previous != null) {
          expect(
            index - previous,
            greaterThanOrEqualTo(4),
            reason: '${assignment.game} repeated too soon on day ${index + 1}',
          );
          expect(
            assignment.difficulty.index,
            greaterThanOrEqualTo(lastDifficulty[assignment.game]!.index),
          );
        }
        lastSeen[assignment.game] = index;
        lastDifficulty[assignment.game] = assignment.difficulty;
      }

      expect(
        defaultAssignments
            .skip(19)
            .every((a) => a.difficulty == GameDifficulty.hard),
        isTrue,
      );
    },
  );
  test(
    'regular doors stay regular on Hanukkah dates and themed doors keep their appearance later',
    () {
      for (final date in [
        DateTime(2026, 11, 15),
        DateTime(2026, 12, 8),
        DateTime(2026, 12, 24),
      ]) {
        final days = calendarDays(date, {}, unlockAll: true);
        for (final day in [5, 6, 7, 8, 9, 10, 11, 12]) {
          final route =
              buildDailyChallenge(days[day - 1], () async {}) as SkinnableGame;
          expect(route.initialSkin, defaultAssignments[day - 1].skin);
        }
        final bells =
            configuredGame(buildDailyChallenge(days[9], () async {}))
                as BellsScreen;
        expect(bells.level.rounds.single.melody.id, 'maoz-tzur');
        expect(bells.level.guidance, BellGuidance.all);
        final shoe =
            configuredGame(buildDailyChallenge(days[5], () async {}))
                as ShoeScreen;
        expect(shoe.level.surface, CleaningSurface.boot);
      }
    },
  );
  test(
    'old full snapshots migrate defaults, preserve true custom edits and store only overrides',
    () async {
      const old = [
        'memory',
        'cookies',
        'maze',
        'chimney',
        'bells',
        'shoe',
        'cookies',
        'workshop',
        'oyVey',
        'walkHome',
        'battery',
        'memory',
        'maze',
        'chimney',
        'bells',
        'cookies',
        'workshop',
        'walkHome',
        'battery',
        'maze',
        'memory',
        'cookies',
        'chimney',
        'bells',
      ];
      final data = {
        for (var i = 0; i < 24; i++)
          '${i + 1}': {
            'game': old[i],
            'difficulty': i < 2
                ? 'easy'
                : i >= 19
                ? 'hard'
                : 'normal',
          },
      };
      data['19'] = {'game': 'cookies', 'difficulty': 'hard'};
      SharedPreferences.setMockInitialValues({
        CalendarSchedule.previousStorageKey: jsonEncode(data),
        'progress.completed.v1': ['day-6', 'day-9'],
      });
      final schedule = CalendarSchedule();
      await schedule.ready;
      addTearDown(schedule.dispose);
      expect(schedule.forDay(4).game, Minigame.oyVey);
      expect(schedule.forDay(8).skin, GameSkin.christmas);
      expect(schedule.forDay(19).game, Minigame.cookies);
      expect(schedule.forDay(19).difficulty, GameDifficulty.hard);
      await schedule.assign(
        10,
        const DayAssignment.themed(
          Minigame.bells,
          GameDifficulty.easy,
          skin: GameSkin.hanukkah,
          melodyId: 'maoz-tzur',
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      final saved =
          jsonDecode(prefs.getString(CalendarSchedule.storageKey)!) as Map;
      expect(saved.keys.toSet(), {'19', '10'});
      expect(prefs.getStringList('progress.completed.v1'), ['day-6', 'day-9']);
      final reloaded = CalendarSchedule();
      await reloaded.ready;
      addTearDown(reloaded.dispose);
      expect(reloaded.forDay(10).melodyId, 'maoz-tzur');
      expect(reloaded.forDay(10).skin, GameSkin.hanukkah);
      expect(reloaded.forDay(4).game, Minigame.oyVey);
    },
  );
  test(
    'the coin has a round cleaning mask and every difficulty supports both stages',
    () {
      for (final difficulty in GameDifficulty.values) {
        final game = ShoeGame(
          ShoeLevel.forDifficulty(difficulty, hanukkah: true),
        );
        expect(game.level.surface, CleaningSurface.coin);
        expect(game.patches.every((p) => insideCoin(p.center)), isTrue);
        expect(
          game.stroke(const ShoePoint(.01, .01), const ShoePoint(.04, .04)),
          isFalse,
        );
        expect(
          game.stroke(const ShoePoint(.5, .5), const ShoePoint(.5, .5)),
          isFalse,
        );
        var polishing = false;
        for (var i = 0; i < 2000 && !game.won; i++) {
          game.brushNextPatch();
          polishing |= game.phase == ShoePhase.polishing;
        }
        expect(polishing, isTrue);
        expect(game.won, isTrue);
      }
    },
  );
  testWidgets(
    'cleaning the coin saves a seasonal win but does not award the Nikolaus boot badge',
    (tester) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      var completions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementScope(
            record: (facts) => store.record(
              AchievementRun(
                day: 6,
                game: Minigame.shoe,
                difficulty: GameDifficulty.easy,
                facts: facts,
              ),
            ),
            child: buildMinigame(Minigame.shoe, GameDifficulty.easy, () async {
              completions++;
            }, skin: GameSkin.hanukkah),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Schekel polieren'), findsOneWidget);
      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label?.startsWith('Eine schmutzige Münze') ??
                  false),
        ),
      );
      final brush = semantics.properties.customSemanticsActions!.values.single;
      for (
        var i = 0;
        i < 1000 && find.byType(CompletionPanel).evaluate().isEmpty;
        i++
      ) {
        brush();
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(completions, 1);
      expect(store.tokenComplete('skin:shoe'), isTrue);
      expect(store.tokenComplete('bonus:shoe'), isFalse);
      expect(find.byKey(const ValueKey('hanukkah-skin-switch')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('completion-replay')));
      await tester.pumpAndSettle();
      expect(find.text('Schekel polieren'), findsOneWidget);
      expect(store.tokenComplete('skin:shoe'), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test(
    'an old eight-mode badge requires the new coin mode without losing other badges or claims',
    () async {
      SharedPreferences.setMockInitialValues({
        AchievementStore.storageKey: jsonEncode({
          'rulesVersion': 5,
          'tokens': [for (final g in hanukkahGames.take(8)) 'skin:${g.name}'],
          'earned': ['hanukkah', 'memory', 'allAchievements'],
          'claimed': ['allAchievements'],
          'rewards': {},
        }),
      });
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      final festival = achievements.firstWhere((a) => a.id == 'hanukkah');
      expect(store.progress(festival), 8);
      expect(store.earned(festival), isFalse);
      expect(
        store.earned(achievements.firstWhere((a) => a.id == 'memory')),
        isTrue,
      );
      expect(store.claimed(finalReward), isTrue);
      await store.record(
        const AchievementRun(
          day: null,
          game: Minigame.shoe,
          difficulty: GameDifficulty.easy,
          facts: RunFacts(hanukkahMode: true),
        ),
      );
      expect(store.earned(festival), isTrue);
    },
  );
}
