import 'package:drift/drift.dart';
import '../app_database.dart';

part 'movies_dao.g.dart';

@DriftAccessor(tables: [TrackedMovies])
class MoviesDao extends DatabaseAccessor<AppDatabase> with _$MoviesDaoMixin {
  MoviesDao(super.db);

  Future<int> insertMovie(TrackedMoviesCompanion movie) =>
      into(trackedMovies).insert(movie);

  Future<TrackedMovy?> getByTmdbId(int tmdbId) =>
      (select(trackedMovies)..where((t) => t.tmdbId.equals(tmdbId)))
          .getSingleOrNull();

  Future<void> updateStatus(int id, MediaStatus status) =>
      (update(trackedMovies)..where((t) => t.id.equals(id)))
          .write(TrackedMoviesCompanion(status: Value(status), updatedAt: Value(DateTime.now())));

  Future<void> updateRating(int id, double? rating) =>
      (update(trackedMovies)..where((t) => t.id.equals(id)))
          .write(TrackedMoviesCompanion(userRating: Value(rating), updatedAt: Value(DateTime.now())));

  Future<int> deleteMovie(int id) =>
      (delete(trackedMovies)..where((t) => t.id.equals(id))).go();

  Stream<List<TrackedMovy>> watchAll() =>
      (select(trackedMovies)
            ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
          .watch();

  Stream<List<TrackedMovy>> watchUpcoming() {
    final now = DateTime.now();
    return (select(trackedMovies)
          ..where((t) => t.releaseDate.isBiggerThanValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.releaseDate)]))
        .watch();
  }
}
