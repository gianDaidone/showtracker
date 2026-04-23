import 'package:drift/drift.dart';

/// Cache locale dei dettagli degli episodi scaricati da TMDB.
/// Ogni riga scade dopo [CacheDao.ttlDays] giorni (vedere cachedAt).
class CachedEpisodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tmdbShowId => integer()();
  IntColumn get seasonNumber => integer()();
  IntColumn get episodeNumber => integer()();
  TextColumn get name => text()();
  TextColumn get overview => text().nullable()();
  TextColumn get stillPath => text().nullable()();
  TextColumn get airDate => text().nullable()();
  RealColumn get voteAverage => real().nullable()();
  IntColumn get absoluteEpisodeNumber => integer().nullable()();
  DateTimeColumn get airingAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {tmdbShowId, seasonNumber, episodeNumber},
      ];
}
