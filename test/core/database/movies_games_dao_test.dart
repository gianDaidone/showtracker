import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  final old = DateTime.utc(2020, 1, 1);

  TrackedMoviesCompanion movie(int tmdbId, {DateTime? releaseDate}) =>
      TrackedMoviesCompanion(
        tmdbId: Value(tmdbId),
        title: Value('Film $tmdbId'),
        status: const Value(MediaStatus.planToWatch),
        addedAt: Value(DateTime.utc(2026, 1, tmdbId)),
        releaseDate: Value(releaseDate),
        updatedAt: Value(old),
      );

  TrackedGamesCompanion game(int rawgId) => TrackedGamesCompanion(
        rawgId: Value(rawgId),
        title: Value('Gioco $rawgId'),
        status: const Value(MediaStatus.planToWatch),
        addedAt: Value(DateTime.utc(2026, 1, rawgId)),
        updatedAt: Value(old),
      );

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('MoviesDao', () {
    test('CRUD, unicità, ordine e rimozione inesistente', () async {
      final first = await db.moviesDao.insertMovie(movie(1));
      final second = await db.moviesDao.insertMovie(movie(2));
      expect((await db.moviesDao.getByTmdbId(1))!.id, first);
      expect(await db.moviesDao.getByTmdbId(99), isNull);
      await expectLater(
          db.moviesDao.insertMovie(movie(1)), throwsA(isA<Exception>()));
      expect((await db.moviesDao.watchAll().first).map((m) => m.id),
          [second, first]);
      expect(await db.moviesDao.deleteMovie(first), 1);
      expect(await db.moviesDao.deleteMovie(first), 0);
      expect(await db.moviesDao.getByTmdbId(1), isNull);
      expect((await db.moviesDao.getByTmdbId(2))!.id, second);
    });

    test('stati e voto nullable persistono aggiornando timestamp', () async {
      final id = await db.moviesDao.insertMovie(movie(1));
      for (final status in [MediaStatus.completed, MediaStatus.planToWatch]) {
        await (db.update(db.trackedMovies)..where((m) => m.id.equals(id)))
            .write(TrackedMoviesCompanion(updatedAt: Value(old)));
        await db.moviesDao.updateStatus(id, status);
        final saved = (await db.moviesDao.getByTmdbId(1))!;
        expect(saved.status, status);
        expect(saved.updatedAt!.isAfter(old), isTrue);
      }
      for (final rating in <double?>[7.5, null]) {
        await (db.update(db.trackedMovies)..where((m) => m.id.equals(id)))
            .write(TrackedMoviesCompanion(updatedAt: Value(old)));
        await db.moviesDao.updateRating(id, rating);
        final saved = (await db.moviesDao.getByTmdbId(1))!;
        expect(saved.userRating, rating);
        expect(saved.updatedAt!.isAfter(old), isTrue);
      }
    });

    test('stream emette inserimento, stato, voto e cancellazione', () async {
      final stream = StreamIterator(db.moviesDao.watchAll());
      addTearDown(stream.cancel);
      expect(await stream.moveNext(), isTrue);
      expect(stream.current, isEmpty);
      var next = stream.moveNext();
      final id = await db.moviesDao.insertMovie(movie(1));
      expect(await next, isTrue);
      expect(stream.current.single.id, id);
      next = stream.moveNext();
      await db.moviesDao.updateStatus(id, MediaStatus.completed);
      expect(await next, isTrue);
      expect(stream.current.single.status, MediaStatus.completed);
      next = stream.moveNext();
      await db.moviesDao.updateRating(id, 8);
      expect(await next, isTrue);
      expect(stream.current.single.userRating, 8);
      next = stream.moveNext();
      await db.moviesDao.deleteMovie(id);
      expect(await next, isTrue);
      expect(stream.current, isEmpty);
    });

    test('upcoming esclude passato/null e ordina le uscite future', () async {
      final future = DateTime.now().add(const Duration(days: 300));
      await db.moviesDao.insertMovie(movie(1));
      await db.moviesDao.insertMovie(movie(2, releaseDate: old));
      await db.moviesDao.insertMovie(
          movie(3, releaseDate: future.add(const Duration(days: 5))));
      final stream = StreamIterator(db.moviesDao.watchUpcoming());
      addTearDown(stream.cancel);
      expect(await stream.moveNext(), isTrue);
      expect(stream.current.map((m) => m.tmdbId), [3]);
      final next = stream.moveNext();
      await db.moviesDao.insertMovie(movie(4, releaseDate: future));
      expect(await next, isTrue);
      expect(stream.current.map((m) => m.tmdbId), [4, 3]);
    });
  });

  group('GamesDao', () {
    test('CRUD, duplicato ignorato senza sovrascrivere e ordine', () async {
      final first = await db.gamesDao.insertGame(game(1));
      final second = await db.gamesDao.insertGame(game(2));
      final before = await db.gamesDao.getByRawgId(1);
      await db.gamesDao.insertGame(game(1).copyWith(
          title: const Value('Non deve sostituire'),
          status: const Value(MediaStatus.completed)));
      expect(await db.gamesDao.getByRawgId(1), before);
      expect(await db.gamesDao.getByRawgId(99), isNull);
      expect((await db.gamesDao.watchAll().first).map((g) => g.id),
          [second, first]);
      expect(await db.gamesDao.deleteGame(first), 1);
      expect(await db.gamesDao.deleteGame(first), 0);
      expect(await db.gamesDao.getByRawgId(1), isNull);
      expect((await db.gamesDao.getByRawgId(2))!.id, second);
    });

    test('tutti gli stati e voto nullable aggiornano timestamp', () async {
      final id = await db.gamesDao.insertGame(game(1));
      for (final status in MediaStatus.values) {
        await (db.update(db.trackedGames)..where((g) => g.id.equals(id)))
            .write(TrackedGamesCompanion(updatedAt: Value(old)));
        await db.gamesDao.updateStatus(id, status);
        final saved = (await db.gamesDao.getByRawgId(1))!;
        expect(saved.status, status);
        expect(saved.updatedAt!.isAfter(old), isTrue);
      }
      for (final rating in <double?>[9, null]) {
        await (db.update(db.trackedGames)..where((g) => g.id.equals(id)))
            .write(TrackedGamesCompanion(updatedAt: Value(old)));
        await db.gamesDao.updateRating(id, rating);
        final saved = (await db.gamesDao.getByRawgId(1))!;
        expect(saved.userRating, rating);
        expect(saved.updatedAt!.isAfter(old), isTrue);
      }
    });

    test('stream emette inserimento, stato, voto e cancellazione', () async {
      final stream = StreamIterator(db.gamesDao.watchAll());
      addTearDown(stream.cancel);
      expect(await stream.moveNext(), isTrue);
      expect(stream.current, isEmpty);
      var next = stream.moveNext();
      final id = await db.gamesDao.insertGame(game(1));
      expect(await next, isTrue);
      expect(stream.current.single.id, id);
      next = stream.moveNext();
      await db.gamesDao.updateStatus(id, MediaStatus.watching);
      expect(await next, isTrue);
      expect(stream.current.single.status, MediaStatus.watching);
      next = stream.moveNext();
      await db.gamesDao.updateRating(id, null);
      expect(await next, isTrue);
      expect(stream.current.single.userRating, isNull);
      next = stream.moveNext();
      await db.gamesDao.deleteGame(id);
      expect(await next, isTrue);
      expect(stream.current, isEmpty);
    });
  });
}
