import 'dart:async';
import 'package:advent_calendar/hardware/pico_service.dart';
import 'package:flutter_test/flutter_test.dart';

const home = PicoResponse(
  200,
  '{"device":"DoorZero","status":"ready","mode":"connected","ip":"192.168.178.68"}',
);
const hotspot = PicoResponse(
  200,
  '{"device":"DoorZero","status":"ready","mode":"hotspot","ip":"192.168.4.1"}',
);
void main() {
  testWidgets(
    'healthy polling, hotspot failover, backed-off retries and automatic recovery',
    (t) async {
      var network = 'home';
      final calls = <String>[];
      final service = PicoService(
        request: (u, _) async {
          calls.add(u.host);
          if (u.host == '192.168.178.68' && network == 'home') return home;
          if (u.host == '192.168.4.1' && network == 'ap') return hotspot;
          throw StateError('offline');
        },
      );
      service.startMonitoring();
      await t.pump();
      expect(service.state, PicoConnectionStatus.connected);
      expect(calls.length, 1);
      await t.pump(const Duration(seconds: 14));
      expect(calls.length, 1);
      network = 'ap';
      await t.pump(const Duration(seconds: 1));
      expect(service.health!.mode, 'hotspot');
      expect(calls.sublist(1), ['192.168.178.68', '192.168.4.1']);
      network = 'offline';
      await t.pump(const Duration(seconds: 15));
      expect(service.state, PicoConnectionStatus.disconnected);
      final failed = calls.length;
      await t.pump(const Duration(seconds: 4));
      expect(calls.length, failed);
      await t.pump(const Duration(seconds: 1));
      expect(calls.length, failed + 2);
      await t.pump(const Duration(seconds: 9));
      expect(calls.length, failed + 2);
      network = 'home';
      await t.pump(const Duration(seconds: 1));
      expect(service.state, PicoConnectionStatus.connected);
      expect(service.baseUri.host, '192.168.178.68');
      final stopped = calls.length;
      service.stopMonitoring();
      await t.pump(const Duration(minutes: 3));
      expect(calls.length, stopped);
      service.dispose();
    },
  );
  testWidgets('retry is immediate and overlapping checks share one request', (
    t,
  ) async {
    var available = false;
    final pending = Completer<PicoResponse>();
    var count = 0;
    final service = PicoService(
      baseUrl: 'http://home',
      request: (_, _) async {
        count++;
        if (available) return pending.future;
        throw StateError('offline');
      },
    );
    service.startMonitoring();
    await t.pump();
    expect(service.state, PicoConnectionStatus.disconnected);
    available = true;
    final a = service.checkConnection();
    final b = service.checkConnection();
    expect(identical(a, b), isTrue);
    await t.pump();
    expect(count, 2);
    pending.complete(home);
    await t.pump();
    expect(await a, isTrue);
    expect(service.state, PicoConnectionStatus.connected);
    service.dispose();
  });
  testWidgets(
    'stopped/disposed checks cannot publish stale health; resume rechecks',
    (t) async {
      final pending = Completer<PicoResponse>();
      var calls = 0;
      final service = PicoService(
        baseUrl: 'http://home',
        request: (_, _) async {
          calls++;
          return calls == 1 ? pending.future : home;
        },
      );
      service.startMonitoring();
      await t.pump();
      service.stopMonitoring();
      service.startMonitoring();
      pending.complete(home);
      await t.pump();
      expect(calls, 2);
      expect(service.state, PicoConnectionStatus.connected);
      service.dispose();
      final before = calls;
      await t.pump(const Duration(minutes: 1));
      expect(calls, before);
      expect(await service.checkConnection(), isFalse);
    },
  );
}
