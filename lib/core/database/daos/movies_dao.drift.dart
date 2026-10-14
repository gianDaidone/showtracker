// dart format width=80
// ignore_for_file: type=lint
part of 'movies_dao.dart';

mixin _$MoviesDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrackedMoviesTable get trackedMovies => attachedDatabase.trackedMovies;
  MoviesDaoManager get managers => MoviesDaoManager(this);
}

class MoviesDaoManager {
  final _$MoviesDaoMixin _db;
  MoviesDaoManager(this._db);
  $$TrackedMoviesTableTableManager get trackedMovies =>
      $$TrackedMoviesTableTableManager(_db.attachedDatabase, _db.trackedMovies);
}
