import 'dart:async';
import '../hardware/pico_service.dart';
import '../hardware/lock_gateway.dart';
import '../progress/progress_repository.dart';
import 'gift_reward.dart';

/// Central daily-completion boundary. Minigames and previews do not know the
/// Pico protocol. Saved progress is authoritative; feedback is best effort.
class ChallengeCompletionHandler {
  ChallengeCompletionHandler({
    required this.progress,
    required this.pico,
    this.lockGateway,
  });
  final ProgressRepository progress;
  final PicoService? pico;

  /// Hardware protocol and request bounds belong to the gateway; the admin
  /// PIN only controls the admin UI, never the Pico's authorization policy.
  final LockGateway? lockGateway;
  final _completions = <String, Future<void>>{};
  final _newlyCompleted = <String>{};
  final _gifts = <String, Future<GiftOpenResult>>{};

  Future<void> complete(String challengeId) => _completions.putIfAbsent(
    challengeId,
    () => _record(challengeId).onError((Object error, StackTrace stack) {
      _completions.remove(challengeId);
      Error.throwWithStackTrace(error, stack);
    }),
  );

  Future<void> _record(String challengeId) async {
    if ((await progress.completedChallengeIds()).contains(challengeId)) return;
    await progress.markCompleted(challengeId);
    _newlyCompleted.add(challengeId);
    // Do not await network availability, health checks or LED acknowledgement.
    unawaited(_acknowledge());
  }

  /// Called by the gift tap, never by winning alone. Replays cannot reopen the
  /// box. Cache even an uncertain outcome: a timed-out command may have worked.
  Future<GiftOpenResult> openGift(String challengeId) async {
    final completion = _completions[challengeId];
    if (completion == null) return GiftOpenResult.replay;
    await completion;
    if (!_newlyCompleted.contains(challengeId)) return GiftOpenResult.replay;
    if (lockGateway == null) return GiftOpenResult.notConfigured;
    if (_gifts.containsKey(challengeId)) return GiftOpenResult.replay;
    return _gifts.putIfAbsent(challengeId, () async {
      try {
        // The gateway bounds health and command requests. An outer timeout could
        // abandon discovery while a later physical command was still pending.
        await lockGateway!.unlock();
        return GiftOpenResult.boxOpened;
      } catch (_) {
        return GiftOpenResult.unconfirmed;
      }
    });
  }

  Future<void> _acknowledge() async {
    try {
      await pico?.acknowledgeGameCompletion();
    } catch (_) {
      // A timeout may follow a successfully processed POST. Never retry it or
      // turn an optional physical acknowledgement into a failed game save.
    }
  }
}
