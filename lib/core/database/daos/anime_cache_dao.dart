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
        final row = AnimeSeasonCacheCompanion(
          tmdbShowId: Value(tmdbShowId),
          seasonNumber: Value(s.seasonNumber),
          anilistId: Value(s.anilistId),
          episodeCount: Value(s.episodeCount),
          status: Value(s.status),
          animeSeasonJson: Value(jsonEncode(s.toJson())),
          cachedAt: Value(now),
          validUntil: Value(validUntil),
        );
        // Il conflitto va cercato sulla chiave unica (show, stagione), non
        // sulla chiave primaria `id`, che è autoincrementale e non coincide
        // mai: `insertOnConflictUpdate` usa quella, e su una riga già presente
        // fallirebbe con UNIQUE constraint failed. Da quando la cache si fa
        // scadere invece di cancellarla la riga c'è sempre, quindi ogni
        // refresh falliva e l'app restava sui dati del primo download.
        await into(animeSeasonCache).insert(
          row,
          onConflict: DoUpdate(
            (_) => row,
            target: [animeSeasonCache.tmdbShowId, animeSeasonCache.seasonNumber],
          ),
        );
      }
      // Cour che non esistono più nei dati nuovi (es. un aggancio AniList
      // sbagliato che ne produceva di più): lasciarli farebbe convivere
      // stagioni vecchie e nuove. Qui il download è riuscito, quindi non
      // rischiamo di perdere l'unico fallback.
      await (delete(animeSeasonCache)
            ..where((t) =>
                t.tmdbShowId.equals(tmdbShowId) &
                t.seasonNumber.isBiggerThanValue(seasons.length)))
          .go();
    });
  }

  /// Marca come scaduta la cache anime (Yuna mapping + season cache) di uno
  /// show, senza cancellarla.
  ///
  /// È ciò che serve al refresh manuale, richiesto quando AniList ha aggiunto
  /// stagioni ma il record in cache è ancora valido: la prossima lettura è un
  /// miss garantito, quindi si rifetcha da Yuna + AniList, ma se il fetch
  /// fallisce `getStaleAnimeSeasons` ha ancora qualcosa da restituire.
  ///
  /// Cancellare le righe distrugge l'unico fallback: con AniList irraggiungibile
  /// la serie ricade sulle stagioni TMDB grezze e perde cours, etichette
  /// ("Stagione 1 Parte 1 · Fall 2017") e conteggi — in modo irreversibile
  /// finché il servizio non torna.
  Future<void> expireAnimeCacheForShow(int tmdbId) async {
    final expired = DateTime.fromMillisecondsSinceEpoch(0);
    await transaction(() async {
      await (update(animeSeasonCache)
            ..where((t) => t.tmdbShowId.equals(tmdbId)))
          .write(AnimeSeasonCacheCompanion(validUntil: Value(expired)));
      await (update(yunaCache)..where((t) => t.tmdbId.equals(tmdbId)))
          .write(YunaCacheCompanion(cachedAt: Value(expired)));
    });
  }
}
