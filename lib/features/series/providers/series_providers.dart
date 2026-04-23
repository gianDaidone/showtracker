import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/services/app_toast.dart';
import '../../../core/services/notification_service.dart';
import '../data/anilist_service.dart';
import '../data/anime_data_merger.dart';
import '../data/tmdb_service.dart';
import '../data/yuna_service.dart';
import '../data/models/normalized_anime_season.dart';
import '../data/models/tmdb_show.dart';
import '../data/models/tmdb_show_detail.dart';
import '../data/models/tmdb_episode.dart';
import '../data/models/tmdb_season.dart';

part 'series_providers.g.dart';

// ── Model: episodio in uscita ─────────────────────────────────────────────────

class UpcomingEpisodeInfo {
  final TrackedShow show;
  final TmdbNextEpisode episode;

  /// Midnight of the air date (used for sorting and day-diff labels).
  final DateTime airDate;

  /// Exact airing time from AniList (non-null for anime with precise schedule).
  final DateTime? preciseAirTime;

  const UpcomingEpisodeInfo({
    required this.show,
    required this.episode,
    required this.airDate,
    this.preciseAirTime,
  });
}

// ── Singleton services ────────────────────────────────────────────────────────

@riverpod
TmdbService tmdbService(TmdbServiceRef ref) => TmdbService();

@Riverpod(keepAlive: true)
AniListService anilistService(AnilistServiceRef ref) {
  final service = AniListService();
  ref.onDispose(service.dispose);
  return service;
}

@riverpod
YunaService yunaService(YunaServiceRef ref) => YunaService();

// ── TMDB: ricerca ─────────────────────────────────────────────────────────────

@riverpod
Future<List<TmdbShow>> searchShows(SearchShowsRef ref, String query) async {
  if (query.length < 2) return [];
  return ref.watch(tmdbServiceProvider).searchShows(query);
}

// ── AniList data provider ─────────────────────────────────────────────────────

@riverpod
Future<List<NormalizedAnimeSeason>?> animeData(
  AnimeDataRef ref,
  int tmdbId,
) async {
  final animeCacheDao = ref.read(animeCacheDaoProvider);
  final tmdbSvc = ref.read(tmdbServiceProvider);

  // 1. Check cache
  final cached = await animeCacheDao.getFreshAnimeSeasons(tmdbId);
  if (cached != null) return cached;

  // 2. Fetch fresh from Yuna + AniList
  try {
    final yunaSvc = ref.read(yunaServiceProvider);
    final anilistSvc = ref.read(anilistServiceProvider);

    // 2a. Yuna mapping: TMDB ID → AniList IDs
    var anilistIds = await animeCacheDao.getYunaIds(tmdbId);
    if (anilistIds == null) {
      anilistIds = await yunaSvc.getAniListIds(tmdbId);
      await animeCacheDao.saveYunaIds(tmdbId, anilistIds);
    }

    // 2b. If Yuna has no mapping, try searching by title
    if (anilistIds.isEmpty) {
      final detail = await tmdbSvc.getShowDetails(tmdbId);
      final found = await anilistSvc.searchByTitle(detail.name);
      if (found != null) anilistIds = [found.id];
    }

    if (anilistIds.isEmpty) return null;

    // 2c. Fetch AniList media for each ID
    final anilistMedia = await anilistSvc.fetchBatch(anilistIds);
    if (anilistMedia.isEmpty) return null;

    // 2d. Merge with TMDB season structure
    final detail = await tmdbSvc.getShowDetails(tmdbId);
    final seasons = AnimeDataMerger.merge(
      tmdbSeasons: detail.seasons,
      anilistMedia: anilistMedia,
    );

    if (seasons.isEmpty) return null;

    // 2e. Persist to cache
    await animeCacheDao.saveAnimeSeasons(tmdbId, seasons);

    return seasons;
  } catch (_) {
    return null;
  }
}

// ── Show detail (enriched with AniList for anime) ─────────────────────────────

@riverpod
Future<TmdbShowDetail> showDetail(ShowDetailRef ref, int tmdbId) async {
  final detail = await ref.watch(tmdbServiceProvider).getShowDetails(tmdbId);

  if (!detail.isAnime) return detail;

  // Enrich anime with AniList data
  final animeSeasonsData =
      await ref.read(animeDataProvider(tmdbId).future);

  if (animeSeasonsData == null || animeSeasonsData.isEmpty) return detail;

  // Build synthetic TmdbSeason list from AniList season metadata
  // so existing UI (SeasonSection) works without changes.
  final syntheticSeasons = animeSeasonsData.map((as_) {
    final label = as_.seasonLabel;
    final name = label.isNotEmpty
        ? 'Stagione ${as_.seasonNumber} · $label'
        : 'Stagione ${as_.seasonNumber}';
    return TmdbSeason(
      seasonNumber: as_.seasonNumber,
      episodeCount: as_.episodeCount,
      name: name,
    );
  }).toList();

  return detail.copyWith(
    seasons: syntheticSeasons,
    animeSeasonsData: animeSeasonsData,
  );
}

