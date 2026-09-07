import 'dart:async';
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
import '../data/watch_next_rules.dart';
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

  // 1. Check cache
  final cached = await animeCacheDao.getFreshAnimeSeasons(tmdbId);
  if (cached != null) return cached;

  // 2. Fetch fresh from Yuna + AniList
  try {
    final seasons = await _fetchAnimeSeasons(ref, tmdbId);
    if (seasons != null) {
      await animeCacheDao.saveAnimeSeasons(tmdbId, seasons);
      return seasons;
    }
  } catch (_) {
    // Gestito dal fallback qui sotto.
  }

  // 3. Fallback: la cache è scaduta ma il refresh non ha prodotto nulla (rete
  // assente, Yuna/AniList non raggiungibili, rate limit). Restituire null
  // farebbe ricadere `showDetail` sulle stagioni TMDB grezze, che per un anime
  // usano una numerazione diversa da quella dei cours con cui sono salvati gli
  // episodi visti: l'utente vedrebbe conteggi senza senso ("11/23") e card
  // rotte. I dati stantii restano coerenti, quindi sono la scelta migliore.
  //
  // NB: la TTL di un cour RELEASING scade esattamente all'ora di messa in onda
  // dell'episodio successivo, quindi questo percorso è tutt'altro che raro —
  // è proprio il momento in cui l'utente apre l'app per segnare il nuovo
  // episodio.
  return animeCacheDao.getStaleAnimeSeasons(tmdbId);
}

