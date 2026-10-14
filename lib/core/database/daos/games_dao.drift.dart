// dart format width=80
// ignore_for_file: type=lint
part of 'games_dao.dart';

mixin _$GamesDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrackedGamesTable get trackedGames => attachedDatabase.trackedGames;
  GamesDaoManager get managers => GamesDaoManager(this);
}

class GamesDaoManager {
  final _$GamesDaoMixin _db;
  GamesDaoManager(this._db);
  $$TrackedGamesTableTableManager get trackedGames =>
      $$TrackedGamesTableTableManager(_db.attachedDatabase, _db.trackedGames);
}
