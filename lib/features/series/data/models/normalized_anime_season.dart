import 'dart:convert';

import 'anilist_media.dart';

class NormalizedAnimeSeason {
  final int seasonNumber;
  final int tmdbSeasonNumber;
  final int anilistId;
  final int episodeCount;
  final String status;
  final String? season;
  final int? seasonYear;
  final String? titleRomaji;
  final String? titleEnglish;
  final int? averageScore;
  final AniListNextAiring? nextAiringEpisode;
  final List<AniListStreamingEpisode> streamingEpisodes;

  const NormalizedAnimeSeason({
    required this.seasonNumber,
    required this.tmdbSeasonNumber,
    required this.anilistId,
    required this.episodeCount,
    required this.status,
    this.season,
    this.seasonYear,
    this.titleRomaji,
    this.titleEnglish,
    this.averageScore,
    this.nextAiringEpisode,
    required this.streamingEpisodes,
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'seasonNumber': seasonNumber,
        'tmdbSeasonNumber': tmdbSeasonNumber,
        'anilistId': anilistId,
        'episodeCount': episodeCount,
        'status': status,
        'season': season,
        'seasonYear': seasonYear,
        'titleRomaji': titleRomaji,
        'titleEnglish': titleEnglish,
        'averageScore': averageScore,
        'nextAiringEpisode': nextAiringEpisode?.toJson(),
        'streamingEpisodes': streamingEpisodes.map((e) => e.toJson()).toList(),
      };

  factory NormalizedAnimeSeason.fromJson(Map<String, dynamic> json) {
    final nextAiring = json['nextAiringEpisode'] as Map<String, dynamic>?;
    final streamingEps = json['streamingEpisodes'] as List<dynamic>? ?? [];
    return NormalizedAnimeSeason(
      seasonNumber: json['seasonNumber'] as int,
      tmdbSeasonNumber: json['tmdbSeasonNumber'] as int,
      anilistId: json['anilistId'] as int,
      episodeCount: json['episodeCount'] as int,
      status: json['status'] as String,
      season: json['season'] as String?,
      seasonYear: json['seasonYear'] as int?,
      titleRomaji: json['titleRomaji'] as String?,
      titleEnglish: json['titleEnglish'] as String?,
      averageScore: json['averageScore'] as int?,
      nextAiringEpisode:
          nextAiring != null ? AniListNextAiring.fromJson(nextAiring) : null,
      streamingEpisodes: streamingEps
          .map((e) =>
              AniListStreamingEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<NormalizedAnimeSeason> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => NormalizedAnimeSeason.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<NormalizedAnimeSeason> seasons) =>
      jsonEncode(seasons.map((s) => s.toJson()).toList());

  // ── Display helpers ───────────────────────────────────────────────────────

  String get seasonLabel {
    final name = switch (season) {
      'WINTER' => 'Winter',
      'SPRING' => 'Spring',
      'SUMMER' => 'Summer',
      'FALL' => 'Fall',
      _ => season ?? '',
    };
    if (name.isNotEmpty && seasonYear != null) return '$name $seasonYear';
    if (seasonYear != null) return '$seasonYear';
    return name;
  }

  String get statusLabel => switch (status) {
        'RELEASING' => 'In corso',
        'FINISHED' => 'Concluso',
        'HIATUS' => 'In pausa',
        'NOT_YET_RELEASED' => 'Non ancora uscito',
        'CANCELLED' => 'Cancellato',
        _ => status,
      };

  // ── Cache TTL ─────────────────────────────────────────────────────────────

  Duration get cacheTtl {
    if (status == 'RELEASING') {
      if (nextAiringEpisode != null) {
        final diff =
            nextAiringEpisode!.airingDateTime.difference(DateTime.now());
        return diff.isNegative ? const Duration(hours: 6) : diff;
      }
      return const Duration(hours: 6);
    }
    if (status == 'HIATUS') return const Duration(days: 14);
    if (status == 'NOT_YET_RELEASED') return const Duration(days: 7);
    return const Duration(days: 30); // FINISHED, CANCELLED
  }
}
