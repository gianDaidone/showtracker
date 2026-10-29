import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/database/database_provider.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/features/movies/data/models/tmdb_movie_detail.dart';
import 'package:showtracker/features/movies/providers/movies_providers.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(retry: noProviderRetry, overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    // Riverpod 3 mette in pausa gli stream senza listener, anche keepAlive.
    container.listen(trackedMoviesProvider, (_, __) {});
    await container.read(trackedMoviesProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('notifier salva metadati, transizioni e rimozione nello stream reale',
      () async {
    final notifier = container.read(trackedMoviesProvider.notifier);
    expect(await container.read(trackedMoviesProvider.future), isEmpty);
    final added = Completer<List<TrackedMovy>>();
    final removed = Completer<List<TrackedMovy>>();
    var sawMovie = false;
    final sub = container.listen(trackedMoviesProvider, (_, state) {
      final movies = state.value;
      if (movies == null) return;
      if (movies.isNotEmpty) {
        sawMovie = true;
        if (!added.isCompleted) added.complete(movies);
      } else if (sawMovie && !removed.isCompleted) {
        removed.complete(movies);
      }
    });
    addTearDown(sub.close);
    await notifier.addMovie(const TmdbMovieDetail(
      id: 100,
      title: 'Film',
      overview: 'Trama',
      posterPath: '/poster.jpg',
      releaseDate: '2035-12-07',
      genres: [],
    ));
    final streamed = (await added.future).single;
    final movie = (await db.moviesDao.getByTmdbId(100))!;
    expect(streamed.id, movie.id);
    expect(movie.title, 'Film');
    expect(movie.overview, 'Trama');
    expect(movie.posterPath, '/poster.jpg');
    expect(movie.releaseYear, 2035);
    expect(movie.releaseDate, DateTime(2035, 12, 7));
    expect(movie.status, MediaStatus.planToWatch);
    expect(movie.userRating, isNull);

    for (final status in [
      MediaStatus.watching,
      MediaStatus.completed,
      MediaStatus.dropped,
      MediaStatus.planToWatch
    ]) {
      await notifier.updateStatus(movie.id, status);
      expect((await db.moviesDao.getByTmdbId(100))!.status, status);
    }
    await notifier.removeMovie(movie.id);
    expect(await db.moviesDao.getByTmdbId(100), isNull);
    expect(await removed.future, isEmpty);
  });

  test('aggiunta senza metadati opzionali non inventa data, anno o trama',
      () async {
    await container.read(trackedMoviesProvider.notifier).addMovie(
          const TmdbMovieDetail(
              id: 101, title: 'Film annunciato', overview: '', genres: []),
        );
    final movie = (await db.moviesDao.getByTmdbId(101))!;
    expect(movie.overview, isNull);
    expect(movie.releaseDate, isNull);
    expect(movie.releaseYear, isNull);
    expect(movie.posterPath, isNull);
    expect(movie.status, MediaStatus.planToWatch);
  });
}
