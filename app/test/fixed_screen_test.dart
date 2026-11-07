import 'package:advent_calendar/app.dart';
import 'package:advent_calendar/challenges/games/game_preview_screen.dart';
import 'package:advent_calendar/challenges/games/game_widgets.dart';
import 'package:advent_calendar/challenges/maze/maze_game.dart';
import 'package:advent_calendar/challenges/maze/maze_screen.dart';
import 'package:advent_calendar/challenges/maze/tilt_source.dart';
import 'package:advent_calendar/challenges/memory/memory_screen.dart';
import 'package:advent_calendar/challenges/shoe/shoe_screen.dart';
import 'package:advent_calendar/challenges/tutorial/first_day_screen.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'package:advent_calendar/presentation/challenge_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoTilt implements TiltSource {
  @override
  Stream<Vec2> get events => Stream.error(UnsupportedError('test'));
}

void main() {
  void size(WidgetTester tester, Size viewport, double scale) {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  void noVerticalScroll(WidgetTester tester) {
    expect(find.byType(SingleChildScrollView), findsNothing);
    for (final element in find.byType(Scrollable).evaluate()) {
      final state = (element as StatefulElement).state as ScrollableState;
      if (axisDirectionToAxis(state.axisDirection) == Axis.vertical) {
        expect(state.position.maxScrollExtent, 0);
      }
    }
    expect(tester.takeException(), isNull);
  }

  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('all pages fit without vertical scrolling at $scenario', (
      tester,
    ) async {
      size(tester, scenario.$1, scenario.$2);
      await tester.pumpWidget(AdventCalendarApp(now: DateTime(2026, 11, 6)));
      await tester.pumpAndSettle();
      noVerticalScroll(tester);
      final pages = <Widget>[
        const GamePreviewScreen(),
        MemoryScreen(onComplete: () async {}),
        MazeScreen(tiltSource: _NoTilt(), onComplete: () async {}),
        ShoeScreen(onComplete: () async {}),
        FirstDayScreen(onComplete: () async {}),
        ChallengeScreen(day: calendarDays(DateTime(2026, 12, 8), {})[7]),
      ];
      for (final page in pages) {
        await tester.pumpWidget(MaterialApp(home: page));
        await tester.pumpAndSettle();
        noVerticalScroll(tester);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'result floats above the game and blocks its controls at $scenario',
      (tester) async {
        size(tester, scenario.$1, scenario.$2);
        var backgroundTaps = 0;
        var completions = 0;
        var showResult = true;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, update) => GameResultLayer(
                result: showResult
                    ? CompletionPanel(
                        onComplete: () async {
                          completions++;
                        },
                        onReplay: () => update(() => showResult = false),
                        message:
                            'Dein Stiefel glänzt. Der Nikolaus kann kommen!',
                      )
                    : null,
                child: Scaffold(
                  body: Center(
                    child: TextButton(
                      key: const ValueKey('background-control'),
                      onPressed: () => backgroundTaps++,
                      child: const Text('Im Hintergrund'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('game-result-overlay')),
          findsOneWidget,
        );
        expect(completions, 1);
        final card = tester.getRect(find.byType(CompletionPanel));
        expect(card.top, greaterThanOrEqualTo(0));
        expect(card.bottom, lessThanOrEqualTo(scenario.$1.height));
        expect(card.left, greaterThanOrEqualTo(0));
        expect(card.right, lessThanOrEqualTo(scenario.$1.width));
        await tester.tapAt(
          tester.getCenter(find.byKey(const ValueKey('background-control'))),
        );
        await tester.pumpAndSettle();
        expect(backgroundTaps, 0);
        await tester.tap(find.text('Noch einmal spielen'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('game-result-overlay')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('background-control')));
        expect(backgroundTaps, 1);
        noVerticalScroll(tester);
      },
    );
  }
}
