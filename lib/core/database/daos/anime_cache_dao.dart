import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../../features/series/data/models/normalized_anime_season.dart';

part 'anime_cache_dao.g.dart';

@DriftAccessor(tables: [YunaCache, AnimeSeasonCache])
class AnimeCacheDao extends DatabaseAccessor<AppDatabase>
    with _$AnimeCacheDaoMixin {
  AnimeCacheDao(super.db);

  // ── Yuna mapping ──────────────────────────────────────────────────────────

  Future<List<int>?> getYunaIds(int tmdbId) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final row = await (select(yunaCache)
          ..where((t) =>
              t.tmdbId.equals(tmdbId) & t.cachedAt.isBiggerThanValue(cutoff)))
        .getSingleOrNull();
    if (row == null) return null;
    return (jsonDecode(row.anilistIdsJson) as List<dynamic>).cast<int>();
  }

  Future<void> saveYunaIds(int tmdbId, List<int> ids) async {
    await into(yunaCache).insertOnConflictUpdate(YunaCacheCompanion(
      tmdbId: Value(tmdbId),
      anilistIdsJson: Value(jsonEncode(ids)),
      cachedAt: Value(DateTime.now()),
    ));
  }

  // ── Anime season cache ────────────────────────────────────────────────────

  /// Returns cached seasons if ALL are still valid (validUntil > now).
  /// Returns null if the cache is missing or any season has expired.
  Future<List<NormalizedAnimeSeason>?> getFreshAnimeSeasons(
      int tmdbShowId) async {
    final now = DateTime.now();
    // Ottieni tutte le stagioni in cache per questo show
    final rows = await _seasonRows(tmdbShowId);

    if (rows.isEmpty) return null;

    // Se anche solo una stagione è scaduta, invalida tutta la cache.
    // Questo previene il bug in cui una stagione in corso scade prima delle
    // stagioni concluse, scomparendo silenziosamente dall'interfaccia.
    if (rows.any((r) => r.validUntil.isBefore(now) || r.validUntil.isAtSameMomentAs(now))) {
      return null;
    }

    return rows.map(_decodeSeason).toList();
  }

  /// Come [getFreshAnimeSeasons] ma ignora la scadenza.
  ///
  /// Serve da fallback offline-first quando il refresh da Yuna/AniList
  /// fallisce: dati stantii sono molto meglio di nessun dato. Senza AniList la
  /// serie ricadrebbe sulla suddivisione in stagioni di TMDB, che per gli anime
  /// raggruppa più cours in una sola stagione e usa quindi numeri di stagione
  /// incompatibili con quelli con cui sono salvati gli episodi visti.
  Future<List<NormalizedAnimeSeason>?> getStaleAnimeSeasons(
      int tmdbShowId) async {
    final rows = await _seasonRows(tmdbShowId);
    if (rows.isEmpty) return null;
    return rows.map(_decodeSeason).toList();
  }

  Future<List<AnimeSeasonCacheData>> _seasonRows(int tmdbShowId) =>
      (select(animeSeasonCache)
            ..where((t) => t.tmdbShowId.equals(tmdbShowId))
            ..orderBy([(t) => OrderingTerm.asc(t.seasonNumber)]))
          .get();

  NormalizedAnimeSeason _decodeSeason(AnimeSeasonCacheData row) =>
      NormalizedAnimeSeason.fromJson(
          jsonDecode(row.animeSeasonJson) as Map<String, dynamic>);

  /// True if the earliest-expiring season has consumed >80% of its TTL.
  Future<bool> isNearExpiry(int tmdbShowId) async {
    final rows = await (select(animeSeasonCache)
          ..where((t) => t.tmdbShowId.equals(tmdbShowId))
          ..orderBy([(t) => OrderingTerm.asc(t.validUntil)])
          ..limit(1))
        .get();
    if (rows.isEmpty) return false;
    final r = rows.first;
    final totalMs =
        r.validUntil.difference(r.cachedAt).inMilliseconds;
    if (totalMs <= 0) return true;
    final elapsedMs =
        DateTime.now().difference(r.cachedAt).inMilliseconds;
    return elapsedMs / totalMs > 0.8;
  }

  Future<void> saveAnimeSeasons(
      int tmdbShowId, List<NormalizedAnimeSeason> seasons) async {
    await transaction(() async {
      for (final s in seasons) {
        final now = DateTime.now();
        final validUntil = now.add(s.cacheTtl);
        await into(animeSeasonCache).insertOnConflictUpdate(
          AnimeSeasonCacheCompanion(
            tmdbShowId: Value(tmdbShowId),
            seasonNumber: Value(s.seasonNumber),
            anilistId: Value(s.anilistId),
            episodeCount: Value(s.episodeCount),
            status: Value(s.status),
            animeSeasonJson: Value(jsonEncode(s.toJson())),
            cachedAt: Value(now),
            validUntil: Value(validUntil),
          ),
        );
      }
    });
  }

  /// Cancella tutta la cache anime (Yuna mapping + season cache) per un dato
  /// show. Usato quando AniList ha aggiunto nuove stagioni ma il record in
  /// cache è ancora valido e non si rifresca da solo.
  Future<void> clearAnimeCacheForShow(int tmdbId) async {
    await transaction(() async {
      await (delete(animeSeasonCache)
            ..where((t) => t.tmdbShowId.equals(tmdbId)))
          .go();
      await (delete(yunaCache)..where((t) => t.tmdbId.equals(tmdbId))).go();
    });
  }
}
