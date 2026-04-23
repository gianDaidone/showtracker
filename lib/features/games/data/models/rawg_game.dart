/// Risultato di ricerca RAWG (lista).
class RawgGame {
  final int id;
  final String name;
  final String? backgroundImage;
  final String? released; // "YYYY-MM-DD" oppure null
  final double? rating; // scala /5
  final int? playtime; // ore medie
  final List<String> platforms;
  final List<String> genres;

  const RawgGame({
    required this.id,
    required this.name,
    this.backgroundImage,
    this.released,
    this.rating,
    this.playtime,
    this.platforms = const [],
    this.genres = const [],
  });

  factory RawgGame.fromJson(Map<String, dynamic> json) {
    return RawgGame(
      id: json['id'] as int,
      name: (json['name'] as String?)?.isNotEmpty == true
          ? json['name'] as String
          : 'Titolo sconosciuto',
      backgroundImage: json['background_image'] as String?,
      released: json['released'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      playtime: json['playtime'] as int?,
      platforms: ((json['platforms'] as List<dynamic>?) ?? [])
          .map((p) =>
              (p['platform'] as Map<String, dynamic>)['name'] as String)
          .toList(),
      genres: ((json['genres'] as List<dynamic>?) ?? [])
          .map((g) => g['name'] as String)
          .toList(),
    );
  }

  /// URL diretto della copertina (RAWG restituisce URL completi, non path).
  String? get coverUrl => backgroundImage;

  /// Rating normalizzato su scala /10 (RAWG usa /5).
  double get voteAverage => rating != null ? double.parse((rating! * 2).toStringAsFixed(1)) : 0.0;

  DateTime? get releaseDateParsed {
    if (released == null || released!.isEmpty) return null;
    return DateTime.tryParse(released!);
  }

  int? get year => releaseDateParsed?.year;
}
