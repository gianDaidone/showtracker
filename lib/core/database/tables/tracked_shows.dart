import 'package:drift/drift.dart';
import 'enums.dart';

class TrackedShows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tmdbId => integer().unique()();
  TextColumn get title => text()();
  TextColumn get overview => text().nullable()();
  TextColumn get posterPath => text().nullable()();
  TextColumn get status => textEnum<MediaStatus>()();
  RealColumn get userRating => real().nullable()();
  TextColumn get userNotes => text().nullable()();
  IntColumn get totalSeasons => integer().nullable()();
  IntColumn get totalEpisodes => integer().nullable()();
  /// Stato TMDB della serie: "Returning Series", "Ended", "Canceled", ecc.
  /// Usato per calcolare il TTL della cache episodi in modo intelligente.
  TextColumn get tmdbStatus => text().nullable()();
  BoolColumn get isAnime =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get lastWatchedAt => dateTime().nullable()();
}
