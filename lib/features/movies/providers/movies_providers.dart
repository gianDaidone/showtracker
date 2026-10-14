import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncNotifierProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/paged_search.dart';
import '../../series/providers/series_providers.dart';
import '../data/models/tmdb_movie.dart';
import '../data/models/tmdb_movie_detail.dart';

part 'movies_providers.g.dart';

// ── TMDB: ricerca e dettaglio film ────────────────────────────────────────────

// Paginata, quindi scritta a mano: un notifier generico non si genera.
final movieSearchProvider = AsyncNotifierProvider.autoDispose
    .family<PagedSearchNotifier<TmdbMovie>, PagedResults<TmdbMovie>, String>(
  (query) => PagedSearchNotifier(
    query,
    (ref) {
      final tmdb = ref.watch(tmdbServiceProvider);
      return (q, page) => tmdb.searchMovies(q, page: page);
    },
    (movie) => movie.id,
  ),
);

@riverpod
Future<TmdbMovieDetail> movieDetail(Ref ref, int tmdbId) {
  return ref.watch(tmdbServiceProvider).getMovieDetails(tmdbId);
}

// ── DB: film tracciati (stream reattivo) ──────────────────────────────────────

// keepAlive: stato globale dell'app. Con Riverpod 3 un notifier autoDispose
// eliminato durante un await fa fallire il resto del metodo (ref/state dopo
// il dispose lanciano UnmountedRefException).
@Riverpod(keepAlive: true)
class TrackedMoviesNotifier extends _$TrackedMoviesNotifier {
  @override
  Stream<List<TrackedMovy>> build() {
    return ref.watch(moviesDaoProvider).watchAll();
  }

  Future<void> addMovie(TmdbMovieDetail detail) async {
    await ref.read(moviesDaoProvider).insertMovie(
          TrackedMoviesCompanion(
            tmdbId: Value(detail.id),
            title: Value(detail.title),
            overview: Value(
              (detail.overview?.isNotEmpty ?? false) ? detail.overview : null,
            ),
            posterPath: Value(detail.posterPath),
            status: const Value(MediaStatus.planToWatch),
            releaseYear: Value(detail.year),
            releaseDate: Value(detail.releaseDateParsed),
            addedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> removeMovie(int dbId) async {
    await ref.read(moviesDaoProvider).deleteMovie(dbId);
  }

  Future<void> updateStatus(int dbId, MediaStatus status) async {
    await ref.read(moviesDaoProvider).updateStatus(dbId, status);
  }
}

// ── Film in uscita (stream reattivo) ──────────────────────────────────────────

@riverpod
Stream<List<TrackedMovy>> upcomingMovies(Ref ref) {
  return ref.watch(moviesDaoProvider).watchUpcoming();
}
