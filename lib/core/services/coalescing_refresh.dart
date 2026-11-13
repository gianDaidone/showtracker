import 'dart:async';

/// Serial refreshes with one trailing pass for requests made during work.
///
/// Synchronous bursts share the scheduled first pass. Every caller awaits the
/// whole drain, including trailing work. A failed pass does not strand callers
/// or poison subsequent refreshes; already-requested trailing work still runs.
class CoalescingRefresh {
  CoalescingRefresh(this._refresh);

  final Future<void> Function() _refresh;
  Completer<void>? _pending;
  bool _dirty = false;

  bool get isActive => _pending != null;

  Future<void> request() {
    _dirty = true;
    final pending = _pending;
    if (pending != null) return pending.future;

    final completer = Completer<void>();
    _pending = completer;
    scheduleMicrotask(() => _drain(completer));
    return completer.future;
  }

  Future<void> _drain(Completer<void> completer) async {
    Object? firstError;
    StackTrace? firstStack;
    while (_dirty) {
      _dirty = false;
      try {
        await _refresh();
      } catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }

    // Reset before completing: a request in a completion listener starts a new
    // drain rather than attaching to a Future whose work has already ended.
    _pending = null;
    if (firstError != null) {
      completer.completeError(firstError, firstStack!);
    } else {
      completer.complete();
    }
  }
}
