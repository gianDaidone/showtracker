import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/models/sync_payload.dart';

/// Checkpoint e importazione condividono la stessa transazione SQLite.
class SyncJobStore {
  SyncJobStore(this.db);
  final AppDatabase db;

  Future<List<int>> unfinishedSessions() async => (await db.customSelect(
        "SELECT DISTINCT session_id FROM sync_items WHERE status NOT IN ('completed', 'removed') ORDER BY session_id",
        readsFrom: {db.syncItems},
      ).get())
          .map((r) => r.read<int>('session_id'))
          .toList();

  Future<int?> latestSession() async => (await (db.select(db.syncSessions)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingleOrNull())
      ?.id;

  Future<int> record(SyncPayload payload, String fingerprint) async {
    final session = await db.into(db.syncSessions).insert(
          SyncSessionsCompanion.insert(
            fingerprint: fingerprint,
            createdAt: DateTime.now(),
          ),
        );
    final shows = {
      for (final row in await db.showsDao.getAll()) row.tmdbId: row
    };
    final movies = {
      for (final row in await db.moviesDao.watchAll().first) row.tmdbId: row
    };
    final games = {
      for (final row in await db.gamesDao.watchAll().first) row.rawgId: row
    };
    final rows = <SyncItemsCompanion>[
      for (final key in payload.shows.keys)
        SyncItemsCompanion.insert(
          sessionId: session,
          domain: 'shows',
          externalId: int.parse(key),
          localId: shows[int.parse(key)]!.id,
          title: Value(shows[int.parse(key)]!.title),
          progressData: Value(jsonEncode(payload.shows[key]!.toJson())),
        ),
      for (final key in payload.movies.keys)
        SyncItemsCompanion.insert(
          sessionId: session,
          domain: 'movies',
          externalId: int.parse(key),
          localId: movies[int.parse(key)]!.id,
          title: Value(movies[int.parse(key)]!.title),
        ),
      for (final key in payload.games.keys)
        SyncItemsCompanion.insert(
          sessionId: session,
          domain: 'games',
          externalId: int.parse(key),
          localId: games[int.parse(key)]!.id,
          title: Value(games[int.parse(key)]!.title),
        ),
    ];
    await db.batch((b) => b.insertAll(db.syncItems, rows));
    return session;
  }

  Future<List<SyncItem>> items(int session) => (db.select(db.syncItems)
        ..where((t) => t.sessionId.equals(session))
        ..orderBy([(t) => OrderingTerm.asc(t.id)]))
      .get();

  Future<List<SyncItem>> itemsByIds(List<int> ids) async {
    final rows = <SyncItem>[];
    for (var start = 0; start < ids.length; start += 900) {
      rows.addAll(await (db.select(db.syncItems)
            ..where((t) => t.id.isIn(ids.skip(start).take(900))))
          .get());
    }
    return rows;
  }

  Future<void> update(int id, String status, {String? title, String? error}) =>
      (db.update(db.syncItems)..where((t) => t.id.equals(id))).write(
        SyncItemsCompanion(
            status: Value(status),
            error: Value(error),
            title: title == null ? const Value.absent() : Value(title)),
      );
}

extension SyncItemState on SyncItem {
  bool get syncCompleted =>
      status == 'completed' || status == 'completed_notice';
  bool get syncRemoved => status == 'removed' || status == 'removed_notice';
  bool get syncDeferred => status == 'deferred' || status == 'deferred_ack';
  bool get syncNeedsAcknowledgement =>
      status == 'deferred' || status.endsWith('_notice');
  bool get syncTerminal => syncCompleted || syncRemoved;
}
