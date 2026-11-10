import 'package:advent_calendar/challenges/battery/battery_screen.dart';
import 'package:advent_calendar/challenges/battery/battery_game.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/game_preview_screen.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BatteryDeviceTile tile(WidgetTester tester, int i) =>
    tester.widget<BatteryDeviceTile>(find.byKey(ValueKey('battery-device-$i')));
Future<void> frames(WidgetTester t, double seconds) async {
  for (var i = 0; i < (seconds / .05).ceil(); i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('dragging plugs in, tapping switches, only one battery charges', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: BatteryScreen(
          level: const BatteryLevel(seed: 1),
          onComplete: () async {},
        ),
      ),
    );
    await t.pumpAndSettle();
    final initial = List.generate(5, (i) => tile(t, i).device.battery);
    await t.dragFrom(
      t.getCenter(find.byKey(const ValueKey('battery-cable'))),
      t.getCenter(find.byKey(const ValueKey('battery-device-0'))) -
          t.getCenter(find.byKey(const ValueKey('battery-cable'))),
    );
    await t.pump();
    await frames(t, .5);
    expect(tile(t, 0).charging, isTrue);
    expect(tile(t, 0).device.battery, greaterThan(initial[0]));
    expect(tile(t, 1).device.battery, lessThan(initial[1]));
    await t.tap(find.byKey(const ValueKey('battery-device-4')));
    await t.pump();
    expect(tile(t, 4).charging, isTrue);
    expect(tile(t, 0).charging, isFalse);
    expect(
      List.generate(5, (i) => tile(t, i)).where((d) => d.charging).length,
      1,
    );
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'help, background and pause freeze time, resume has no catch-up',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: BatteryScreen(
            level: const BatteryLevel(seed: 3),
            onComplete: () async {},
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('battery-device-0')));
      await frames(t, .4);
      await t.tap(find.byTooltip('Anleitung'));
      await t.pumpAndSettle();
      final beforeHelp = tile(t, 1).device.battery;
      await t.pump(const Duration(seconds: 10));
      expect(tile(t, 1).device.battery, beforeHelp);
      await t.tap(find.text('Verstanden'));
      await t.pumpAndSettle();
      await t.tap(find.text('Weiter'));
      await frames(t, .2);
      expect(tile(t, 1).device.battery, lessThan(beforeHelp));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final beforeBackground = tile(t, 1).device.battery;
      await t.pump(const Duration(seconds: 50));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(tile(t, 1).device.battery, beforeBackground);
      expect(find.text('Weiter'), findsOneWidget);
      await t.tap(find.text('Weiter'));
      await frames(t, .2);
      await t.tap(find.byTooltip('Pause'));
      await t.pump();
      final paused = tile(t, 1).device.battery;
      await t.pump(const Duration(seconds: 5));
      expect(tile(t, 1).device.battery, paused);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'failure is foreground, retry resets, success saves once and replay preserves completion',
    (t) async {
      var saves = 0;
      await t.pumpWidget(
        MaterialApp(
          home: BatteryScreen(
            level: const BatteryLevel(initialMinimum: 1, initialMaximum: 1),
            onComplete: () async {
              saves++;
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Los geht’s'));
      await frames(t, 2);
      await t.pumpAndSettle();
      expect(find.text('War doch noch bei 2 %!'), findsOneWidget);
      expect(saves, 0);
      expect(find.byKey(const ValueKey('game-result-overlay')), findsOneWidget);
      await t.tap(find.text('Noch einmal versuchen'));
      await t.pumpAndSettle();
      expect(find.text('Los geht’s'), findsOneWidget);
      await t.pumpWidget(
        MaterialApp(
          home: BatteryScreen(
            key: const ValueKey('win'),
            alreadyCompleted: true,
            level: const BatteryLevel(duration: .3),
            onComplete: () async {
              saves++;
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Los geht’s'));
      await frames(t, .5);
      await t.pumpAndSettle();
      expect(
        find.text('Du hast tatsächlich mal etwas rechtzeitig geladen!'),
        findsOneWidget,
      );
      expect(saves, 1);
      await t.tap(find.text('Noch einmal spielen'));
      await t.pumpAndSettle();
      expect(find.byTooltip('Bereits geschafft'), findsOneWidget);
      expect(saves, 1);
      await t.pumpWidget(const SizedBox());
    },
  );
  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets(
      'all difficulties and preview fit without scrolling at $scenario',
      (t) async {
        t.view.physicalSize = scenario.$1;
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = scenario.$2;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        for (final d in GameDifficulty.values) {
          await t.pumpWidget(
            MaterialApp(
              key: ValueKey(d),
              home: BatteryScreen(
                level: BatteryLevel.forDifficulty(d),
                onComplete: () async {},
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          expect(find.byType(Scrollable), findsNothing);
          await t.tap(find.byKey(const ValueKey('battery-device-0')));
          await frames(t, .3);
          expect(t.takeException(), isNull);
        }
        await t.pumpWidget(const MaterialApp(home: GamePreviewScreen()));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  test('day 11 uses shared completion and difficulty factories', () {
    Future<void> complete() async {}
    final days = calendarDays(DateTime(2026, 12, 11), {'day-11'});
    final screen = buildDailyChallenge(days[10], complete) as BatteryScreen;
    expect(screen.onComplete, same(complete));
    expect(screen.alreadyCompleted, isTrue);
    for (final d in GameDifficulty.values) {
      final preview =
          buildMinigame(Minigame.battery, d, complete) as BatteryScreen;
      expect(preview.level.drain, BatteryLevel.forDifficulty(d).drain);
    }
  });
}
