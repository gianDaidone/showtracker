import 'package:drift/drift.dart';

class AnimeSeasonCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tmdbShowId => integer()();
  IntColumn get seasonNumber => integer()();
  IntColumn get anilistId => integer()();
  IntColumn get episodeCount => integer()();
  TextColumn get status => text()();
  TextColumn get animeSeasonJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get validUntil => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {tmdbShowId, seasonNumber},
      ];
}
