import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/features/series/data/yuna_service.dart';

void main() {
  Future<List<int>> lookup(http.Response response) => http.runWithClient(
        () => YunaService().getAniListIds(42),
        () => MockClient((request) async {
          expect(request.url.host, 'relations.yuna.moe');
          expect(request.url.path, '/api/v2/themoviedb/');
          expect(request.url.queryParameters, {'id': '42'});
          return response;
        }),
      );

  test('estrae solo mappature AniList intere dalle relazioni', () async {
    expect(
        await lookup(http.Response(
            '[{"anilist":7},{"anilist":8},{"anilist":"9"},{"anilist":null},4,{}]',
            200)),
        [7, 8]);
  });

  test('assenza di mapping, HTTP fallito e payload errato restano recuperabili',
      () async {
    for (final response in [
      http.Response('', 404),
      http.Response('', 204),
      http.Response('', 503),
      http.Response('not json', 200),
      http.Response('{}', 200),
    ]) {
      expect(await lookup(response), isEmpty);
    }
  });

  test('errore di trasporto restituisce una lista vuota', () async {
    final result = await http.runWithClient(
      () => YunaService().getAniListIds(42),
      () => MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(result, isEmpty);
  });

  test('timeout dopo dieci secondi senza attesa reale', () {
    fakeAsync((time) {
      final pending = Completer<http.Response>();
      List<int>? result;
      http
          .runWithClient(
            () => YunaService().getAniListIds(42),
            () => MockClient((_) => pending.future),
          )
          .then((ids) => result = ids);
      time.flushMicrotasks();
      time.elapse(const Duration(seconds: 9));
      expect(result, isNull);
      time.elapse(const Duration(seconds: 1));
      expect(result, isEmpty);
      pending.complete(http.Response('[]', 200));
      time.flushMicrotasks();
      expect(time.nonPeriodicTimerCount, 0);
    });
  });
}
