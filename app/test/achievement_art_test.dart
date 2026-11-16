import 'package:advent_calendar/achievements/achievement_art.dart';
import 'package:advent_calendar/achievements/achievement_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'every achievement has artwork that renders in locked and earned states',
    (tester) async {
      for (final achievement in [...achievementCatalog, finalReward]) {
        for (final earned in [false, true]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: AchievementIllustration(
                    achievementId: achievement.id,
                    earned: earned,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${achievement.id}, earned: $earned',
          );
          final painter =
              tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: find.byType(AchievementIllustration),
                          matching: find.byType(CustomPaint),
                        ),
                      )
                      .painter
                  as AchievementPainter;
          expect(painter.scene.name, achievement.id);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
