import 'package:advent_calendar/app.dart';
import 'package:advent_calendar/admin/admin_screen.dart';
import 'package:advent_calendar/achievements/achievement_store.dart';
import 'package:advent_calendar/achievements/achievements_screen.dart';
import 'package:advent_calendar/achievements/bell_songs_screen.dart';
import 'package:advent_calendar/challenges/bells/bells_screen.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/memory/memory_screen.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin_scope.dart';
import 'package:advent_calendar/content/calendar_access.dart';
import 'package:advent_calendar/content/calendar_schedule.dart';
import 'package:advent_calendar/content/game_access_scope.dart';
import 'package:advent_calendar/presentation/calendar_screen.dart';
import 'package:advent_calendar/presentation/illustrated_door.dart';
import 'package:advent_calendar/progress/mock_progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'welcome.seen.v1': true,
      SkinnableGame.unlockNoticeKey: true,
    }),
  );
  Future<CalendarAccess> access(
    WidgetTester t,
    int day,
    Set<String> completed,
  ) async {
    final schedule = CalendarSchedule();
    final policy = CalendarAccess(
      schedule: schedule,
      now: () => DateTime(2026, 12, day),
    );
    await policy.ready;
    policy.updateCompleted(completed);
    addTearDown(policy.dispose);
    addTearDown(schedule.dispose);
    return policy;
  }

  Future<void> admin(WidgetTester t) async {
    for (var i = 0; i < 5; i++) {
      await t.tap(find.byKey(const ValueKey('admin-title-entry')));
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('admin-pin')), '0542');
    await t.pump();
    await t.tap(find.text('Öffnen'));
    await t.pumpAndSettle();
  }

  testWidgets(
    'app defaults to dated locks; tapping a locked door rattles without a toast',
    (t) async {
      expect(const AdventCalendarApp().previewAllDays, isFalse);
      await t.pumpWidget(AdventCalendarApp(now: DateTime(2026, 11, 26)));
      await t.pumpAndSettle();
      expect(
        t.widget<IllustratedDoor>(find.byType(IllustratedDoor)).day.isAvailable,
        isFalse,
      );
      await t.tap(find.byType(IllustratedDoor));
      await t.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(MemoryScreen), findsNothing);
      await t.tap(find.bySemanticsLabel('2. Dezember, Gesperrt'));
      await t.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(
        t.widget<IllustratedDoor>(find.byType(IllustratedDoor)).day.number,
        1,
      );
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'admin override persists and can be turned off without deleting wins',
    (t) async {
      final progress = MockProgressRepository(completedIds: {'day-1'});
      Widget app() => MaterialApp(
        home: CalendarScreen(
          now: DateTime(2026, 11, 26),
          progressRepository: progress,
        ),
      );
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      await admin(t);
      expect(find.byType(AdminScreen), findsOneWidget);
      final toggle = find.byKey(const ValueKey('admin-unlock-all'));
      expect(t.widget<SwitchListTile>(toggle).value, isFalse);
      await t.tap(toggle);
      await t.pumpAndSettle();
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(
        t.widget<IllustratedDoor>(find.byType(IllustratedDoor)).day.isAvailable,
        isTrue,
      );
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      expect(
        t.widget<IllustratedDoor>(find.byType(IllustratedDoor)).day.isAvailable,
        isTrue,
      );
      await admin(t);
      await t.tap(toggle);
      await t.pumpAndSettle();
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(
        t.widget<IllustratedDoor>(find.byType(IllustratedDoor)).day.isAvailable,
        isFalse,
      );
      expect(await progress.completedChallengeIds(), {'day-1'});
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'award details expose every difficulty but lock later calendar levels in both skins',
    (t) async {
      final policy = await access(t, 1, {'day-1'});
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: GameAccessScope(
            access: policy,
            child: AchievementsScreen(store: store),
          ),
        ),
      );
      await t.pumpAndSettle();
      final index = achievements.indexWhere((a) => a.id == 'memory');
      t
          .widget<PageView>(find.byType(PageView))
          .controller!
          .jumpToPage(index ~/ 4);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('achievement-memory')));
      await t.pumpAndSettle();
      for (final skin in GameSkin.values) {
        expect(
          t
              .widget<OutlinedButton>(
                find.byKey(ValueKey('achievement-play-${skin.name}-easy')),
              )
              .onPressed,
          isNotNull,
        );
        for (final d in [GameDifficulty.normal, GameDifficulty.hard]) {
          expect(
            t
                .widget<OutlinedButton>(
                  find.byKey(
                    ValueKey('achievement-play-${skin.name}-${d.name}'),
                  ),
                )
                .onPressed,
            isNull,
          );
        }
      }
      await t.tap(
        find.byKey(const ValueKey('achievement-play-christmas-easy')),
      );
      await t.pumpAndSettle();
      expect(find.byType(MemoryScreen), findsOneWidget);
      expect(find.byType(GameAccessScope), findsWidgets);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'song list locks calendar tunes independently of selected difficulty',
    (t) async {
      final policy = await access(t, 10, {'day-10'});
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: GameAccessScope(
            access: policy,
            child: BellSongsScreen(store: store),
          ),
        ),
      );
      await t.pumpAndSettle();
      t
          .widget<DropdownButtonFormField<GameDifficulty>>(
            find.byType(DropdownButtonFormField<GameDifficulty>),
          )
          .onChanged!(GameDifficulty.easy);
      await t.pumpAndSettle();
      expect(
        t
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('bell-song-jingle')),
            )
            .onPressed,
        isNull,
      );
      expect(
        t
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('bell-song-all-i-want')),
            )
            .onPressed,
        isNull,
      );
      expect(
        t
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('bell-song-carol')),
            )
            .onPressed,
        isNotNull,
      );
      await t.tap(find.byKey(const ValueKey('bell-song-carol')));
      await t.pumpAndSettle();
      expect(find.byType(BellsScreen), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'the achievement song checklist cannot launch a reserved calendar melody',
    (t) async {
      final policy = await access(t, 10, {'day-10'});
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: GameAccessScope(
            access: policy,
            child: AchievementsScreen(store: store),
          ),
        ),
      );
      await t.pumpAndSettle();
      final index = achievements.indexWhere((a) => a.id == 'bells');
      t
          .widget<PageView>(find.byType(PageView))
          .controller!
          .jumpToPage(index ~/ 4);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('achievement-bells')));
      await t.pumpAndSettle();
      final jingle = find.byKey(const ValueKey('objective-bonus:bells:jingle'));
      await t.ensureVisible(jingle);
      await t.pumpAndSettle();
      await t.tap(jingle);
      await t.pumpAndSettle();
      expect(find.text('Schließe zuerst Türchen 15 ab.'), findsOneWidget);
      expect(find.byType(BellsScreen), findsNothing);
      final carol = find.byKey(const ValueKey('objective-bonus:bells:carol'));
      await t.ensureVisible(carol);
      await t.pumpAndSettle();
      await t.tap(carol);
      await t.pumpAndSettle();
      expect(
        t
            .widget<BellsScreen>(find.byType(BellsScreen))
            .level
            .rounds
            .single
            .melody
            .id,
        'carol',
      );
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'theme switch cannot reveal a scheduled song whose door was not completed',
    (t) async {
      final policy = await access(t, 15, {'day-15'});
      await t.pumpWidget(
        MaterialApp(
          home: GameAccessScope(
            access: policy,
            child: buildMinigame(
              Minigame.bells,
              GameDifficulty.normal,
              () async {},
              melodyId: 'jingle',
              alreadyCompleted: true,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('hanukkah-replay')));
      await t.pumpAndSettle();
      expect(find.text('Schließe zuerst Türchen 10 ab.'), findsOneWidget);
      expect(
        t
            .widget<BellsScreen>(find.byType(BellsScreen))
            .level
            .rounds
            .single
            .melody
            .id,
        'jingle',
      );
      await t.pumpWidget(const SizedBox());
    },
  );
}
