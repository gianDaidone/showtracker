import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/paged_search.dart';
import '../../games/data/models/rawg_game.dart';
import '../../games/providers/games_providers.dart';
import '../../movies/data/models/tmdb_movie.dart';
import '../../movies/providers/movies_providers.dart';
import '../../series/data/models/tmdb_show.dart';
import '../../series/providers/series_providers.dart';
import '../data/discover_rules.dart';

// Liste mostrate in Cerca a barra vuota. Restano in vita 30 minuti dopo che
// si esce dalla schermata: tornarci non rifà le chiamate, e le righe di
// "Tutti" e le liste dei filtri singoli leggono gli stessi provider.
//
// I titoli già tracciati li toglie la schermata, non questi provider: così
// un titolo appena aggiunto sparisce subito senza rifare le richieste.

const _discoverCache = Duration(minutes: 30);

// ── Semi per "Per te" ─────────────────────────────────────────────────────────

List<TrackedShow> showSeeds(List<TrackedShow> shows) => pickSeeds(
      shows,
      statusOf: (s) => s.status,
      ratingOf: (s) => s.userRating,
      recencyOf: (s) => s.lastWatchedAt ?? s.updatedAt ?? s.addedAt,
    );

List<TrackedMovy> movieSeeds(List<TrackedMovy> movies) => pickSeeds(
      movies,
      statusOf: (m) => m.status,
      ratingOf: (m) => m.userRating,
      recencyOf: (m) => m.updatedAt ?? m.addedAt,
    );

/// Solo 3: per i giochi ogni seme costa una chiamata RAWG al dettaglio.
List<TrackedGame> gameSeeds(List<TrackedGame> games) => pickSeeds(
      games,
      statusOf: (g) => g.status,
      ratingOf: (g) => g.userRating,
      recencyOf: (g) => g.updatedAt ?? g.addedAt,
      max: 3,
    );

/// Chiama [fetch] per ogni seme in parallelo. Un seme che fallisce conta come
/// lista vuota; l'errore arriva alla schermata solo se falliscono tutti.
Future<List<R>> _perSeed<S, R>(
  List<S> seeds,
  Future<R> Function(S seed) fetch,
  R empty,
) async {
  Object? error;
  var failed = 0;
  final results = await Future.wait(seeds.map((s) async {
    try {
      return await fetch(s);
    } catch (e) {
      debugPrint('Consigli: un seme non è stato caricato: $e');
      error = e;
      failed++;
      return empty;
    }
  }));
  if (seeds.isNotEmpty && failed == seeds.length) throw error!;
  return results;
}

const _noPage = SearchPage<Never>(items: [], hasMore: false);

// ── Serie ─────────────────────────────────────────────────────────────────────

final showDiscoverProvider = AsyncNotifierProvider.autoDispose
    .family<PagedListNotifier<TmdbShow>, PagedResults<TmdbShow>, DiscoverList>(
  (list) => PagedListNotifier(
    (ref) {
      final tmdb = ref.watch(tmdbServiceProvider);
      return switch (list) {
        DiscoverList.trending => (page) => tmdb.trendingShows(page: page),
        DiscoverList.topRated => (page) => tmdb.topRatedShows(page: page),
        // Una pagina sola: i consigli di 5 serie sono già un centinaio
        DiscoverList.forYou => (_) async {
            final seeds = showSeeds(await ref.read(trackedShowsProvider.future));
            if (seeds.isEmpty) return _noPage;
            final perSeed = await _perSeed(seeds,
                (s) => tmdb.showRecommendations(s.tmdbId), const <TmdbShow>[]);
            return SearchPage(
              items: mergeRecommendations(perSeed, (s) => s.id),
              hasMore: false,
            );
          },
      };
    },
    (show) => show.id,
    label: 'Serie da scoprire (${list.name})',
    cacheFor: _discoverCache,
  ),
);

// ── Film ──────────────────────────────────────────────────────────────────────

final movieDiscoverProvider = AsyncNotifierProvider.autoDispose
    .family<PagedListNotifier<TmdbMovie>, PagedResults<TmdbMovie>, DiscoverList>(
  (list) => PagedListNotifier(
    (ref) {
      final tmdb = ref.watch(tmdbServiceProvider);
      return switch (list) {
        DiscoverList.trending => (page) => tmdb.trendingMovies(page: page),
        DiscoverList.topRated => (page) => tmdb.topRatedMovies(page: page),
        DiscoverList.forYou => (_) async {
            final seeds =
                movieSeeds(await ref.read(trackedMoviesProvider.future));
            if (seeds.isEmpty) return _noPage;
            final perSeed = await _perSeed(seeds,
                (m) => tmdb.movieRecommendations(m.tmdbId), const <TmdbMovie>[]);
            return SearchPage(
              items: mergeRecommendations(perSeed, (m) => m.id),
              hasMore: false,
            );
          },
      };
    },
    (movie) => movie.id,
    label: 'Film da scoprire (${list.name})',
    cacheFor: _discoverCache,
  ),
);

// ── Giochi ────────────────────────────────────────────────────────────────────

/// `AAAA-MM-GG,AAAA-MM-GG` degli ultimi [days] giorni, per il filtro `dates`.
String _lastDays(int days) {
  String day(DateTime d) => d.toIso8601String().substring(0, 10);
  final now = DateTime.now();
  return '${day(now.subtract(Duration(days: days)))},${day(now)}';
}

final gameDiscoverProvider = AsyncNotifierProvider.autoDispose
    .family<PagedListNotifier<RawgGame>, PagedResults<RawgGame>, DiscoverList>(
  (list) => PagedListNotifier(
    (ref) {
      final rawg = ref.watch(rawgServiceProvider);
      switch (list) {
        case DiscoverList.trending:
          // RAWG non ha un "di tendenza": i più aggiunti tra le uscite recenti
          final dates = _lastDays(90);
          return (page) =>
              rawg.discoverGames(ordering: '-added', dates: dates, page: page);
        case DiscoverList.topRated:
          return (page) =>
              rawg.discoverGames(ordering: '-metacritic', page: page);
        case DiscoverList.forYou:
          // TrackedGames non salva i generi: li prende dal dettaglio dei semi,
          // una volta sola, e li riusa per le pagine successive.
          List<int>? genres;
          return (page) async {
            if (genres == null) {
              final seeds =
                  gameSeeds(await ref.read(trackedGamesProvider.future));
              final perSeed = await _perSeed(seeds,
                  (g) async => (await rawg.getGameDetails(g.rawgId)).genreIds,
                  const <int>[]);
              genres = topGenreIds(perSeed);
            }
            if (genres!.isEmpty) return _noPage;
            return rawg.discoverGames(
                ordering: '-added', genreIds: genres!, page: page);
          };
      }
    },
    (game) => game.id,
    label: 'Giochi da scoprire (${list.name})',
    cacheFor: _discoverCache,
  ),
);
