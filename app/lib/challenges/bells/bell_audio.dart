import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'bell_melodies.dart';

abstract interface class BellAudio {
  Future<void> prepare();
  Future<void> play(BellNote note);
  Future<void> stop();
  Future<void> dispose();
}

/// Recorded chimes, preloaded with overlapping voices so repeated notes retain
/// their natural tails. AudioPool uses each platform's native audio backend.
class SampledBellAudio implements BellAudio {
  final Map<BellNote, AudioPool> _pools = {};
  final Map<Timer, StopFunction> _voices = {};
  Future<void>? _preparing;
  bool _disposed = false;
  int _generation = 0;

  @override
  Future<void> prepare() => _preparing ??= _load();

  Future<void> _load() async {
    try {
      for (final note in BellNote.values) {
        final pool = await AudioPool.createFromAsset(
          path: 'audio/bells/${note.asset}.wav',
          minPlayers: 2,
          maxPlayers: 4,
        );
        if (_disposed) {
          await pool.dispose();
          return;
        }
        _pools[note] = pool;
      }
    } catch (_) {
      await Future.wait(_pools.values.map((pool) => pool.dispose()));
      _pools.clear();
      _preparing = null;
      rethrow;
    }
  }

  @override
  Future<void> play(BellNote note) async {
    final generation = _generation;
    await prepare();
    if (_disposed || generation != _generation) return;
    final stopVoice = await _pools[note]!.start(volume: .75);
    if (_disposed || generation != _generation) {
      await stopVoice();
      return;
    }
    late Timer timer;
    timer = Timer(const Duration(milliseconds: 2500), () {
      _voices.remove(timer);
      unawaited(stopVoice().catchError((Object _) {}));
    });
    _voices[timer] = stopVoice;
  }

  @override
  Future<void> stop() async {
    _generation++;
    final voices = _voices.entries.toList();
    _voices.clear();
    for (final entry in voices) {
      entry.key.cancel();
    }
    await Future.wait(voices.map((entry) => entry.value()));
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    try {
      await _preparing;
    } catch (_) {
      /* Already surfaced by prepare. */
    }
    await stop();
    await Future.wait(_pools.values.map((pool) => pool.dispose()));
    _pools.clear();
  }
}
