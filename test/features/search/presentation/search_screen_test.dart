import 'package:drift/drift.dart' hide isNull;
import 'package:showtracker/core/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/paged_search.dart';
import 'package:showtracker/core/theme/app_theme.dart';
import 'package:showtracker/features/search/data/discover_rules.dart';
import 'package:showtracker/features/search/presentation/discover_view.dart';
import 'package:showtracker/features/search/presentation/search_screen.dart';
import 'package:showtracker/features/search/providers/discover_providers.dart';
import 'package:showtracker/features/series/data/models/tmdb_show.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';

import '../../../support/app_test_harness.dart';

void main() {
  testWidgets('discovery riprova e nasconde i titoli aggiunti senza refetch',
      (tester) async {
    var requests = 0;
    final app = (await tester.runAsync(() => AppTestHarness.create(overrides: [
          showDiscoverProvider(DiscoverList.trending).overrideWith(
            () => PagedListNotifier<TmdbShow>(
              (_) => (page) async {
                requests++;
                if (requests == 1) throw StateError('offline di prova');
                return const SearchPage(
                  items: [TmdbShow(id: 42, name: 'Serie da scoprire')],
                  hasMore: false,
                );
              },
              (show) => show.id,
            ),
          ),
        ])))!;
    addTearDown(() => app.dispose(tester));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: app.container,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SearchScreen(initialFilter: 'series'),
      ),
    ));
    await app.flush(tester);
    expect(find.text('Riprova'), findsOneWidget);
    expect(requests, 1);
    await tester.tap(find.text('Riprova'));
    await app.flush(tester);
    expect(find.text('Serie da scoprire'), findsOneWidget);
    expect(requests, 2);
    await tester.runAsync(() => app.db.showsDao.insertShow(
          TrackedShowsCompanion(
            tmdbId: const Value(42),
            title: const Value('Serie da scoprire'),
            status: const Value(MediaStatus.planToWatch),
            addedAt: Value(DateTime(2026, 1, 1)),
          ),
        ));
    await app.flush(tester);
    expect(find.text('Serie da scoprire'), findsNothing);
    expect(requests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('query vuota, debounce e clear non fanno richieste inutili',
      (tester) async {
    final queries = <String>[];
    var discoveries = 0;
    final app = (await tester.runAsync(() => AppTestHarness.create(overrides: [
          showDiscoverProvider(DiscoverList.trending).overrideWith(
            () => PagedListNotifier<TmdbShow>(
              (_) => (page) async {
                discoveries++;
                return const SearchPage(items: [], hasMore: false);
              },
              (show) => show.id,
            ),
          ),
          showSearchProvider.overrideWith2((query) => PagedSearchNotifier(
                query,
                (_) => (q, page) async {
                  queries.add(q);
                  return const SearchPage<TmdbShow>(items: [], hasMore: false);
                },
                (show) => show.id,
              )),
        ])))!;
    addTearDown(() => app.dispose(tester));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: app.container,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SearchScreen(initialFilter: 'series'),
      ),
    ));
    await app.flush(tester);
    expect(find.byType(DiscoverView), findsOneWidget);
    expect(discoveries, 1);
    expect(queries, isEmpty);

    await tester.enterText(find.byType(TextField), 'z');
    await tester.pump(const Duration(milliseconds: 500));
    expect(queries, isEmpty);
    await tester.enterText(find.byType(TextField), 'zel');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'zelda');
    await tester.pump(const Duration(milliseconds: 399));
    expect(queries, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    await app.flush(tester);
    expect(queries, ['zelda']);
    expect(find.byType(DiscoverView), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await app.flush(tester);
    expect(find.byType(DiscoverView), findsOneWidget);
    expect(queries, ['zelda']);
    expect(tester.takeException(), isNull);
  });
}
