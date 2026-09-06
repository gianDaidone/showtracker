import 'package:drift/drift.dart';
import '../app_database.dart';

part 'cache_dao.g.dart';

@DriftAccessor(tables: [CachedEpisodes])
class CacheDao extends DatabaseAccessor<AppDatabase> with _$CacheDaoMixin {
  CacheDao(super.db);

  /// Restituisce gli episodi di una stagione se presenti in cache e non scaduti.
  /// [ttl] determina per quanto tempo i dati sono considerati freschi;
  /// la durata viene calcolata in base allo stato TMDB della serie (smart TTL).
  /// Lista vuota se assente o scaduta.
  Future<List<CachedEpisode>> getFreshSeasonEpisodes(
    int tmdbShowId,
    int seasonNumber, {
    Duration ttl = const Duration(days: 7),
  }) async {
    final cutoff = DateTime.now().subtract(ttl);
    return (select(cachedEpisodes)
          ..where(
            (t) =>
                t.tmdbShowId.equals(tmdbShowId) &
                t.seasonNumber.equals(seasonNumber) &
                t.cachedAt.isBiggerThanValue(cutoff),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.episodeNumber)]))
        .get();
  }

  /// Come [getFreshSeasonEpisodes] ma ignora la scadenza.
  ///
  /// Serve a decidere offline se un episodio è già andato in onda: la data di
  /// messa in onda è la parte più stabile del payload TMDB, quindi un dato
  /// stantio è comunque molto meglio di nessun dato (e ci evita di scatenare
  /// una richiesta di rete solo per contare le card della lista "Da Vedere").
  Future<List<CachedEpisode>> getSeasonEpisodesIgnoringTtl(
    int tmdbShowId,
    int seasonNumber,
  ) =>
      (select(cachedEpisodes)
            ..where(
              (t) =>
                  t.tmdbShowId.equals(tmdbShowId) &
                  t.seasonNumber.equals(seasonNumber),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.episodeNumber)]))
          .get();

  /// Salva (o aggiorna) i dettagli degli episodi di una stagione in cache.
  Future<void> saveSeasonEpisodes(List<CachedEpisodesCompanion> rows) async {
    await transaction(() async {
      for (final row in rows) {
        await into(cachedEpisodes)
            .insert(row, mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Rimuove tutti gli episodi in cache per una specifica serie (utile per refresh manuali).
  Future<void> clearCacheForShow(int tmdbShowId) async {
    await (delete(cachedEpisodes)..where((t) => t.tmdbShowId.equals(tmdbShowId))).go();
  }
}
