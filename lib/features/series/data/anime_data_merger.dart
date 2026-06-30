import 'models/anilist_media.dart';
import 'models/normalized_anime_season.dart';
import 'models/tmdb_season.dart';

class AnimeDataMerger {
  // Formati primari: trasmissioni TV "classiche".
  static const _primaryFormats = {'TV', 'TV_SHORT'};
  // Fallback: ONA (Original Net Animation), tipico delle produzioni
  // streaming-first (Netflix, Crunchyroll Originals, ecc.). Lo usiamo solo se
  // non esiste nessun entry TV/TV_SHORT, così per gli anime TV "normali"
  // continuiamo a escludere gli ONA correlati (recap, extra, side-stories).
  static const _fallbackFormats = {'ONA'};

  static const _seasonOrder = {
    'WINTER': 0,
    'SPRING': 1,
    'SUMMER': 2,
    'FALL': 3,
  };

  /// Merges TMDB seasons with AniList media into normalized anime seasons.
  ///
  /// [tmdbSeasons] are the non-special seasons from TmdbShowDetail.
  /// [anilistMedia] are the raw AniList media entries for this show.
  /// [maxSeasons] is TmdbShowDetail.numberOfSeasons (clamps the result).
  static List<NormalizedAnimeSeason> merge({
    required List<TmdbSeason> tmdbSeasons,
    required List<AniListMedia> anilistMedia,
  }) {
    // 1. Prefer TV/TV_SHORT; fallback su ONA se non c'è nessun entry TV
    //    (anime streaming-only come Witch Hat Atelier hanno format=ONA).
    var filtered = anilistMedia
        .where((m) => _primaryFormats.contains(m.format))
        .toList();
    if (filtered.isEmpty) {
      filtered = anilistMedia
          .where((m) => _fallbackFormats.contains(m.format))
          .toList();
    }

    if (filtered.isEmpty) return [];

    // 2. Sort deterministically: year ASC, season order ASC, id ASC
    filtered.sort((a, b) {
      final yearCmp = (a.seasonYear ?? 0).compareTo(b.seasonYear ?? 0);
      if (yearCmp != 0) return yearCmp;
      final orderA = _seasonOrder[a.season] ?? 99;
      final orderB = _seasonOrder[b.season] ?? 99;
      final orderCmp = orderA.compareTo(orderB);
      if (orderCmp != 0) return orderCmp;
      return a.id.compareTo(b.id);
    });

    // AniList is authoritative for season count — no clamping to TMDB.
    // TMDB often groups multiple cours into fewer seasons; AniList always
    // splits correctly. tmdbSeasons is used only for positional mapping below.

    // 3. Build normalized seasons with positional TMDB season mapping
    final result = <NormalizedAnimeSeason>[];
    for (var i = 0; i < filtered.length; i++) {
      final media = filtered[i];
      // Positional mapping: AniList season i → TMDB seasons[i]
      final tmdbSeasonNumber =
          i < tmdbSeasons.length ? tmdbSeasons[i].seasonNumber : (i + 1);

      result.add(NormalizedAnimeSeason(
        seasonNumber: i + 1,
        tmdbSeasonNumber: tmdbSeasonNumber,
        anilistId: media.id,
        episodeCount: media.episodes ?? 0,
        status: media.status,
        season: media.season,
        seasonYear: media.seasonYear,
        titleRomaji: media.titleRomaji,
        titleEnglish: media.titleEnglish,
        averageScore: media.averageScore,
        nextAiringEpisode: media.nextAiringEpisode,
        streamingEpisodes: media.streamingEpisodes,
      ));
    }

    return result;
  }
}
