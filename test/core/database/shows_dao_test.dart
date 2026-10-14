import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int showId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    showId = await db.showsDao.insertShow(TrackedShowsCompanion(
      tmdbId: const Value(73223),
      title: const Value('Black Clover'),
      status: const Value(MediaStatus.watching),
      addedAt: Value(DateTime(2026, 10, 1)),
    ));
  });

  tearDown(() => db.close());

  group('ShowsDao.insertSeasons', () {
    test('aggiorna le stagioni già salvate invece di fallire', () async {
      await db.showsDao.insertSeasons(showId, {1: 12, 2: 2});

      // Un nuovo episodio della stagione 2 in onda: prima del fix questo
      // falliva con UNIQUE constraint failed e il conteggio restava 2.
      await db.showsDao.insertSeasons(showId, {1: 12, 2: 3});

      expect(await db.showsDao.getSeasonCounts(showId), {1: 12, 2: 3});
    });

    test('aggiunge le stagioni nuove accanto a quelle esistenti', () async {
      await db.showsDao.insertSeasons(showId, {1: 12});
      await db.showsDao.insertSeasons(showId, {1: 12, 2: 1});

      expect(await db.showsDao.getSeasonCounts(showId), {1: 12, 2: 1});
    });
  });
}
