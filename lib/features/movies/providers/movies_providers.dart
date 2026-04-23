import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../series/providers/series_providers.dart';
import '../data/models/tmdb_movie.dart';
import '../data/models/tmdb_movie_detail.dart';

part 'movies_providers.g.dart';

// ── TMDB: ricerca e dettaglio film ────────────────────────────────────────────

@riverpod
Future<List<TmdbMovie>> searchMovies(SearchMoviesRef ref, String query) async {
  if (query.length < 2) return [];
  return ref.watch(tmdbServiceProvider).searchMovies(query);
}

@riverpod
Future<TmdbMovieDetail> movieDetail(MovieDetailRef ref, int tmdbId) {
  return ref.watch(tmdbServiceProvider).getMovieDetails(tmdbId);
}

// ── DB: film tracciati (stream reattivo) ──────────────────────────────────────

@riverpod
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
Stream<List<TrackedMovy>> upcomingMovies(UpcomingMoviesRef ref) {
  return ref.watch(moviesDaoProvider).watchUpcoming();
}
