import 'package:drift/drift.dart';
import '../app_database.dart';

part 'cache_dao.drift.dart';

/// Date del solo episodio richiesto ed esistenza indipendente della stagione.
/// [targetEpisodes] è vuota se l'episodio manca, anche quando [hasSeason] è true.
class CachedEpisodeSummary {
  final bool hasSeason;

  /// Proiezione minima compatibile con `airedPerCachedEpisodes`: non contiene
  /// titolo/trama/immagini e non va usata per renderizzare i dettagli.
  final List<CachedEpisode> targetEpisodes;

  const CachedEpisodeSummary({
    required this.hasSeason,
    required this.targetEpisodes,
  });
}

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

  /// Summary bulk per (TMDB show, stagione, episodio), anche con cache scaduta.
  /// Una SELECT ogni 300 target (900 parametri, sotto il limite SQLite di 999).
  /// L'EXISTS usa il prefisso della chiave unica senza leggere trame/immagini
  /// dell'intera stagione; il LEFT JOIN legge le date del solo episodio target.
  Future<Map<(int, int, int), CachedEpisodeSummary>> getEpisodeSummaries(
    Iterable<(int, int, int)> targets,
  ) async {
    final unique = targets.toSet().toList();
    final result = <(int, int, int), CachedEpisodeSummary>{};
    for (var start = 0; start < unique.length; start += 300) {
      final chunk = unique.skip(start).take(300).toList();
      final values = List.filled(chunk.length, '(?, ?, ?)').join(', ');
      final rows = await customSelect('''
        WITH targets(show_id, season, episode) AS (VALUES $values)
        SELECT targets.show_id, targets.season, targets.episode,
          EXISTS(SELECT 1 FROM cached_episodes AS season_cache
            WHERE season_cache.tmdb_show_id = targets.show_id
              AND season_cache.season_number = targets.season) AS has_season,
          ep.id, ep.air_date, ep.airing_at, ep.cached_at
        FROM targets
        LEFT JOIN cached_episodes AS ep
          ON ep.tmdb_show_id = targets.show_id
          AND ep.season_number = targets.season
          AND ep.episode_number = targets.episode
      ''', variables: [
        for (final target in chunk) ...[
          Variable.withInt(target.$1),
          Variable.withInt(target.$2),
          Variable.withInt(target.$3),
        ],
      ], readsFrom: {
        cachedEpisodes
      }).get();
      for (final row in rows) {
        final target = (
          row.read<int>('show_id'),
          row.read<int>('season'),
          row.read<int>('episode')
        );
        final id = row.readNullable<int>('id');
        result[target] = CachedEpisodeSummary(
          hasSeason: row.read<bool>('has_season'),
          targetEpisodes: [
            if (id != null)
              CachedEpisode(
                id: id,
                tmdbShowId: target.$1,
                seasonNumber: target.$2,
                episodeNumber: target.$3,
                name: '',
                airDate: row.readNullable<String>('air_date'),
                airingAt: row.readNullable<DateTime>('airing_at'),
                cachedAt: row.read<DateTime>('cached_at'),
              ),
          ],
        );
      }
    }
    return result;
  }

  /// Salva (o aggiorna) i dettagli degli episodi di una stagione in cache.
  Future<void> saveSeasonEpisodes(List<CachedEpisodesCompanion> rows) async {
    await transaction(() async {
      await batch((b) {
        b.insertAll(cachedEpisodes, rows, mode: InsertMode.insertOrReplace);
      });
    });
  }

  /// Sostituisce atomicamente lo snapshot completo di una stagione.
  /// A differenza di [saveSeasonEpisodes], elimina anche gli episodi non più
  /// presenti; una lista vuota esplicita svuota la stagione. Chiamare solo dopo
  /// un fetch completo riuscito, mai con un risultato parziale o incerto.
  /// In caso di errore rimane disponibile l'intero snapshot precedente.
  Future<void> replaceSeasonEpisodes(
    int tmdbShowId,
    int seasonNumber,
    List<CachedEpisodesCompanion> rows,
  ) async {
    for (final row in rows) {
      if (!row.tmdbShowId.present ||
          row.tmdbShowId.value != tmdbShowId ||
          !row.seasonNumber.present ||
          row.seasonNumber.value != seasonNumber) {
        throw ArgumentError.value(
          rows,
          'rows',
          'Tutti gli episodi devono appartenere alla stagione richiesta',
        );
      }
    }
    await transaction(() async {
      await (delete(cachedEpisodes)
            ..where(
              (t) =>
                  t.tmdbShowId.equals(tmdbShowId) &
                  t.seasonNumber.equals(seasonNumber),
            ))
          .go();
      await batch((b) {
        b.insertAll(cachedEpisodes, rows);
      });
    });
  }

  /// Forza un refresh senza perdere gli episodi disponibili offline.
  /// Un singolo UPDATE fa scadere atomicamente tutte le stagioni della serie.
  Future<void> expireCacheForShow(int tmdbShowId) async {
    await (update(cachedEpisodes)
          ..where((t) => t.tmdbShowId.equals(tmdbShowId)))
        .write(CachedEpisodesCompanion(
      cachedAt: Value(DateTime.fromMillisecondsSinceEpoch(0)),
    ));
  }

  /// Rimuove definitivamente tutti gli episodi in cache per una serie.
  Future<void> clearCacheForShow(int tmdbShowId) async {
    await (delete(cachedEpisodes)
          ..where((t) => t.tmdbShowId.equals(tmdbShowId)))
        .go();
  }
}
