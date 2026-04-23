import '../../../../core/constants.dart';

class TmdbEpisode {
  final int episodeNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final String? airDate;
  final double? voteAverage;
  final int? absoluteEpisodeNumber;
  final DateTime? airingAt;

  const TmdbEpisode({
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.stillPath,
    this.airDate,
    this.voteAverage,
    this.absoluteEpisodeNumber,
    this.airingAt,
  });

  factory TmdbEpisode.fromJson(
    Map<String, dynamic> it, {
    Map<String, dynamic>? en,
  }) {
    String? notEmpty(String key, Map<String, dynamic> map) {
      final v = map[key] as String?;
      return (v?.isNotEmpty ?? false) ? v : null;
    }

    // Prefer Italian name; fall back to English if Italian is a placeholder
    // like "Episodio 5" (TMDB fills these when no translation exists).
    final itName = notEmpty('name', it);
    final enName = notEmpty('name', en ?? {});
    final name = (itName != null && !RegExp(r'^Episodio\s+\d+$').hasMatch(itName))
        ? itName
        : (enName ?? itName ?? 'Episodio ${it['episode_number']}');

    return TmdbEpisode(
      episodeNumber: it['episode_number'] as int,
      name: name,
      overview: notEmpty('overview', it) ?? notEmpty('overview', en ?? {}),
      stillPath: it['still_path'] as String?,
      airDate: it['air_date'] as String?,
      voteAverage: (it['vote_average'] as num?)?.toDouble(),
    );
  }

  bool get hasAired {
    if (airingAt != null) {
      return airingAt!.isBefore(DateTime.now());
    }
    if (airDate == null || airDate!.isEmpty) return false;
    try {
      return DateTime.parse(airDate!).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String? get stillUrl =>
      stillPath != null ? '$kTmdbImageBase/w300$stillPath' : null;
}
