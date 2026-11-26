import 'dart:async';
import 'package:advent_calendar/challenges/games/game_widgets.dart';
import 'package:advent_calendar/challenges/games/gift_reward_scope.dart';
import 'package:advent_calendar/challenges/gift_reward.dart';
import 'package:advent_calendar/achievements/achievement_scope.dart';
import 'package:advent_calendar/achievements/run_facts.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin_scope.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'reopening an already completed game congratulates without a gift or box action',
    (tester) async {
      var saves = 0, opens = 0, records = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: GiftRewardScope(
            openGift: () async {
              opens++;
              return GiftOpenResult.boxOpened;
            },
            child: AchievementScope(
              record: (_) async {
                records++;
                return [];
              },
              child: _ReplayGame(
                alreadyCompleted: true,
                save: () async {
                  saves++;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('test-win')));
      await tester.pumpAndSettle();
      expect(find.text('Großartig!'), findsOneWidget);
      expect(find.text('Alle Paare gefunden.'), findsOneWidget);
      expect(find.byKey(const ValueKey('completion-gift')), findsNothing);
      expect(find.text('Zum Öffnen tippen'), findsNothing);
      expect(find.byKey(const ValueKey('completion-replay')), findsOneWidget);
      expect(find.byKey(const ValueKey('completion-calendar')), findsOneWidget);
      expect((saves, records, opens), (1, 1, 0));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'first win keeps its gift; same-visit and switched-skin replays only congratulate',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        SkinnableGame.unlockNoticeKey: true,
      });
      var records = 0, opens = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: GiftRewardScope(
            openGift: () async {
              opens++;
              return GiftOpenResult.boxOpened;
            },
            child: AchievementScope(
              record: (_) async {
                records++;
                return [];
              },
              child: SkinnableGame(
                initialSkin: GameSkin.christmas,
                builder: (_) => _ReplayGame(save: () async {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('test-win')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('completion-gift')), findsOneWidget);
      expect(find.text('Großartig!'), findsNothing);
      for (final switchSkin in [false, true]) {
        await tester.tap(find.byKey(const ValueKey('completion-replay')));
        await tester.pumpAndSettle();
        if (switchSkin) {
          await tester.tap(find.byKey(const ValueKey('hanukkah-replay')));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const ValueKey('test-win')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('completion-congratulations')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('completion-gift')), findsNothing);
      }
      expect(records, 3);
      expect(opens, 0);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  Widget panel({
    required Future<void> Function() save,
    Future<GiftOpenResult> Function()? open,
    Future<GiftOpenResult> Function()? reopen,
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
          : GiftRewardScope(openGift: open, reopenBox: reopen, child: child),
    );
  }

  testWidgets(
    'explicit retry on the same result does not replay or save twice',
    (tester) async {
      var saves = 0, opens = 0, retries = 0;
      final pending = Completer<GiftOpenResult>();
      await tester.pumpWidget(
        panel(
          save: () async {
            saves++;
          },
          open: () async {
            opens++;
            return GiftOpenResult.boxOpened;
          },
          reopen: () {
            retries++;
            return pending.future;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Box erneut öffnen'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('completion-gift')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Box erneut öffnen'));
      await tester.pump();
      final button = tester.widget<TextButton>(
        find.byKey(const ValueKey('completion-reopen-box')),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Jetzt die Box öffnen'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('completion-reopen-box')));
      await tester.pump();
      expect(retries, 1);
      pending.complete(GiftOpenResult.boxOpened);
      await tester.pumpAndSettle();
      expect(find.text('Box erneut öffnen'), findsOneWidget);
      expect(saves, 1);
      expect(opens, 1);
      expect(find.text('Die Box wurde entriegelt.'), findsOneWidget);
    },
  );

  testWidgets('uncertain opening permits a deliberate retry after an error', (
    tester,
  ) async {
    await tester.pumpWidget(
      panel(
        save: () async {},
        open: () async => GiftOpenResult.unconfirmed,
        reopen: () async => GiftOpenResult.boxOpened,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('completion-gift')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Box erneut öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Die Box wurde entriegelt.'), findsOneWidget);
  });

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
      expect(find.text('Die Box wurde entriegelt.'), findsOneWidget);
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
    expect(find.text('Die Box wurde entriegelt.'), findsNothing);
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

class _ReplayGame extends StatefulWidget {
  const _ReplayGame({required this.save, this.alreadyCompleted = false});
  final Future<void> Function() save;
  final bool alreadyCompleted;
  @override
  State<_ReplayGame> createState() => _ReplayGameState();
}

class _ReplayGameState extends State<_ReplayGame> {
  bool _won = false;
  @override
  Widget build(BuildContext context) => GameScaffold(
    title: 'Paare finden',
    instructions: '',
    alreadyCompleted: widget.alreadyCompleted,
    children: [
      TextButton(
        key: const ValueKey('test-win'),
        onPressed: () => setState(() => _won = true),
        child: const Text('Gewinnen'),
      ),
      if (_won)
        CompletionPanel(
          onComplete: widget.save,
          onReplay: () => setState(() => _won = false),
          message: 'Alle Paare gefunden.',
        ),
    ],
  );
}
