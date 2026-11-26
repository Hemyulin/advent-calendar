import 'package:advent_calendar/challenges/games/game_widgets.dart';
import 'package:advent_calendar/presentation/app_haptics.dart';
import 'package:advent_calendar/presentation/calendar_screen.dart';
import 'package:advent_calendar/presentation/illustrated_door.dart';
import 'package:advent_calendar/presentation/shake_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final calls = <String>[];
  setUp(() {
    calls.clear();
    AppHaptics.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments as String);
          }
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  testWidgets(
    'locked door rattles, gives one short rejection cue and never shows a toast',
    (t) async {
      await t.pumpWidget(
        MaterialApp(home: CalendarScreen(now: DateTime(2026, 11, 26))),
      );
      await t.pumpAndSettle();
      final door = find.byType(IllustratedDoor);
      final start = t.getTopLeft(door);
      await t.tap(door);
      await t.pump();
      await t.pump(const Duration(milliseconds: 40));
      expect((t.getTopLeft(door).dx - start.dx).abs(), greaterThan(1));
      expect(find.byType(SnackBar), findsNothing);
      expect(calls, ['HapticFeedbackType.heavyImpact']);
      expect(t.widget<IllustratedDoor>(door).day.isAvailable, isFalse);
      await t.pumpAndSettle();
      expect(t.getTopLeft(door).dx, closeTo(start.dx, .01));
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('reduced motion suppresses the rattle translation', (t) async {
    final trigger = ValueNotifier(0);
    addTearDown(trigger.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Center(
            child: ValueListenableBuilder<int>(
              valueListenable: trigger,
              builder: (_, value, _) => ShakeFeedback(
                trigger: value,
                child: const SizedBox(
                  key: ValueKey('shake-child'),
                  width: 60,
                  height: 60,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final start = t.getTopLeft(find.byKey(const ValueKey('shake-child')));
    trigger.value++;
    await t.pump();
    await t.pump(const Duration(milliseconds: 40));
    expect(t.getTopLeft(find.byKey(const ValueKey('shake-child'))), start);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('haptics are rate-limited and honor a disabled per-game scope', (
    t,
  ) async {
    Widget screen(bool enabled) => MaterialApp(
      home: HapticsScope(
        enabled: enabled,
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              AppHaptics.locked(context);
              AppHaptics.locked(context);
            },
            child: const Text('Test'),
          ),
        ),
      ),
    );
    await t.pumpWidget(screen(false));
    await t.tap(find.text('Test'));
    await t.pump();
    expect(calls, isEmpty);
    await t.pumpWidget(screen(true));
    await t.tap(find.text('Test'));
    await t.pump();
    expect(calls, ['HapticFeedbackType.heavyImpact']);
  });

  testWidgets('result feedback runs once per result, not on every rebuild', (
    t,
  ) async {
    Widget screen(bool won) => MaterialApp(
      home: Scaffold(
        body: GameResultLayer(
          result: won
              ? CompletionPanel(
                  onComplete: () async {},
                  onReplay: () {},
                  message: 'Fertig!',
                )
              : DefeatPanel(message: 'Noch einmal!', onRetry: () {}),
          child: const Text('Spiel'),
        ),
      ),
    );
    await t.pumpWidget(screen(true));
    await t.pumpAndSettle();
    expect(calls, ['HapticFeedbackType.mediumImpact']);
    await t.pumpWidget(screen(true));
    await t.pumpAndSettle();
    expect(calls.length, 1);
    await t.pumpWidget(screen(false));
    await t.pumpAndSettle();
    expect(calls.length, 2);
    await t.pumpWidget(screen(false));
    await t.pumpAndSettle();
    expect(calls.length, 2);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('unsupported haptic platforms cannot interrupt the action', (
    t,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            throw PlatformException(code: 'unavailable');
          }
          return null;
        });
    var actions = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              AppHaptics.tap(context);
              actions++;
            },
            child: const Text('Test'),
          ),
        ),
      ),
    );
    await t.tap(find.text('Test'));
    await t.pumpAndSettle();
    expect(actions, 1);
    expect(t.takeException(), isNull);
  });
}
