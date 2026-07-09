import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'core/database/database_provider.dart';
import 'features/series/providers/series_providers.dart';
import 'features/series/presentation/next_episodes_screen.dart';
import 'features/series/data/tmdb_service.dart';

// Callback per le azioni in background (es. pulsante "Maratona")
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'mark_watched') {
    final showIdStr = uri?.queryParameters['id'];
    final seasonStr = uri?.queryParameters['s'];
    final episodeStr = uri?.queryParameters['e'];
    
    if (showIdStr != null && seasonStr != null && episodeStr != null) {
      final showId = int.tryParse(showIdStr);
      final s = int.tryParse(seasonStr);
      final e = int.tryParse(episodeStr);
      
      if (showId != null && s != null && e != null) {
        final container = ProviderContainer();
        try {
          final db = container.read(databaseProvider);
          await db.showsDao.markEpisodeWatched(showId, s, e, watched: true);
          // Ricalcola lo stato del widget e aggiornalo
          await ShowTrackerWidgetsManager.updateWidgets(container: container);
        } finally {
          container.dispose();
        }
      }
    }
  }
}

class ShowTrackerWidgetsManager {
  static Future<void> setup() async {
    await HomeWidget.setAppGroupId('group.showtracker');
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  static Future<String?> _downloadImage(String? url, String filename) async {
    if (url == null || url.isEmpty) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      
      // Se il file esiste già, usalo direttamente per evitare download ripetuti
      if (await file.exists()) {
        return file.path;
      }
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  static String _formatMonth(int month) {
    const months = ['gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott', 'nov', 'dic'];
    return months[month - 1];
  }

  static Future<void> updateWidgets({ProviderContainer? container}) async {
    final shouldDispose = container == null;
    final c = container ?? ProviderContainer();

    try {
      // ---- WIDGET 2: MARATONA ----
      final watching = await c.read(watchingShowsWithEpisodesProvider.future);
      bool foundMaratona = false;
      
      for (final showData in watching) {
         final show = showData.show;
         final watchedCount = showData.watchedCount;
         final total = show.totalEpisodes ?? 9999;
         
         // Se lo show è completato (visti tutti gli episodi), skippa
         if (watchedCount >= total) continue;
         
         final watched = showData.watchedBySeason;
         final seasonCounts = await c.read(seasonEpisodeCountsProvider(show.id).future) ?? {};
         
         int s = 1;
         int e = 1;
         if (watched.isNotEmpty) {
            final lastSeason = watched.keys.reduce((a, b) => a > b ? a : b);
            final lastEp = watched[lastSeason]!.reduce((a, b) => a > b ? a : b);
            e = lastEp + 1;
            final countInSeason = seasonCounts[lastSeason];
            final hasNextSeason = seasonCounts.containsKey(lastSeason + 1);
            if (countInSeason != null && countInSeason > 0 && e > countInSeason && hasNextSeason) {
              s = lastSeason + 1;
              e = 1;
            } else {
              s = lastSeason;
            }
         }
         
         final posterUrl = show.posterPath != null ? 'https://image.tmdb.org/t/p/w500${show.posterPath}' : null;
         String? finalImgUrl = posterUrl;
         
         try {
           final tmdb = c.read(tmdbServiceProvider);
           final seasonDetails = await tmdb.getSeasonDetails(show.tmdbId, s);
           if (seasonDetails.episodes != null) {
             final ep = seasonDetails.episodes!.firstWhere((element) => element.episodeNumber == e);
             if (ep.stillUrl != null) {
               finalImgUrl = ep.stillUrl;
             }
           }
         } catch (_) {}
         
         // Genera un nome file univoco per questa specifica puntata,
         // così se il file esiste già saltiamo il download e il widget si aggiorna istantaneamente.
         final fileName = 'marathon_${show.id}_s${s}_e${e}.jpg';
         final imgPath = await _downloadImage(finalImgUrl, fileName);
         
         await HomeWidget.saveWidgetData('marathon_title', show.title);
         await HomeWidget.saveWidgetData('marathon_episode_title', 'S${s.toString().padLeft(2, '0')} E${e.toString().padLeft(2, '0')}');
         await HomeWidget.saveWidgetData('marathon_show_id', show.tmdbId.toString());
         await HomeWidget.saveWidgetData('marathon_mark_uri', 'homeWidget://mark_watched?id=${show.id}&s=$s&e=$e');
         if (imgPath != null) await HomeWidget.saveWidgetData('marathon_image', imgPath);
         
         foundMaratona = true;
         break;
      }

      if (!foundMaratona) {
         await HomeWidget.saveWidgetData('marathon_title', 'Tutto in pari!');
         await HomeWidget.saveWidgetData('marathon_episode_title', 'Ottimo lavoro.');
         await HomeWidget.saveWidgetData('marathon_show_id', '');
         await HomeWidget.saveWidgetData('marathon_mark_uri', '');
         await HomeWidget.saveWidgetData('marathon_image', '');
      }

      // ---- WIDGET 1: PROSSIMAMENTE ----
      final upcoming = await c.read(upcomingEpisodesProvider.future);
      
      if (upcoming.isNotEmpty) {
         final up1 = upcoming[0];
         final poster1 = up1.show.posterPath != null ? 'https://image.tmdb.org/t/p/w500${up1.show.posterPath}' : null;
         final img1 = await _downloadImage(poster1, 'upcoming_1.jpg');
         
         await HomeWidget.saveWidgetData('upcoming_1_title', up1.show.title);
         await HomeWidget.saveWidgetData('upcoming_1_se', 'S${up1.episode.seasonNumber.toString().padLeft(2,'0')} E${up1.episode.episodeNumber.toString().padLeft(2,'0')}');
         
         final diff1 = up1.airDate.difference(DateTime.now()).inDays;
         final countdown1 = diff1 <= 0 ? 'Oggi' : 'Tra $diff1 giorni';
         
         await HomeWidget.saveWidgetData('upcoming_1_countdown', countdown1);
         await HomeWidget.saveWidgetData('upcoming_1_date', '${up1.airDate.day} ${_formatMonth(up1.airDate.month)}');
         await HomeWidget.saveWidgetData('upcoming_1_id', up1.show.tmdbId.toString());
         if (img1 != null) await HomeWidget.saveWidgetData('upcoming_1_image', img1);
      } else {
         await HomeWidget.saveWidgetData('upcoming_1_title', 'Nessuna uscita');
         await HomeWidget.saveWidgetData('upcoming_1_se', '');
         await HomeWidget.saveWidgetData('upcoming_1_countdown', '');
         await HomeWidget.saveWidgetData('upcoming_1_date', '');
         await HomeWidget.saveWidgetData('upcoming_1_id', '');
         await HomeWidget.saveWidgetData('upcoming_1_image', '');
      }
      
      if (upcoming.length > 1) {
         final up2 = upcoming[1];
         final poster2 = up2.show.posterPath != null ? 'https://image.tmdb.org/t/p/w500${up2.show.posterPath}' : null;
         final img2 = await _downloadImage(poster2, 'upcoming_2.jpg');
         
         await HomeWidget.saveWidgetData('upcoming_2_title', up2.show.title);
         await HomeWidget.saveWidgetData('upcoming_2_se', 'S${up2.episode.seasonNumber.toString().padLeft(2,'0')} E${up2.episode.episodeNumber.toString().padLeft(2,'0')}');
         
         final diff2 = up2.airDate.difference(DateTime.now()).inDays;
         final countdown2 = diff2 <= 0 ? 'Oggi' : 'Tra $diff2 giorni';
         
         await HomeWidget.saveWidgetData('upcoming_2_countdown', countdown2);
         await HomeWidget.saveWidgetData('upcoming_2_date', '${up2.airDate.day} ${_formatMonth(up2.airDate.month)}');
         await HomeWidget.saveWidgetData('upcoming_2_id', up2.show.tmdbId.toString());
         if (img2 != null) await HomeWidget.saveWidgetData('upcoming_2_image', img2);
      } else {
         await HomeWidget.saveWidgetData('upcoming_2_title', '');
         await HomeWidget.saveWidgetData('upcoming_2_se', '');
         await HomeWidget.saveWidgetData('upcoming_2_countdown', '');
         await HomeWidget.saveWidgetData('upcoming_2_date', '');
         await HomeWidget.saveWidgetData('upcoming_2_id', '');
         await HomeWidget.saveWidgetData('upcoming_2_image', '');
      }

      // Aggiorna fisicamente i widget su Android
      await HomeWidget.updateWidget(
          name: 'ProssimamenteWidgetProvider',
          iOSName: 'ProssimamenteWidget'
      );
      await HomeWidget.updateWidget(
          name: 'MaratonaWidgetProvider',
          iOSName: 'MaratonaWidget'
      );
    } finally {
      if (shouldDispose) c.dispose();
    }
  }
}
