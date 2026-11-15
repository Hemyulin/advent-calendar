import 'dart:async';
import 'package:advent_calendar/challenges/games/game_widgets.dart';
import 'package:advent_calendar/challenges/games/gift_reward_scope.dart';
import 'package:advent_calendar/challenges/gift_reward.dart';
import 'package:advent_calendar/achievements/achievement_scope.dart';
import 'package:advent_calendar/achievements/run_facts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget panel({
    required Future<void> Function() save,
    Future<GiftOpenResult> Function()? open,
  }) {
    final child = GameResultLayer(
      result: CompletionPanel(
        onComplete: save,
        onReplay: () {},
        message: 'Alle Paare gefunden.',
      ),
      child: const Scaffold(body: Text('Spiel')),
    );
    return MaterialApp(
      home: open == null
          ? child
          : GiftRewardScope(openGift: open, child: child),
    );
  }

  testWidgets(
    'leaving the result during a save still records the won attempt',
    (tester) async {
      final saving = Completer<void>();
      var records = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementScope(
            record: (facts) async {
              expect(facts.feats, contains(RunFeat.perfectCookie));
              records++;
              return [];
            },
            child: Scaffold(
              body: CompletionPanel(
                facts: const RunFacts(feats: {RunFeat.perfectCookie}),
                onComplete: () => saving.future,
                onReplay: () {},
                message: 'Fertig!',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      saving.complete();
      await tester.pumpAndSettle();
      expect(records, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'gift and opening instruction are the primary action; navigation stays secondary',
    (tester) async {
      var opens = 0;
      await tester.pumpWidget(
        panel(
          save: () async {},
          open: () async {
            opens++;
            return GiftOpenResult.boxOpened;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Zum Öffnen tippen'), findsOneWidget);
      expect(find.text('Alle Paare gefunden.'), findsNothing);
      expect(find.text('Geschafft!'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      final gift = tester.getRect(
        find.byKey(const ValueKey('completion-gift')),
      );
      final replay = tester.getRect(
        find.byKey(const ValueKey('completion-replay')),
      );
      final calendar = tester.getRect(
        find.byKey(const ValueKey('completion-calendar')),
      );
      expect(gift.height, greaterThan(replay.height * 3));
      expect(replay.center.dy, lessThan(gift.center.dy));
      expect(calendar.center.dy, greaterThan(gift.center.dy));
      await tester.tap(find.text('Zum Öffnen tippen'));
      await tester.pumpAndSettle();
      expect(opens, 1);
      expect(find.text('Alle Paare gefunden.'), findsOneWidget);
      expect(find.text('Geschenk geöffnet'), findsOneWidget);
    },
  );

  testWidgets(
    'winning saves immediately but box opens only on a gift tap, once',
    (tester) async {
      var saves = 0, opens = 0;
      await tester.pumpWidget(
        panel(
          save: () async {
            saves++;
          },
          open: () async {
            opens++;
            return GiftOpenResult.boxOpened;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(opens, 0);
      await tester.tap(find.byKey(const ValueKey('completion-gift')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('completion-gift')));
      expect(opens, 1);
      await tester.pumpAndSettle();
      expect(find.text('Die Box ist offen!'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('completion-gift')));
      await tester.pumpAndSettle();
      expect(opens, 1);
      expect(saves, 1);
    },
  );

  testWidgets(
    'failed save blocks gift; retry saves without repeating the game',
    (tester) async {
      var attempts = 0, opens = 0;
      await tester.pumpWidget(
        panel(
          save: () async {
            if (++attempts == 1) throw StateError('storage');
          },
          open: () async {
            opens++;
            return GiftOpenResult.boxOpened;
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('completion-gift')));
      expect(opens, 0);
      await tester.tap(find.text('Erneut speichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('completion-gift')));
      await tester.pumpAndSettle();
      expect(opens, 1);
      expect(attempts, 2);
    },
  );

  testWidgets(
    'pending save cannot open gift and previews never need hardware',
    (tester) async {
      final save = Completer<void>();
      await tester.pumpWidget(panel(save: () => save.future));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('completion-gift')));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Vorschau · ohne Box'), findsNothing);
      save.complete();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('completion-gift')));
      await tester.pumpAndSettle();
      expect(find.text('Vorschau · ohne Box'), findsOneWidget);
    },
  );

  testWidgets('box failures do not undo success or claim the box opened', (
    tester,
  ) async {
    await tester.pumpWidget(
      panel(save: () async {}, open: () async => throw StateError('offline')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('completion-gift')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('completion-gift')), findsOneWidget);
    expect(find.text('Die Box ist offen!'), findsNothing);
    expect(
      find.text('Die Box hat das Öffnen nicht bestätigt.'),
      findsOneWidget,
    );
  });

  testWidgets('reduced motion opens gift without an animated wait', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(panel(save: () async {}));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('completion-gift')));
    await tester.pump();
    expect(find.text('Vorschau · ohne Box'), findsOneWidget);
  });
}
