import '../../../../core/constants.dart';
import 'tmdb_episode.dart';
import 'tmdb_season.dart';

// ── Prossimo episodio in uscita (da TMDB next_episode_to_air) ─────────────────

class TmdbNextEpisode {
  final int seasonNumber;
  final int episodeNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final String? airDate;
  final double? voteAverage;

  const TmdbNextEpisode({
    required this.seasonNumber,
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.stillPath,
    this.airDate,
    this.voteAverage,
  });

  factory TmdbNextEpisode.fromJson(Map<String, dynamic> json) {
    return TmdbNextEpisode(
      seasonNumber: json['season_number'] as int? ?? 0,
      episodeNumber: json['episode_number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      overview: (json['overview'] as String?)?.isNotEmpty == true
          ? json['overview'] as String
          : null,
      stillPath: json['still_path'] as String?,
      airDate: json['air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }

  /// Converte in TmdbEpisode per riusare showEpisodeDetailSheet.
  TmdbEpisode toTmdbEpisode() => TmdbEpisode(
        episodeNumber: episodeNumber,
        name: name,
        overview: overview,
        stillPath: stillPath,
        airDate: airDate,
        voteAverage: voteAverage,
      );
}

class TmdbShowDetail {
  final int id;
  final String name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? status;
  final bool inProduction;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final double? voteAverage;
  final String? firstAirDate;
  final List<String> genres;
  final List<TmdbSeason> seasons;
  final TmdbNextEpisode? nextEpisodeToAir;

  const TmdbShowDetail({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.status,
    required this.inProduction,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.voteAverage,
    this.firstAirDate,
    required this.genres,
    required this.seasons,
    this.nextEpisodeToAir,
  });

  factory TmdbShowDetail.fromJson(
    Map<String, dynamic> it, {
    Map<String, dynamic>? en,
  }) {
    String? nonEmpty(String key) {
      final v = it[key] as String?;
      if (v != null && v.isNotEmpty) return v;
      final fb = en?[key] as String?;
      return (fb?.isNotEmpty ?? false) ? fb : null;
    }

    final rawSeasons = it['seasons'] as List<dynamic>? ?? [];

    return TmdbShowDetail(
      id: it['id'] as int,
      name: nonEmpty('name') ?? '',
      overview: nonEmpty('overview'),
      posterPath: it['poster_path'] as String?,
      backdropPath: it['backdrop_path'] as String?,
      status: it['status'] as String?,
      inProduction: it['in_production'] as bool? ?? false,
      numberOfSeasons: it['number_of_seasons'] as int?,
      numberOfEpisodes: it['number_of_episodes'] as int?,
      voteAverage: (it['vote_average'] as num?)?.toDouble(),
      firstAirDate: it['first_air_date'] as String?,
      genres: ((it['genres'] as List<dynamic>?) ?? [])
          .map((g) => (g as Map<String, dynamic>)['name'] as String)
          .toList(),
      seasons: rawSeasons
          .map((s) => TmdbSeason.fromJson(s as Map<String, dynamic>))
          .where((s) => s.seasonNumber > 0) // exclude Season 0 (Speciali)
          .toList(),
      nextEpisodeToAir: it['next_episode_to_air'] != null
          ? TmdbNextEpisode.fromJson(
              it['next_episode_to_air'] as Map<String, dynamic>)
          : null,
    );
  }

  String? get posterUrl =>
      posterPath != null ? '$kTmdbImageBase/w342$posterPath' : null;

  String? get backdropUrl =>
      backdropPath != null ? '$kTmdbImageBase/w780$backdropPath' : null;

  int? get year {
    if (firstAirDate == null || firstAirDate!.length < 4) return null;
    return int.tryParse(firstAirDate!.substring(0, 4));
  }

  String get statusLabel => switch (status) {
        'Returning Series' => 'In corso',
        'Ended' => 'Terminata',
        'Canceled' => 'Cancellata',
        'In Production' => 'In produzione',
        _ => status ?? '—',
      };
}
