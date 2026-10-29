import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/features/series/data/models/anilist_media.dart';
import 'package:showtracker/features/series/data/models/normalized_anime_season.dart';

void main() {
  late AppDatabase db;

  NormalizedAnimeSeason season(int number,
          {int count = 12,
          String status = 'FINISHED',
          AniListNextAiring? nextAiring}) =>
      NormalizedAnimeSeason(
        seasonNumber: number,
        tmdbSeasonNumber: 1,
        anilistId: 100 + number,
        episodeCount: count,
        status: status,
        season: 'FALL',
        seasonYear: 2026,
        titleRomaji: 'Titolo originale',
        titleEnglish: 'English title',
        averageScore: 85,
        nextAiringEpisode: nextAiring,
        streamingEpisodes: const [
          AniListStreamingEpisode(title: 'Pilota', thumbnail: '/thumb.jpg'),
        ],
      );

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('cache mancante non è fresca, stale o prossima a scadere', () async {
    expect(await db.animeCacheDao.getFreshAnimeSeasons(1), isNull);
    expect(await db.animeCacheDao.getStaleAnimeSeasons(1), isNull);
    expect(await db.animeCacheDao.getYunaIds(1), isNull);
    expect(await db.animeCacheDao.isNearExpiry(1), isFalse);
  });

  test('round-trip JSON completo con ordine cour e TTL specifico', () async {
    final airing = AniListNextAiring(
        episode: 4,
        airingAt: DateTime.now()
                .add(const Duration(days: 2))
                .millisecondsSinceEpoch ~/
            1000,
        timeUntilAiring: 172800);
    final releasing = season(2, status: 'RELEASING', nextAiring: airing);
    final finished = season(1);
    await db.animeCacheDao.saveAnimeSeasons(1, [releasing, finished]);
    final fresh = (await db.animeCacheDao.getFreshAnimeSeasons(1))!;
    expect(
        fresh.map((s) => s.toJson()), [finished.toJson(), releasing.toJson()]);
    final rows = await (db.select(db.animeSeasonCache)
          ..orderBy([(t) => OrderingTerm.asc(t.seasonNumber)]))
        .get();
    expect(rows.first.validUntil.difference(rows.first.cachedAt),
        const Duration(days: 30));
    expect(
        (rows.last.validUntil.millisecondsSinceEpoch - airing.airingAt * 1000)
            .abs(),
        lessThanOrEqualTo(1000));
    expect(await db.animeCacheDao.isNearExpiry(1), isFalse);
  });

  test('upsert composto aggiorna righe esistenti e rimuove cour obsolete',
      () async {
    await db.animeCacheDao
        .saveAnimeSeasons(1, [season(1), season(2), season(3)]);
    await db.animeCacheDao.saveAnimeSeasons(2, [season(1), season(2)]);
    final before = await (db.select(db.animeSeasonCache)
          ..where((t) => t.tmdbShowId.equals(1) & t.seasonNumber.equals(1)))
        .getSingle();
    await db.animeCacheDao.expireAnimeCacheForShow(1);
    await db.animeCacheDao
        .saveAnimeSeasons(1, [season(1, count: 13), season(2)]);
    final fresh = (await db.animeCacheDao.getFreshAnimeSeasons(1))!;
    expect(fresh.map((s) => s.episodeCount), [13, 12]);
    final after = await (db.select(db.animeSeasonCache)
          ..where((t) => t.tmdbShowId.equals(1) & t.seasonNumber.equals(1)))
        .getSingle();
    expect(after.id, before.id);
    expect(after.episodeCount, 13);
    expect(after.validUntil.isAfter(DateTime.now()), isTrue);
    expect(await db.select(db.animeSeasonCache).get(), hasLength(4));
    expect(
        (await db.animeCacheDao.getFreshAnimeSeasons(2))!
            .map((s) => s.episodeCount),
        [12, 12]);
  });

  test('una cour scaduta invalida tutto il set ma stale le conserva tutte',
      () async {
    await db.animeCacheDao.saveAnimeSeasons(1, [season(1), season(2)]);
    await (db.update(db.animeSeasonCache)
          ..where((t) => t.tmdbShowId.equals(1) & t.seasonNumber.equals(2)))
        .write(
            AnimeSeasonCacheCompanion(validUntil: Value(DateTime.utc(2000))));
    expect(await db.animeCacheDao.getFreshAnimeSeasons(1), isNull);
    expect(
        (await db.animeCacheDao.getStaleAnimeSeasons(1))!
            .map((s) => s.seasonNumber),
        [1, 2]);
    expect(await db.animeCacheDao.isNearExpiry(1), isTrue);
  });

  test('scadenza manuale preserva fallback e invalida Yuna solo per la serie',
      () async {
    await db.animeCacheDao.saveAnimeSeasons(1, [season(1), season(2)]);
    await db.animeCacheDao.saveAnimeSeasons(2, [season(1)]);
    await db.animeCacheDao.saveYunaIds(1, [101, 102]);
    await db.animeCacheDao.saveYunaIds(2, [201]);
    final before = await db.animeCacheDao.getStaleAnimeSeasons(1);
    await db.animeCacheDao.expireAnimeCacheForShow(1);
    await db.animeCacheDao.expireAnimeCacheForShow(1);
    expect(await db.animeCacheDao.getFreshAnimeSeasons(1), isNull);
    expect(
        (await db.animeCacheDao.getStaleAnimeSeasons(1))!
            .map((s) => s.toJson()),
        before!.map((s) => s.toJson()));
    expect(await db.animeCacheDao.getYunaIds(1), isNull);
    expect(await db.animeCacheDao.getYunaIds(2), [201]);
    expect(await db.animeCacheDao.getFreshAnimeSeasons(2), hasLength(1));
    expect(await db.select(db.yunaCache).get(), hasLength(2));
    expect(await db.select(db.animeSeasonCache).get(), hasLength(3));
  });

  test('Yuna upsert, lista vuota e TTL sette giorni', () async {
    await db.animeCacheDao.saveYunaIds(1, [100]);
    await db.animeCacheDao.saveYunaIds(1, [101, 102]);
    await db.animeCacheDao.saveYunaIds(2, []);
    expect(await db.animeCacheDao.getYunaIds(1), [101, 102]);
    expect(await db.animeCacheDao.getYunaIds(2), isEmpty);
    expect(await db.select(db.yunaCache).get(), hasLength(2));
    await (db.update(db.yunaCache)..where((t) => t.tmdbId.equals(1))).write(
        YunaCacheCompanion(
            cachedAt: Value(DateTime.now().subtract(const Duration(days: 8)))));
    expect(await db.animeCacheDao.getYunaIds(1), isNull);
    expect(await db.animeCacheDao.getYunaIds(2), isEmpty);
  });

  test('near expiry usa la prima cour a scadere e supera 80 percento',
      () async {
    await db.animeCacheDao.saveAnimeSeasons(1, [season(1), season(2)]);
    final now = DateTime.now();
    await (db.update(db.animeSeasonCache)
          ..where((t) => t.seasonNumber.equals(2)))
        .write(AnimeSeasonCacheCompanion(
      cachedAt: Value(now.subtract(const Duration(days: 9))),
      validUntil: Value(now.add(const Duration(days: 1))),
    ));
    expect(await db.animeCacheDao.isNearExpiry(1), isTrue);
    await (db.update(db.animeSeasonCache)
          ..where((t) => t.seasonNumber.equals(2)))
        .write(AnimeSeasonCacheCompanion(
      cachedAt: Value(now.subtract(const Duration(days: 1))),
      validUntil: Value(now.add(const Duration(days: 9))),
    ));
    expect(await db.animeCacheDao.isNearExpiry(1), isFalse);
  });
}
