import 'package:drift/drift.dart';

class YunaCache extends Table {
  IntColumn get tmdbId => integer()();
  TextColumn get anilistIdsJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {tmdbId};
}
