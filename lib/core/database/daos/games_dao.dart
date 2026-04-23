import 'package:drift/drift.dart';
import '../app_database.dart';

part 'games_dao.g.dart';

@DriftAccessor(tables: [TrackedGames])
class GamesDao extends DatabaseAccessor<AppDatabase> with _$GamesDaoMixin {
  GamesDao(super.db);

  Future<int> insertGame(TrackedGamesCompanion game) =>
      into(trackedGames).insert(game, mode: InsertMode.insertOrIgnore);

  Future<TrackedGame?> getByRawgId(int rawgId) =>
      (select(trackedGames)..where((t) => t.rawgId.equals(rawgId)))
          .getSingleOrNull();

  Future<void> updateStatus(int id, MediaStatus status) =>
      (update(trackedGames)..where((t) => t.id.equals(id)))
          .write(TrackedGamesCompanion(status: Value(status)));

  Future<void> updateRating(int id, double? rating) =>
      (update(trackedGames)..where((t) => t.id.equals(id)))
          .write(TrackedGamesCompanion(userRating: Value(rating)));

  Future<int> deleteGame(int id) =>
      (delete(trackedGames)..where((t) => t.id.equals(id))).go();

  Stream<List<TrackedGame>> watchAll() =>
      (select(trackedGames)
            ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
          .watch();
}
