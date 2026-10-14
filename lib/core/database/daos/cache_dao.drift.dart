// dart format width=80
// ignore_for_file: type=lint
part of 'cache_dao.dart';

mixin _$CacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedEpisodesTable get cachedEpisodes => attachedDatabase.cachedEpisodes;
  CacheDaoManager get managers => CacheDaoManager(this);
}

class CacheDaoManager {
  final _$CacheDaoMixin _db;
  CacheDaoManager(this._db);
  $$CachedEpisodesTableTableManager get cachedEpisodes =>
      $$CachedEpisodesTableTableManager(
          _db.attachedDatabase, _db.cachedEpisodes);
}
