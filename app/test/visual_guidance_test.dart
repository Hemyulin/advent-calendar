import 'package:advent_calendar/challenges/games/game_widgets.dart';
import 'package:advent_calendar/challenges/memory/memory_screen.dart';
import 'package:advent_calendar/challenges/shoe/shoe_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('rules are optional and the help overlay does not scroll', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(home: MemoryScreen(onComplete: () async {})),
    );
    await tester.pumpAndSettle();
    final screen = tester.widget<GameScaffold>(find.byType(GameScaffold));
    expect(find.text(screen.instructions), findsNothing);
    expect(find.byTooltip('Neu starten'), findsOneWidget);
    await tester.tap(find.byTooltip('Anleitung'));
    await tester.pumpAndSettle();
    expect(find.text(screen.instructions), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    await tester.tap(find.text('Verstanden'));
    await tester.pumpAndSettle();
    expect(find.text(screen.instructions), findsNothing);
  });

  testWidgets('shoe demonstrates swiping and hides the cue after rubbing', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(home: ShoeScreen(onComplete: () async {})),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.swipe_rounded), findsOneWidget);
    expect(find.textContaining('Mit dem Finger'), findsNothing);
    final canvas = find.byKey(const ValueKey('shoe-canvas'));
    await tester.tap(canvas);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.swipe_rounded), findsOneWidget);
    final box = tester.getRect(canvas);
    await tester.dragFrom(
      Offset(box.left + box.width * 0.3, box.top + box.height * 0.4),
      Offset(box.width * 0.4, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.swipe_rounded), findsNothing);
    expect(find.text('Bürsten · 0 %'), findsNothing);
  });

  testWidgets('successful saves do not add technical text to the result', (
    tester,
  ) async {
    phone(tester);
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompletionPanel(
            onComplete: () async {
              saves++;
            },
            onReplay: () {},
            message: 'Blitzblank!',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Geschafft!'), findsOneWidget);
    expect(find.textContaining('gespeichert'), findsNothing);
    expect(saves, 1);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Noch einmal spielen'),
          )
          .onPressed,
      isNotNull,
    );
  });
}
