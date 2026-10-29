import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int showId;
  final old = DateTime.utc(2020, 1, 1);

  Future<int> addShow(int tmdbId,
          {MediaStatus status = MediaStatus.watching}) =>
      db.showsDao.insertShow(TrackedShowsCompanion(
        tmdbId: Value(tmdbId),
        title: Value('Serie $tmdbId'),
        status: Value(status),
        addedAt: Value(DateTime.utc(2026, 10, tmdbId == 73223 ? 1 : 2)),
        updatedAt: Value(old),
      ));

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    showId = await addShow(73223);
  });

  tearDown(() => db.close());

  group('ShowsDao.insertSeasons', () {
    test('aggiorna le stagioni già salvate invece di fallire', () async {
      await db.showsDao.insertSeasons(showId, {1: 12, 2: 2});
      await db.showsDao.insertSeasons(showId, {1: 12, 2: 3});
      expect(await db.showsDao.getSeasonCounts(showId), {1: 12, 2: 3});
    });

    test('aggiunge stagioni nuove e isola le altre serie', () async {
      final other = await addShow(2);
      await db.showsDao.insertSeasons(other, {1: 99});
      await db.showsDao.insertSeasons(showId, {1: 12});
      await db.showsDao.insertSeasons(showId, {1: 12, 2: 1});
      expect(await db.showsDao.getSeasonCounts(showId), {1: 12, 2: 1});
      expect(await db.showsDao.getSeasonCounts(other), {1: 99});
      expect(await db.select(db.trackedSeasons).get(), hasLength(3));
    });
  });

  test('CRUD, unicità TMDB e ordinamento per aggiunta', () async {
    final second = await addShow(2);
    expect(await db.showsDao.getByTmdbId(73223),
        await db.showsDao.getById(showId));
    expect(await db.showsDao.getById(-1), isNull);
    await expectLater(addShow(73223), throwsA(isA<Exception>()));
    expect((await db.showsDao.getAll()).map((s) => s.id), [second, showId]);
    expect(await db.showsDao.deleteShow(second), 1);
    expect(await db.showsDao.deleteShow(second), 0);
    expect(await db.showsDao.getByTmdbId(2), isNull);
  });

  test('stato e voto anche null aggiornano updatedAt', () async {
    await db.showsDao.updateStatus(showId, MediaStatus.completed);
    var show = (await db.showsDao.getById(showId))!;
    expect(show.status, MediaStatus.completed);
    expect(show.updatedAt, isNotNull);
    expect(show.updatedAt!.isAfter(old), isTrue);
    await db.showsDao.updateRating(showId, 8.5);
    expect((await db.showsDao.getById(showId))!.userRating, 8.5);
    await (db.update(db.trackedShows)..where((s) => s.id.equals(showId)))
        .write(TrackedShowsCompanion(updatedAt: Value(old)));
    await db.showsDao.updateRating(showId, null);
    show = (await db.showsDao.getById(showId))!;
    expect(show.userRating, isNull);
    expect(show.updatedAt!.isAfter(old), isTrue);
  });

  test('metadati assenti preservano il puntatore, null espliciti lo azzerano',
      () async {
    final airDate = DateTime.utc(2026, 12, 1);
    await db.showsDao.updateShowMetadata(showId, 24, 2, 'Returning Series',
        title: const Value('Titolo aggiornato'),
        nextEpisodeNumber: const Value(3),
        nextEpisodeSeason: const Value(2),
        nextEpisodeName: const Value('Il ritorno'),
        nextEpisodeAirDate: Value(airDate));
    await db.showsDao.updateShowMetadata(showId, 25, 2, 'Ended');
    var show = (await db.showsDao.getById(showId))!;
    expect(show.title, 'Titolo aggiornato');
    expect(show.totalEpisodes, 25);
    expect(show.totalSeasons, 2);
    expect(show.tmdbStatus, 'Ended');
    expect(show.nextEpisodeNumber, 3);
    expect(show.nextEpisodeSeason, 2);
    expect(show.nextEpisodeName, 'Il ritorno');
    expect(show.nextEpisodeAirDate!.isAtSameMomentAs(airDate), isTrue);
    expect(show.updatedAt!.isAfter(old), isTrue);
    await db.showsDao.updateShowMetadata(showId, null, null, null,
        nextEpisodeNumber: const Value(null),
        nextEpisodeSeason: const Value(null),
        nextEpisodeName: const Value(null),
        nextEpisodeAirDate: const Value(null));
    show = (await db.showsDao.getById(showId))!;
    expect(show.totalEpisodes, isNull);
    expect(show.totalSeasons, isNull);
    expect(show.tmdbStatus, isNull);
    expect(show.nextEpisodeNumber, isNull);
    expect(show.nextEpisodeSeason, isNull);
    expect(show.nextEpisodeName, isNull);
    expect(show.nextEpisodeAirDate, isNull);
  });

  test('watched e unwatch ripetuti sono idempotenti, ordinati e isolati',
      () async {
    final other = await addShow(2);
    await db.showsDao.markEpisodeWatched(other, 1, 1);
    await db.showsDao.markEpisodeWatched(showId, 2, 1);
    await db.showsDao.markEpisodeWatched(showId, 1, 2);
    await db.showsDao.markEpisodeWatched(showId, 1, 2);
    expect(await db.showsDao.countWatchedEpisodes(showId), 2);
    final episodes = await db.showsDao.getEpisodesByShow(showId);
    expect(episodes.map((e) => '${e.seasonNumber}/${e.episodeNumber}'),
        ['1/2', '2/1']);
    expect(episodes.every((e) => e.updatedAt!.isAfter(old)), isTrue);
    var show = (await db.showsDao.getById(showId))!;
    expect(show.lastWatchedAt, isNotNull);
    expect(show.updatedAt!.isAfter(old), isTrue);
    final lastWatched = show.lastWatchedAt;
    await (db.update(db.trackedEpisodes)..where((e) => e.showId.equals(showId)))
        .write(TrackedEpisodesCompanion(updatedAt: Value(old)));
    await db.showsDao.markEpisodeWatched(showId, 1, 2, watched: false);
    await db.showsDao.markEpisodeWatched(showId, 1, 2, watched: false);
    expect(await db.showsDao.countWatchedEpisodes(showId), 1);
    final unwatched = (await db.showsDao.getEpisodesByShow(showId)).first;
    expect(unwatched.watched, isFalse);
    expect(unwatched.updatedAt!.isAfter(old), isTrue);
    expect(await db.showsDao.getEpisodesByShow(showId), hasLength(2));
    show = (await db.showsDao.getById(showId))!;
    expect(show.lastWatchedAt, lastWatched);
    expect(await db.showsDao.countWatchedEpisodes(other), 1);
  });

  test('unwatch crea anche una riga mancante senza segnare ultimo visto',
      () async {
    await db.showsDao.markEpisodeWatched(showId, 1, 1, watched: false);
    expect(await db.showsDao.countWatchedEpisodes(showId), 0);
    expect(await db.showsDao.getEpisodesByShow(showId), hasLength(1));
    expect((await db.showsDao.getById(showId))!.lastWatchedAt, isNull);
  });

  test('precedenti attraversa stagioni senza includere target o speciali',
      () async {
    await db.showsDao.insertSeasons(showId, {0: 2, 1: 3, 2: 4});
    expect(await db.showsDao.hasMissingPreviousEpisodes(showId, 1, 1), isFalse);
    await db.showsDao.markAllPreviousEpisodesWatched(showId, 1, 1);
    expect(await db.showsDao.getEpisodesByShow(showId), isEmpty);
    expect((await db.showsDao.getById(showId))!.lastWatchedAt, isNull);
    await db.showsDao.markEpisodeWatched(showId, 1, 2, watched: false);
    expect(await db.showsDao.hasMissingPreviousEpisodes(showId, 2, 3), isTrue);
    await db.showsDao.markAllPreviousEpisodesWatched(showId, 2, 3);
    await db.showsDao.markAllPreviousEpisodesWatched(showId, 2, 3);
    final episodes = await db.showsDao.getEpisodesByShow(showId);
    expect(episodes.map((e) => '${e.seasonNumber}/${e.episodeNumber}'),
        ['1/1', '1/2', '1/3', '2/1', '2/2']);
    expect(
        episodes.every((e) => e.watched && e.updatedAt!.isAfter(old)), isTrue);
    expect(await db.showsDao.countWatchedEpisodes(showId), 5);
    expect(await db.showsDao.hasMissingPreviousEpisodes(showId, 2, 3), isFalse);
    expect(await db.showsDao.hasMissingPreviousEpisodes(showId, 2, 4), isTrue);
    final show = (await db.showsDao.getById(showId))!;
    expect(show.lastWatchedAt, isNotNull);
    expect(show.updatedAt!.isAfter(old), isTrue);
  });

  test('stream serie ed episodi emettono dopo le scritture', () async {
    final shows = StreamIterator(db.showsDao.watchAll());
    final episodes = StreamIterator(db.showsDao.watchEpisodesByShow(showId));
    addTearDown(shows.cancel);
    addTearDown(episodes.cancel);
    expect(await shows.moveNext(), isTrue);
    expect(shows.current.single.id, showId);
    expect(await episodes.moveNext(), isTrue);
    expect(episodes.current, isEmpty);
    final nextShow = shows.moveNext();
    await db.showsDao.updateStatus(showId, MediaStatus.paused);
    expect(await nextShow, isTrue);
    expect(shows.current.single.status, MediaStatus.paused);
    final nextEpisode = episodes.moveNext();
    await db.showsDao.markEpisodeWatched(showId, 1, 1);
    expect(await nextEpisode, isTrue);
    expect(episodes.current.single.watched, isTrue);
    final unwatch = episodes.moveNext();
    await db.showsDao.markEpisodeWatched(showId, 1, 1, watched: false);
    expect(await unwatch, isTrue);
    expect(episodes.current.single.watched, isFalse);
  });

  test('join include serie senza visti ed emette conteggi senza duplicati',
      () async {
    await addShow(2, status: MediaStatus.paused);
    final joined = StreamIterator(db.showsDao.watchWatchingShowsWithEpisodes());
    addTearDown(joined.cancel);
    expect(await joined.moveNext(), isTrue);
    expect(joined.current.single.show.id, showId);
    expect(joined.current.single.watchedBySeason, isEmpty);
    // markEpisodeWatched aggiorna prima la serie e poi l'episodio: il join
    // può emettere uno stato intermedio valido, non solo quello finale.
    Future<void> nextCount(int count) async {
      do {
        expect(await joined.moveNext(), isTrue);
      } while (joined.current.single.watchedCount != count);
    }

    var next = nextCount(1);
    await db.showsDao.markEpisodeWatched(showId, 1, 1);
    await next;
    expect(joined.current.single.watchedBySeason, {
      1: {1}
    });
    next = nextCount(2);
    await db.showsDao.markEpisodeWatched(showId, 2, 1);
    await next;
    expect(joined.current.single.watchedCount, 2);
    next = nextCount(1);
    await db.showsDao.markEpisodeWatched(showId, 1, 1, watched: false);
    await next;
    expect(joined.current.single.watchedBySeason, {
      2: {1}
    });
    final completed = joined.moveNext();
    await db.showsDao.updateStatus(showId, MediaStatus.completed);
    expect(await completed, isTrue);
    expect(joined.current, isEmpty);
  });

  test('rimozione fallita non perde progressi grazie al rollback', () async {
    await db.showsDao.markEpisodeWatched(showId, 1, 1);
    await db.showsDao.insertSeasons(showId, {1: 12});
    await db.customStatement('''
      CREATE TRIGGER reject_show_delete BEFORE DELETE ON tracked_shows
      BEGIN SELECT RAISE(ABORT, 'test rollback'); END
    ''');
    await expectLater(
        db.showsDao.deleteShow(showId), throwsA(isA<Exception>()));
    expect(await db.showsDao.getById(showId), isNotNull);
    expect(await db.showsDao.countWatchedEpisodes(showId), 1);
    expect(await db.showsDao.getSeasonCounts(showId), {1: 12});
  });

  for (final foreignKeys in [false, true]) {
    test('rimozione elimina progressi e stagioni (foreign_keys=$foreignKeys)',
        () async {
      await db.customStatement('PRAGMA foreign_keys = ${foreignKeys ? 1 : 0}');
      final other = await addShow(2);
      await db.showsDao.markEpisodeWatched(showId, 1, 1);
      await db.showsDao.insertSeasons(showId, {1: 12});
      await db.showsDao.markEpisodeWatched(other, 1, 1);
      await db.showsDao.insertSeasons(other, {1: 3});
      expect(await db.showsDao.deleteShow(showId), 1);
      expect(await db.showsDao.getById(showId), isNull);
      expect(await db.showsDao.getEpisodesByShow(showId), isEmpty);
      expect(await db.showsDao.getSeasonCounts(showId), isEmpty);
      expect(await db.showsDao.countWatchedEpisodes(other), 1);
      expect(await db.showsDao.getSeasonCounts(other), {1: 3});
      final readded = await addShow(73223);
      expect(await db.showsDao.countWatchedEpisodes(readded), 0);
      expect(await db.showsDao.getSeasonCounts(readded), isEmpty);
    });
  }
}
