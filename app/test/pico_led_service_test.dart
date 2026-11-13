import 'dart:io';
import 'package:advent_calendar/hardware/pico_led_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'default and configurable URLs use only the exact LED endpoints',
    () async {
      final calls = <Uri>[];
      final service = PicoLedService(
        request: (uri, timeout) async {
          calls.add(uri);
          expect(timeout, const Duration(seconds: 3));
          return 200;
        },
      );
      await service.setLed(true);
      await service.setLed(false);
      expect(calls.map((u) => u.toString()), [
        'http://192.168.178.68/led/on',
        'http://192.168.178.68/led/off',
      ]);
      final custom = PicoLedService(
        baseUrl: 'http://127.0.0.1:8123/',
        request: (uri, _) async {
          calls.add(uri);
          return 204;
        },
      );
      await custom.setLed(false);
      expect(calls.last.toString(), 'http://127.0.0.1:8123/led/off');
    },
  );
  test('native HTTP sends GET for on/off to a real local server', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final seen = <String>[];
    server.listen((request) async {
      seen.add('${request.method} ${request.uri.path}');
      request.response.write('ok');
      await request.response.close();
    });
    final service = PicoLedService(baseUrl: 'http://127.0.0.1:${server.port}');
    await service.setLed(true);
    await service.setLed(false);
    expect(seen, ['GET /led/on', 'GET /led/off']);
  });
  for (final status in [302, 503]) {
    test('HTTP $status fails without following redirects', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var count = 0;
      server.listen((request) async {
        count++;
        request.response.statusCode = status;
        if (status == 302) request.response.headers.set('location', '/led/off');
        await request.response.close();
      });
      final service = PicoLedService(
        baseUrl: 'http://127.0.0.1:${server.port}',
      );
      await expectLater(
        service.setLed(true),
        throwsA(
          isA<PicoLedException>().having(
            (e) => e.message,
            'message',
            contains('HTTP $status'),
          ),
        ),
      );
      expect(count, 1);
    });
  }
  for (final sendHeaders in [false, true]) {
    test(
      'timeout bounds ${sendHeaders ? 'response body' : 'response headers'} waiting',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        server.listen((request) async {
          if (sendHeaders) {
            request.response.bufferOutput = false;
            request.response.write('pending');
            await request.response.flush();
          }
          // Intentionally leave the response open until the timeout closes it.
        });
        final service = PicoLedService(
          baseUrl: 'http://127.0.0.1:${server.port}',
          timeout: const Duration(milliseconds: 80),
        );
        await expectLater(
          service.setLed(true),
          throwsA(
            isA<PicoLedException>().having(
              (e) => e.message,
              'message',
              startsWith('Zeitüberschreitung'),
            ),
          ),
        );
      },
    );
  }
  test('unreachable device produces a German connection error', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close(force: true);
    await expectLater(
      PicoLedService(baseUrl: 'http://127.0.0.1:$port').setLed(false),
      throwsA(
        isA<PicoLedException>().having(
          (e) => e.message,
          'message',
          startsWith('Keine Verbindung'),
        ),
      ),
    );
  });
  test('invalid config and unsupported transports fail explicitly', () async {
    for (final url in [
      'ftp://pico',
      '192.168.178.68',
      'http://pico/other',
      'http://user:password@pico',
      'http://pico?x=1',
    ]) {
      expect(() => PicoLedService(baseUrl: url), throwsArgumentError);
    }
    expect(() => PicoLedService(timeout: Duration.zero), throwsArgumentError);
    final unsupported = PicoLedService(
      request: (_, _) async => throw UnsupportedError('unsupported'),
    );
    await expectLater(
      unsupported.setLed(true),
      throwsA(
        isA<PicoLedException>().having(
          (e) => e.message,
          'message',
          contains('nicht unterstützt'),
        ),
      ),
    );
  });
}
