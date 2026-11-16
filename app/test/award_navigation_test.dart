import 'package:advent_calendar/achievements/achievement_store.dart';
import 'package:advent_calendar/challenges/cookies/cookie_screen.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/memory/memory_screen.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin_scope.dart';
import 'package:advent_calendar/challenges/workshop/workshop_screen.dart';
import 'package:advent_calendar/content/calendar_schedule.dart';
import 'package:advent_calendar/presentation/calendar_screen.dart';
import 'package:advent_calendar/progress/mock_progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/memory_driver.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'day award shows two columns, disables future days and opens live assignments',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final schedule = CalendarSchedule();
      await schedule.ready;
      await schedule.assign(2, const DayAssignment(Minigame.workshop));
      final store = AchievementStore();
      await store.ready;
      addTearDown(schedule.dispose);
      addTearDown(store.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: CalendarScreen(
            now: DateTime(2026, 12, 2),
            schedule: schedule,
            achievementStore: store,
            progressRepository: MockProgressRepository(completedIds: {'day-1'}),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Erfolge'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('achievement-allDays')));
      await t.pumpAndSettle();
      expect(find.text('Teilziele ansehen'), findsNothing);
      final first = find.byKey(const ValueKey('award-day-1'));
      final second = find.byKey(const ValueKey('award-day-2'));
      await t.ensureVisible(first);
      await t.pumpAndSettle();
      expect(t.getTopLeft(first).dy, t.getTopLeft(second).dy);
      expect(t.getTopLeft(first).dx, lessThan(t.getTopLeft(second).dx));
      expect(t.widget<OutlinedButton>(first).onPressed, isNotNull);
      expect(
        t
            .widget<OutlinedButton>(find.byKey(const ValueKey('award-day-3')))
            .onPressed,
        isNull,
      );
      await t.tap(second);
      await t.pumpAndSettle();
      expect(find.byType(WorkshopScreen), findsOneWidget);
      expect(find.byType(CookieScreen), findsNothing);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('award-day-2')), findsOneWidget);
      await t.ensureVisible(find.byKey(const ValueKey('award-day-24')));
      await t.pumpAndSettle();
      expect(
        t.getRect(find.byKey(const ValueKey('award-day-24'))).bottom,
        lessThanOrEqualTo(844),
      );
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'first regular replay announces Chanukka once and offers a new themed run',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: buildMinigame(
            Minigame.memory,
            GameDifficulty.normal,
            () async {},
            alreadyCompleted: true,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.textContaining('Chanukka-Modus freigeschaltet!'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hanukkah-unlock-dialog')),
        findsOneWidget,
      );
      expect(
        t.getSize(
          find.descendant(
            of: find.byKey(const ValueKey('hanukkah-unlock-dialog')),
            matching: find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is StarOfDavidPainter,
            ),
          ),
        ),
        const Size(36, 36),
      );
      expect(
        find.textContaining('Davidstern oben in der App-Leiste'),
        findsOneWidget,
      );
      expect(
        GameSkinScope.isHanukkah(t.element(find.byType(MemoryScreen))),
        isFalse,
      );
      await t.tap(find.byKey(const ValueKey('hanukkah-unlock-understood')));
      await t.pumpAndSettle();
      expect(
        GameSkinScope.isHanukkah(t.element(find.byType(MemoryScreen))),
        isFalse,
      );
      expect(find.byKey(const ValueKey('hanukkah-replay')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('hanukkah-replay')));
      await t.pumpAndSettle();
      expect(
        GameSkinScope.isHanukkah(t.element(find.byType(MemoryScreen))),
        isTrue,
      );
      expect(find.byKey(const ValueKey('hanukkah-replay')), findsOneWidget);
      expect(find.byTooltip('Weihnachtsmodus spielen'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('hanukkah-replay')));
      await t.pumpAndSettle();
      expect(
        GameSkinScope.isHanukkah(t.element(find.byType(MemoryScreen))),
        isFalse,
      );
      expect(find.byTooltip('Chanukka spielen'), findsOneWidget);
      expect(
        find.textContaining('Chanukka-Modus freigeschaltet!'),
        findsNothing,
      );
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpWidget(
        MaterialApp(
          home: buildMinigame(
            Minigame.memory,
            GameDifficulty.normal,
            () async {},
            alreadyCompleted: true,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.textContaining('Chanukka-Modus freigeschaltet!'),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('hanukkah-replay')), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'first attempt has no theme shortcut; victory replay unlocks it',
    (t) async {
      var completed = 0;
      await t.pumpWidget(
        MaterialApp(
          home: buildMinigame(Minigame.memory, GameDifficulty.normal, () async {
            completed++;
          }),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('hanukkah-replay')), findsNothing);
      await solveVisibleMemory(t);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('completion-replay')));
      await t.pumpAndSettle();
      expect(completed, 1);
      expect(find.byKey(const ValueKey('hanukkah-replay')), findsOneWidget);
      expect(
        find.textContaining('Chanukka-Modus freigeschaltet!'),
        findsOneWidget,
      );
      expect(
        GameSkinScope.isHanukkah(t.element(find.byType(MemoryScreen))),
        isFalse,
      );
      await t.tap(find.byKey(const ValueKey('hanukkah-unlock-understood')));
      await t.pumpAndSettle();
      expect(
        GameSkinScope.isHanukkah(t.element(find.byType(MemoryScreen))),
        isFalse,
      );
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
