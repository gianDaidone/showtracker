import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/tmdb_http_client.dart';
import '../../../core/auth/auth_state.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/services/app_toast.dart';
import '../../../core/services/notification_service.dart';
import '../data/anilist_service.dart';
import '../data/anime_data_merger.dart';
import '../data/tmdb_service.dart';
import '../data/yuna_service.dart';
import '../data/models/anilist_media.dart';
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

  /// The formatted season name, useful for anime where season numbers are synthetic cours.
  final String? seasonName;

  /// Other episodes of the same series releasing on the EXACT same day.
  final List<TmdbEpisode> additionalEpisodes;

  const UpcomingEpisodeInfo({
    required this.show,
    required this.episode,
    required this.airDate,
    this.preciseAirTime,
    this.seasonName,
    this.additionalEpisodes = const [],
  });
}

// ── Singleton services ────────────────────────────────────────────────────────

@riverpod
TmdbService tmdbService(TmdbServiceRef ref) {
  final authStateAsync = ref.watch(authControllerProvider);
  final authState = authStateAsync.valueOrNull ?? const Unauthenticated();
  final client = AppInterceptor(http.Client(), tmdbAuthState: authState);
  ref.onDispose(client.close);
  return TmdbService(client);
}

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
      final found = await _searchAniListByTmdbTitles(anilistSvc, detail);
      if (found != null) anilistIds = [found.id];
    }

    if (anilistIds.isEmpty) return null;

    // 2c. Fetch AniList media for each ID
    var anilistMedia = await anilistSvc.fetchBatch(anilistIds);

    // 2c-bis. Resilienza: se gli ID Yuna non hanno restituito media validi
    // (mapping obsoleto, ID errati, anime appena annunciato non ancora
    // indicizzato) riprova con la ricerca per titolo prima di arrenderti.
    if (anilistMedia.isEmpty) {
      final detail = await tmdbSvc.getShowDetails(tmdbId);
      final found = await _searchAniListByTmdbTitles(anilistSvc, detail);
      if (found != null) {
        anilistMedia = [found];
        // Sostituisci il mapping Yuna stale con l'ID corretto trovato per
        // titolo, così le successive richieste passano subito da AniList.
        await animeCacheDao.saveYunaIds(tmdbId, [found.id]);
      }
    }

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

/// Cerca l'anime su AniList provando prima il nome localizzato (TMDB it-IT
/// con fallback en-US) poi il `original_name` (di solito il titolo nativo:
/// per anime giapponesi è la forma in romaji o in giapponese, che AniList
/// indicizza meglio del titolo localizzato).
Future<AniListMedia?> _searchAniListByTmdbTitles(
  AniListService anilistSvc,
  TmdbShowDetail detail,
) async {
  if (detail.name.isNotEmpty) {
    final found = await anilistSvc.searchByTitle(detail.name);
    if (found != null) return found;
  }
  final original = detail.originalName;
  if (original != null && original.isNotEmpty && original != detail.name) {
    return anilistSvc.searchByTitle(original);
  }
  return null;
}

/// Calcola il totalEpisodes effettivo per una serie.
///
/// Per gli anime con dati AniList, somma gli episodi di tutte le stagioni
/// sintetiche (cours). Questo evita il bug dove TMDB riporta un numero di
/// episodi inferiore al reale perché raggruppa più cours in una singola stagione.
/// Per le serie non-anime, restituisce il valore TMDB grezzo.
int? _effectiveTotalEpisodes(TmdbShowDetail detail) {
  if (detail.isAnime && detail.animeSeasonsData != null && detail.animeSeasonsData!.isNotEmpty) {
    final sum = detail.animeSeasonsData!.fold<int>(0, (acc, s) => acc + s.episodeCount);
    // Usa il totale AniList solo se è maggiore di zero per evitare di
    // sovrascrivere un valore TMDB valido con 0 (anime non ancora uscito).
    return sum > 0 ? sum : detail.numberOfEpisodes;
  }
  return detail.numberOfEpisodes;
}

