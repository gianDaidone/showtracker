import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/core/auth/rawg_auth_state.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/theme/app_theme.dart';
import 'package:showtracker/features/games/data/rawg_service.dart';
import 'package:showtracker/features/games/presentation/games_list_screen.dart';
import 'package:showtracker/features/movies/presentation/movies_list_screen.dart';
import 'package:showtracker/features/series/data/tmdb_service.dart';

import '../../support/app_test_harness.dart';

void main() {
  for (final games in [true, false]) {
    testWidgets(
        'apertura libreria recupera placeholder ${games ? 'giochi' : 'film'}',
        (tester) async {
      final client = MockClient((request) async => http.Response(
          jsonEncode(games
              ? {
                  'id': 42,
                  'name': 'Titolo recuperato',
                  'platforms': [],
                  'rating': 4.5
                }
              : {
                  'id': 42,
                  'title': 'Titolo recuperato',
                  'release_date': '2020-01-01'
                }),
          200));
      addTearDown(client.close);
      final app = (await tester.runAsync(() => AppTestHarness.create(
            rawgAuth: const RawgAuthenticated('test-only'),
            rawgService: RawgService(client),
            tmdbService: TmdbService(client),
          )))!;
      addTearDown(() => app.dispose(tester));
      final before = await tester.runAsync(() async {
        if (games) {
          await app.db.gamesDao.insertGame(TrackedGamesCompanion(
            rawgId: const Value(42),
            title: const Value('Sconosciuto'),
            status: const Value(MediaStatus.paused),
            addedAt: Value(DateTime(2020)),
            userRating: const Value(7.0),
            updatedAt: Value(DateTime(2021)),
          ));
          return await app.db.gamesDao.getByRawgId(42);
        }
        await app.db.moviesDao.insertMovie(TrackedMoviesCompanion(
          tmdbId: const Value(42),
          title: const Value('Sconosciuto'),
          status: const Value(MediaStatus.completed),
          addedAt: Value(DateTime(2020)),
          userRating: const Value(7.0),
          updatedAt: Value(DateTime(2021)),
        ));
        return await app.db.moviesDao.getByTmdbId(42);
      });
      // Il post-frame apre una transazione SQLite: avviarlo nella zona
      // asincrona reale, come i timer watched nei test delle serie. Altrimenti
      // la lettura-barriera di flush aspetta una transazione il cui callback è
      // fermo nella zona fake, producendo un deadlock solo nel test.
      await tester.runAsync(() => tester.pumpWidget(UncontrolledProviderScope(
            container: app.container,
            child: MaterialApp(
                theme: AppTheme.dark(),
                home:
                    games ? const GamesListScreen() : const MoviesListScreen()),
          )));
      await tester.runAsync(() async {
        if (games) {
          await app.db.gamesDao.watchAll().firstWhere(
              (rows) => rows.any((row) => row.title == 'Titolo recuperato'));
        } else {
          await app.db.moviesDao.watchAll().firstWhere(
              (rows) => rows.any((row) => row.title == 'Titolo recuperato'));
        }
      });
      await app.flush(tester);
      expect(find.text('Titolo recuperato'), findsOneWidget);
      expect(find.text('Sconosciuto'), findsNothing);
      final dynamic old = before;
      final dynamic after = await tester.runAsync(() async => games
          ? await app.db.gamesDao.getByRawgId(42)
          : await app.db.moviesDao.getByTmdbId(42));
      expect(after.id, old.id);
      expect(after.status, old.status);
      expect(after.userRating, old.userRating);
      expect(after.addedAt, old.addedAt);
      expect(after.updatedAt, old.updatedAt);
      expect(tester.takeException(), isNull);
    });
  }
}
