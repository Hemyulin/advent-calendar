import 'package:advent_calendar/welcome/welcome_gate.dart';
import 'package:advent_calendar/presentation/calendar_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget welcomeApp() => MaterialApp(
  theme: ThemeData(scaffoldBackgroundColor: CalendarStyle.ivory),
  home: const WelcomeGate(child: Scaffold(body: Text('Kalender'))),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'first launch explains regular and secret awards, then persists dismissal',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(welcomeApp());
      await tester.pumpAndSettle();
      expect(
        find.text('Willkommen in deinem Adventskalender, Schlizi!'),
        findsOneWidget,
      );
      expect(
        find.textContaining('alle regulären Auszeichnungen'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Für das Zusatzgeschenk brauchst du sie nicht.'),
        findsOneWidget,
      );
      expect(find.text('Dein Lieblingsmann, ps ich dich auch'), findsOneWidget);
      expect(find.text('Kalender'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('welcome-continue')));
      await tester.pumpAndSettle();
      expect(find.text('Kalender'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool(WelcomeGate.seenKey),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(welcomeApp());
      await tester.pumpAndSettle();
      expect(find.text('Kalender'), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    },
  );

  testWidgets('existing dismissal skips welcome without changing progress', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      WelcomeGate.seenKey: true,
      'progress.completed.v1': ['day-1'],
    });
    await tester.pumpWidget(welcomeApp());
    await tester.pumpAndSettle();
    expect(find.text('Kalender'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getStringList(
        'progress.completed.v1',
      ),
      ['day-1'],
    );
  });

  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('welcome fits $scenario with a full-size continue target', (
      tester,
    ) async {
      tester.view.physicalSize = scenario.$1;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(welcomeApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final scrollable in tester.widgetList<Scrollable>(
        find.byType(Scrollable),
      )) {
        expect(
          scrollable.axisDirection,
          isNot(anyOf(AxisDirection.down, AxisDirection.up)),
        );
      }
      expect(
        tester.getSize(find.byKey(const ValueKey('welcome-continue'))).height,
        greaterThanOrEqualTo(54),
      );
      if (find.text('Weiter').evaluate().isNotEmpty) {
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle();
        expect(
          (await SharedPreferences.getInstance()).getBool(WelcomeGate.seenKey),
          isNull,
        );
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Für das Zusatzgeschenk brauchst du sie nicht.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Türchen entdecken'));
        await tester.pumpAndSettle();
        expect(find.text('Kalender'), findsOneWidget);
      }
    });
  }
}