// ── Show detail (enriched with AniList for anime) ─────────────────────────────

@riverpod
Future<TmdbShowDetail> showDetail(ShowDetailRef ref, int tmdbId) async {
  final detail = await ref.watch(tmdbServiceProvider).getShowDetails(tmdbId);

  if (!detail.isAnime) return detail;

  // Enrich anime with AniList data
  final animeSeasonsData =
      await ref.watch(animeDataProvider(tmdbId).future);

  if (animeSeasonsData == null || animeSeasonsData.isEmpty) return detail;

  // Build synthetic TmdbSeason list from AniList season metadata
  // so existing UI (SeasonSection) works without changes.
  
  final tmdbSeasonCounts = <int, int>{};
  for (final as_ in animeSeasonsData) {
    tmdbSeasonCounts[as_.tmdbSeasonNumber] = 
        (tmdbSeasonCounts[as_.tmdbSeasonNumber] ?? 0) + 1;
  }
  
  final currentPart = <int, int>{};

  final syntheticSeasons = animeSeasonsData.map((as_) {
    final tmdbNum = as_.tmdbSeasonNumber;
    final totalParts = tmdbSeasonCounts[tmdbNum] ?? 1;

    final tmdbName = detail.seasons
        .where((s) => s.seasonNumber == tmdbNum)
        .map((s) => s.name)
        .firstOrNull;

    final isGenericName = tmdbName == null || 
        RegExp(r'^(Stagione|Season)\s*\d+$', caseSensitive: false).hasMatch(tmdbName.trim());

    String baseName = isGenericName ? 'Stagione $tmdbNum' : tmdbName;

    if (totalParts > 1) {
      currentPart[tmdbNum] = (currentPart[tmdbNum] ?? 0) + 1;
      baseName = '$baseName Parte ${currentPart[tmdbNum]}';
    }

    final label = as_.seasonLabel;
    final name = label.isNotEmpty ? '$baseName · $label' : baseName;

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
  final detail = await ref.watch(showDetailProvider(showId).future);
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
      // data yet, or they were all consumed by a previous cour).
      return TmdbSeason(seasonNumber: seasonNumber, episodeCount: 0);
    }
  }

  // ── Standard TMDB path ─────────────────────────────────────────────────────
  final ttl = _seasonCacheTtl(show?.tmdbStatus, seasonNumber, show?.totalSeasons);

  // Compute 09:00 airingAt for the next airing episode of this season.
  // Evaluated fresh each time (not cached) so it stays accurate as episodes air.
  final nextEp = detail.nextEpisodeToAir;
  DateTime? nextAt;
  int? nextEpNum;
  if (nextEp != null &&
      nextEp.seasonNumber == seasonNumber &&
      nextEp.airDate != null) {
    final d = DateTime.tryParse(nextEp.airDate!);
    if (d != null) {
      final candidate = DateTime(d.year, d.month, d.day, 9, 0);
      if (candidate.isAfter(DateTime.now())) {
        nextAt = candidate;
        nextEpNum = nextEp.episodeNumber;
      }
    }
  }

  TmdbEpisode injectAt(TmdbEpisode ep) {
    if (nextAt == null || ep.episodeNumber != nextEpNum) return ep;
    return TmdbEpisode(
      episodeNumber: ep.episodeNumber,
      name: ep.name,
      overview: ep.overview,
      stillPath: ep.stillPath,
      airDate: ep.airDate,
      voteAverage: ep.voteAverage,
      absoluteEpisodeNumber: ep.absoluteEpisodeNumber,
      airingAt: nextAt,
    );
  }

  final cached =
      await cacheDao.getFreshSeasonEpisodes(showId, seasonNumber, ttl: ttl);
  if (cached.isNotEmpty) {
    return TmdbSeason(
      seasonNumber: seasonNumber,
      episodeCount: cached.length,
      episodes: cached
          .map((e) => injectAt(TmdbEpisode(
                episodeNumber: e.episodeNumber,
                name: e.name,
                overview: e.overview,
                stillPath: e.stillPath,
                airDate: e.airDate,
                voteAverage: e.voteAverage,
                absoluteEpisodeNumber: e.absoluteEpisodeNumber,
                airingAt: e.airingAt,
              )))
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

  return TmdbSeason(
    seasonNumber: season.seasonNumber,
    episodeCount: season.episodeCount,
    name: season.name,
    episodes: season.episodes?.map(injectAt).toList(),
  );
}

// ── DB: serie tracciate (stream reattivo) ─────────────────────────────────────

@riverpod
class TrackedShowsNotifier extends _$TrackedShowsNotifier {
  @override
  Stream<List<TrackedShow>> build() {
    return ref.watch(showsDaoProvider).watchAll();
  }

  Future<void> addShow(TmdbShowDetail detail) async {
    // ── Fase 1: inserimento immediato con i dati disponibili ───────────────
    // L'utente potrebbe premere "Aggiungi" prima che AniList abbia finito
    // di caricare (animeSeasonsData == null). Inseriamo subito la serie con
    // i valori TMDB grezzi per dare feedback istantaneo all'utente.
    TmdbShowDetail effectiveDetail = detail;

    // ── Fase 2: per gli anime senza dati AniList, attendiamo il caricamento ─
    // Se animeSeasonsData è null (AniList non ancora caricato), aspettiamo
    // i dati sintetici prima di salvare totali e stagioni corrette.
    // Questo è il fix critico: senza di esso totalEpisodes viene salvato
    // dal valore TMDB grezzo che può essere inferiore al totale reale
    // (TMDB raggruppa più cours in meno stagioni).
    if (detail.isAnime && detail.animeSeasonsData == null) {
      try {
        final anilistSeasons = await ref.read(animeDataProvider(detail.id).future);
        if (anilistSeasons != null && anilistSeasons.isNotEmpty) {
          // Ricarica il detail arricchito con i dati AniList appena ottenuti
          effectiveDetail = await ref.read(showDetailProvider(detail.id).future);
        }
      } catch (_) {
        // In caso di errore, usiamo il detail originale (TMDB grezzo).
        // syncMetadata() nella pagina dettaglio correggerà i valori appena
        // i dati AniList diventano disponibili.
      }
    }

    final effectiveTotal = _effectiveTotalEpisodes(effectiveDetail);
    final effectiveSeasons = effectiveDetail.isAnime && effectiveDetail.animeSeasonsData != null
        ? effectiveDetail.animeSeasonsData!.length
        : effectiveDetail.numberOfSeasons;

    final dbId = await ref.read(showsDaoProvider).insertShow(
          TrackedShowsCompanion(
            tmdbId: Value(effectiveDetail.id),
            title: Value(effectiveDetail.name),
            overview: Value(
              (effectiveDetail.overview?.isNotEmpty ?? false) ? effectiveDetail.overview : null,
            ),
            posterPath: Value(effectiveDetail.posterPath),
            status: const Value(MediaStatus.watching),
            totalSeasons: Value(effectiveSeasons),
            totalEpisodes: Value(effectiveTotal),
            tmdbStatus: Value(effectiveDetail.status),
            isAnime: Value(effectiveDetail.isAnime),
            addedAt: Value(DateTime.now()),
          ),
        );
    final counts = {for (final s in effectiveDetail.seasons) s.seasonNumber: s.episodeCount};
    await ref.read(showsDaoProvider).insertSeasons(dbId, counts);

    // Pianifica notifica con orario preciso per anime, 09:00 per serie normali.
    await _scheduleNotification(effectiveDetail);
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

  Future<void> syncMetadata(TmdbShowDetail detail, int dbId) async {
    final show = await ref.read(showsDaoProvider).getById(dbId);
    if (show == null) return;
    
    // Forza la pulizia della cache locale per la serie, così forziamo un refresh 
    // dal web ed evitiamo problemi di mapping sporco (es. Episodio 0)
    await ref.read(cacheDaoProvider).clearCacheForShow(show.tmdbId);
    await ref.read(animeCacheDaoProvider).clearAnimeCacheForShow(show.tmdbId);
    
    // Per gli anime, usa la somma degli episodi dalle stagioni sintetiche AniList
    // invece del numberOfEpisodes TMDB grezzo (che può escludere cours futuri).
    final effectiveTotal = _effectiveTotalEpisodes(detail);
    final effectiveSeasons = detail.isAnime && detail.animeSeasonsData != null
        ? detail.animeSeasonsData!.length
        : detail.numberOfSeasons;

    if (show.totalEpisodes != effectiveTotal ||
        show.totalSeasons != effectiveSeasons ||
        show.tmdbStatus != detail.status) {
      await ref.read(showsDaoProvider).updateShowMetadata(
        dbId, 
        effectiveTotal, 
        effectiveSeasons, 
        detail.status,
      );
    }
    
    final counts = {for (final s in detail.seasons) s.seasonNumber: s.episodeCount};
    final currentCounts = await ref.read(showsDaoProvider).getSeasonCounts(dbId);
    bool countsChanged = counts.length != currentCounts.length;
    if (!countsChanged) {
      for (final s in counts.keys) {
        if (counts[s] != currentCounts[s]) {
          countsChanged = true;
          break;
        }
      }
    }
    if (countsChanged) {
      await ref.read(showsDaoProvider).insertSeasons(dbId, counts);
      ref.invalidate(seasonEpisodeCountsProvider(dbId));
    }
  }

  /// Re-schedules the notification for an already-tracked show.
  /// Safe to call multiple times (overwrites the previous notification).
  Future<void> rescheduleNotification(TmdbShowDetail detail) =>
      _scheduleNotification(detail);

  /// Fetches the show detail and re-schedules the notification.
  /// Errors are swallowed — notification scheduling is best-effort.
  Future<void> rescheduleNotificationById(int tmdbId) async {
    try {
      final detail = await ref.read(showDetailProvider(tmdbId).future);
      await _scheduleNotification(detail);
    } catch (_) {}
  }

  /// Reschedules notifications for every actively-tracked show. Acts as a
  /// safety net on app startup: if a previous schedule attempt silently
  /// skipped because TMDB's `next_episode_to_air` was still pointing at the
  /// just-aired episode, this re-runs the logic with now-current data.
  Future<void> rescheduleAllNotifications() async {
    final shows = await ref.read(showsDaoProvider).getAll();
    for (final show in shows) {
      if (show.status == MediaStatus.completed ||
          show.status == MediaStatus.dropped) {
        continue;
      }
      try {
        final detail = await ref.read(showDetailProvider(show.tmdbId).future);
        await _scheduleNotification(detail);
      } catch (_) {}
    }
  }

  Future<void> _scheduleNotification(TmdbShowDetail detail) async {
    // Anime: use AniList precise airingAt if available.
    //
    // We deliberately do NOT fall through to the 09:00 TMDB path when AniList
    // data is missing or stale: 09:00 would be wrong for most anime (which
    // typically air evening JST ≈ early afternoon Europe), and overwriting an
    // already-correct precise notification with a 09:00 one is worse than
    // leaving the existing schedule untouched.
    if (detail.isAnime) {
      if (detail.animeSeasonsData == null) return;
      for (final animeSeason in detail.animeSeasonsData!) {
        final nextAiring = animeSeason.nextAiringEpisode;
        if (nextAiring == null) continue;
        final airingAt = nextAiring.airingDateTime;
        if (!airingAt.isAfter(DateTime.now())) continue;

        String? seasonName;
        final sSeason = detail.seasons.where((s) => s.seasonNumber == animeSeason.seasonNumber).firstOrNull;
        if (sSeason != null && sSeason.name != null) {
          seasonName = sSeason.name!.split(' · ').first.trim();
        }

        await NotificationService.schedule(
          tmdbId: detail.id,
          showTitle: detail.name,
          seasonNumber: animeSeason.seasonNumber,
          episodeNumber: nextAiring.episode,
          episodeName: '',
          airDate: airingAt,
          useExactTime: true,
          seasonName: seasonName,
        );
        return;
      }
      return;
    }

    // Standard TMDB scheduling at 09:00.
    //
    // TMDB's `next_episode_to_air` lags: for several hours after an episode
    // airs it still points to the just-aired episode. Scheduling at 09:00 of
    // an already-elapsed day silently bails out in NotificationService.schedule,
    // leaving the show without a future notification. To work around this we
    // cross-reference with the season's full episode list and pick the first
    // episode whose 09:00 air time is still in the future.
    final next = detail.nextEpisodeToAir;
    if (next == null || next.airDate == null) return;

    final now = DateTime.now();
    int targetSeason = next.seasonNumber;
    int targetEpisode = next.episodeNumber;
    String targetName = next.name;
    String? targetAirDate = next.airDate;

    try {
      final season = await ref.read(seasonDetailProvider(
        showId: detail.id,
        seasonNumber: next.seasonNumber,
      ).future);
      TmdbEpisode? futureEp;
      for (final ep in season.episodes ?? const <TmdbEpisode>[]) {
        if (ep.airDate == null) continue;
        final ad = DateTime.tryParse(ep.airDate!);
        if (ad == null) continue;
        final scheduledAt = DateTime(ad.year, ad.month, ad.day, 9, 0);
        if (!scheduledAt.isAfter(now)) continue;
        if (futureEp == null || ep.episodeNumber < futureEp.episodeNumber) {
          futureEp = ep;
        }
      }
      if (futureEp != null) {
        targetEpisode = futureEp.episodeNumber;
        targetName = futureEp.name;
        targetAirDate = futureEp.airDate;
      }
    } catch (_) {}

    final airDate = DateTime.tryParse(targetAirDate!);
    if (airDate == null) return;

    String? tmdbSeasonName;
    final tSeason = detail.seasons.where((s) => s.seasonNumber == targetSeason).firstOrNull;
    if (tSeason != null && tSeason.name != null) {
      tmdbSeasonName = tSeason.name!.split(' · ').first.trim();
    }

    await NotificationService.schedule(
      tmdbId: detail.id,
      showTitle: detail.name,
      seasonNumber: targetSeason,
      episodeNumber: targetEpisode,
      episodeName: targetName,
      airDate: airDate,
      seasonName: tmdbSeasonName,
    );
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
        bool foundAnimeAiring = false;
        for (final animeSeason in detail.animeSeasonsData!) {
          final nextAiring = animeSeason.nextAiringEpisode;
          if (nextAiring == null) continue;
          final airingAt = nextAiring.airingDateTime;
          final airMidnight =
              DateTime(airingAt.year, airingAt.month, airingAt.day);
          if (airMidnight.isBefore(todayMidnight)) continue;

          // Try to get episode name from season detail (uses SQLite cache,
          // falls back to TMDB fetch if not cached yet).
          String episodeName = '';
          List<TmdbEpisode> additionalEpisodes = [];
          try {
            final seasonDetail = await ref.read(seasonDetailProvider(
              showId: show.tmdbId,
              seasonNumber: animeSeason.seasonNumber,
            ).future);
            final ep = seasonDetail.episodes
                ?.where((e) => e.episodeNumber == nextAiring.episode)
                .firstOrNull;
            if (ep != null && ep.name.isNotEmpty) episodeName = ep.name;
            
            if (seasonDetail.episodes != null && ep?.airDate != null) {
               additionalEpisodes = seasonDetail.episodes!
                   .where((e) => e.airDate == ep!.airDate && e.episodeNumber > nextAiring.episode)
                   .toList();
            }
          } catch (_) {}

          String? sName;
          final sSeason = detail.seasons.where((s) => s.seasonNumber == animeSeason.seasonNumber).firstOrNull;
          if (sSeason != null && sSeason.name != null) {
            sName = sSeason.name!.split(' · ').first.trim();
          }

          results.add(UpcomingEpisodeInfo(
            show: show,
            episode: TmdbNextEpisode(
              seasonNumber: animeSeason.seasonNumber,
              episodeNumber: nextAiring.episode,
              name: episodeName,
              airDate: airingAt.toIso8601String(),
            ),
            airDate: airMidnight,
            preciseAirTime: airingAt,
            seasonName: sName,
            additionalEpisodes: additionalEpisodes,
          ));
          foundAnimeAiring = true;
          break;
        }
        if (foundAnimeAiring) continue;
      }

      // Standard TMDB (or Anime fallback when AniList data lacks nextAiringEpisode)
      final next = detail.nextEpisodeToAir;
      if (next == null || next.airDate == null) continue;
      final airDate = DateTime.tryParse(next.airDate!);
      if (airDate == null) continue;
      final airMidnight =
          DateTime(airDate.year, airDate.month, airDate.day);
      if (airMidnight.isBefore(todayMidnight)) continue;

      // If it's an anime falling back to TMDB, we MUST map the TMDB season number
      // to the corresponding AniList season number so the UI links to the correct tab.
      int mappedSeasonNumber = next.seasonNumber;
      if (detail.isAnime && detail.animeSeasonsData != null) {
        final matchingSeason = detail.animeSeasonsData!
            .where((s) => s.tmdbSeasonNumber == next.seasonNumber)
            .firstOrNull;
        if (matchingSeason != null) {
          mappedSeasonNumber = matchingSeason.seasonNumber;
        }
      }

      String episodeName = next.name;
      List<TmdbEpisode> additionalEpisodes = [];
      final placeholderRe = RegExp(r'^Episodio\s+\d+$|^Episode\s+\d+$', caseSensitive: false);
      try {
        final seasonDetail = await ref.read(seasonDetailProvider(
          showId: show.tmdbId,
          seasonNumber: mappedSeasonNumber,
        ).future);
        final ep = seasonDetail.episodes
            ?.where((e) => e.episodeNumber == next.episodeNumber)
            .firstOrNull;
            
        if (episodeName.isEmpty || placeholderRe.hasMatch(episodeName.trim())) {
          if (ep != null && ep.name.isNotEmpty) episodeName = ep.name;
        }
        
        if (seasonDetail.episodes != null) {
           additionalEpisodes = seasonDetail.episodes!
               .where((e) => e.airDate == next.airDate && e.episodeNumber > next.episodeNumber)
               .toList();
        }
      } catch (_) {}

      String? sName;
      if (detail.isAnime) {
        final sSeason = detail.seasons.where((s) => s.seasonNumber == mappedSeasonNumber).firstOrNull;
        if (sSeason != null && sSeason.name != null) {
          sName = sSeason.name!.split(' · ').first.trim();
        }
      }

      results.add(UpcomingEpisodeInfo(
        show: show,
        episode: TmdbNextEpisode(
          seasonNumber: mappedSeasonNumber,
          episodeNumber: next.episodeNumber,
          name: episodeName,
          overview: next.overview,
          stillPath: next.stillPath,
          airDate: next.airDate,
          voteAverage: next.voteAverage,
        ),
        airDate: airMidnight,
        seasonName: sName,
        additionalEpisodes: additionalEpisodes,
      ));
    } catch (_) {
      // Ignora show non caricabili
    }
  }

  results.sort((a, b) => a.airDate.compareTo(b.airDate));
  return results;
}
