import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'core/auth/auth_state.dart';
import 'core/database/database_provider.dart';
import 'core/database/daos/shows_dao.dart';
import 'core/riverpod_utils.dart';
import 'core/services/coalescing_refresh.dart';
import 'features/series/data/models/tmdb_episode.dart';
import 'features/series/data/models/tmdb_season.dart';
import 'features/series/data/watch_next_rules.dart';
import 'features/series/providers/series_providers.dart';

// Callback per le azioni in background (es. pulsante "Maratona")
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host != 'mark_watched') return;
  final showId = int.tryParse(uri?.queryParameters['id'] ?? '');
  final season = int.tryParse(uri?.queryParameters['s'] ?? '');
  final episode = int.tryParse(uri?.queryParameters['e'] ?? '');
  if (showId == null || season == null || episode == null) return;

  final container = ProviderContainer(retry: noProviderRetry);
  try {
    // Il client intercettato deve vedere le credenziali ripristinate prima
    // dell'eventuale arricchimento remoto; i dati locali non dipendono dal login.
    await container.readFuture(authControllerProvider.future);
    final db = container.read(databaseProvider);
    await db.showsDao.markEpisodeWatched(
      showId,
      season,
      episode,
      watched: true,
    );
    // Attende anche gli eventuali passaggi trailing prima di chiudere il DB.
    await ShowTrackerWidgetsManager.updateWidgets(container: container);
  } finally {
    container.dispose();
  }
}

class _WidgetRefresh {
  _WidgetRefresh(ProviderContainer container) {
    refresh = CoalescingRefresh(() async {
      final snapshot = await ShowTrackerWidgetsManager._prepare(container);
      await ShowTrackerWidgetsManager._publish(snapshot, drainToken);
    });
  }

  late final CoalescingRefresh refresh;
  Object drainToken = Object();

  Future<void> request() {
    if (!refresh.isActive) drainToken = Object();
    return refresh.request();
  }
}

class ShowTrackerWidgetsManager {
  static final _refreshes = Expando<_WidgetRefresh>();
  static final _imageDownloads = <String, Future<String?>>{};
  static Future<void> _publication = Future<void>.value();
  static Object? _lastPublishedToken;
  static Map<String, String>? _lastPublished;

