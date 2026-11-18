import 'package:drift/drift.dart';

class SyncSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fingerprint => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class SyncItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(SyncSessions, #id)();
  TextColumn get domain => text()();
  IntColumn get externalId => integer()();
  IntColumn get localId => integer()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get title => text().nullable()();
  TextColumn get error => text().nullable()();
  TextColumn get progressData => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {sessionId, domain, externalId}
      ];
}
