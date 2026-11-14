import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advent_calendar/challenges/games/game_widgets.dart';

/// Solve through visible card faces, without accessing a shuffled game's state.
Future<void> solveVisibleMemory(WidgetTester tester) async {
  Future<void> card(int i) async {
    await tester.tap(find.byKey(ValueKey('memory-card-$i')));
    await tester.pumpAndSettle();
  }

  String face(int i) => tester
      .widget<Semantics>(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label?.startsWith('Karte ${i + 1}, ') ?? false),
        ),
      )
      .properties
      .label!
      .split(', ')[1];
  final positions = <String, List<int>>{};
  // Inspect each pair, then use those memories to solve the shuffled board.
  for (var i = 0; i < 16; i += 2) {
    await card(i);
    final first = face(i);
    await card(i + 1);
    final second = face(i + 1);
    positions.putIfAbsent(first, () => []).add(i);
    positions.putIfAbsent(second, () => []).add(i + 1);
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
  }
  for (final pair in positions.values) {
    if (find.byType(CompletionPanel).evaluate().isNotEmpty) break;
    await card(pair[0]);
    await card(pair[1]);
  }
}