  static Future<void> setup() async {
    await HomeWidget.setAppGroupId('group.showtracker');
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  /// Each container reads current providers in a serialized, coalesced pass.
  /// The returned Future includes all trailing work requested during that drain.
  static Future<void> updateWidgets({
    ProviderContainer? container,
    // Kept for callers compiled against the old API. Never use stale snapshots.
    List<ShowWithWatchedEpisodes>? watchingList,
  }) async {
    final c = container ?? ProviderContainer(retry: noProviderRetry);
    try {
      final refresh = _refreshes[c] ??= _WidgetRefresh(c);
      await refresh.request();
    } finally {
      if (container == null) c.dispose();
    }
  }

  static Future<String?> _downloadImage(String? url, String filename) {
    if (url == null || url.isEmpty) return Future<String?>.value();
    return _imageDownloads.putIfAbsent(url, () async {
      try {
        return await _fetchImage(url, filename);
      } finally {
        _imageDownloads.remove(url);
      }
    });
  }

  static Future<String?> _fetchImage(String url, String filename) async {
    final client = http.Client();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      // Conserva la cache file esistente: nessuna cancellazione automatica.
      if (await file.exists()) return file.path;

      final response =
          await client.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes, flush: true);
        return file.path;
      }
    } catch (_) {
      // Il nuovo snapshot cancella esplicitamente l'immagine precedente.
    } finally {
      client.close();
    }
    return null;
  }

  static String _formatMonth(int month) {
    const months = [
      'gen',
      'feb',
      'mar',
      'apr',
      'mag',
      'giu',
      'lug',
      'ago',
      'set',
      'ott',
      'nov',
      'dic',
    ];
    return months[month - 1];
  }

  static String _formatEpisodeTitle(
      int season, int episode, String? seasonName) {
    if (seasonName != null) {
      final baseName = seasonName.split(' · ').first.trim();
      var abbr = baseName.replaceAll(
        RegExp(r'^(Stagione|Season)\s*', caseSensitive: false),
        'S',
      );
      abbr = abbr.replaceAll(
        RegExp(r'\s*Parte\s*', caseSensitive: false),
        ' P',
      );
      abbr = abbr.replaceAllMapped(RegExp(r'(S)(\d)(?!\d)'), (match) {
        return '${match.group(1)}0${match.group(2)}';
      });
      return '$abbr E${episode.toString().padLeft(2, '0')}';
    }
    return 'S${season.toString().padLeft(2, '0')} E${episode.toString().padLeft(2, '0')}';
  }

  static Future<Map<String, String>> _prepare(ProviderContainer c) async {
    final snapshot = <String, String>{
      'marathon_title': 'Tutto in pari!',
      'marathon_episode_title': 'Ottimo lavoro.',
      'marathon_show_id': '',
      'marathon_mark_uri': '',
      'marathon_image': '',
    };
    await _prepareMarathon(c, snapshot);

    final upcoming = await c.readFuture(upcomingEpisodesProvider.future);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 2; i++) {
      final prefix = 'upcoming_${i + 1}';
      // Empty slots and failed images must not keep the previous show's data.
      snapshot.addAll({
        '${prefix}_title': i == 0 ? 'Nessuna uscita' : '',
        '${prefix}_se': '',
        '${prefix}_countdown': '',
        '${prefix}_date': '',
        '${prefix}_id': '',
        '${prefix}_image': '',
      });
      if (i >= upcoming.length) continue;
      final item = upcoming[i];
      final poster = item.show.posterPath == null
          ? null
          : 'https://image.tmdb.org/t/p/w500${item.show.posterPath}';
      final hash = poster?.hashCode.toString() ?? 'none';
      final image = await _downloadImage(poster, '${prefix}_$hash.jpg');
      final airDay = DateTime(
        item.airDate.year,
        item.airDate.month,
        item.airDate.day,
      );
      final diff = airDay.difference(today).inDays;
      snapshot.addAll({
        '${prefix}_title': item.show.title,
        '${prefix}_se': _formatEpisodeTitle(
          item.episode.seasonNumber,
          item.episode.episodeNumber,
          item.seasonName,
        ),
        '${prefix}_countdown':
            diff <= 0 ? 'Oggi' : (diff == 1 ? 'Domani' : 'Tra $diff giorni'),
        '${prefix}_date':
            '${item.airDate.day} ${_formatMonth(item.airDate.month)}',
        '${prefix}_id': item.show.tmdbId.toString(),
        '${prefix}_image': image ?? '',
      });
    }
    return snapshot;
  }

  static Future<void> _prepareMarathon(
    ProviderContainer c,
    Map<String, String> snapshot,
  ) async {
    final watching = await c.readFuture(visibleWatchingShowsProvider.future);
    if (watching.isEmpty) return;
    // Unknown/loading auth also stays local. Foreground bootstrap and the
    // background entry point restore auth before requesting remote enrichment.
    final auth = c.read(authControllerProvider).value;
    final canEnrich =
        auth is AuthenticatedWithSession || auth is AuthenticatedWithManualKey;
    for (final showData in watching) {
      final show = showData.show;
      final counts = await c.readFuture(
        seasonEpisodeCountsProvider(show.id).future,
      );
      // Fresh e stale hanno la stessa numerazione cour. Nessun fetch AniList
      // aggiuntivo per decidere quale episodio proporre, anche offline.
      final animeSeasons = show.isAnime
          ? await c
              .read(animeCacheDaoProvider)
              .getStaleAnimeSeasons(show.tmdbId)
          : null;
      final (season, episode) = computeNextToWatch(
        showData.watchedBySeason,
        counts,
        animeSeasonsData: animeSeasons,
      );
      final cached = await c
          .read(cacheDaoProvider)
          .getSeasonEpisodesIgnoringTtl(show.tmdbId, season);
      final cachedAired = airedPerCachedEpisodes(cached, episode);
      final locallyAired = resolveHasAired(
        show: show,
        dbSeasonCounts: counts,
        season: season,
        episode: episode,
        animeSeasonsData: animeSeasons,
        airedPerTmdb: cachedAired,
      );
      // visibleWatchingShows include anche riepiloghi di serie terminate:
      // non sono episodi da segnare e non devono finire in Maratona.
      if (!locallyAired) continue;

      TmdbSeason? details;
      if (canEnrich && (!show.isAnime || animeSeasons != null)) {
        try {
          details = await c.readFuture(seasonDetailProvider(
            showId: show.tmdbId,
            seasonNumber: season,
          ).future);
        } catch (_) {
          // Metadati estetici facoltativi; il fallback locale resta utilizzabile.
        }
      }
      final cachedEpisode =
          cached.where((e) => e.episodeNumber == episode).firstOrNull;
      final nextEpisode = details?.episodes
          ?.where((e) => e.episodeNumber == episode)
          .firstOrNull;
      if (!resolveHasAired(
        show: show,
        dbSeasonCounts: counts,
        season: season,
        episode: episode,
        animeSeasonsData: animeSeasons,
        airedPerTmdb: nextEpisode?.hasAired ?? cachedAired,
      )) {
        continue;
      }

      final fallbackEpisode = cachedEpisode == null
          ? null
          : TmdbEpisode(
              episodeNumber: episode,
              name: cachedEpisode.name,
              stillPath: cachedEpisode.stillPath,
            );
      final poster = show.posterPath == null
          ? null
          : 'https://image.tmdb.org/t/p/w500${show.posterPath}';
      final imageUrl =
          nextEpisode?.stillUrl ?? fallbackEpisode?.stillUrl ?? poster;
      final hash = imageUrl?.hashCode.toString() ?? 'none';
      final image = await _downloadImage(
        imageUrl,
        'marathon_${show.id}_s${season}_e${episode}_$hash.jpg',
      );
      // seasonDetail ha già letto il dettaglio condiviso; non iniziarne uno
      // nuovo solo per la label se il provider è fallito (o sostituito nei test).
      final detailProvider = showDetailProvider(show.tmdbId);
      final detail =
          c.exists(detailProvider) ? c.read(detailProvider).value : null;
      final seasonName = details?.name ??
          detail?.seasons
              .where((s) => s.seasonNumber == season)
              .firstOrNull
              ?.name;
      snapshot.addAll({
        'marathon_title': show.title,
        'marathon_episode_title':
            _formatEpisodeTitle(season, episode, seasonName),
        'marathon_show_id': show.tmdbId.toString(),
        'marathon_mark_uri':
            'homeWidget://mark_watched?id=${show.id}&s=$season&e=$episode',
        'marathon_image': image ?? '',
      });
      return;
    }
  }

  static Future<void> _publish(
      Map<String, String> snapshot, Object drainToken) {
    // Serialize native writes across containers in this isolate as well. This
    // is not an atomic transaction or a cross-isolate lock in HomeWidget.
    final publication = _publication.then((_) async {
      // Only suppress identical trailing passes of the SAME drain. A later
      // independent flush must write again: another isolate could have changed
      // the shared preferences while this isolate was idle.
      if (identical(_lastPublishedToken, drainToken) &&
          mapEquals(_lastPublished, snapshot)) {
        return;
      }
      try {
        for (final entry in snapshot.entries) {
          final saved = await HomeWidget.saveWidgetData(entry.key, entry.value);
          if (saved == false) throw StateError('HomeWidget save: ${entry.key}');
        }
        final upcomingUpdated = await HomeWidget.updateWidget(
          name: 'ProssimamenteWidgetProvider',
          iOSName: 'ProssimamenteWidget',
        );
        if (upcomingUpdated == false) {
          throw StateError('HomeWidget Prossimamente');
        }
        final marathonUpdated = await HomeWidget.updateWidget(
          name: 'MaratonaWidgetProvider',
          iOSName: 'MaratonaWidget',
        );
        if (marathonUpdated == false) throw StateError('HomeWidget Maratona');
        _lastPublished = Map.of(snapshot);
        _lastPublishedToken = drainToken;
      } catch (_) {
        _lastPublished = null;
        _lastPublishedToken = null;
        rethrow;
      }
    });
    // Keep the serialization tail healthy without swallowing the caller's error.
    _publication =
        publication.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return publication;
  }
}
