import 'rawg_game.dart';

/// Dettaglio completo di un gioco RAWG.
class RawgGameDetail extends RawgGame {
  final String? overview; // description_raw
  final List<String> developers;
  final List<String> publishers;
  final List<String> tags;

  const RawgGameDetail({
    required super.id,
    required super.slug,
    required super.name,
    super.backgroundImage,
    super.released,
    super.rating,
    super.playtime,
    super.platforms,
    super.genres,
    this.overview,
    this.developers = const [],
    this.publishers = const [],
    this.tags = const [],
  });

  factory RawgGameDetail.fromJson(Map<String, dynamic> json) {
    final base = RawgGame.fromJson(json);
    return RawgGameDetail(
      id: base.id,
      slug: base.slug,
      name: base.name,
      backgroundImage: base.backgroundImage,
      released: base.released,
      rating: base.rating,
      playtime: base.playtime,
      platforms: base.platforms,
      genres: base.genres,
      overview: (json['description_raw'] as String?)?.isNotEmpty == true
          ? json['description_raw'] as String
          : null,
      developers: ((json['developers'] as List<dynamic>?) ?? [])
          .map((d) => d['name'] as String)
          .toList(),
      publishers: ((json['publishers'] as List<dynamic>?) ?? [])
          .map((p) => p['name'] as String)
          .toList(),
      tags: ((json['tags'] as List<dynamic>?) ?? [])
          .map((t) => t['name'] as String)
          .take(10) // limitiamo i tag
          .toList(),
    );
  }
}
