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
