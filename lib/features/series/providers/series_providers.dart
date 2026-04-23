import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/services/app_toast.dart';
import '../../../core/services/notification_service.dart';
import '../data/tmdb_service.dart';
import '../data/models/tmdb_show.dart';
import '../data/models/tmdb_show_detail.dart';
import '../data/models/tmdb_episode.dart';
import '../data/models/tmdb_season.dart';

part 'series_providers.g.dart';

// ── Model: episodio in uscita ─────────────────────────────────────────────────

class UpcomingEpisodeInfo {
  final TrackedShow show;
  final TmdbNextEpisode episode;
  final DateTime airDate;

  const UpcomingEpisodeInfo({
    required this.show,
    required this.episode,
    required this.airDate,
  });
}

// ── TmdbService ───────────────────────────────────────────────────────────────

@riverpod
TmdbService tmdbService(TmdbServiceRef ref) => TmdbService();

// ── TMDB: ricerca e dettaglio ─────────────────────────────────────────────────

@riverpod
Future<List<TmdbShow>> searchShows(SearchShowsRef ref, String query) async {
  if (query.length < 2) return [];
  return ref.watch(tmdbServiceProvider).searchShows(query);
}

@riverpod
Future<TmdbShowDetail> showDetail(ShowDetailRef ref, int tmdbId) {
  return ref.watch(tmdbServiceProvider).getShowDetails(tmdbId);
}

/// Calcola il TTL della cache degli episodi in base allo stato TMDB della serie.
///
/// Replica la logica della vecchia app:
/// - Serie terminata/cancellata → 30 giorni (gli episodi non cambieranno mai)
/// - Stagione corrente di una serie in corso → 1 giorno (nuovi episodi settimanali)
/// - Stagione passata di una serie in corso → 7 giorni (raramente cambia)
Duration _seasonCacheTtl(String? tmdbStatus, int seasonNumber, int? totalSeasons) {
  if (tmdbStatus == 'Ended' || tmdbStatus == 'Canceled') {
    return const Duration(days: 30);
  }
  final isCurrentSeason = totalSeasons == null || seasonNumber >= totalSeasons;
  return isCurrentSeason ? const Duration(days: 1) : const Duration(days: 7);
}

@riverpod
Future<TmdbSeason> seasonDetail(
  SeasonDetailRef ref, {
  required int showId,
  required int seasonNumber,
}) async {
  final cacheDao = ref.read(cacheDaoProvider);

  // Legge lo stato TMDB dal DB per calcolare il TTL corretto.
  final show = await ref.read(showsDaoProvider).getByTmdbId(showId);
  final ttl = _seasonCacheTtl(show?.tmdbStatus, seasonNumber, show?.totalSeasons);

  // 1. Prova la cache locale con TTL intelligente.
  final cached = await cacheDao.getFreshSeasonEpisodes(showId, seasonNumber, ttl: ttl);
  if (cached.isNotEmpty) {
    return TmdbSeason(
      seasonNumber: seasonNumber,
      episodeCount: cached.length,
      episodes: cached
          .map((e) => TmdbEpisode(
                episodeNumber: e.episodeNumber,
                name: e.name,
                overview: e.overview,
                stillPath: e.stillPath,
                airDate: e.airDate,
                voteAverage: e.voteAverage,
              ))
          .toList(),
    );
  }

  // 2. Cache assente o scaduta: scarica da TMDB.
  final season = await ref.read(tmdbServiceProvider).getSeasonDetails(showId, seasonNumber);

  // 3. Salva in cache per le prossime chiamate.
  if (season.episodes?.isNotEmpty ?? false) {
    final now = DateTime.now();
    await cacheDao.saveSeasonEpisodes(
      season.episodes!
          .map((e) => CachedEpisodesCompanion(
                tmdbShowId: Value(showId),
                seasonNumber: Value(seasonNumber),
                episodeNumber: Value(e.episodeNumber),
                name: Value(e.name),
                overview: Value(e.overview),
                stillPath: Value(e.stillPath),
                airDate: Value(e.airDate),
                voteAverage: Value(e.voteAverage),
                cachedAt: Value(now),
              ))
          .toList(),
    );
  }

  return season;
}

// ── DB: serie tracciate (stream reattivo) ─────────────────────────────────────

@riverpod
class TrackedShowsNotifier extends _$TrackedShowsNotifier {
  @override
  Stream<List<TrackedShow>> build() {
    return ref.watch(showsDaoProvider).watchAll();
  }

  Future<void> addShow(TmdbShowDetail detail) async {
    final dbId = await ref.read(showsDaoProvider).insertShow(
          TrackedShowsCompanion(
            tmdbId: Value(detail.id),
            title: Value(detail.name),
            overview: Value(
              (detail.overview?.isNotEmpty ?? false) ? detail.overview : null,
            ),
            posterPath: Value(detail.posterPath),
            status: const Value(MediaStatus.planToWatch),
            totalSeasons: Value(detail.numberOfSeasons),
            totalEpisodes: Value(detail.numberOfEpisodes),
            tmdbStatus: Value(detail.status),
            addedAt: Value(DateTime.now()),
          ),
        );
    final counts = {for (final s in detail.seasons) s.seasonNumber: s.episodeCount};
    await ref.read(showsDaoProvider).insertSeasons(dbId, counts);

    // Pianifica notifica se c'è un prossimo episodio con data nota.
    final next = detail.nextEpisodeToAir;
    if (next?.airDate != null) {
      final airDate = DateTime.tryParse(next!.airDate!);
      if (airDate != null) {
        await NotificationService.schedule(
          tmdbId: detail.id,
          showTitle: detail.name,
          seasonNumber: next.seasonNumber,
          episodeNumber: next.episodeNumber,
          episodeName: next.name,
          airDate: airDate,
        );
      }
    }
  }

