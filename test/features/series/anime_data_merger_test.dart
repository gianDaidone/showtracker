import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/features/series/data/anime_data_merger.dart';
import 'package:showtracker/features/series/data/models/anilist_media.dart';
import 'package:showtracker/features/series/data/models/tmdb_season.dart';

void main() {
  // Black Clover (TMDB 73223) al 2026-10-03: la seconda stagione è appena
  // confluita come Stagione 2, ma Yuna conosce solo la serie del 2017.
  const tmdbSeasons = [
    TmdbSeason(seasonNumber: 1, episodeCount: 170, airDate: '2017-10-03'),
    TmdbSeason(seasonNumber: 2, episodeCount: 2, airDate: '2026-10-03'),
  ];
  const original = AniListMedia(
    id: 97940,
    status: 'FINISHED',
    format: 'TV',
    episodes: 170,
    season: 'FALL',
    seasonYear: 2017,
    streamingEpisodes: [],
  );
  const secondSeason = AniListMedia(
    id: 195604,
    status: 'RELEASING',
    format: 'TV',
    season: 'FALL',
    seasonYear: 2026,
    streamingEpisodes: [],
  );

  test('stagione TMDB senza voce AniList diventa un segnaposto', () {
    final seasons = AnimeDataMerger.merge(
      tmdbSeasons: tmdbSeasons,
      anilistMedia: [original],
    );
    expect(seasons.map((s) => s.anilistId), [97940, -1]);
    expect(seasons[1].tmdbSeasonNumber, 2);
  });

  test('con la voce trovata per titolo il cour viene agganciato', () {
    final seasons = AnimeDataMerger.merge(
      tmdbSeasons: tmdbSeasons,
      anilistMedia: [original, secondSeason],
    );
    expect(seasons.map((s) => s.anilistId), [97940, 195604]);
    // La numerazione dei cour (su cui sono salvati gli episodi visti) non
    // cambia: il cour 2 resta legato alla Stagione 2 di TMDB.
    expect(seasons.map((s) => s.seasonNumber), [1, 2]);
    expect(seasons[1].tmdbSeasonNumber, 2);
    expect(seasons[1].status, 'RELEASING');
  });
}
