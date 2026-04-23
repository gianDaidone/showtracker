import 'package:drift/drift.dart';
import 'enums.dart';

class TrackedMovies extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tmdbId => integer().unique()();
  TextColumn get title => text()();
  TextColumn get overview => text().nullable()();
  TextColumn get posterPath => text().nullable()();
  TextColumn get status => textEnum<MediaStatus>()();
  RealColumn get userRating => real().nullable()();
  TextColumn get userNotes => text().nullable()();
  IntColumn get releaseYear => integer().nullable()();
  DateTimeColumn get releaseDate => dateTime().nullable()();
  DateTimeColumn get addedAt => dateTime()();
}
