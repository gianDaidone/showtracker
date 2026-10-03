import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/features/series/data/tmdb_service.dart';

void main() {
  // Black Clover (73223) il 2026-10-03: /season/2 risponde con una copia
  // vecchia senza episodi, mentre i singoli episodi esistono già.
  http.Response handler(http.Request req, {required int episodes}) {
    final path = req.url.path;
    if (path == '/3/tv/73223/season/2') {
      return http.Response(
        jsonEncode({'season_number': 2, 'name': 'Stagione 2', 'episodes': []}),
        200,
      );
    }
    final match = RegExp(r'^/3/tv/73223/season/2/episode/(\d+)$')
        .firstMatch(path);
    final n = match == null ? null : int.parse(match.group(1)!);
    if (n != null && n <= episodes) {
      return http.Response(
        jsonEncode({
          'episode_number': n,
          'season_number': 2,
          'name': 'Episodio $n',
          'air_date': '2026-10-0${n + 2}',
        }),
        200,
      );
    }
    return http.Response('{"status_code":34}', 404);
  }

  test('stagione vuota: gli episodi vengono scaricati uno per uno', () async {
    final svc = TmdbService(
        MockClient((req) async => handler(req, episodes: 7)));
    final season = await svc.getSeasonDetails(73223, 2);

    expect(season.episodes!.map((e) => e.episodeNumber),
        [1, 2, 3, 4, 5, 6, 7]);
    expect(season.episodeCount, 7);
    expect(season.name, 'Stagione 2');
  });

  test('stagione davvero vuota resta vuota', () async {
    final svc = TmdbService(
        MockClient((req) async => handler(req, episodes: 0)));
    final season = await svc.getSeasonDetails(73223, 2);

    expect(season.episodes, isEmpty);
  });

  test('un errore diverso dal 404 non produce una lista parziale', () async {
    final svc = TmdbService(MockClient((req) async {
      if (req.url.path.endsWith('/episode/3')) {
        return http.Response('', 503);
      }
      return handler(req, episodes: 7);
    }));

    expect(svc.getSeasonDetails(73223, 2), throwsA(isA<TmdbException>()));
  });
}
