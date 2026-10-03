import '../../../../core/constants.dart';
import 'tmdb_episode.dart';

class TmdbSeason {
  final int seasonNumber;
  final int episodeCount;
  final String? posterPath;
  final String? name;
  final List<TmdbEpisode>? episodes;

  /// Data di uscita del primo episodio (`YYYY-MM-DD`), solo dal blocco
  /// `seasons[]` di /tv/{id}.
  final String? airDate;

  const TmdbSeason({
    required this.seasonNumber,
    required this.episodeCount,
    this.posterPath,
    this.name,
    this.episodes,
    this.airDate,
  });

  /// Costruito dal blocco `seasons[]` nella risposta /tv/{id}.
  factory TmdbSeason.fromJson(Map<String, dynamic> json) => TmdbSeason(
        seasonNumber: json['season_number'] as int,
        episodeCount: json['episode_count'] as int? ?? 0,
        posterPath: json['poster_path'] as String?,
        name: json['name'] as String?,
        airDate: json['air_date'] as String?,
      );

  /// Costruito dalla risposta completa /tv/{id}/season/{n}.
  factory TmdbSeason.fromDetailJson(
    Map<String, dynamic> it, {
    Map<String, dynamic>? en,
  }) {
    final itEps = it['episodes'] as List<dynamic>? ?? [];
    final enEps = en?['episodes'] as List<dynamic>? ?? [];

    final episodes = itEps.asMap().entries.map((entry) {
      final idx = entry.key;
      final itEp = entry.value as Map<String, dynamic>;
      final enEp = idx < enEps.length ? enEps[idx] as Map<String, dynamic> : null;
      return TmdbEpisode.fromJson(itEp, en: enEp);
    }).toList();

    return TmdbSeason(
      seasonNumber: it['season_number'] as int,
      episodeCount: episodes.length,
      posterPath: it['poster_path'] as String?,
      name: it['name'] as String?,
      episodes: episodes,
    );
  }

  String? get posterUrl =>
      posterPath != null ? '$kTmdbImageBase/w185$posterPath' : null;
}
