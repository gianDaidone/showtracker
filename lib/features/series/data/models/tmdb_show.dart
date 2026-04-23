import '../../../../core/constants.dart';

class TmdbShow {
  final int id;
  final String name;
  final String? posterPath;
  final String? overview;
  final String? firstAirDate;
  final double? voteAverage;

  const TmdbShow({
    required this.id,
    required this.name,
    this.posterPath,
    this.overview,
    this.firstAirDate,
    this.voteAverage,
  });

  factory TmdbShow.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.isNotEmpty == true
        ? json['name'] as String
        : (json['original_name'] as String?) ?? '';
    return TmdbShow(
      id: json['id'] as int,
      name: name,
      posterPath: json['poster_path'] as String?,
      overview: json['overview'] as String?,
      firstAirDate: json['first_air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }

  String? get posterUrl =>
      posterPath != null ? '$kTmdbImageBase/w342$posterPath' : null;

  int? get year {
    if (firstAirDate == null || firstAirDate!.length < 4) return null;
    return int.tryParse(firstAirDate!.substring(0, 4));
  }
}
