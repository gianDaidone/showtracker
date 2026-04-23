import 'dart:async';
import 'dart:collection';

/// Token-bucket rate limiter for the AniList GraphQL API.
/// Budget: 12 tokens / 10 s, max 3 concurrent requests.
class AniListQueue {
  static const int _maxTokens = 12;
  static const int _maxConcurrent = 3;
  static const Duration _refillInterval = Duration(seconds: 10);

  int _tokens = _maxTokens;
  int _inflight = 0;
  final Queue<Completer<void>> _pending = Queue();
  late final Timer _refillTimer;

  AniListQueue() {
    _refillTimer = Timer.periodic(_refillInterval, (_) {
      _tokens = _maxTokens;
      _drain();
    });
  }

  void _drain() {
    while (_pending.isNotEmpty && _tokens > 0 && _inflight < _maxConcurrent) {
      _tokens--;
      _inflight++;
      _pending.removeFirst().complete();
    }
  }

  Future<T> enqueue<T>(Future<T> Function() work) async {
    final slot = Completer<void>();
    _pending.add(slot);
    _drain();
    await slot.future;
    try {
      return await work();
    } finally {
      _inflight--;
      _drain();
    }
  }

  void dispose() => _refillTimer.cancel();
}
