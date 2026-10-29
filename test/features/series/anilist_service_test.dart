import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/features/series/data/anilist_service.dart';

http.Response _media(int id) => http.Response(
    jsonEncode({
      'data': {
        'Media': {
          'id': id,
          'status': 'RELEASING',
          'format': 'TV',
          'episodes': 12,
          'streamingEpisodes': []
        }
      },
    }),
    200);

class _ClosingClient extends MockClient {
  bool closed = false;
  _ClosingClient() : super((_) async => _media(1));
  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  test('client iniettato mantiene la coda anche per fetchBatch', () {
    fakeAsync((time) {
      final pending = <Completer<http.Response>>[];
      final requested = <int>[];
      final service = AniListService(client: MockClient((request) {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://graphql.anilist.co');
        expect(request.headers['content-type'], 'application/json');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        requested.add((body['variables'] as Map)['id'] as int);
        final response = Completer<http.Response>();
        pending.add(response);
        return response.future;
      }));
      List<int>? result;
      service.fetchBatch([1, 2, 3, 4]).then(
        (media) => result = media.map((m) => m.id).toList(),
      );
      time.flushMicrotasks();
      expect(requested, [1, 2, 3]);
      pending[0].complete(_media(1));
      time.flushMicrotasks();
      expect(requested, [1, 2, 3, 4]);
      pending[1].complete(_media(2));
      pending[2]
          .complete(http.Response('{"errors":[{"message":"missing"}]}', 200));
      pending[3].complete(_media(4));
      time.flushMicrotasks();
      expect(result, [1, 2, 4]);
      service.dispose();
      expect(time.periodicTimerCount, 0);
    });
  });

  test('429 usa retry-after, massimo due tentativi aggiuntivi', () {
    fakeAsync((time) {
      var requests = 0;
      final service = AniListService(client: MockClient((_) async {
        requests++;
        return http.Response('', 429, headers: {'retry-after': '2'});
      }));
      var completed = false;
      service.fetchById(1).then((media) {
        expect(media, isNull);
        completed = true;
      });
      time.flushMicrotasks();
      expect(requests, 1);
      time.elapse(const Duration(seconds: 1));
      expect(requests, 1);
      time.elapse(const Duration(seconds: 1));
      expect(requests, 2);
      time.elapse(const Duration(seconds: 2));
      expect(requests, 3);
      expect(completed, isTrue);
      service.dispose();
    });
  });

  test('429 senza retry-after aspetta dieci secondi e recupera', () {
    fakeAsync((time) {
      var requests = 0;
      final service = AniListService(client: MockClient((_) async {
        return ++requests == 1 ? http.Response('', 429) : _media(7);
      }));
      int? id;
      service.fetchById(7).then((media) => id = media?.id);
      time.flushMicrotasks();
      time.elapse(const Duration(seconds: 9));
      expect(requests, 1);
      time.elapse(const Duration(seconds: 1));
      expect(id, 7);
      service.dispose();
    });
  });

  test('errori trasporto, HTTP, JSON e GraphQL non producono media fittizi',
      () async {
    for (final response in [
      http.Response('', 403),
      http.Response('not-json', 200),
      http.Response('{"errors":[{"message":"outage"}]}', 200),
      http.Response('{"data":{"Media":null}}', 200),
    ]) {
      final service = AniListService(client: MockClient((_) async => response));
      try {
        expect(await service.fetchById(1), isNull);
      } finally {
        service.dispose();
      }
    }
    final offline = AniListService(
        client: MockClient((_) async => throw http.ClientException('offline')));
    try {
      expect(await offline.fetchById(1), isNull);
    } finally {
      offline.dispose();
    }
  });

  test('ricerca invia titolo nelle variabili e legge la pagina', () async {
    final service = AniListService(client: MockClient((request) async {
      final body = jsonDecode(request.body) as Map;
      expect(body['variables'], {'search': 'Anime seguito'});
      expect(body['query'], contains('Page(perPage: 10)'));
      return http.Response(
          jsonEncode({
            'data': {
              'Page': {
                'media': [
                  {'id': 2, 'format': 'TV', 'status': 'FINISHED'},
                ]
              }
            }
          }),
          200);
    }));
    try {
      expect((await service.searchByTitle('Anime seguito')).single.id, 2);
    } finally {
      service.dispose();
    }
  });

  test('dispose chiude il client e il timer della coda', () {
    fakeAsync((time) {
      final client = _ClosingClient();
      final service = AniListService(client: client);
      expect(time.periodicTimerCount, 1);
      service.dispose();
      expect(client.closed, isTrue);
      expect(time.periodicTimerCount, 0);
    });
  });
}