/// Scarica e normalizza le stagioni AniList per [tmdbId].
///
/// Restituisce null quando non c'è alcun dato utilizzabile; solleva l'eccezione
/// originale in caso di errore di rete, così il chiamante può distinguere
/// "nessun dato" da "richiesta fallita".
Future<List<NormalizedAnimeSeason>?> _fetchAnimeSeasons(
  AnimeDataRef ref,
  int tmdbId,
) async {
  final animeCacheDao = ref.read(animeCacheDaoProvider);
  final tmdbSvc = ref.read(tmdbServiceProvider);
  final yunaSvc = ref.read(yunaServiceProvider);
  final anilistSvc = ref.read(anilistServiceProvider);

  // Il detail TMDB serve fino a tre volte qui sotto e ogni chiamata sono due
  // richieste HTTP (it-IT + en-US): memoizziamo la Future così ne parte una sola.
  Future<TmdbShowDetail>? detailFuture;
  Future<TmdbShowDetail> showDetails() =>
      detailFuture ??= tmdbSvc.getShowDetails(tmdbId);

  // 2a. Yuna mapping: TMDB ID → AniList IDs
  var anilistIds = await animeCacheDao.getYunaIds(tmdbId);
  if (anilistIds == null) {
    anilistIds = await yunaSvc.getAniListIds(tmdbId);
    // Non mettiamo in cache una mappatura vuota: `getAniListIds` restituisce []
    // anche quando Yuna è irraggiungibile, e la TTL di 7 giorni congelerebbe
    // quel fallimento in "questo show non esiste su AniList".
    if (anilistIds.isNotEmpty) {
      await animeCacheDao.saveYunaIds(tmdbId, anilistIds);
    }
  }

  // 2b. If Yuna has no mapping, try searching by title
  if (anilistIds.isEmpty) {
    final found =
        await _searchAniListByTmdbTitles(anilistSvc, await showDetails());
    if (found != null) anilistIds = [found.id];
  }

  if (anilistIds.isEmpty) return null;

  // 2c. Fetch AniList media for each ID
  var anilistMedia = await anilistSvc.fetchBatch(anilistIds);

  // 2c-bis. Resilienza: se gli ID Yuna non hanno restituito media validi
  // (mapping obsoleto, ID errati, anime appena annunciato non ancora
  // indicizzato) riprova con la ricerca per titolo prima di arrenderti.
  if (anilistMedia.isEmpty) {
    final found =
        await _searchAniListByTmdbTitles(anilistSvc, await showDetails());
    if (found != null) {
      anilistMedia = [found];
      // Sostituisci il mapping Yuna stale con l'ID corretto trovato per
      // titolo, così le successive richieste passano subito da AniList.
      await animeCacheDao.saveYunaIds(tmdbId, [found.id]);
    }
  }

  if (anilistMedia.isEmpty) return null;

  // 2d. Merge with TMDB season structure
  final detail = await showDetails();
  final seasons = AnimeDataMerger.merge(
    tmdbSeasons: detail.seasons,
    anilistMedia: anilistMedia,
  );

  return seasons.isEmpty ? null : seasons;
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

// ── Prossimo episodio in uscita ───────────────────────────────────────────────

/// Prossimo episodio ancora da uscire di una serie: quello che finisce nelle
/// colonne `nextEpisode*` di `TrackedShows` e nella notifica.
class _NextEpisodeInfo {
  final int? season;
  final int? episode;
  final String? name;

  /// Orario preciso per gli anime (AniList), 09:00 del giorno di uscita per le
  /// altre serie (TMDB non pubblica l'ora).
  final DateTime? airDate;

  const _NextEpisodeInfo({this.season, this.episode, this.name, this.airDate});

  bool get isKnown => season != null && episode != null;
}

// ── Show detail (enriched with AniList for anime) ─────────────────────────────

@riverpod
Future<TmdbShowDetail> showDetail(ShowDetailRef ref, int tmdbId) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(seconds: 30), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

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

  // Per gli anime i numeri di stagione sono cours sintetici (1..N) che non
  // corrispondono alle stagioni TMDB. Se arriviamo qui con un anime significa
  // che l'arricchimento AniList non è disponibile: chiedere a TMDB una stagione
  // che non esiste (es. la 5 quando TMDB ne ha 3) risponde 404, il provider
  // finisce in errore e la card mostra un episodio senza titolo né immagine.
  // Meglio dichiarare la stagione vuota e riprovare al prossimo refresh.
  if (detail.isAnime &&
      !detail.seasons.any((s) => s.seasonNumber == seasonNumber)) {
    return TmdbSeason(seasonNumber: seasonNumber, episodeCount: 0);
  }

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

    final next = await _resolveNextEpisode(effectiveDetail);

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
            nextEpisodeNumber: Value(next.episode),
            nextEpisodeSeason: Value(next.season),
            nextEpisodeName: Value(next.name),
            nextEpisodeAirDate: Value(next.airDate),
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

  /// Allinea i metadati salvati (totali, stagioni, prossimo episodio) al
  /// [detail] appena caricato.
  ///
  /// Non svuota le cache: è il pulsante di refresh nella pagina dettaglio a
  /// farlo quando l'utente lo chiede esplicitamente. Farlo qui significherebbe
  /// cancellare episodi e mapping AniList a ogni apertura della pagina — e
  /// quindi pagare un fetch completo (Yuna + N query AniList + stagioni TMDB)
  /// al successivo accesso alla lista.
  Future<void> syncMetadata(TmdbShowDetail detail, int dbId) async {
    final show = await ref.read(showsDaoProvider).getById(dbId);
    if (show == null) return;

    // Per un anime la struttura in stagioni viene da AniList (un cour per
    // stagione). Se `animeSeasonsData` è null l'arricchimento non è disponibile
    // e `detail` contiene la suddivisione TMDB grezza, che raggruppa più cours:
    // scriverla sovrascriverebbe i conteggi corretti con numeri di stagione
    // incompatibili con quelli degli episodi visti (da cui "11/23", "12/24").
    // Meglio non toccare nulla e riprovare quando AniList torna disponibile.
    if (detail.isAnime && detail.animeSeasonsData == null) return;

    // Per gli anime, usa la somma degli episodi dalle stagioni sintetiche AniList
    // invece del numberOfEpisodes TMDB grezzo (che può escludere cours futuri).
    final effectiveTotal = _effectiveTotalEpisodes(detail);
    final effectiveSeasons = detail.isAnime && detail.animeSeasonsData != null
        ? detail.animeSeasonsData!.length
        : detail.numberOfSeasons;
        
    final next = await _resolveNextEpisode(detail);

    if (show.totalEpisodes != effectiveTotal ||
        show.totalSeasons != effectiveSeasons ||
        show.tmdbStatus != detail.status ||
        show.nextEpisodeNumber != next.episode ||
        show.nextEpisodeSeason != next.season ||
        show.nextEpisodeAirDate != next.airDate) {
      await ref.read(showsDaoProvider).updateShowMetadata(
        dbId,
        effectiveTotal,
        effectiveSeasons,
        detail.status,
        nextEpisodeNumber: Value(next.episode),
        nextEpisodeSeason: Value(next.season),
        nextEpisodeName: Value(next.name),
        nextEpisodeAirDate: Value(next.airDate),
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
    // Questa funzione ora funge anche da background worker per aggiornare 
    // il database locale (architettura offline-first).
    final shows = await ref.read(showsDaoProvider).getAll();
    final eligibleShows = shows.where((s) => 
        s.status != MediaStatus.completed && s.status != MediaStatus.dropped
    ).toList();

    for (int i = 0; i < eligibleShows.length; i++) {
      final show = eligibleShows[i];
      try {
        final detail = await ref.read(showDetailProvider(show.tmdbId).future);
        // Aggiorna anche il database con il prossimo episodio, ma non cancellare la cache!
        await syncMetadata(detail, show.id);
        await _scheduleNotification(detail);
      } catch (_) {}
      
      // Attendi 2 secondi tra una serie e l'altra per non saturare la connessione
      // e non bloccare l'app se l'utente naviga nel frattempo.
      if (i < eligibleShows.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  /// Primo episodio della serie ancora da uscire, con la data più affidabile a
  /// disposizione.
  ///
  /// Anime: da AniList, con orario preciso.
  ///
  /// Altre serie: da TMDB, che però resta indietro — per diverse ore dopo la
  /// messa in onda `next_episode_to_air` punta ancora all'episodio appena
  /// uscito. Un puntatore così sporca tre cose: la notifica non viene
  /// pianificata (09:00 di un giorno passato viene scartato), "In Uscita"
  /// annuncia come futuro un episodio già uscito e "Da Vedere" non riesce più a
  /// capire che l'episodio successivo non è ancora disponibile (finendo per
  /// contare una serie di cui poi non mostra nessuna card). Quindi, quando la
  /// data è già passata, cerchiamo nella stagione il primo episodio davvero
  /// futuro.
  Future<_NextEpisodeInfo> _resolveNextEpisode(TmdbShowDetail detail) async {
    final now = DateTime.now();

    if (detail.isAnime) {
      // Senza dati AniList non inventiamo un orario: le 09:00 di TMDB sono
      // sbagliate per quasi tutti gli anime (di solito escono la sera JST).
      if (detail.animeSeasonsData == null) return const _NextEpisodeInfo();
      for (final animeSeason in detail.animeSeasonsData!) {
        final nextAiring = animeSeason.nextAiringEpisode;
        if (nextAiring != null && nextAiring.airingDateTime.isAfter(now)) {
          return _NextEpisodeInfo(
            season: animeSeason.seasonNumber,
            episode: nextAiring.episode,
            airDate: nextAiring.airingDateTime,
          );
        }
      }
      return const _NextEpisodeInfo();
    }

    final tmdbNext = detail.nextEpisodeToAir;
    if (tmdbNext == null) return const _NextEpisodeInfo();

    final parsed =
        tmdbNext.airDate != null ? DateTime.tryParse(tmdbNext.airDate!) : null;
    final candidate = _NextEpisodeInfo(
      season: tmdbNext.seasonNumber,
      episode: tmdbNext.episodeNumber,
      name: tmdbNext.name,
      airDate: parsed == null
          ? null
          : DateTime(parsed.year, parsed.month, parsed.day, 9, 0),
    );
    if (candidate.airDate != null && candidate.airDate!.isAfter(now)) {
      return candidate;
    }

    try {
      final season = await ref.read(seasonDetailProvider(
        showId: detail.id,
        seasonNumber: tmdbNext.seasonNumber,
      ).future);

      TmdbEpisode? futureEp;
      DateTime? futureAt;
      for (final ep in season.episodes ?? const <TmdbEpisode>[]) {
        if (ep.airDate == null) continue;
        final ad = DateTime.tryParse(ep.airDate!);
        if (ad == null) continue;
        final scheduledAt = DateTime(ad.year, ad.month, ad.day, 9, 0);
        if (!scheduledAt.isAfter(now)) continue;
        if (futureEp == null || ep.episodeNumber < futureEp.episodeNumber) {
          futureEp = ep;
          futureAt = scheduledAt;
        }
      }

      if (futureEp != null) {
        return _NextEpisodeInfo(
          season: tmdbNext.seasonNumber,
          episode: futureEp.episodeNumber,
          name: futureEp.name,
          airDate: futureAt,
        );
      }
    } catch (_) {
      // Rete assente o stagione non disponibile: teniamo il dato TMDB grezzo.
    }

    return candidate;
  }

  Future<void> _scheduleNotification(TmdbShowDetail detail) async {
    final next = await _resolveNextEpisode(detail);
    if (!next.isKnown || next.airDate == null) return;

    String? seasonName;
    final season =
        detail.seasons.where((s) => s.seasonNumber == next.season).firstOrNull;
    if (season != null && season.name != null) {
      seasonName = season.name!.split(' · ').first.trim();
    }

    await NotificationService.schedule(
      tmdbId: detail.id,
      showTitle: detail.name,
      seasonNumber: next.season!,
      episodeNumber: next.episode!,
      episodeName: next.name ?? '',
      airDate: next.airDate!,
      // Solo AniList conosce l'ora esatta; per TMDB resta la convenzione 09:00.
      useExactTime: detail.isAnime,
      seasonName: seasonName,
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

// ── Lista "Da Vedere" ─────────────────────────────────────────────────────────

/// Serie in visione che hanno davvero qualcosa da guardare (o un riepilogo da
/// mostrare, per le serie terminate e viste tutte).
///
/// È l'unica autorità sulla visibilità: la lista che ne deriva e il numero
/// nell'intestazione ("Da Vedere (n)") sono lo stesso dato, e `NextEpisodeCard`
/// applica le stesse regole (`watch_next_rules.dart`) sugli stessi input, quindi
/// non può contarsi una card che poi si nasconde.
///
/// Lavora solo su dati locali — DB, cache episodi TMDB, cache AniList — così la
/// lista compare anche offline e non paghiamo richieste di rete per contarla.
final visibleWatchingShowsProvider =
    FutureProvider.autoDispose<List<ShowWithWatchedEpisodes>>((ref) async {
  final watching = await ref.watch(watchingShowsWithEpisodesProvider.future);
  if (watching.isEmpty) return [];

  final cacheDao = ref.read(cacheDaoProvider);
  final animeCacheDao = ref.read(animeCacheDaoProvider);

  final visible = <ShowWithWatchedEpisodes>[];

  for (final showData in watching) {
    final show = showData.show;
    final watched = showData.watchedBySeason;
    final watchedCount = showData.watchedCount;
    final seasonCounts =
        await ref.watch(seasonEpisodeCountsProvider(show.id).future);

    // Dati AniList dalla sola cache (fresca o stantia): un fetch qui
    // bloccherebbe l'intera lista dietro Yuna + AniList per ogni serie.
    final animeSeasonsData = show.isAnime
        ? await animeCacheDao.getFreshAnimeSeasons(show.tmdbId) ??
            await animeCacheDao.getStaleAnimeSeasons(show.tmdbId)
        : null;

    final (nextSeason, nextEp) = computeNextToWatch(
      watched,
      seasonCounts,
      animeSeasonsData: animeSeasonsData,
    );

    // L'episodio successivo è già andato in onda? Stessa precedenza di fonti
    // della card (AniList → TMDB → soli dati locali). Il verdetto TMDB arriva
    // dagli episodi in cache, che è ciò che la card stessa vedrà.
    final cachedEpisodes =
        await cacheDao.getSeasonEpisodesIgnoringTtl(show.tmdbId, nextSeason);
    final hasAired = resolveHasAired(
      show: show,
      dbSeasonCounts: seasonCounts,
      season: nextSeason,
      episode: nextEp,
      animeSeasonsData: animeSeasonsData,
      airedPerTmdb: airedPerCachedEpisodes(cachedEpisodes, nextEp),
    );

    // Ha visto tutto quello che esiste? Per gli anime con dati AniList non ci
    // fidiamo di `watchedCount >= totalEpisodes` (il totale può includere cours
    // con episodeCount ignoto): decide la struttura in cours.
    final lastWatchedSeason =
        watched.keys.isEmpty ? 0 : watched.keys.reduce((a, b) => a > b ? a : b);
    final isCompleted = animeSeasonsData != null
        ? (cachedEpisodes.isEmpty &&
            !hasLaterUpcomingAnimeSeason(animeSeasonsData, lastWatchedSeason))
        : (show.totalEpisodes != null && watchedCount >= show.totalEpisodes!);

    if (isCompleted && !hasAired) {
      // Serie terminata e vista tutta: la card mostra il riepilogo con
      // "Segna come Completata". Altrimenti aspetta nuovi episodi, niente card.
      final isTerminata =
          show.tmdbStatus == 'Ended' || show.tmdbStatus == 'Canceled';
      if (isTerminata) visible.add(showData);
      continue;
    }

    // Episodio non ancora uscito: l'utente è in pari, comparirà in "In Uscita".
    if (!hasAired) continue;

    visible.add(showData);
  }

  return visible;
});

// ── Prossimi episodi in uscita ────────────────────────────────────────────────

@riverpod
Future<List<UpcomingEpisodeInfo>> upcomingEpisodes(
    UpcomingEpisodesRef ref) async {
  final shows = await ref.watch(trackedShowsNotifierProvider.future);

  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);
  
  final watchingShows = shows.where((s) => s.status == MediaStatus.watching).toList();
  
  final results = <UpcomingEpisodeInfo>[];

  for (final show in watchingShows) {
    if (show.nextEpisodeAirDate == null || show.nextEpisodeSeason == null || show.nextEpisodeNumber == null) {
      continue;
    }

    final airMidnight = DateTime(
      show.nextEpisodeAirDate!.year, 
      show.nextEpisodeAirDate!.month, 
      show.nextEpisodeAirDate!.day
    );

    if (airMidnight.isBefore(todayMidnight)) {
      continue;
    }

    results.add(UpcomingEpisodeInfo(
      show: show,
      episode: TmdbNextEpisode(
        seasonNumber: show.nextEpisodeSeason!,
        episodeNumber: show.nextEpisodeNumber!,
        name: show.nextEpisodeName ?? '',
        airDate: show.nextEpisodeAirDate!.toIso8601String(),
      ),
      airDate: airMidnight,
      preciseAirTime: show.isAnime ? show.nextEpisodeAirDate : null,
      seasonName: null,
      additionalEpisodes: const [], 
    ));
  }

  results.sort((a, b) => a.airDate.compareTo(b.airDate));
  return results;
}
