import 'package:drift/drift.dart';
import '../app_database.dart';

part 'shows_dao.g.dart';

class ShowWithWatchedEpisodes {
  final TrackedShow show;

  /// Mappa stagione → set di numeri episodio visti.
  final Map<int, Set<int>> watchedBySeason;

  const ShowWithWatchedEpisodes({
    required this.show,
    required this.watchedBySeason,
  });

  int get watchedCount =>
      watchedBySeason.values.fold(0, (sum, s) => sum + s.length);
}

@DriftAccessor(tables: [TrackedShows, TrackedEpisodes, TrackedSeasons])
class ShowsDao extends DatabaseAccessor<AppDatabase> with _$ShowsDaoMixin {
  ShowsDao(super.db);

  // ── Shows: one-shot ──────────────────────────────────────────────────────

  Future<int> insertShow(TrackedShowsCompanion show) =>
      into(trackedShows).insert(show);

  Future<List<TrackedShow>> getAll() =>
      (select(trackedShows)
            ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
          .get();

  Future<TrackedShow?> getById(int id) =>
      (select(trackedShows)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<TrackedShow?> getByTmdbId(int tmdbId) =>
      (select(trackedShows)..where((t) => t.tmdbId.equals(tmdbId)))
          .getSingleOrNull();

  Future<void> updateStatus(int id, MediaStatus status) =>
      (update(trackedShows)..where((t) => t.id.equals(id)))
          .write(TrackedShowsCompanion(status: Value(status), updatedAt: Value(DateTime.now())));

  Future<void> updateRating(int id, double? rating) =>
      (update(trackedShows)..where((t) => t.id.equals(id)))
          .write(TrackedShowsCompanion(userRating: Value(rating), updatedAt: Value(DateTime.now())));

  Future<int> deleteShow(int id) =>
      (delete(trackedShows)..where((t) => t.id.equals(id))).go();

  // ── Shows: stream (reactive) ─────────────────────────────────────────────

  Stream<List<TrackedShow>> watchAll() =>
      (select(trackedShows)
            ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
          .watch();

  // ── Episodes: one-shot ───────────────────────────────────────────────────

  /// Inserisce o aggiorna lo stato di un episodio.
  /// Sicuro da chiamare anche se la riga non esiste ancora.
  Future<void> markEpisodeWatched(
    int showId,
    int season,
    int episode, {
    bool watched = true,
  }) async {
    if (watched) {
      await (update(trackedShows)..where((t) => t.id.equals(showId)))
          .write(TrackedShowsCompanion(lastWatchedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));
    }

    final updated = await (update(trackedEpisodes)
          ..where(
            (t) =>
                t.showId.equals(showId) &
                t.seasonNumber.equals(season) &
                t.episodeNumber.equals(episode),
          ))
        .write(TrackedEpisodesCompanion(watched: Value(watched), updatedAt: Value(DateTime.now())));

    if (updated == 0) {
      await into(trackedEpisodes).insert(
        TrackedEpisodesCompanion(
          showId: Value(showId),
          seasonNumber: Value(season),
          episodeNumber: Value(episode),
          watched: Value(watched),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<List<TrackedEpisode>> getEpisodesByShow(int showId) =>
      (select(trackedEpisodes)
            ..where((t) => t.showId.equals(showId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.seasonNumber),
              (t) => OrderingTerm.asc(t.episodeNumber),
            ]))
          .get();

  Future<int> countWatchedEpisodes(int showId) async {
    final countExpr = trackedEpisodes.id.count();
    final result = await (selectOnly(trackedEpisodes)
          ..addColumns([countExpr])
          ..where(trackedEpisodes.showId.equals(showId) &
              trackedEpisodes.watched.equals(true)))
        .getSingle();
    return result.read(countExpr) ?? 0;
  }

  Future<void> updateShowMetadata(
      int id, int? totalEpisodes, int? totalSeasons, String? status,
      {
        Value<int?> nextEpisodeNumber = const Value.absent(),
        Value<int?> nextEpisodeSeason = const Value.absent(),
        Value<String?> nextEpisodeName = const Value.absent(),
        Value<DateTime?> nextEpisodeAirDate = const Value.absent(),
      }) async {
    await (update(trackedShows)..where((t) => t.id.equals(id))).write(
      TrackedShowsCompanion(
        totalEpisodes: Value(totalEpisodes),
        totalSeasons: Value(totalSeasons),
        tmdbStatus: Value(status),
        nextEpisodeNumber: nextEpisodeNumber,
        nextEpisodeSeason: nextEpisodeSeason,
        nextEpisodeName: nextEpisodeName,
        nextEpisodeAirDate: nextEpisodeAirDate,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ── Episodes: stream (reactive) ──────────────────────────────────────────

  Stream<List<TrackedEpisode>> watchEpisodesByShow(int showId) =>
      (select(trackedEpisodes)
            ..where((t) => t.showId.equals(showId)))
          .watch();

  // ── Seasons: episodi per stagione (dal DB, senza API) ────────────────────

  /// Salva o aggiorna il numero di episodi per ogni stagione di una serie.
  Future<void> insertSeasons(int showId, Map<int, int> counts) async {
    for (final entry in counts.entries) {
      await into(trackedSeasons).insertOnConflictUpdate(
        TrackedSeasonsCompanion(
          showId: Value(showId),
          seasonNumber: Value(entry.key),
          episodeCount: Value(entry.value),
        ),
      );
    }
  }

  /// Restituisce la mappa stagione→episodeCount per una serie.
  Future<Map<int, int>> getSeasonCounts(int showId) async {
    final rows = await (select(trackedSeasons)
          ..where((t) => t.showId.equals(showId)))
        .get();
    return {for (final r in rows) r.seasonNumber: r.episodeCount};
  }

  /// Restituisce true se almeno un episodio precedente a
  /// [targetSeason]/[targetEpisode] non è ancora segnato come visto.
  Future<bool> hasMissingPreviousEpisodes(
    int showId,
    int targetSeason,
    int targetEpisode,
  ) async {
    if (targetSeason == 1 && targetEpisode <= 1) return false;

    final allEpisodes = await getEpisodesByShow(showId);
    final watchedMap = <int, Set<int>>{};
    for (final ep in allEpisodes.where((e) => e.watched)) {
      watchedMap.putIfAbsent(ep.seasonNumber, () => {}).add(ep.episodeNumber);
    }

    final seasonCounts = await getSeasonCounts(showId);

    for (int s = 1; s <= targetSeason; s++) {
      final maxEp =
          s < targetSeason ? (seasonCounts[s] ?? 0) : targetEpisode - 1;
      final watchedInSeason = watchedMap[s] ?? {};
      for (int e = 1; e <= maxEp; e++) {
        if (!watchedInSeason.contains(e)) return true;
      }
    }
    return false;
  }

  /// Segna come visti in un'unica transazione tutti gli episodi precedenti
  /// a [targetSeason]/[targetEpisode] (stagioni precedenti incluse).
  Future<void> markAllPreviousEpisodesWatched(
    int showId,
    int targetSeason,
    int targetEpisode,
  ) async {
    if (targetSeason > 1 || targetEpisode > 1) {
      await (update(trackedShows)..where((t) => t.id.equals(showId)))
          .write(TrackedShowsCompanion(lastWatchedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));
    }
    
    final seasonCounts = await getSeasonCounts(showId);
    await batch((b) {
      for (int s = 1; s <= targetSeason; s++) {
        final maxEp =
            s < targetSeason ? (seasonCounts[s] ?? 0) : targetEpisode - 1;
        for (int e = 1; e <= maxEp; e++) {
          b.insert(
            trackedEpisodes,
            TrackedEpisodesCompanion(
              showId: Value(showId),
              seasonNumber: Value(s),
              episodeNumber: Value(e),
              watched: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
  }

  // ── Query aggregata: serie in visione + episodi visti ────────────────────

  /// Emette tutte le serie con status watching/paused già unite ai loro
  /// episodi visti in un'unica query JOIN.
  /// Elimina gli N stream separati di watchedEpisodesBySeason nelle card.
  Stream<List<ShowWithWatchedEpisodes>> watchWatchingShowsWithEpisodes() {
    final query = select(trackedShows).join([
      leftOuterJoin(
        trackedEpisodes,
        trackedEpisodes.showId.equalsExp(trackedShows.id) &
            trackedEpisodes.watched.equals(true),
      ),
    ])
      ..where(
        trackedShows.status.equalsValue(MediaStatus.watching),
      )
      ..orderBy([OrderingTerm.desc(trackedShows.addedAt)]);

    return query.watch().map((rows) {
      final showMap = <int, TrackedShow>{};
      final episodesMap = <int, Map<int, Set<int>>>{};
      final orderedIds = <int>[];

      for (final row in rows) {
        final show = row.readTable(trackedShows);
        final ep = row.readTableOrNull(trackedEpisodes);

        if (!showMap.containsKey(show.id)) {
          showMap[show.id] = show;
          orderedIds.add(show.id);
        }
        if (ep != null) {
          episodesMap
              .putIfAbsent(show.id, () => {})
              .putIfAbsent(ep.seasonNumber, () => {})
              .add(ep.episodeNumber);
        }
      }

      return orderedIds
          .map((id) => ShowWithWatchedEpisodes(
                show: showMap[id]!,
                watchedBySeason: episodesMap[id] ?? {},
              ))
          .toList();
    });
  }
}
