import 'package:drift/drift.dart';
import 'enums.dart';

class TrackedGames extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get rawgId => integer().unique()();
  TextColumn get title => text()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get status => textEnum<MediaStatus>()();
  RealColumn get userRating => real().nullable()();
  TextColumn get userNotes => text().nullable()();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get releaseDate => dateTime().nullable()();
  IntColumn get playtime => integer().nullable()();
  TextColumn get platforms => text().nullable()(); // JSON-encoded List<String>
  RealColumn get voteAverage => real().nullable()();
}