// ── Season detail (with anime redistribution) ─────────────────────────────────

Duration _seasonCacheTtl(
    String? tmdbStatus, int seasonNumber, int? totalSeasons) {
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
  final show = await ref.read(showsDaoProvider).getByTmdbId(showId);

  // ── Anime path ─────────────────────────────────────────────────────────────
  final detail = await ref.read(showDetailProvider(showId).future);
  if (detail.isAnime && detail.animeSeasonsData != null) {
    final animeSeasonsData = detail.animeSeasonsData!;
    final animeSeason = animeSeasonsData
        .where((s) => s.seasonNumber == seasonNumber)
        .firstOrNull;

    if (animeSeason != null) {
      // Use AniList-aware TTL for cache check
      final animeTtl = animeSeason.cacheTtl;

      final cached = await cacheDao.getFreshSeasonEpisodes(
        showId,
        seasonNumber,
        ttl: animeTtl,
      );
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
                    absoluteEpisodeNumber: e.absoluteEpisodeNumber,
                    airingAt: e.airingAt,
                  ))
              .toList(),
        );
      }

      // Cache miss: redistribute all seasons from TMDB at once
      final redistributed = await ref
          .read(tmdbServiceProvider)
          .getAnimeEpisodesBySeason(showId, animeSeasonsData);

      if (redistributed.isNotEmpty) {
        // Cache only non-empty seasons (empty ones will be retried next time)
        final now = DateTime.now();
        for (final entry in redistributed.entries) {
          final sNum = entry.key;
          final eps = entry.value;
          if (eps.isEmpty) continue;
          await cacheDao.saveSeasonEpisodes(eps
              .map((e) => CachedEpisodesCompanion(
                    tmdbShowId: Value(showId),
                    seasonNumber: Value(sNum),
                    episodeNumber: Value(e.episodeNumber),
                    name: Value(e.name),
                    overview: Value(e.overview),
                    stillPath: Value(e.stillPath),
                    airDate: Value(e.airDate),
                    voteAverage: Value(e.voteAverage),
                    absoluteEpisodeNumber: Value(e.absoluteEpisodeNumber),
                    airingAt: Value(e.airingAt),
                    cachedAt: Value(now),
                  ))
              .toList());
        }

        final eps = redistributed[seasonNumber] ?? [];
        if (eps.isNotEmpty) {
          return TmdbSeason(
            seasonNumber: seasonNumber,
            episodeCount: eps.length,
            episodes: eps,
          );
        }
      }

      // Redistribution gave 0 episodes for this season (TMDB doesn't have the
      // data yet). For airing/upcoming seasons, try fetching TMDB directly.
      if (animeSeason.status == 'RELEASING' ||
          animeSeason.status == 'NOT_YET_RELEASED') {
        try {
          final direct = await ref
              .read(tmdbServiceProvider)
              .getSeasonDetails(showId, animeSeason.tmdbSeasonNumber);
          final rawEps = direct.episodes;
          if (rawEps != null && rawEps.isNotEmpty) {
            // Inject AniList precise airingAt into the next airing episode,
            // since the raw TMDB fetch doesn't include this data.
            final nextAiring = animeSeason.nextAiringEpisode;
            if (nextAiring == null) return direct;
            final enriched = rawEps.map((ep) {
              if (ep.episodeNumber != nextAiring.episode) return ep;
              return TmdbEpisode(
                episodeNumber: ep.episodeNumber,
                name: ep.name,
                overview: ep.overview,
                stillPath: ep.stillPath,
                airDate: ep.airDate,
                voteAverage: ep.voteAverage,
                absoluteEpisodeNumber: ep.absoluteEpisodeNumber,
                airingAt: nextAiring.airingDateTime,
              );
            }).toList();
            return TmdbSeason(
              seasonNumber: direct.seasonNumber,
              episodeCount: direct.episodeCount,
              name: direct.name,
              episodes: enriched,
            );
          }
        } catch (_) {}
      }

      return TmdbSeason(seasonNumber: seasonNumber, episodeCount: 0);
    }
  }

  // ── Standard TMDB path ─────────────────────────────────────────────────────
  final ttl = _seasonCacheTtl(show?.tmdbStatus, seasonNumber, show?.totalSeasons);

  final cached =
      await cacheDao.getFreshSeasonEpisodes(showId, seasonNumber, ttl: ttl);
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
                absoluteEpisodeNumber: e.absoluteEpisodeNumber,
                airingAt: e.airingAt,
              ))
          .toList(),
    );
  }

  final season =
      await ref.read(tmdbServiceProvider).getSeasonDetails(showId, seasonNumber);

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
                absoluteEpisodeNumber: const Value(null),
                airingAt: const Value(null),
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
            isAnime: Value(detail.isAnime),
            addedAt: Value(DateTime.now()),
          ),
        );
    final counts = {for (final s in detail.seasons) s.seasonNumber: s.episodeCount};
    await ref.read(showsDaoProvider).insertSeasons(dbId, counts);

    // Pianifica notifica con orario preciso per anime, 09:00 per serie normali.
    await _scheduleNotification(detail);
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
      try {
        final detail =
            await ref.read(showDetailProvider(show.tmdbId).future);
        await _scheduleNotification(detail);
      } catch (_) {
        AppToast.show('Impossibile aggiornare la notifica per ${show.title}');
      }
    }
  }

  /// Re-schedules the notification for an already-tracked show.
  /// Safe to call multiple times (overwrites the previous notification).
  Future<void> rescheduleNotification(TmdbShowDetail detail) =>
      _scheduleNotification(detail);

  Future<void> _scheduleNotification(TmdbShowDetail detail) async {
    // Anime: use AniList precise airingAt if available
    if (detail.isAnime && detail.animeSeasonsData != null) {
      for (final animeSeason in detail.animeSeasonsData!) {
        final nextAiring = animeSeason.nextAiringEpisode;
        if (nextAiring == null) continue;
        final airingAt = nextAiring.airingDateTime;
        if (!airingAt.isAfter(DateTime.now())) continue;

        await NotificationService.schedule(
          tmdbId: detail.id,
          showTitle: detail.name,
          seasonNumber: animeSeason.seasonNumber,
          episodeNumber: nextAiring.episode,
          episodeName: '',
          airDate: airingAt,
          useExactTime: true,
        );
        return;
      }
    }

    // Standard TMDB scheduling at 09:00
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
}

