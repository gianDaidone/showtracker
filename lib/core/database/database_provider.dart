import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.instance;
  ref.onDispose(db.close);
  return db;
});

final showsDaoProvider = Provider<ShowsDao>((ref) {
  return ref.watch(databaseProvider).showsDao;
});

final moviesDaoProvider = Provider<MoviesDao>((ref) {
  return ref.watch(databaseProvider).moviesDao;
});

final gamesDaoProvider = Provider<GamesDao>((ref) {
  return ref.watch(databaseProvider).gamesDao;
});

final cacheDaoProvider = Provider<CacheDao>((ref) {
  return ref.watch(databaseProvider).cacheDao;
});
