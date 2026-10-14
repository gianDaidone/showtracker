// dart format width=80
// ignore_for_file: type=lint
part of 'anime_cache_dao.dart';

mixin _$AnimeCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $YunaCacheTable get yunaCache => attachedDatabase.yunaCache;
  $AnimeSeasonCacheTable get animeSeasonCache =>
      attachedDatabase.animeSeasonCache;
  AnimeCacheDaoManager get managers => AnimeCacheDaoManager(this);
}

class AnimeCacheDaoManager {
  final _$AnimeCacheDaoMixin _db;
  AnimeCacheDaoManager(this._db);
  $$YunaCacheTableTableManager get yunaCache =>
      $$YunaCacheTableTableManager(_db.attachedDatabase, _db.yunaCache);
  $$AnimeSeasonCacheTableTableManager get animeSeasonCache =>
      $$AnimeSeasonCacheTableTableManager(
          _db.attachedDatabase, _db.animeSeasonCache);
}
