import 'dart:async';
import 'package:advent_calendar/admin/pico_led_test_screen.dart';
import 'package:advent_calendar/hardware/pico_led_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'no automatic calls; buttons serialize commands and display success/error/retry',
    (t) async {
      final calls = <Uri>[];
      var result = Completer<int>();
      final service = PicoLedService(
        request: (uri, _) {
          calls.add(uri);
          return result.future;
        },
      );
      await t.pumpWidget(
        MaterialApp(home: PicoLedTestScreen(service: service)),
      );
      await t.pumpAndSettle();
      expect(calls, isEmpty);
      expect(find.text('Noch nicht geprüft'), findsOneWidget);
      await t.tap(find.text('LED einschalten'));
      await t.pump();
      expect(calls.single.path, '/led/on');
      expect(
        t
            .widget<FilledButton>(
              find.byWidgetPredicate((w) => w is FilledButton),
            )
            .onPressed,
        isNull,
      );
      expect(
        t
            .widget<OutlinedButton>(
              find.byWidgetPredicate((w) => w is OutlinedButton),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Verbindung wird geprüft …'), findsOneWidget);
      result.complete(200);
      await t.pumpAndSettle();
      expect(find.text('Verbunden'), findsOneWidget);
      expect(find.text('LED eingeschaltet.'), findsOneWidget);
      result = Completer<int>();
      await t.tap(find.text('LED ausschalten'));
      await t.pump();
      result.complete(503);
      await t.pumpAndSettle();
      expect(calls.last.path, '/led/off');
      expect(find.text('Verbindung fehlgeschlagen'), findsOneWidget);
      expect(
        find.text('Der Pico meldet einen Fehler (HTTP 503).'),
        findsOneWidget,
      );
      result = Completer<int>();
      await t.tap(find.text('LED ausschalten'));
      await t.pump();
      result.complete(204);
      await t.pumpAndSettle();
      expect(find.text('LED ausgeschaltet.'), findsOneWidget);
      expect(find.text('Verbunden'), findsOneWidget);
    },
  );
  testWidgets('leaving an in-flight test does not update a disposed screen', (
    t,
  ) async {
    final result = Completer<int>();
    await t.pumpWidget(
      MaterialApp(
        home: PicoLedTestScreen(
          service: PicoLedService(request: (_, _) => result.future),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('LED einschalten'));
    await t.pump();
    await t.pumpWidget(const SizedBox());
    result.complete(200);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('connection and timeout feedback fit at $scenario', (t) async {
      t.view.physicalSize = scenario.$1;
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = scenario.$2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(
        MaterialApp(
          home: PicoLedTestScreen(
            service: PicoLedService(
              request: (_, _) async => throw TimeoutException('test'),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.tap(find.text('LED einschalten'));
      await t.pumpAndSettle();
      expect(find.textContaining('Zeitüberschreitung'), findsOneWidget);
      expect(t.takeException(), isNull);
      expect(find.byType(Scrollable), findsNothing);
    });
  }
}
