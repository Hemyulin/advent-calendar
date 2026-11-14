import 'dart:async';
import 'package:advent_calendar/admin/admin_authenticator.dart';
import 'package:advent_calendar/admin/admin_pin_dialog.dart';
import 'package:advent_calendar/admin/admin_screen.dart';
import 'package:advent_calendar/admin/pico_connection_screen.dart';
import 'package:advent_calendar/challenges/games/game_preview_screen.dart';
import 'package:advent_calendar/challenges/memory/memory_screen.dart';
import 'package:advent_calendar/presentation/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app({AdminAuthenticator auth = const DevelopmentAdminAuthenticator()}) =>
    MaterialApp(
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: CalendarScreen(
        now: DateTime(2026, 11, 12),
        adminAuthenticator: auth,
      ),
    );
Future<void> taps(WidgetTester t, int count) async {
  for (var i = 0; i < count; i++) {
    await t.tap(find.byKey(const ValueKey('admin-title-entry')));
    await t.pump(const Duration(milliseconds: 60));
  }
}

Future<void> enterAdmin(WidgetTester t) async {
  await taps(t, 5);
  await t.pumpAndSettle();
  await t.enterText(find.byKey(const ValueKey('admin-pin')), '0542');
  await t.pump();
  await t.tap(find.text('Öffnen'));
  await t.pumpAndSettle();
}

class DeferredAuth implements AdminAuthenticator {
  final result = Completer<bool>();
  int calls = 0;
  @override
  Future<bool> authenticate(String pin) {
    calls++;
    return result.future;
  }
}

void main() {
  test('development PIN preserves leading zero and matches exactly', () async {
    const auth = DevelopmentAdminAuthenticator();
    expect(await auth.authenticate('0542'), isTrue);
    for (final pin in ['542', '05420', ' 0542', '0000', '']) {
      expect(await auth.authenticate(pin), isFalse);
    }
  });
  testWidgets(
    'five taps open an obscured numeric PIN dialog; incorrect PIN can be retried',
    (t) async {
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      await taps(t, 4);
      expect(find.byType(AdminPinDialog), findsNothing);
      await taps(t, 1);
      await t.pumpAndSettle();
      final field = t.widget<TextField>(
        find.byKey(const ValueKey('admin-pin')),
      );
      expect(field.obscureText, isTrue);
      expect(field.keyboardType, TextInputType.number);
      await t.enterText(find.byKey(const ValueKey('admin-pin')), 'abcd123456');
      await t.pump();
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('admin-pin')))
            .controller!
            .text,
        '1234',
      );
      await t.tap(find.text('Öffnen'));
      await t.pumpAndSettle();
      expect(find.text('Falscher PIN'), findsOneWidget);
      expect(find.byType(AdminScreen), findsNothing);
      await t.enterText(find.byKey(const ValueKey('admin-pin')), '0542');
      await t.pump();
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(find.text('Advent-Verwaltung'), findsOneWidget);
      expect(find.byType(AdminPinDialog), findsNothing);
    },
  );
  testWidgets(
    'tap window expires from the first tap, rather than extending with each tap',
    (t) async {
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      await taps(t, 1);
      await t.pump(const Duration(seconds: 2));
      await taps(t, 2);
      await t.pump(const Duration(milliseconds: 1100));
      await taps(t, 2);
      expect(find.byType(AdminPinDialog), findsNothing);
      await taps(t, 3);
      await t.pumpAndSettle();
      expect(find.byType(AdminPinDialog), findsOneWidget);
    },
  );
  testWidgets(
    'cancelling resets entry and backgrounding discards partial taps',
    (t) async {
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      await taps(t, 5);
      await t.pumpAndSettle();
      await t.tap(find.text('Abbrechen'));
      await t.pumpAndSettle();
      await taps(t, 4);
      expect(find.byType(AdminPinDialog), findsNothing);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await taps(t, 1);
      expect(find.byType(AdminPinDialog), findsNothing);
      await taps(t, 4);
      await t.pumpAndSettle();
      expect(find.byType(AdminPinDialog), findsOneWidget);
    },
  );
  testWidgets('no duplicate authentication or navigation after dismissal', (
    t,
  ) async {
    final auth = DeferredAuth();
    await t.pumpWidget(app(auth: auth));
    await t.pumpAndSettle();
    await taps(t, 5);
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('admin-pin')), '0542');
    await t.pump();
    await t.tap(find.text('Öffnen'));
    await t.pump();
    await t.tap(find.byType(FilledButton));
    await t.pump();
    expect(auth.calls, 1);
    await t.tap(find.text('Abbrechen'));
    await t.pumpAndSettle();
    auth.result.complete(true);
    await t.pumpAndSettle();
    expect(find.byType(AdminScreen), findsNothing);
    expect(find.byType(CalendarScreen), findsOneWidget);
  });
  testWidgets(
    'admin opens the calendar editor, reuses preview and keeps diagnostics planned',
    (t) async {
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      expect(find.byTooltip('Spiele ausprobieren'), findsNothing);
      await enterAdmin(t);
      for (final title in [
        'Kalender bearbeiten',
        'Spiele testen',
        'Box-Steuerung',
        'Diagnose & Fortschritt',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      await t.tap(find.text('Spiele testen'));
      await t.pumpAndSettle();
      expect(find.byType(GamePreviewScreen), findsOneWidget);
      await t.tap(find.text('Paare finden'));
      await t.pumpAndSettle();
      expect(find.byType(MemoryScreen), findsOneWidget);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await t.tap(find.text('Kalender bearbeiten'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit-day-24')), findsOneWidget);
      expect(find.text('Speichern'), findsOneWidget);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      for (final title in ['Diagnose & Fortschritt']) {
        await t.tap(find.text(title));
        await t.pumpAndSettle();
        expect(
          find.text('Dieser Bereich ist noch in Vorbereitung.'),
          findsOneWidget,
        );
        expect(find.byType(FilledButton), findsNothing);
        await t.tap(find.byType(BackButton));
        await t.pumpAndSettle();
      }
      await t.tap(find.text('Box-Steuerung'));
      await t.pumpAndSettle();
      expect(find.byType(PicoConnectionScreen), findsOneWidget);
      expect(find.text('Pico W · Verbindung'), findsOneWidget);
      expect(find.text('Nicht verbunden'), findsOneWidget);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(find.byType(CalendarScreen), findsOneWidget);
      await taps(t, 5);
      await t.pumpAndSettle();
      expect(find.byType(AdminPinDialog), findsOneWidget);
    },
  );
  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('admin entry and sections fit at $scenario', (t) async {
      t.view.physicalSize = scenario.$1;
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = scenario.$2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      await enterAdmin(t);
      expect(t.takeException(), isNull);
      expect(find.byType(AdminScreen), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
    });
  }
  testWidgets('PIN dialog fits above a numeric keyboard on a small screen', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    t.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetViewInsets);
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await taps(t, 5);
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('admin-pin')), '1234');
    await t.pump();
    await t.tap(find.text('Öffnen'));
    await t.pumpAndSettle();
    expect(find.text('Falscher PIN'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('leaving the homepage cleans up its tap timer', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await taps(t, 2);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 4));
    expect(t.takeException(), isNull);
  });
}
