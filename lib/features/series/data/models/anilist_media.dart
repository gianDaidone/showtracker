class AniListNextAiring {
  final int episode;
  final int airingAt;
  final int timeUntilAiring;

  const AniListNextAiring({
    required this.episode,
    required this.airingAt,
    required this.timeUntilAiring,
  });

  factory AniListNextAiring.fromJson(Map<String, dynamic> json) =>
      AniListNextAiring(
        episode: json['episode'] as int,
        airingAt: json['airingAt'] as int,
        timeUntilAiring: json['timeUntilAiring'] as int,
      );

  Map<String, dynamic> toJson() => {
        'episode': episode,
        'airingAt': airingAt,
        'timeUntilAiring': timeUntilAiring,
      };

  DateTime get airingDateTime =>
      DateTime.fromMillisecondsSinceEpoch(airingAt * 1000);
}

class AniListStreamingEpisode {
  final String? title;
  final String? thumbnail;

  const AniListStreamingEpisode({this.title, this.thumbnail});

  factory AniListStreamingEpisode.fromJson(Map<String, dynamic> json) =>
      AniListStreamingEpisode(
        title: json['title'] as String?,
        thumbnail: json['thumbnail'] as String?,
      );

  Map<String, dynamic> toJson() => {'title': title, 'thumbnail': thumbnail};
}

class AniListMedia {
  final int id;
  final String? titleRomaji;
  final String? titleEnglish;
  final String status;
  final String format;
  final int? episodes;
  final String? season;
  final int? seasonYear;
  final int? averageScore;
  final AniListNextAiring? nextAiringEpisode;
  final List<AniListStreamingEpisode> streamingEpisodes;

  /// Data della prima messa in onda; null se AniList non conosce almeno anno,
  /// mese e giorno. Richiesta solo dalla ricerca per titolo.
  final DateTime? startDate;

  const AniListMedia({
    required this.id,
    this.titleRomaji,
    this.titleEnglish,
    required this.status,
    required this.format,
    this.episodes,
    this.season,
    this.seasonYear,
    this.averageScore,
    this.nextAiringEpisode,
    required this.streamingEpisodes,
    this.startDate,
  });

  factory AniListMedia.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as Map<String, dynamic>?;
    final nextAiring = json['nextAiringEpisode'] as Map<String, dynamic>?;
    final streamingEps = json['streamingEpisodes'] as List<dynamic>? ?? [];
    final start = json['startDate'] as Map<String, dynamic>?;
    final startYear = start?['year'] as int?;
    final startMonth = start?['month'] as int?;
    final startDay = start?['day'] as int?;
    return AniListMedia(
      id: json['id'] as int,
      titleRomaji: title?['romaji'] as String?,
      titleEnglish: title?['english'] as String?,
      status: json['status'] as String? ?? 'UNKNOWN',
      format: json['format'] as String? ?? 'TV',
      episodes: json['episodes'] as int?,
      season: json['season'] as String?,
      seasonYear: json['seasonYear'] as int?,
      averageScore: json['averageScore'] as int?,
      nextAiringEpisode:
          nextAiring != null ? AniListNextAiring.fromJson(nextAiring) : null,
      streamingEpisodes: streamingEps
          .map((e) =>
              AniListStreamingEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
      startDate: startYear != null && startMonth != null && startDay != null
          ? DateTime(startYear, startMonth, startDay)
          : null,
    );
  }

  static AniListMedia? fromGraphqlResponse(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors != null) return null;
    final data = body['data'] as Map<String, dynamic>?;
    final media = data?['Media'] as Map<String, dynamic>?;
    if (media == null) return null;
    return AniListMedia.fromJson(media);
  }

  /// Risposta di una query `Page { media { ... } }`; null in caso di errore.
  static List<AniListMedia>? listFromGraphqlPageResponse(
      Map<String, dynamic> body) {
    if (body['errors'] != null) return null;
    final data = body['data'] as Map<String, dynamic>?;
    final page = data?['Page'] as Map<String, dynamic>?;
    final media = page?['media'] as List<dynamic>?;
    if (media == null) return null;
    return media
        .map((m) => AniListMedia.fromJson(m as Map<String, dynamic>))
        .toList();
  }

}
