import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/features/series/data/anilist_queue.dart';

void main() {
  test('limita a tre richieste concorrenti e mantiene ordine FIFO', () {
    fakeAsync((time) {
      final queue = AniListQueue();
      final started = <int>[];
      final jobs = List.generate(5, (_) => Completer<int>());
      final results = <int>[];
      for (var i = 0; i < jobs.length; i++) {
        queue.enqueue(() {
          started.add(i);
          return jobs[i].future;
        }).then(results.add);
      }
      time.flushMicrotasks();
      expect(started, [0, 1, 2]);
      jobs[1].complete(11);
      time.flushMicrotasks();
      expect(started, [0, 1, 2, 3]);
      jobs[0].complete(10);
      time.flushMicrotasks();
      expect(started, [0, 1, 2, 3, 4]);
      for (var i = 2; i < jobs.length; i++) {
        jobs[i].complete(i + 10);
      }
      time.flushMicrotasks();
      expect(results, [11, 10, 12, 13, 14]);
      queue.dispose();
      expect(time.periodicTimerCount, 0);
    });
  });

  test('dodici token per finestra, refill a dieci secondi e non prima', () {
    fakeAsync((time) {
      final queue = AniListQueue();
      var started = 0;
      var finished = 0;
      for (var i = 0; i < 25; i++) {
        queue.enqueue(() async {
          started++;
        }).then((_) => finished++);
      }
      time.flushMicrotasks();
      expect(started, 12);
      expect(finished, 12);
      time.elapse(const Duration(seconds: 9, milliseconds: 999));
      expect(started, 12);
      time.elapse(const Duration(milliseconds: 1));
      expect(started, 24);
      expect(finished, 24);
      time.elapse(const Duration(seconds: 10));
      expect(started, 25);
      expect(finished, 25);
      queue.dispose();
    });
  });

  test('errore libera slot senza rimborsare il token consumato', () {
    fakeAsync((time) {
      final queue = AniListQueue();
      final hold = List.generate(2, (_) => Completer<void>());
      final errors = <Object>[];
      var started = 0;
      for (final job in hold) {
        queue.enqueue(() => job.future);
      }
      queue.enqueue<void>(() => throw StateError('HTTP failure')).then<void>(
        (_) => fail('Errore atteso'),
        onError: (Object e) {
          errors.add(e);
        },
      );
      for (var i = 0; i < 10; i++) {
        queue.enqueue(() async {
          started++;
        });
      }
      time.flushMicrotasks();
      expect(errors.single, isA<StateError>());
      expect(started, 9); // 2 in corso + 1 fallita + 9 completate = 12.
      for (final job in hold) {
        job.complete();
      }
      time.flushMicrotasks();
      expect(started, 9);
      time.elapse(const Duration(seconds: 10));
      expect(started, 10);
      queue.dispose();
    });
  });

  test('dispose cancella timer senza interrompere il lavoro già iniziato', () {
    fakeAsync((time) {
      final queue = AniListQueue();
      final work = Completer<int>();
      int? result;
      queue.enqueue(() => work.future).then((value) => result = value);
      time.flushMicrotasks();
      expect(time.periodicTimerCount, 1);
      queue.dispose();
      queue.dispose();
      expect(time.periodicTimerCount, 0);
      work.complete(42);
      time.flushMicrotasks();
      expect(result, 42);
    });
  });
}
