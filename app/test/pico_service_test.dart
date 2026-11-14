import 'dart:io';
import 'package:advent_calendar/hardware/pico_service.dart';
import 'package:flutter_test/flutter_test.dart';

const ready = PicoResponse(
  200,
  '{"device":"DoorZero","status":"ready","mode":"connected","ip":"192.168.178.68"}',
);
void main() {
  test(
    'completion acknowledgement sends one empty POST after verified health',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final seen = <String>[];
      server.listen((r) async {
        seen.add('${r.method} ${r.uri.path}');
        if (r.uri.path == '/health') {
          r.response.write(ready.body);
        } else {
          expect(await r.fold<int>(0, (n, chunk) => n + chunk.length), 0);
          r.response.statusCode = 204;
        }
        await r.response.close();
      });
      final service = PicoService(baseUrl: 'http://127.0.0.1:${server.port}');
      addTearDown(service.dispose);
      await service.acknowledgeGameCompletion();
      expect(seen, ['GET /health', 'POST /game/completed']);
    },
  );
  test(
    'completion POST redirects are rejected without retransmission',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var posts = 0;
      server.listen((r) async {
        if (r.uri.path == '/health') {
          r.response.write(ready.body);
        } else {
          posts++;
          r.response.statusCode = 307;
          r.response.headers.set('location', '/other');
        }
        await r.response.close();
      });
      final service = PicoService(baseUrl: 'http://127.0.0.1:${server.port}');
      addTearDown(service.dispose);
      await expectLater(
        service.acknowledgeGameCompletion(),
        throwsA(
          isA<PicoException>().having((e) => e.statusCode, 'status', 307),
        ),
      );
      expect(posts, 1);
    },
  );
  test('unverified devices cannot receive completion POSTs', () async {
    var posts = 0;
    final service = PicoService(
      baseUrl: 'http://other',
      request: (_, _) async => const PicoResponse(200, '{"device":"Other"}'),
      postRequest: (_, _) async {
        posts++;
        return const PicoResponse(204);
      },
    );
    addTearDown(service.dispose);
    await service.acknowledgeGameCompletion();
    expect(posts, 0);
  });

  test('default candidates issue only health GETs', () async {
    final calls = <Uri>[];
    final service = PicoService(
      request: (uri, timeout) async {
        calls.add(uri);
        expect(timeout, const Duration(milliseconds: 1500));
        return uri.path == '/health' ? ready : const PicoResponse(200);
      },
    );
    addTearDown(service.dispose);
    expect(service.candidates.map((u) => u.host), [
      '192.168.178.68',
      '192.168.4.1',
    ]);
    expect(await service.checkConnection(), isTrue);
    expect(calls.map((u) => u.toString()), ['http://192.168.178.68/health']);
  });
  test('native transport reads health JSON over GET', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final seen = <String>[];
    server.listen((r) async {
      seen.add('${r.method} ${r.uri.path}');
      r.response.write(r.uri.path == '/health' ? ready.body : 'ok');
      await r.response.close();
    });
    final service = PicoService(baseUrl: 'http://127.0.0.1:${server.port}');
    addTearDown(service.dispose);
    expect(await service.checkConnection(), isTrue);
    expect(seen, ['GET /health']);
  });
  for (final status in [302, 410, 503]) {
    test('health HTTP $status fails without following redirects', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var count = 0;
      server.listen((r) async {
        count++;
        r.response.statusCode = status;
        if (status == 302) r.response.headers.set('location', '/other');
        await r.response.close();
      });
      final service = PicoService(baseUrl: 'http://127.0.0.1:${server.port}');
      addTearDown(service.dispose);
      expect(await service.checkConnection(), isFalse);
      expect(service.lastError, contains('HTTP $status'));
      expect(count, 1);
      expect(service.state, PicoConnectionStatus.disconnected);
    });
  }
  for (final headers in [false, true]) {
    test('timeout bounds stalled ${headers ? 'body' : 'headers'}', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((r) async {
        if (headers) {
          r.response.bufferOutput = false;
          r.response.write('pending');
          await r.response.flush();
        }
      });
      final service = PicoService(
        baseUrl: 'http://127.0.0.1:${server.port}',
        timeout: const Duration(milliseconds: 80),
      );
      addTearDown(service.dispose);
      expect(await service.checkConnection(), isFalse);
      expect(service.lastError, startsWith('Zeitüberschreitung'));
    });
  }
  test('oversized responses are bounded and rejected', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((r) async {
      r.response.write('x' * 9000);
      await r.response.close();
    });
    final service = PicoService(baseUrl: 'http://127.0.0.1:${server.port}');
    addTearDown(service.dispose);
    expect(await service.checkConnection(), isFalse);
    expect(service.state, PicoConnectionStatus.disconnected);
  });
  test(
    'malformed health, wrong identity and not-ready devices stay disconnected',
    () async {
      for (final body in [
        'not json',
        '{}',
        '{"device":"Other","status":"ready","mode":"connected","ip":"192.168.178.68"}',
        '{"device":"DoorZero","status":"starting","mode":"connected","ip":"192.168.178.68"}',
        '{"device":"DoorZero","status":"ready","mode":"connected","ip":"999.1.1.1"}',
      ]) {
        final paths = <String>[];
        final service = PicoService(
          baseUrl: 'http://127.0.0.1',
          request: (u, _) async {
            paths.add(u.path);
            return PicoResponse(200, body);
          },
        );
        expect(await service.checkConnection(), isFalse);
        expect(paths, ['/health']);
        expect(service.state, PicoConnectionStatus.disconnected);
        service.dispose();
      }
    },
  );
  test(
    'configurable candidates prepare for future discovery without trusting advertised IP',
    () async {
      final seen = <Uri>[];
      final service = PicoService(
        baseUrls: ['http://home:8123', 'http://ap:8080'],
        request: (u, _) async {
          seen.add(u);
          return u.host == 'home'
              ? const PicoResponse(503)
              : u.path == '/health'
              ? const PicoResponse(
                  200,
                  '{"device":"DoorZero","status":"ready","mode":"hotspot","ip":"192.168.4.1"}',
                )
              : const PicoResponse(204);
        },
      );
      addTearDown(service.dispose);
      expect(await service.checkConnection(), isTrue);
      expect(seen.map((u) => u.toString()), [
        'http://home:8123/health',
        'http://ap:8080/health',
      ]);
      expect(service.health!.mode, 'hotspot');
    },
  );
  test('invalid config and unsupported transports fail cleanly', () async {
    for (final url in [
      'ftp://pico',
      '192.168.178.68',
      'http://pico/other',
      'http://user:password@pico',
      'http://pico?x=1',
    ]) {
      expect(() => PicoService(baseUrl: url), throwsArgumentError);
    }
    expect(() => PicoService(baseUrls: []), throwsArgumentError);
    expect(() => PicoService(timeout: Duration.zero), throwsArgumentError);
    final service = PicoService(
      request: (_, _) async => throw UnsupportedError('unsupported'),
    );
    addTearDown(service.dispose);
    expect(await service.checkConnection(), isFalse);
    expect(service.lastError, contains('nicht unterstützt'));
  });
}
