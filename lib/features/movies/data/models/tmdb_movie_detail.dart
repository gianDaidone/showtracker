import '../../../../core/constants.dart';

class TmdbMovieDetail {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final int? runtime;
  final double? voteAverage;
  final List<String> genres;

  const TmdbMovieDetail({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.runtime,
    this.voteAverage,
    required this.genres,
  });

  factory TmdbMovieDetail.fromJson(
    Map<String, dynamic> it, {
    Map<String, dynamic>? en,
  }) {
    String? nonEmpty(String key) {
      final v = it[key] as String?;
      if (v != null && v.isNotEmpty) return v;
      final fb = en?[key] as String?;
      return (fb?.isNotEmpty ?? false) ? fb : null;
    }

    return TmdbMovieDetail(
      id: it['id'] as int,
      title: nonEmpty('title') ?? '',
      overview: nonEmpty('overview'),
      posterPath: it['poster_path'] as String?,
      backdropPath: it['backdrop_path'] as String?,
      releaseDate: it['release_date'] as String?,
      runtime: it['runtime'] as int?,
      voteAverage: (it['vote_average'] as num?)?.toDouble(),
      genres: ((it['genres'] as List<dynamic>?) ?? [])
          .map((g) => (g as Map<String, dynamic>)['name'] as String)
          .toList(),
    );
  }

  String? get posterUrl =>
      posterPath != null ? '$kTmdbImageBase/w342$posterPath' : null;

  String? get backdropUrl =>
      backdropPath != null ? '$kTmdbImageBase/w780$backdropPath' : null;

  int? get year {
    if (releaseDate == null || releaseDate!.length < 4) return null;
    return int.tryParse(releaseDate!.substring(0, 4));
  }

  DateTime? get releaseDateParsed {
    if (releaseDate == null || releaseDate!.length < 10) return null;
    return DateTime.tryParse(releaseDate!);
  }

  String? get runtimeFormatted {
    if (runtime == null || runtime! <= 0) return null;
    final h = runtime! ~/ 60;
    final m = runtime! % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}
