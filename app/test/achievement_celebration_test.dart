import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/achievements/achievement_scope.dart';
import 'package:advent_calendar/achievements/achievement_store.dart';
import 'package:advent_calendar/challenges/games/game_widgets.dart';
import 'package:advent_calendar/challenges/games/gift_reward_scope.dart';
import 'package:advent_calendar/challenges/gift_reward.dart';

Achievement award(String id) => achievements.firstWhere((a) => a.id == id);
final toast = find.byKey(const ValueKey('achievement-celebration-toast'));
final confetti = find.byKey(const ValueKey('achievement-confetti'));

Widget won({
  required Future<List<Achievement>> Function() record,
  Future<GiftOpenResult> Function()? open,
}) => MaterialApp(
  home: AchievementScope(
    record: (_) => record(),
    child: GiftRewardScope(
      openGift: open ?? () async => GiftOpenResult.preview,
      child: GameResultLayer(
        result: CompletionPanel(
          onComplete: () async {},
          onReplay: () {},
          message: 'Alle Paare gefunden.',
        ),
        child: const Scaffold(),
      ),
    ),
  ),
);
Future<void> show(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> expire(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'new achievement celebrates automatically without intercepting the present tap',
    (tester) async {
      var opens = 0, records = 0;
      await show(
        tester,
        won(
          record: () async {
            records++;
            return [award('memory')];
          },
          open: () async {
            opens++;
            return GiftOpenResult.boxOpened;
          },
        ),
      );
      expect(toast, findsOneWidget);
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(of: toast, matching: find.byType(Opacity)).first,
            )
            .opacity,
        1,
      );
      expect(confetti, findsOneWidget);
      expect(find.text('Erfolg freigeschaltet!'), findsOneWidget);
      expect(find.text(award('memory').title), findsOneWidget);
      expect(opens, 0);
      await tester.tap(find.byKey(const ValueKey('completion-gift')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(opens, 1);
      expect(records, 1);
      expect(find.text('Geschenk geöffnet'), findsOneWidget);
      await expire(tester);
      expect(toast, findsNothing);
      expect(confetti, findsNothing);
      expect(find.text('Die Box ist offen!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'multiple awards rotate automatically; confetti only bursts once',
    (tester) async {
      await show(
        tester,
        won(record: () async => [award('memory'), award('allGames')]),
      );
      expect(find.text(award('memory').title), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(award('memory').title), findsNothing);
      expect(find.text(award('allGames').title), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);
      expect(confetti, findsNothing);
      await expire(tester);
      expect(toast, findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'no new awards means no toast, and rebuilding the result never repeats an award',
    (tester) async {
      var records = 0;
      await show(
        tester,
        won(
          record: () async {
            records++;
            return [];
          },
        ),
      );
      expect(toast, findsNothing);
      expect(confetti, findsNothing);
      await tester.tap(find.text('Zum Öffnen tippen'));
      await tester.pumpAndSettle();
      expect(toast, findsNothing);
      expect(records, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'reduced motion keeps the announcement but skips flying confetti and transitions',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await show(tester, won(record: () async => [award('shoe')]));
      expect(toast, findsOneWidget);
      expect(confetti, findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pump(const Duration(seconds: 3));
      expect(toast, findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'leaving during the celebration removes its overlay, ticker and timer',
    (tester) async {
      await show(
        tester,
        won(record: () async => [award('shoe'), award('allGames')]),
      );
      expect(toast, findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
      expect(toast, findsNothing);
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'failed achievement save never celebrates before the retry succeeds',
    (tester) async {
      var attempts = 0;
      await show(
        tester,
        won(
          record: () async {
            if (++attempts == 1) throw StateError('storage');
            return [award('memory')];
          },
        ),
      );
      expect(toast, findsNothing);
      expect(find.text('Speichern fehlgeschlagen.'), findsOneWidget);
      await tester.tap(find.text('Erneut speichern'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(toast, findsOneWidget);
      expect(attempts, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('celebration fits without blocking the gift at $scenario', (
      tester,
    ) async {
      tester.view.physicalSize = scenario.$1;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var opens = 0;
      await show(
        tester,
        won(
          record: () async => [award('memory')],
          open: () async {
            opens++;
            return GiftOpenResult.boxOpened;
          },
        ),
      );
      expect(tester.takeException(), isNull);
      final bounds = tester.getRect(toast);
      expect(bounds.top, greaterThanOrEqualTo(0));
      expect(bounds.bottom, lessThanOrEqualTo(scenario.$1.height));
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(scenario.$1.width));
      if (scenario.$1.width > scenario.$1.height) {
        expect(
          bounds.overlaps(
            tester.getRect(find.byKey(const ValueKey('completion-gift'))),
          ),
          isFalse,
        );
      }
      await tester.tap(find.text('Zum Öffnen tippen'));
      await tester.pump(const Duration(seconds: 1));
      expect(opens, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