// ── DB: episodi visti ─────────────────────────────────────────────────────────

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

@riverpod
Stream<int> watchedCount(WatchedCountRef ref, int dbShowId) {
  return ref
      .watch(showsDaoProvider)
      .watchEpisodesByShow(dbShowId)
      .map((eps) => eps.where((e) => e.watched).length);
}

@riverpod
Future<Map<int, int>> seasonEpisodeCounts(
  SeasonEpisodeCountsRef ref,
  int dbShowId,
) {
  return ref.watch(showsDaoProvider).getSeasonCounts(dbShowId);
}

@riverpod
Stream<List<ShowWithWatchedEpisodes>> watchingShowsWithEpisodes(
    WatchingShowsWithEpisodesRef ref) {
  return ref.watch(showsDaoProvider).watchWatchingShowsWithEpisodes();
}

// ── Prossimi episodi in uscita ────────────────────────────────────────────────

@riverpod
Future<List<UpcomingEpisodeInfo>> upcomingEpisodes(
    UpcomingEpisodesRef ref) async {
  final shows = await ref.watch(trackedShowsNotifierProvider.future);

  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);
  final results = <UpcomingEpisodeInfo>[];

  for (final show in shows) {
    if (show.status == MediaStatus.completed ||
        show.status == MediaStatus.dropped) {
      continue;
    }
    try {
      final detail = await ref.read(showDetailProvider(show.tmdbId).future);

      // Anime: use precise AniList airingAt
      if (detail.isAnime && detail.animeSeasonsData != null) {
        for (final animeSeason in detail.animeSeasonsData!) {
          final nextAiring = animeSeason.nextAiringEpisode;
          if (nextAiring == null) continue;
          final airingAt = nextAiring.airingDateTime;
          final airMidnight =
              DateTime(airingAt.year, airingAt.month, airingAt.day);
          if (airMidnight.isBefore(todayMidnight)) continue;

          results.add(UpcomingEpisodeInfo(
            show: show,
            episode: TmdbNextEpisode(
              seasonNumber: animeSeason.seasonNumber,
              episodeNumber: nextAiring.episode,
              name: '',
              airDate: airingAt.toIso8601String(),
            ),
            airDate: airMidnight,
            preciseAirTime: airingAt,
          ));
          break;
        }
        continue;
      }

      // Standard TMDB
      final next = detail.nextEpisodeToAir;
      if (next == null || next.airDate == null) continue;
      final airDate = DateTime.tryParse(next.airDate!);
      if (airDate == null) continue;
      final airMidnight =
          DateTime(airDate.year, airDate.month, airDate.day);
      if (airMidnight.isBefore(todayMidnight)) continue;

      results.add(UpcomingEpisodeInfo(
        show: show,
        episode: next,
        airDate: airMidnight,
      ));
    } catch (_) {
      // Ignora show non caricabili
    }
  }

  results.sort((a, b) => a.airDate.compareTo(b.airDate));
  return results;
}
