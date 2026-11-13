import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/services/coalescing_refresh.dart';

void main() {
  test('a synchronous burst shares one scheduled pass and Future', () async {
    var passes = 0;
    final refresh = CoalescingRefresh(() async => passes++);
    final first = refresh.request();
    final second = refresh.request();
    final third = refresh.request();
    expect(identical(first, second), isTrue);
    expect(identical(first, third), isTrue);
    expect(passes, 0);
    await first;
    expect(passes, 1);
    expect(refresh.isActive, isFalse);
  });

  test('requests during work coalesce into a serialized latest pass', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    final trailingStarted = Completer<void>();
    final releaseTrailing = Completer<void>();
    final seen = <int>[];
    var latest = 1;
    var active = 0;
    var maxActive = 0;
    final refresh = CoalescingRefresh(() async {
      active++;
      if (active > maxActive) maxActive = active;
      seen.add(latest);
      if (seen.length == 1) {
        started.complete();
        await release.future;
      } else {
        trailingStarted.complete();
        await releaseTrailing.future;
      }
      active--;
    });
    var completed = false;
    final first = refresh.request();
    first.then((_) => completed = true);
    await started.future;
    latest = 2;
    final second = refresh.request();
    latest = 3;
    final third = refresh.request();
    release.complete();
    await trailingStarted.future;
    expect(completed, isFalse);
    expect(seen, [1, 3]);
    expect(maxActive, 1);
    releaseTrailing.complete();
    await Future.wait([first, second, third]);
    expect(completed, isTrue);
  });

  test('a late request during the trailing pass is not lost', () async {
    final gates = List.generate(3, (_) => Completer<void>());
    final started = List.generate(3, (_) => Completer<void>());
    var passes = 0;
    final refresh = CoalescingRefresh(() async {
      final index = passes++;
      started[index].complete();
      await gates[index].future;
    });
    final first = refresh.request();
    await started[0].future;
    final second = refresh.request();
    gates[0].complete();
    await started[1].future;
    final late = refresh.request();
    gates[1].complete();
    await started[2].future;
    gates[2].complete();
    await Future.wait([first, second, late]);
    expect(passes, 3);
  });

  test('an error drains pending work, reports failure and allows recovery',
      () async {
    final started = Completer<void>();
    final release = Completer<void>();
    var passes = 0;
    final error = StateError('temporary');
    final refresh = CoalescingRefresh(() async {
      passes++;
      if (passes == 1) {
        started.complete();
        await release.future;
        throw error;
      }
    });
    final first = refresh.request();
    final failed = expectLater(first, throwsA(same(error)));
    await started.future;
    final pending = refresh.request();
    expect(identical(first, pending), isTrue);
    release.complete();
    await failed;
    expect(passes, 2);
    expect(refresh.isActive, isFalse);
    await refresh.request();
    expect(passes, 3);
  });

  test('a request from completion starts a fresh drain', () async {
    var passes = 0;
    final refresh = CoalescingRefresh(() async => passes++);
    await refresh.request().then((_) => refresh.request());
    expect(passes, 2);
  });
}
