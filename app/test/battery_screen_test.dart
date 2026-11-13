import 'package:advent_calendar/challenges/battery/battery_screen.dart';
import 'package:advent_calendar/challenges/battery/battery_game.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/game_preview_screen.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:advent_calendar/challenges/battery/battery_art.dart';
import 'package:flutter_test/flutter_test.dart';

BatteryDeviceTile tile(WidgetTester tester, int i) =>
    tester.widget<BatteryDeviceTile>(find.byKey(ValueKey('battery-device-$i')));
Future<void> frames(WidgetTester t, double seconds) async {
  for (var i = 0; i < (seconds / .05).ceil(); i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> connect(WidgetTester t, int index) async {
  final plug = find.byKey(const ValueKey('battery-cable'));
  final target = find.byKey(ValueKey('battery-device-$index'));
  await t.dragFrom(t.getCenter(plug), t.getCenter(target) - t.getCenter(plug));
  await t.pump();
}

void main() {
  testWidgets('only dragging the actual plug starts or changes charging', (
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
    final initial = tile(t, 0).device.battery;
    expect(find.text('Los geht’s'), findsNothing);
    await t.tap(find.byKey(const ValueKey('battery-device-0')));
    await frames(t, 1);
    expect(tile(t, 0).charging, isFalse);
    expect(tile(t, 0).device.battery, initial);
    await connect(t, 0);
    expect(tile(t, 0).charging, isTrue);
    final pluggedBounds = t.getRect(
      find.byKey(const ValueKey('battery-cable')),
    );
    expect(
      pluggedBounds,
      t.getRect(find.byKey(const ValueKey('battery-device-0'))),
    );
    await t.tap(find.byKey(const ValueKey('battery-device-4')));
    await t.pump();
    expect(tile(t, 0).charging, isTrue);
    expect(tile(t, 4).charging, isFalse);
    await t.drag(
      find.byKey(const ValueKey('battery-device-4')),
      const Offset(0, -120),
    );
    await t.pump();
    expect(tile(t, 0).charging, isTrue);
    final gesture = await t.startGesture(
      t.getCenter(find.byKey(const ValueKey('battery-device-0'))),
    );
    await gesture.moveTo(
      t.getCenter(find.byKey(const ValueKey('battery-device-1'))),
    );
    await t.pump();
    expect(List.generate(5, (i) => tile(t, i)).any((d) => d.charging), isFalse);
    await gesture.up();
    await t.pump();
    expect(tile(t, 1).charging, isTrue);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
    'cord follows a scaled pointer, unplugging and cancelling restores the previous connection',
    (t) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        MaterialApp(
          home: BatteryScreen(
            level: const BatteryLevel(seed: 1),
            onComplete: () async {},
          ),
        ),
      );
      await t.pumpAndSettle();
      await connect(t, 0);
      await t.pump();
      await frames(t, .3);
      final gesture = await t.startGesture(
        t.getCenter(find.byKey(const ValueKey('battery-cable'))),
      );
      final point =
          t.getTopLeft(find.byKey(const ValueKey('battery-cord'))) +
          const Offset(15, 15);
      await gesture.moveTo(point);
      await t.pump();
      final custom = t.widget<CustomPaint>(
        find.byKey(const ValueKey('battery-cord')),
      );
      final cord = custom.painter! as CablePainter;
      expect(cord.dragging, isTrue);
      expect(
        List.generate(5, (i) => tile(t, i)).any((d) => d.charging),
        isFalse,
      );
      final box = t.renderObject<RenderBox>(
        find.byKey(const ValueKey('battery-cord')),
      );
      expect((cord.end - box.globalToLocal(point)).distance, lessThan(.01));
      await gesture.up();
      await t.pump();
      await frames(t, .25);
      expect(tile(t, 0).charging, isTrue);
      final snapped =
          t
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('battery-cord')),
                  )
                  .painter!
              as CablePainter;
      expect((snapped.end - deskPort(0, box.size)).distance, lessThan(.01));
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'haptics are opt-in, critical warning is distinct and not repeated each frame',
    (t) async {
      final calls = <MethodCall>[];
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await t.pumpWidget(
        MaterialApp(home: BatteryScreen(onComplete: () async {})),
      );
      await t.pumpAndSettle();
      await connect(t, 0);
      await t.pump();
      expect(calls.where((c) => c.method == 'HapticFeedback.vibrate'), isEmpty);
      await t.tap(find.byTooltip('Vibration einschalten'));
      await t.pump();
      await connect(t, 2);
      await t.pump();
      expect(
        calls.any((c) => c.arguments == 'HapticFeedbackType.selectionClick'),
        isTrue,
      );
      tile(t, 1).device.battery = 2;
      await frames(t, .3);
      expect(
        calls
            .where((c) => c.arguments == 'HapticFeedbackType.mediumImpact')
            .length,
        1,
      );
      await frames(t, .3);
      expect(
        calls
            .where((c) => c.arguments == 'HapticFeedbackType.mediumImpact')
            .length,
        1,
      );
      await t.tap(find.byTooltip('Vibration ausschalten'));
      await t.pump();
      final count = calls
          .where((c) => c.method == 'HapticFeedback.vibrate')
          .length;
      await connect(t, 0);
      await frames(t, .1);
      expect(
        calls.where((c) => c.method == 'HapticFeedback.vibrate').length,
        count,
      );
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('final clock ticks can be muted and pause stops them', (t) async {
    final calls = <MethodCall>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await t.pumpWidget(
      MaterialApp(
        home: BatteryScreen(
          level: const BatteryLevel(
            duration: 11,
            drain: .01,
            eventInterval: 100,
          ),
          onComplete: () async {},
        ),
      ),
    );
    await t.pumpAndSettle();
    await connect(t, 0);
    await t.pump();
    calls.clear();
    await frames(t, 1.2);
    expect(calls.where((c) => c.method == 'SystemSound.play').length, 1);
    await t.tap(find.byTooltip('Pause'));
    await t.pump();
    calls.clear();
    await t.pump(const Duration(seconds: 20));
    expect(calls.where((c) => c.method == 'SystemSound.play'), isEmpty);
    await t.tap(find.byTooltip('Uhrenticken ausschalten'));
    await t.tap(find.text('Weiter'));
    await t.pump();
    calls.clear();
    await frames(t, 1.5);
    expect(calls.where((c) => c.method == 'SystemSound.play'), isEmpty);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'events draw on devices and every screen lights up before completion',
    (t) async {
      var saves = 0;
      await t.pumpWidget(
        MaterialApp(
          home: BatteryScreen(
            level: const BatteryLevel(duration: .5, drain: .01),
            onComplete: () async {
              saves++;
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      await connect(t, 0);
      await t.pump();
      tile(t, 2).device.eventLeft = 1;
      await frames(t, .1);
      DeviceIllustration tabletArt() => t
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<DeviceIllustration>()
          .firstWhere((p) => p.kind == DeviceKind.tablet);
      expect(tabletArt().eventActive, isTrue);
      await frames(t, .5);
      await t.pump(const Duration(milliseconds: 400));
      expect(saves, 0);
      expect(tabletArt().victory, greaterThan(0));
      expect(find.text('Geschafft!'), findsNothing);
      await t.pumpAndSettle();
      expect(saves, 1);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('dragging plugs in and switches, only one battery charges', (
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
    expect(find.byKey(const ValueKey('battery-cable')), findsOneWidget);
    final idleCord =
        t
                .widget<CustomPaint>(find.byKey(const ValueKey('battery-cord')))
                .painter!
            as CablePainter;
    expect(idleCord.connected, isFalse);
    expect(idleCord.dragging, isFalse);
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
    await connect(t, 4);
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
      await connect(t, 0);
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
      await connect(t, 0);
      await frames(t, 2);
      await t.pumpAndSettle();
      expect(find.text('War doch noch bei 2 %!'), findsOneWidget);
      expect(saves, 0);
      expect(find.byKey(const ValueKey('game-result-overlay')), findsOneWidget);
      await t.tap(find.text('Noch einmal versuchen'));
      await t.pumpAndSettle();
      expect(find.text('Los geht’s'), findsNothing);
      expect(find.byKey(const ValueKey('battery-cable')), findsOneWidget);
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
      await connect(t, 0);
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
          await connect(t, 0);
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
