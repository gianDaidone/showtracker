// dart format width=80
// ignore_for_file: type=lint
part of 'shows_dao.dart';

mixin _$ShowsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrackedShowsTable get trackedShows => attachedDatabase.trackedShows;
  $TrackedEpisodesTable get trackedEpisodes => attachedDatabase.trackedEpisodes;
  $TrackedSeasonsTable get trackedSeasons => attachedDatabase.trackedSeasons;
  ShowsDaoManager get managers => ShowsDaoManager(this);
}

class ShowsDaoManager {
  final _$ShowsDaoMixin _db;
  ShowsDaoManager(this._db);
  $$TrackedShowsTableTableManager get trackedShows =>
      $$TrackedShowsTableTableManager(_db.attachedDatabase, _db.trackedShows);
  $$TrackedEpisodesTableTableManager get trackedEpisodes =>
      $$TrackedEpisodesTableTableManager(
          _db.attachedDatabase, _db.trackedEpisodes);
  $$TrackedSeasonsTableTableManager get trackedSeasons =>
      $$TrackedSeasonsTableTableManager(
          _db.attachedDatabase, _db.trackedSeasons);
}
