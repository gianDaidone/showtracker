class SyncPayload {
  final Map<String, ShowSyncData> shows; // key: tmdbId
  final Map<String, GameSyncData> games; // key: rawgId
  final Map<String, MovieSyncData> movies; // key: tmdbId

  SyncPayload({
    required this.shows,
    required this.games,
    required this.movies,
  });

  Map<String, dynamic> toJson() => {
        if (shows.isNotEmpty) 's': shows.map((k, v) => MapEntry(k, v.toJson())),
        if (games.isNotEmpty) 'g': games.map((k, v) => MapEntry(k, v.toJson())),
        if (movies.isNotEmpty) 'm': movies.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory SyncPayload.fromJson(Map<String, dynamic> json) => SyncPayload(
        shows: (json['s'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, ShowSyncData.fromJson(v)),
            ) ??
            {},
        games: (json['g'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, GameSyncData.fromJson(v)),
            ) ??
            {},
        movies: (json['m'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, MovieSyncData.fromJson(v)),
            ) ??
            {},
      );
}

class ShowSyncData {
  final String status;
  final int updatedAt;
  final Map<String, String> eps; // season -> episodes range (e.g. "1": "1-10,12")

  ShowSyncData({
    required this.status,
    required this.updatedAt,
    required this.eps,
  });

  Map<String, dynamic> toJson() => {
        'st': status,
        'u': updatedAt,
        if (eps.isNotEmpty) 'e': eps,
      };

  factory ShowSyncData.fromJson(Map<String, dynamic> json) => ShowSyncData(
        status: json['st'] as String,
        updatedAt: json['u'] as int,
        eps: (json['e'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v as String),
            ) ??
            {},
      );
}

class GameSyncData {
  final String status;
  final int updatedAt;

  GameSyncData({
    required this.status,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'st': status,
        'u': updatedAt,
      };

  factory GameSyncData.fromJson(Map<String, dynamic> json) => GameSyncData(
        status: json['st'] as String,
        updatedAt: json['u'] as int,
      );
}

class MovieSyncData {
  final String status;
  final int updatedAt;

  MovieSyncData({
    required this.status,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'st': status,
        'u': updatedAt,
      };

  factory MovieSyncData.fromJson(Map<String, dynamic> json) => MovieSyncData(
        status: json['st'] as String,
        updatedAt: json['u'] as int,
      );
}
