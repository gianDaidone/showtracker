import '../../../../core/constants.dart';

class TmdbMovie {
  final int id;
  final String title;
  final String? posterPath;
  final String? overview;
  final String? releaseDate;
  final double? voteAverage;

  const TmdbMovie({
    required this.id,
    required this.title,
    this.posterPath,
    this.overview,
    this.releaseDate,
    this.voteAverage,
  });

  factory TmdbMovie.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String?)?.isNotEmpty == true
        ? json['title'] as String
        : (json['original_title'] as String?) ?? '';
    return TmdbMovie(
      id: json['id'] as int,
      title: title,
      posterPath: json['poster_path'] as String?,
      overview: json['overview'] as String?,
      releaseDate: json['release_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }

  String? get posterUrl =>
      posterPath != null ? '$kTmdbImageBase/w342$posterPath' : null;

  int? get year {
    if (releaseDate == null || releaseDate!.length < 4) return null;
    return int.tryParse(releaseDate!.substring(0, 4));
  }
}
