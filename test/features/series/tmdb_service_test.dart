import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/features/series/data/tmdb_service.dart';
import 'package:showtracker/features/series/data/models/anilist_media.dart';
import 'package:showtracker/features/series/data/models/normalized_anime_season.dart';

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
    final match =
        RegExp(r'^/3/tv/73223/season/2/episode/(\d+)$').firstMatch(path);
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
    final svc =
        TmdbService(MockClient((req) async => handler(req, episodes: 7)));
    final season = await svc.getSeasonDetails(73223, 2);

    expect(season.episodes!.map((e) => e.episodeNumber), [1, 2, 3, 4, 5, 6, 7]);
    expect(season.episodeCount, 7);
    expect(season.name, 'Stagione 2');
  });

  test('stagione davvero vuota resta vuota', () async {
    final svc =
        TmdbService(MockClient((req) async => handler(req, episodes: 0)));
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

  test('dettagli bilingue mantengono italiano e usano fallback inglese',
      () async {
    final requests = <Uri>[];
    final client = MockClient((req) async {
      requests.add(req.url);
      final italian = req.url.queryParameters['language'] == 'it-IT';
      return http.Response(
          jsonEncode({
            'id': 42,
            'name': italian ? 'Titolo originale' : 'English title',
            'original_name': 'Titolo originale',
            'original_language': 'ja',
            'title': italian ? 'Film italiano' : 'English movie',
            'overview': italian ? '' : 'English overview',
            'genres': null,
            'seasons': null,
            'origin_country': null,
          }),
          200);
    });
    addTearDown(client.close);
    final service = TmdbService(client);
    final show = await service.getShowDetails(42);
    expect(show.name, 'English title');
    expect(show.overview, 'English overview');
    expect(show.genres, isEmpty);
    expect(show.seasons, isEmpty);
    final movie = await service.getMovieDetails(42);
    expect(movie.title, 'Film italiano');
    expect(movie.overview, 'English overview');
    expect(movie.releaseDateParsed, isNull);
    expect(requests.map((r) => r.queryParameters['language']),
        ['it-IT', 'en-US', 'it-IT', 'en-US']);
  });

  test('ricerca film preserva query, pagina e filtro adulti', () async {
    final client = MockClient((req) async {
      expect(req.url.path, '/3/search/movie');
      expect(req.url.queryParameters, {
        'query': 'città & mare',
        'language': 'it-IT',
        'include_adult': 'false',
        'page': '2',
      });
      return http.Response('{"page":2,"total_pages":2,"results":null}', 200);
    });
    addTearDown(client.close);
    final result =
        await TmdbService(client).searchMovies('città & mare', page: 2);
    expect(result.items, isEmpty);
    expect(result.hasMore, isFalse);
  });

  test('HTTP non riuscito e JSON illeggibile non diventano risultati vuoti',
      () async {
    for (final status in [401, 404, 503]) {
      final client = MockClient((_) async => http.Response('{}', status));
      addTearDown(client.close);
      await expectLater(
          TmdbService(client).searchShows('serie'),
          throwsA(
            isA<TmdbException>()
                .having((e) => e.statusCode, 'statusCode', status),
          ));
    }
    final client = MockClient((_) async => http.Response('not json', 200));
    addTearDown(client.close);
    await expectLater(TmdbService(client).searchShows('serie'),
        throwsA(isA<FormatException>()));
  });

  test('anime redistribuisce una stagione in cour e conserva titoli e orari',
      () async {
    final requests = <Uri>[];
    final client = MockClient((req) async {
      requests.add(req.url);
      return http.Response(
          jsonEncode({
            'season_number': 1,
            'episodes': [
              {
                'episode_number': 1,
                'name': 'Episodio 1',
                'air_date': '2026-01-01'
              },
              {
                'episode_number': 2,
                'name': 'Titolo italiano',
                'air_date': '2026-01-08'
              },
              {
                'episode_number': 3,
                'name': 'Episode 3',
                'air_date': '2026-01-15'
              },
              {
                'episode_number': 4,
                'name': 'Episodio 4',
                'air_date': '2026-01-22'
              },
            ],
          }),
          200);
    });
    addTearDown(client.close);
    final result =
        await TmdbService(client).getAnimeEpisodesBySeason(42, const [
      NormalizedAnimeSeason(
        seasonNumber: 1,
        tmdbSeasonNumber: 1,
        anilistId: 100,
        episodeCount: 2,
        status: 'FINISHED',
        streamingEpisodes: [
          AniListStreamingEpisode(title: 'Episode 1 - Titolo streaming'),
          AniListStreamingEpisode(title: 'Episode 2 - Non sostituire italiano'),
          AniListStreamingEpisode(title: 'Titolo non numerato'),
        ],
      ),
      NormalizedAnimeSeason(
        seasonNumber: 2,
        tmdbSeasonNumber: 1,
        anilistId: 101,
        episodeCount: 2,
        status: 'RELEASING',
        nextAiringEpisode: AniListNextAiring(
            episode: 1, airingAt: 2000000000, timeUntilAiring: 100),
        streamingEpisodes: [
          AniListStreamingEpisode(title: 'Episode 3 – Seconda parte'),
        ],
      ),
    ]);
    expect(requests, hasLength(2)); // Una sola stagione, nelle due lingue.
    expect(
        result[1]!.map((e) => e.name), ['Titolo streaming', 'Titolo italiano']);
    expect(result[2]!.map((e) => e.episodeNumber), [1, 2]);
    expect(result[2]!.map((e) => e.absoluteEpisodeNumber), [3, 4]);
    expect(result[2]!.first.name, 'Seconda parte');
    expect(result[2]!.first.airingAt!.millisecondsSinceEpoch, 2000000000000);
    expect(result[2]!.last.airingAt, isNull);
  });

  test('anime senza mapping o con TMDB indisponibile resta vuoto', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('', 503);
    });
    addTearDown(client.close);
    final service = TmdbService(client);
    expect(await service.getAnimeEpisodesBySeason(42, []), isEmpty);
    expect(requests, 0);
    expect(
        await service.getAnimeEpisodesBySeason(42, const [
          NormalizedAnimeSeason(
              seasonNumber: 1,
              tmdbSeasonNumber: 1,
              anilistId: 100,
              episodeCount: 12,
              status: 'FINISHED',
              streamingEpisodes: []),
        ]),
        isEmpty);
    expect(requests, 2);
  });

  group('liste da scoprire', () {
    final requests = <Uri>[];
    final svc = TmdbService(MockClient((req) async {
      requests.add(req.url);
      return http.Response(
        jsonEncode({
          'page': int.parse(req.url.queryParameters['page'] ?? '1'),
          'total_pages': 3,
          'total_results': 60,
          'results': [
            {'id': 1, 'name': 'Serie', 'title': 'Film'},
          ],
        }),
        200,
      );
    }));
    setUp(requests.clear);

    test('di tendenza: settimana, in italiano, con la pagina', () async {
      final page = await svc.trendingShows(page: 2);

      expect(requests.single.path, '/3/trending/tv/week');
      expect(
          requests.single.queryParameters, {'language': 'it-IT', 'page': '2'});
      expect(page.items.single.name, 'Serie');
      expect(page.hasMore, isTrue);
    });

    test('consigli di un film', () async {
      final items = await svc.movieRecommendations(42);

      expect(requests.single.path, '/3/movie/42/recommendations');
      expect(items.single.title, 'Film');
    });
  });
}
