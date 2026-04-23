import 'package:drift/drift.dart';
import 'tracked_shows.dart';

class TrackedEpisodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get showId => integer().references(TrackedShows, #id)();
  IntColumn get seasonNumber => integer()();
  IntColumn get episodeNumber => integer()();
  BoolColumn get watched => boolean().withDefault(const Constant(false))();

  /// Ensures each episode is stored at most once per show.
  @override
  List<Set<Column>> get uniqueKeys => [
        {showId, seasonNumber, episodeNumber},
      ];
}