  Future<void> removeShow(int dbId) async {
    final show = await ref.read(showsDaoProvider).getById(dbId);
    if (show != null) await NotificationService.cancel(show.tmdbId);
    await ref.read(showsDaoProvider).deleteShow(dbId);
  }

  Future<void> updateStatus(int dbId, MediaStatus status) async {
    final show = await ref.read(showsDaoProvider).getById(dbId);
    await ref.read(showsDaoProvider).updateStatus(dbId, status);
    if (show == null) return;

    if (status == MediaStatus.completed || status == MediaStatus.dropped) {
      await NotificationService.cancel(show.tmdbId);
    } else {
      // Watching / PlanToWatch: ri-pianifica se c'è un episodio in uscita.
      try {
        final detail = await ref.read(tmdbServiceProvider).getShowDetails(show.tmdbId);
        final next = detail.nextEpisodeToAir;
        if (next?.airDate != null) {
          final airDate = DateTime.tryParse(next!.airDate!);
          if (airDate != null) {
            await NotificationService.schedule(
              tmdbId: show.tmdbId,
              showTitle: show.title,
              seasonNumber: next.seasonNumber,
              episodeNumber: next.episodeNumber,
              episodeName: next.name,
              airDate: airDate,
            );
          }
        }
      } catch (_) {
        AppToast.show('Impossibile aggiornare la notifica per ${show.title}');
      }
    }
  }
}

// ── DB: episodi visti (stream reattivo, per schermata di dettaglio) ───────────

/// Emette una mappa stagione→episodi per i soli episodi marcati come visti.
@riverpod
Stream<Map<int, Set<int>>> watchedEpisodesBySeason(
  WatchedEpisodesBySeasonRef ref,
  int dbShowId,
) {
  return ref
      .watch(showsDaoProvider)
      .watchEpisodesByShow(dbShowId)
      .map((episodes) {
    final result = <int, Set<int>>{};
    for (final ep in episodes.where((e) => e.watched)) {
      result.putIfAbsent(ep.seasonNumber, () => {}).add(ep.episodeNumber);
    }
    return result;
  });
}

/// Emette il conteggio totale degli episodi visti per una serie (usato nel card).
@riverpod
Stream<int> watchedCount(WatchedCountRef ref, int dbShowId) {
  return ref
      .watch(showsDaoProvider)
      .watchEpisodesByShow(dbShowId)
      .map((eps) => eps.where((e) => e.watched).length);
}

/// Mappa stagione→episodeCount letta dal DB locale (nessuna chiamata API).
@riverpod
Future<Map<int, int>> seasonEpisodeCounts(
  SeasonEpisodeCountsRef ref,
  int dbShowId,
) {
  return ref.watch(showsDaoProvider).getSeasonCounts(dbShowId);
}

/// Emette serie+episodi visti in un'unica query JOIN (elimina gli skeleton
/// del tab "Da Vedere" causati dai N stream separati per card).
@riverpod
Stream<List<ShowWithWatchedEpisodes>> watchingShowsWithEpisodes(
    WatchingShowsWithEpisodesRef ref) {
  return ref.watch(showsDaoProvider).watchWatchingShowsWithEpisodes();
}

/// Calcola la lista degli episodi in uscita per tutte le serie tracciate.
/// Legge next_episode_to_air da TMDB (già incluso nella risposta di showDetail).
@riverpod
Future<List<UpcomingEpisodeInfo>> upcomingEpisodes(
    UpcomingEpisodesRef ref) async {
  // Re-esegue ogni volta che la lista delle serie cambia.
  final shows = await ref.watch(trackedShowsNotifierProvider.future);

  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);
  final results = <UpcomingEpisodeInfo>[];

  for (final show in shows) {
    // Episodi in uscita non hanno senso per serie completate o abbandonate
    if (show.status == MediaStatus.completed ||
        show.status == MediaStatus.dropped) {
      continue;
    }
    try {
      final detail = await ref.read(showDetailProvider(show.tmdbId).future);
      final next = detail.nextEpisodeToAir;
      if (next == null || next.airDate == null) continue;
      final airDate = DateTime.tryParse(next.airDate!);
      if (airDate == null) continue;
      final airMidnight =
          DateTime(airDate.year, airDate.month, airDate.day);
      // Includi solo episodi da oggi in poi
      if (airMidnight.isBefore(todayMidnight)) continue;
      results.add(UpcomingEpisodeInfo(
        show: show,
        episode: next,
        airDate: airMidnight,
      ));
    } catch (_) {
      // Ignora show non caricabili (errori di rete, ecc.)
    }
  }

  results.sort((a, b) => a.airDate.compareTo(b.airDate));
  return results;
}
