import 'package:drift/drift.dart';
import 'tracked_shows.dart';

/// Memorizza il numero di episodi per stagione di ogni serie tracciata.
/// Popolato quando la serie viene aggiunta, evita chiamate API solo per
/// determinare se un episodio esiste o se la stagione è finita.
class TrackedSeasons extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get showId => integer().references(TrackedShows, #id)();
  IntColumn get seasonNumber => integer()();
  IntColumn get episodeCount => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {showId, seasonNumber},
      ];
}
