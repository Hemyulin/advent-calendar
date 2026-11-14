import 'dart:async';
import 'package:advent_calendar/challenges/challenge_completion_handler.dart';
import 'package:advent_calendar/hardware/pico_service.dart';
import 'package:advent_calendar/hardware/lock_gateway.dart';
import 'package:advent_calendar/challenges/gift_reward.dart';
import 'package:advent_calendar/progress/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const ready = PicoResponse(
  200,
  '{"device":"DoorZero","status":"ready","mode":"connected","ip":"192.168.178.68"}',
);

class Progress implements ProgressRepository {
  final completed = <String>{};
  int writes = 0;
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<Set<String>> completedChallengeIds() async => {...completed};
  @override
  Future<void> markCompleted(String id) async {
    writes++;
    await gate?.future;
    if (fail) throw StateError('save failed');
    completed.add(id);
  }
}

class TestLock implements LockGateway {
  TestLock(this.action);
  final Future<void> Function() action;
  int calls = 0;
  @override
  Future<void> unlock() {
    calls++;
    return action();
  }
}

Future<void> flush() => Future<void>.delayed(Duration.zero);
void main() {
  test(
    'only a newly solved door can request its gift; repeated taps and replay never unlock twice',
    () async {
      final progress = Progress();
      final lock = TestLock(() async {});
      final handler = ChallengeCompletionHandler(
        progress: progress,
        pico: null,
        lockGateway: lock,
      );
      expect(await handler.openGift('day-1'), GiftOpenResult.replay);
      expect(lock.calls, 0);
      await handler.complete('day-1');
      expect(lock.calls, 0);
      final results = await Future.wait([
        handler.openGift('day-1'),
        handler.openGift('day-1'),
      ]);
      expect(results, contains(GiftOpenResult.boxOpened));
      expect(lock.calls, 1);
      await handler.complete('day-1');
      expect(await handler.openGift('day-1'), GiftOpenResult.replay);
      final reopened = ChallengeCompletionHandler(
        progress: progress,
        pico: null,
        lockGateway: lock,
      );
      await reopened.complete('day-1');
      expect(await reopened.openGift('day-1'), GiftOpenResult.replay);
      expect(lock.calls, 1);
    },
  );

  test('missing endpoint opens only the virtual gift', () async {
    final handler = ChallengeCompletionHandler(
      progress: Progress(),
      pico: null,
    );
    await handler.complete('day-1');
    expect(await handler.openGift('day-1'), GiftOpenResult.notConfigured);
  });

  test(
    'failed or ambiguous box actions never retry and do not undo progress',
    () async {
      final progress = Progress();
      final lock = TestLock(
        () async => throw TimeoutException('unknown outcome'),
      );
      final handler = ChallengeCompletionHandler(
        progress: progress,
        pico: null,
        lockGateway: lock,
      );
      await handler.complete('day-1');
      expect(await handler.openGift('day-1'), GiftOpenResult.unconfirmed);
      expect(await handler.openGift('day-1'), GiftOpenResult.replay);
      expect(lock.calls, 1);
      expect(progress.completed, {'day-1'});
    },
  );

  test(
    'unavailable hardware configuration does not prevent saving completion',
    () async {
      final progress = Progress();
      await ChallengeCompletionHandler(
        progress: progress,
        pico: null,
      ).complete('day-2');
      expect(progress.completed, contains('day-2'));
    },
  );

  test(
    'saves before notification; pending POST cannot block completion or replay',
    () async {
      final progress = Progress();
      final post = Completer<PicoResponse>();
      var posts = 0;
      final pico = PicoService(
        baseUrl: 'http://pico',
        timeout: const Duration(seconds: 10),
        request: (_, _) async => ready,
        postRequest: (uri, _) async {
          posts++;
          expect(progress.completed, contains('day-2'));
          expect(uri.path, '/game/completed');
          return post.future;
        },
      );
      addTearDown(pico.dispose);
      final handler = ChallengeCompletionHandler(
        progress: progress,
        pico: pico,
      );
      await handler.complete('day-2');
      await flush();
      expect(post.isCompleted, isFalse);
      expect(posts, 1);
      await handler.complete('day-2');
      expect(progress.writes, 1);
      expect(posts, 1);
      post.complete(const PicoResponse(204));
      await flush();
    },
  );
  test('concurrent callbacks share one save and one notification', () async {
    final progress = Progress()..gate = Completer<void>();
    var posts = 0;
    final pico = PicoService(
      baseUrl: 'http://pico',
      request: (_, _) async => ready,
      postRequest: (_, _) async {
        posts++;
        return const PicoResponse(204);
      },
    );
    addTearDown(pico.dispose);
    final handler = ChallengeCompletionHandler(progress: progress, pico: pico);
    final a = handler.complete('day-2');
    final b = handler.complete('day-2');
    expect(identical(a, b), isTrue);
    progress.gate!.complete();
    await Future.wait([a, b]);
    await flush();
    expect(progress.writes, 1);
    expect(posts, 1);
  });
  test('already completed challenges never probe or notify', () async {
    final progress = Progress()..completed.add('day-2');
    var requests = 0;
    final pico = PicoService(
      request: (_, _) async {
        requests++;
        return ready;
      },
      postRequest: (_, _) async {
        requests++;
        return const PicoResponse(204);
      },
    );
    addTearDown(pico.dispose);
    await ChallengeCompletionHandler(
      progress: progress,
      pico: pico,
    ).complete('day-2');
    await flush();
    expect(requests, 0);
    expect(progress.writes, 0);
  });
  test(
    'offline success is retained and never queued for a later reconnection',
    () async {
      final progress = Progress();
      var online = false;
      var posts = 0;
      final pico = PicoService(
        baseUrl: 'http://pico',
        request: (_, _) async {
          if (!online) throw StateError('offline');
          return ready;
        },
        postRequest: (_, _) async {
          posts++;
          return const PicoResponse(204);
        },
      );
      addTearDown(pico.dispose);
      final handler = ChallengeCompletionHandler(
        progress: progress,
        pico: pico,
      );
      await handler.complete('day-2');
      await flush();
      expect(progress.completed, contains('day-2'));
      expect(posts, 0);
      online = true;
      await pico.checkConnection();
      await handler.complete('day-2');
      await flush();
      expect(posts, 0);
    },
  );
  for (final failWithTimeout in [false, true]) {
    test(
      'POST ${failWithTimeout ? 'timeout' : 'HTTP failure'} does not undo progress or retry notification',
      () async {
        final progress = Progress();
        var posts = 0;
        final pico = PicoService(
          baseUrl: 'http://pico',
          request: (_, _) async => ready,
          postRequest: (_, _) async {
            posts++;
            if (failWithTimeout) throw TimeoutException('ambiguous result');
            return const PicoResponse(503);
          },
        );
        addTearDown(pico.dispose);
        final handler = ChallengeCompletionHandler(
          progress: progress,
          pico: pico,
        );
        await handler.complete('day-2');
        await flush();
        await pico.checkConnection();
        await handler.complete('day-2');
        await flush();
        expect(progress.completed, contains('day-2'));
        expect(posts, 1);
      },
    );
  }
  test(
    'failed progress save can retry and only notifies after successful storage',
    () async {
      final progress = Progress()..fail = true;
      var posts = 0;
      final pico = PicoService(
        baseUrl: 'http://pico',
        request: (_, _) async => ready,
        postRequest: (_, _) async {
          posts++;
          return const PicoResponse(204);
        },
      );
      addTearDown(pico.dispose);
      final handler = ChallengeCompletionHandler(
        progress: progress,
        pico: pico,
      );
      await expectLater(handler.complete('day-2'), throwsStateError);
      expect(posts, 0);
      progress.fail = false;
      await handler.complete('day-2');
      await flush();
      expect(posts, 1);
      expect(progress.writes, 2);
    },
  );
  test('different newly completed challenges each acknowledge once', () async {
    final progress = Progress();
    var posts = 0;
    final pico = PicoService(
      baseUrl: 'http://pico',
      request: (_, _) async => ready,
      postRequest: (_, _) async {
        posts++;
        return const PicoResponse(204);
      },
    );
    addTearDown(pico.dispose);
    final handler = ChallengeCompletionHandler(progress: progress, pico: pico);
    await Future.wait([handler.complete('day-1'), handler.complete('day-2')]);
    await flush();
    expect(posts, 2);
  });
}
