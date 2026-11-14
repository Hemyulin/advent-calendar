import 'dart:async';
import 'package:advent_calendar/admin/pico_connection_screen.dart';
import 'package:advent_calendar/hardware/pico_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const ready = PicoResponse(
  200,
  '{"device":"DoorZero","status":"ready","mode":"connected","ip":"192.168.178.68"}',
);
void main() {
  testWidgets('connection page only probes health and has no LED controls', (
    t,
  ) async {
    final paths = <String>[];
    final pending = Completer<PicoResponse>();
    final service = PicoService(
      baseUrl: 'http://home',
      request: (uri, _) {
        paths.add(uri.path);
        return pending.future;
      },
    );
    await t.pumpWidget(
      MaterialApp(home: PicoConnectionScreen(service: service)),
    );
    await t.pump();
    expect(find.text('Verbinde…'), findsOneWidget);
    pending.complete(ready);
    await t.pumpAndSettle();
    expect(find.text('Verbunden'), findsOneWidget);
    expect(find.text('LED einschalten'), findsNothing);
    expect(find.text('LED ausschalten'), findsNothing);
    await t.pump(const Duration(seconds: 15));
    expect(paths, ['/health', '/health']);
    await t.pumpWidget(const SizedBox());
    service.dispose();
  });
  testWidgets('manual retry works and background/route exit stop polling', (
    t,
  ) async {
    var available = false;
    var calls = 0;
    final service = PicoService(
      baseUrl: 'http://home',
      request: (_, _) async {
        calls++;
        return available ? ready : const PicoResponse(503);
      },
    );
    await t.pumpWidget(
      MaterialApp(home: PicoConnectionScreen(service: service)),
    );
    await t.pumpAndSettle();
    expect(find.text('Nicht verbunden'), findsOneWidget);
    expect(calls, 1);
    available = true;
    await t.tap(find.text('Erneut verbinden'));
    await t.pumpAndSettle();
    expect(find.text('Verbunden'), findsOneWidget);
    expect(calls, 2);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(minutes: 1));
    expect(calls, 2);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pumpAndSettle();
    expect(calls, 3);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(minutes: 1));
    expect(calls, 3);
    service.dispose();
  });
  testWidgets('leaving during a health request ignores stale completion', (
    t,
  ) async {
    final pending = Completer<PicoResponse>();
    final service = PicoService(
      baseUrl: 'http://home',
      request: (_, _) => pending.future,
    );
    await t.pumpWidget(
      MaterialApp(home: PicoConnectionScreen(service: service)),
    );
    await t.pump();
    await t.pumpWidget(const SizedBox());
    pending.complete(ready);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(service.state, PicoConnectionStatus.disconnected);
    service.dispose();
  });
  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('disconnected and connected status fit at $scenario', (
      t,
    ) async {
      t.view.physicalSize = scenario.$1;
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = scenario.$2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      var online = false;
      final service = PicoService(
        baseUrl: 'http://home',
        request: (_, _) async {
          if (!online) throw TimeoutException('test');
          return ready;
        },
      );
      await t.pumpWidget(
        MaterialApp(home: PicoConnectionScreen(service: service)),
      );
      await t.pumpAndSettle();
      expect(find.text('Nicht verbunden'), findsOneWidget);
      expect(t.takeException(), isNull);
      online = true;
      await t.tap(find.text('Erneut verbinden'));
      await t.pumpAndSettle();
      expect(find.text('Verbunden'), findsOneWidget);
      expect(t.takeException(), isNull);
      expect(find.byType(Scrollable), findsNothing);
      await t.pumpWidget(const SizedBox());
      service.dispose();
    });
  }
}
