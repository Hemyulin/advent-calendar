import 'dart:async';
import 'dart:io';
import 'package:advent_calendar/hardware/pico_service.dart';
import 'package:advent_calendar/challenges/challenge_completion_handler.dart';
import 'package:advent_calendar/challenges/gift_reward.dart';
import 'package:advent_calendar/progress/mock_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const ready = PicoResponse(
  200,
  '{"device":"DoorZero","status":"ready","mode":"connected","ip":"192.168.178.68"}',
);
const opened = PicoResponse(200, '{"success":true,"duration_ms":5000}');

void main() {
  test(
    'five-second firmware reply uses unlock timeout, not health timeout',
    () async {
      final service = PicoService(
        baseUrl: 'http://pico',
        request: (_, timeout) async {
          expect(timeout, const Duration(milliseconds: 1500));
          return ready;
        },
        postRequest: (_, timeout) async {
          expect(timeout, const Duration(seconds: 7));
          await Future<void>.delayed(const Duration(seconds: 5));
          return opened;
        },
      );
      addTearDown(service.dispose);
      var finished = false;
      final action = service.unlock().then((_) => finished = true);
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(finished, isFalse);
      await action;
      expect(finished, isTrue);
    },
  );
  test('unlock works without any device key', () async {
    var calls = 0;
    final service = PicoService(
      request: (_, _) async {
        calls++;
        return ready;
      },
      postRequest: (_, _) async {
        calls++;
        return opened;
      },
    );
    addTearDown(service.dispose);
    await service.unlock();
    expect(calls, 2);
  });
  test(
    'native HTTP transport sends a bodyless POST only after verified health',
    () async {
      final requests = <String>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        requests.add('${request.method} ${request.uri.path}');
        expect(request.headers.value('Authorization'), isNull);
        expect(
          await request.fold<int>(0, (count, chunk) => count + chunk.length),
          0,
        );
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          request.uri.path == '/health' ? ready.body : opened.body,
        );
        await request.response.close();
      });
      final service = PicoService(baseUrl: 'http://127.0.0.1:${server.port}');
      addTearDown(service.dispose);
      await service.unlock();
      await service.acknowledgeGameCompletion();
      expect(requests, ['GET /health', 'POST /unlock', 'POST /game/completed']);
    },
  );

  test(
    'verified home/hotspot failover is shared; concurrent unlocks send one POST',
    () async {
      final requests = <String>[];
      final gate = Completer<PicoResponse>();
      final service = PicoService(
        baseUrls: ['http://home', 'http://hotspot'],
        request: (uri, _) async {
          requests.add('GET $uri');
          return uri.host == 'home' ? const PicoResponse(503) : ready;
        },
        postRequest: (uri, _) {
          requests.add('POST $uri');
          return gate.future;
        },
      );
      addTearDown(service.dispose);
      final a = service.unlock(), b = service.unlock();
      expect(identical(a, b), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(requests, [
        'GET http://home/health',
        'GET http://hotspot/health',
        'POST http://hotspot/unlock',
      ]);
      gate.complete(opened);
      await Future.wait([a, b]);
      await service.unlock();
      expect(requests.skip(3), [
        'GET http://hotspot/health',
        'POST http://hotspot/unlock',
      ]);
    },
  );

  test('wrong device/offline health never sends or queues an unlock', () async {
    var online = false, posts = 0;
    final service = PicoService(
      baseUrl: 'http://pico',
      request: (_, _) async =>
          online ? ready : const PicoResponse(200, '{"device":"Other"}'),
      postRequest: (_, _) async {
        posts++;
        return opened;
      },
    );
    addTearDown(service.dispose);
    await expectLater(service.unlock(), throwsA(isA<PicoException>()));
    expect(posts, 0);
    online = true;
    await service.checkConnection();
    expect(posts, 0);
  });

  for (final response in [
    const PicoResponse(200, '{"success":false}'),
    const PicoResponse(200, 'invalid'),
    const PicoResponse(503),
    const PicoResponse(401),
    const PicoResponse(429),
  ]) {
    test(
      'a failed/malformed command cannot claim success: ${response.body}/${response.statusCode}',
      () async {
        var posts = 0;
        final service = PicoService(
          baseUrl: 'http://pico',
          request: (_, _) async => ready,
          postRequest: (_, _) async {
            posts++;
            return response;
          },
        );
        addTearDown(service.dispose);
        await expectLater(service.unlock(), throwsA(isA<PicoException>()));
        await service.checkConnection();
        expect(posts, 1);
      },
    );
  }

  test('timed-out POST is bounded and never retried on reconnection', () async {
    var posts = 0;
    final gate = Completer<PicoResponse>();
    final service = PicoService(
      baseUrl: 'http://pico',
      timeout: const Duration(milliseconds: 20),
      unlockTimeout: const Duration(milliseconds: 20),
      request: (_, _) async => ready,
      postRequest: (_, _) {
        posts++;
        return gate.future;
      },
    );
    addTearDown(service.dispose);
    await expectLater(service.unlock(), throwsA(isA<PicoException>()));
    expect(service.state, PicoConnectionStatus.disconnected);
    await service.checkConnection();
    gate.complete(opened);
    await Future<void>.delayed(Duration.zero);
    expect(posts, 1);
  });

  test(
    'new gift taps unlock; wins/LED acknowledgements and completed-door replays do not',
    () async {
      final paths = <String>[];
      final service = PicoService(
        baseUrl: 'http://pico',
        request: (_, _) async => ready,
        postRequest: (uri, _) async {
          paths.add(uri.path);
          return uri.path == '/unlock' ? opened : const PicoResponse(204);
        },
      );
      addTearDown(service.dispose);
      final progress = MockProgressRepository(completedIds: {});
      final handler = ChallengeCompletionHandler(
        progress: progress,
        pico: service,
        lockGateway: service,
      );
      await handler.complete('day-1');
      await Future<void>.delayed(Duration.zero);
      expect(paths, ['/game/completed']);
      expect(await handler.openGift('day-1'), GiftOpenResult.boxOpened);
      expect(await handler.openGift('day-1'), GiftOpenResult.replay);
      final replay = ChallengeCompletionHandler(
        progress: progress,
        pico: service,
        lockGateway: service,
      );
      await replay.complete('day-1');
      expect(await replay.openGift('day-1'), GiftOpenResult.replay);
      expect(paths, ['/game/completed', '/unlock']);
    },
  );
}
