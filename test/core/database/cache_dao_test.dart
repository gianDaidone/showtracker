import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  CachedEpisodesCompanion episode(int show, int season, int number,
          {DateTime? cachedAt, String name = 'Episodio'}) =>
      CachedEpisodesCompanion(
        tmdbShowId: Value(show),
        seasonNumber: Value(season),
        episodeNumber: Value(number),
        name: Value(name),
        overview: const Value('Trama'),
        stillPath: const Value('/still.jpg'),
        airDate: const Value('2026-10-01'),
        voteAverage: const Value(8.5),
        absoluteEpisodeNumber: Value(12 + number),
        airingAt: Value(DateTime.utc(2026, 10, 1, 15)),
        cachedAt: Value(cachedAt ?? DateTime.now()),
      );

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('cache assente restituisce liste vuote', () async {
    expect(await db.cacheDao.getFreshSeasonEpisodes(1, 1), isEmpty);
    expect(await db.cacheDao.getSeasonEpisodesIgnoringTtl(1, 1), isEmpty);
    await db.cacheDao.clearCacheForShow(1);
  });

  test('round-trip completo ordinato e isolato per serie/stagione', () async {
    await db.cacheDao.saveSeasonEpisodes([
      episode(1, 1, 2),
      episode(2, 1, 1),
      episode(1, 2, 1),
      episode(1, 1, 1),
    ]);
    final rows = await db.cacheDao.getFreshSeasonEpisodes(1, 1);
    expect(rows.map((e) => e.episodeNumber), [1, 2]);
    final first = rows.first;
    expect(first.tmdbShowId, 1);
    expect(first.seasonNumber, 1);
    expect(first.name, 'Episodio');
    expect(first.overview, 'Trama');
    expect(first.stillPath, '/still.jpg');
    expect(first.airDate, '2026-10-01');
    expect(first.voteAverage, 8.5);
    expect(first.absoluteEpisodeNumber, 13);
    expect(first.airingAt!.toUtc(), DateTime.utc(2026, 10, 1, 15));
    expect(await db.cacheDao.getFreshSeasonEpisodes(2, 1), hasLength(1));
    expect(await db.cacheDao.getFreshSeasonEpisodes(1, 2), hasLength(1));
  });

  test('upsert sulla chiave composta sostituisce dati e null espliciti',
      () async {
    await db.cacheDao.saveSeasonEpisodes([
      episode(1, 1, 1),
      episode(1, 1, 2),
      episode(1, 2, 1),
      episode(2, 1, 1),
    ]);
    await db.cacheDao.saveSeasonEpisodes([
      episode(1, 1, 1, name: 'Nome corretto').copyWith(
        overview: const Value(null),
        stillPath: const Value(null),
        airingAt: const Value(null),
        absoluteEpisodeNumber: const Value(null),
      ),
    ]);
    final rows = await db.cacheDao.getFreshSeasonEpisodes(1, 1);
    expect(rows, hasLength(2));
    expect(rows.first.name, 'Nome corretto');
    expect(rows.first.overview, null);
    expect(rows.first.stillPath, null);
    expect(rows.first.airingAt, null);
    expect(rows.first.absoluteEpisodeNumber, null);
    expect(await db.select(db.cachedEpisodes).get(), hasLength(4));
    expect((await db.cacheDao.getFreshSeasonEpisodes(1, 2)).single.name,
        'Episodio');
    expect((await db.cacheDao.getFreshSeasonEpisodes(2, 1)).single.name,
        'Episodio');
  });

  test('TTL configurabile e fallback ignora scadenza senza cancellare',
      () async {
    await db.cacheDao.saveSeasonEpisodes([
      episode(1, 1, 1,
          cachedAt: DateTime.now().subtract(const Duration(days: 10))),
    ]);
    expect(await db.cacheDao.getFreshSeasonEpisodes(1, 1), isEmpty);
    expect(
        await db.cacheDao
            .getFreshSeasonEpisodes(1, 1, ttl: const Duration(days: 30)),
        hasLength(1));
    expect(await db.cacheDao.getSeasonEpisodesIgnoringTtl(1, 1), hasLength(1));
    await db.cacheDao.saveSeasonEpisodes([episode(1, 1, 1, name: 'Fresco')]);
    expect(
        (await db.cacheDao.getFreshSeasonEpisodes(1, 1)).single.name, 'Fresco');
  });

  test('expire conserva tutti i payload e fa scadere solo la serie richiesta',
      () async {
    await db.cacheDao.saveSeasonEpisodes([
      episode(1, 1, 1),
      episode(1, 1, 2),
      episode(1, 2, 1),
      episode(2, 1, 1),
    ]);
    final before = await db.select(db.cachedEpisodes).get();

    await db.cacheDao.expireCacheForShow(1);
    await db.cacheDao.expireCacheForShow(1);
    await db.cacheDao.expireCacheForShow(999);

    final after = await db.select(db.cachedEpisodes).get();
    expect(after, hasLength(before.length));
    for (final original in before) {
      final saved = after.singleWhere((row) => row.id == original.id);
      if (original.tmdbShowId == 1) {
        expect(saved.cachedAt.millisecondsSinceEpoch, 0);
        expect(saved.copyWith(cachedAt: original.cachedAt), original);
      } else {
        expect(saved, original);
      }
    }
    expect(await db.cacheDao.getFreshSeasonEpisodes(1, 1), isEmpty);
    expect(await db.cacheDao.getFreshSeasonEpisodes(1, 2), isEmpty);
    expect(await db.cacheDao.getSeasonEpisodesIgnoringTtl(1, 1), hasLength(2));
    expect(await db.cacheDao.getSeasonEpisodesIgnoringTtl(1, 2), hasLength(1));
    expect(await db.cacheDao.getFreshSeasonEpisodes(2, 1), hasLength(1));

    await db.cacheDao
        .saveSeasonEpisodes([episode(1, 1, 1, name: 'Aggiornato')]);
    final fresh = await db.cacheDao.getFreshSeasonEpisodes(1, 1);
    expect(fresh, hasLength(1));
    expect(fresh.single.name, 'Aggiornato');
    expect(await db.cacheDao.getSeasonEpisodesIgnoringTtl(1, 1), hasLength(2));
  });

  test('snapshot completo riduce da 13 a 12 senza toccare altre stagioni',
      () async {
    await db.cacheDao.saveSeasonEpisodes([
      for (var number = 1; number <= 13; number++) episode(1, 1, number),
      episode(1, 2, 1),
      episode(2, 1, 1),
    ]);
    await db.cacheDao.expireCacheForShow(1);
    final before = await db.select(db.cachedEpisodes).get();
    expect(await db.cacheDao.getFreshSeasonEpisodes(1, 1), isEmpty);
    expect(await db.cacheDao.getSeasonEpisodesIgnoringTtl(1, 1), hasLength(13));

    await db.cacheDao.replaceSeasonEpisodes(1, 1, [
      for (var number = 1; number <= 12; number++)
        episode(1, 1, number, name: 'Aggiornato $number'),
    ]);

    final fresh = await db.cacheDao.getFreshSeasonEpisodes(1, 1);
    expect(
        fresh.map((row) => row.episodeNumber), List.generate(12, (i) => i + 1));
    expect(fresh.last.name, 'Aggiornato 12');
    expect(await db.cacheDao.getSeasonEpisodesIgnoringTtl(1, 1), hasLength(12));
    final otherRows = (await db.select(db.cachedEpisodes).get())
        .where((row) => row.tmdbShowId != 1 || row.seasonNumber != 1);
    expect(
      otherRows,
      unorderedEquals(
          before.where((row) => row.tmdbShowId != 1 || row.seasonNumber != 1)),
    );
  });

  test('snapshot fallito ripristina tutti i payload scaduti e gli id',
      () async {
    await db.cacheDao.saveSeasonEpisodes([
      for (var number = 1; number <= 13; number++) episode(1, 1, number),
      episode(1, 2, 1),
      episode(2, 1, 1),
    ]);
    await db.cacheDao.expireCacheForShow(1);
    final before = await db.select(db.cachedEpisodes).get();
    await db.customStatement('''
      CREATE TRIGGER reject_episode_snapshot
      BEFORE INSERT ON cached_episodes
      WHEN NEW.tmdb_show_id = 1 AND NEW.season_number = 1
        AND NEW.episode_number = 12
      BEGIN
        SELECT RAISE(ABORT, 'snapshot non salvabile');
      END
    ''');

    await expectLater(
      db.cacheDao.replaceSeasonEpisodes(1, 1, [
        for (var number = 1; number <= 12; number++)
          episode(1, 1, number, name: 'Da annullare'),
      ]),
      throwsA(isA<Exception>()),
    );

    expect(await db.select(db.cachedEpisodes).get(), unorderedEquals(before));
    expect(await db.cacheDao.getFreshSeasonEpisodes(1, 1), isEmpty);
    expect(await db.cacheDao.getSeasonEpisodesIgnoringTtl(1, 1), hasLength(13));
  });

  test('snapshot rifiuta righe di un altro target o prive del target',
      () async {
    await db.cacheDao.saveSeasonEpisodes([episode(1, 1, 1)]);
    final before = await db.select(db.cachedEpisodes).get();
    for (final invalid in [
      episode(2, 1, 2),
      episode(1, 2, 2),
      episode(1, 1, 2).copyWith(tmdbShowId: const Value.absent()),
      episode(1, 1, 2).copyWith(seasonNumber: const Value.absent()),
    ]) {
      await expectLater(
        db.cacheDao.replaceSeasonEpisodes(1, 1, [episode(1, 1, 1), invalid]),
        throwsArgumentError,
      );
      expect(await db.select(db.cachedEpisodes).get(), unorderedEquals(before));
    }
  });

  test('snapshot vuoto esplicito svuota solo la stagione richiesta', () async {
    await db.cacheDao.saveSeasonEpisodes([
      episode(1, 1, 1),
      episode(1, 2, 1),
      episode(2, 1, 1),
    ]);
    await db.cacheDao.replaceSeasonEpisodes(1, 1, []);
    expect(await db.cacheDao.getSeasonEpisodesIgnoringTtl(1, 1), isEmpty);
    expect(await db.cacheDao.getSeasonEpisodesIgnoringTtl(1, 2), hasLength(1));
    expect(await db.cacheDao.getSeasonEpisodesIgnoringTtl(2, 1), hasLength(1));
  });

  test('clear elimina tutte le stagioni della sola serie richiesta', () async {
    await db.cacheDao.saveSeasonEpisodes([
      episode(1, 1, 1),
      episode(1, 2, 1),
      episode(2, 1, 1),
    ]);
    await db.cacheDao.clearCacheForShow(1);
    await db.cacheDao.clearCacheForShow(1);
    expect(await db.cacheDao.getSeasonEpisodesIgnoringTtl(1, 1), isEmpty);
    expect(await db.cacheDao.getSeasonEpisodesIgnoringTtl(1, 2), isEmpty);
    expect(await db.cacheDao.getFreshSeasonEpisodes(2, 1), hasLength(1));
  });

  test('salvataggio batch è atomico se una riga non è valida', () async {
    await db.cacheDao.saveSeasonEpisodes([episode(1, 1, 1)]);
    await expectLater(
        db.cacheDao.saveSeasonEpisodes([
          episode(1, 1, 1, name: 'Da annullare'),
          episode(1, 1, 2).copyWith(name: const Value.absent()),
        ]),
        throwsA(isA<Exception>()));
    final saved = await db.cacheDao.getSeasonEpisodesIgnoringTtl(1, 1);
    expect(saved, hasLength(1));
    expect(saved.single.name, 'Episodio');
  });
}
