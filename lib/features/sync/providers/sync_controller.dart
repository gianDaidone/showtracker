import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/auth/rawg_auth_state.dart';
import '../../../core/constants/api_keys.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/riverpod_utils.dart';
import '../../series/data/tmdb_service.dart';
import '../../games/data/rawg_service.dart';
import '../../series/data/watch_next_rules.dart';
import '../../series/providers/series_providers.dart';
import '../domain/models/sync_payload.dart';
import '../domain/models/sync_progress.dart';
import '../services/sync_android_bridge.dart';
import '../services/sync_job_store.dart';
import '../services/sync_receiver.dart';
import '../services/sync_service.dart';
import '../utils/sync_compressor.dart';
import 'sync_panel_controller.dart';

final syncControllerProvider = NotifierProvider<SyncController, SyncProgress>(
  SyncController.new,
);

class SyncController extends Notifier<SyncProgress> {
  late SyncJobStore _store;
  late SyncAndroidBridge _android;
  Future<void>? _work;
  late Future<void> _ready;
  int? _session;
  int _tmdbGeneration = 0;
  int _rawgGeneration = 0;
  bool _retryAfterWork = false;
  bool _stopped = false;
  bool _background = true;
  bool _notifications = true;
  String? _tmdbCredential;
  String? _rawgCredential;
  int _snapshotRevision = 0;
  int _otherSessions = 0;
  final _acknowledgedSessions = <int>{};
  List<int>? _progressItemIds;
  bool _updatingGames = false;
  final _unprocessedItemIds = <int>{};
  Map<int, List<SyncItem>> _runAliases = {};

  bool get busy => _work != null;

  @override
  SyncProgress build() {
    _store = SyncJobStore(ref.read(databaseProvider));
    _android = ref.read(syncAndroidBridgeProvider);
    _android.onStop(() {
      _stopped = true;
    });
    _android.onShow = () {
      if (ref.mounted && _session != null) {
        ref.read(syncPanelOpenProvider.notifier).show();
        unawaited(_snapshot(active: busy));
      }
    };
    ref.onDispose(() {
      _stopped = true;
    });
    ref.listen(authControllerProvider, (_, next) {
      final auth = next.value;
      final credential = next.isLoading
          ? null
          : switch (auth) {
              AuthenticatedWithManualKey(:final apiKey) => apiKey,
              AuthenticatedWithSession(:final sessionId) =>
                ApiKeys.tmdb.isEmpty ? '' : '${ApiKeys.tmdb}:$sessionId',
              _ => ApiKeys.tmdb,
            };
      if (credential == _tmdbCredential) return;
      _tmdbCredential = credential;
      _tmdbGeneration++;
      if (credential != null && credential.isNotEmpty) _credentialsReady();
    }, fireImmediately: true);
    ref.listen(rawgAuthControllerProvider, (_, next) {
      final auth = next.value;
      final credential = next.isLoading
          ? null
          : auth is RawgAuthenticated
              ? auth.apiKey
              : ApiKeys.rawg;
      if (credential == _rawgCredential) return;
      _rawgCredential = credential;
      _rawgGeneration++;
      if (credential != null && credential.isNotEmpty) _credentialsReady();
    }, fireImmediately: true);
    _ready = Future<void>.microtask(_restore);
    return const SyncProgress();
  }

  Future<void> get ready => _ready;

  void _credentialsReady() {
    if (busy && _session != null) {
      _retryAfterWork = true;
      return;
    }
    unawaited(Future<void>.microtask(() async {
      await _ready;
      if (!ref.mounted || busy || _session == null) return;
      await retry(automatic: true);
    }));
  }

  void _finishedWork() {
    _work = null;
    if (_retryAfterWork && ref.mounted) {
      _retryAfterWork = false;
      unawaited(retry(automatic: true));
    }
  }

  Future<void> _restore() async {
    try {
      _session = await _store.latestSession();
      if (!ref.mounted || _session == null) return;
      final items = await _store.items(_session!);
      if (items.any((i) => i.status == 'deferred_ack')) {
        _acknowledgedSessions.add(_session!);
      }
      for (final item in items.where(
          (i) => i.status == 'running' || i.status == 'running_notice')) {
        await _store.update(item.id,
            item.status == 'running_notice' ? 'failed_notice' : 'failed',
            error: 'Sincronizzazione interrotta. Riprova.');
      }
      if (!ref.mounted) return;
      await _snapshot(active: false);
    } catch (_) {
      // L'avvio dell'app non dipende dal recupero del riepilogo.
    }
  }

  /// Acquisisce subito il lock globale; il chiamante può lasciare la route QR.
  Future<void> receive(String qr) {
    if (_work != null) return _work!;
    _work = _receive(qr).whenComplete(_finishedWork);
    return _work!;
  }

  Future<void> _begin() async {
    _stopped = false;
    final support = await _android.start();
    _background = support.available;
    _notifications = support.notifications;
  }

  Future<void> _receive(String qr) async {
    await _ready;
    if (!ref.mounted) return;
    _progressItemIds = null;
    _unprocessedItemIds.clear();
    _updatingGames = false;
    _runAliases = {};
    await _begin();
    _emit(const SyncProgress(phase: SyncPhase.preparing));
    try {
      final encoded = await SyncReceiver().read(qr);
      final payload =
          SyncPayload.fromJson(SyncCompressor.decompressPayload(encoded));
      final digest = await Sha256()
          .hash(utf8.encode(jsonEncode(_canonical(payload.toJson()))));
      if (!ref.mounted) return;
      _emit(SyncProgress(
          phase: SyncPhase.importing,
          total: payload.shows.length +
              payload.movies.length +
              payload.games.length,
          detail: 'Salvataggio dei dati locali'));
      final fingerprint = base64Encode(digest.bytes);
      final latest = await (_store.db.select(_store.db.syncSessions)
            ..where((t) => t.fingerprint.equals(fingerprint))
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingleOrNull();
      if (latest != null) {
        _session = latest.id;
      } else {
        final subscription = ref.listen(syncServiceProvider, (_, __) {});
        try {
          _session = await subscription.read().importData(payload,
              persistSession: true, fingerprint: fingerprint);
        } finally {
          subscription.close();
        }
      }
      if (!ref.mounted) return;
      await _drain();
    } catch (error) {
      if (!ref.mounted) return;
      _emit(SyncProgress(
          phase: SyncPhase.finished,
          errors: [_message(error)],
          detail: 'I dati già salvati sono conservati.'));
    }
  }

  Future<void> retry({bool automatic = false}) {
    if (_work != null) return _work!;
    _work = _retry(automatic: automatic).whenComplete(_finishedWork);
    return _work!;
  }

  Future<void> resumeOlder() async {
    if (busy) return;
    final sessions = await _store.unfinishedSessions();
    if (!ref.mounted || busy) return;
    final older = sessions.where((id) => id != _session).firstOrNull;
    if (older == null) return;
    _session = older;
    await retry();
  }

  Future<void> _retry({required bool automatic}) async {
    try {
      await _ready;
      if (!ref.mounted || _session == null) return;
      _stopped = false;
      final currentItems = await _store.items(_session!);
      final candidates = currentItems
          .where((i) =>
              !i.syncTerminal &&
              !(i.syncDeferred && (_rawgCredential?.trim().isEmpty ?? true)))
          .toList();
      if (automatic && !(_rawgCredential?.trim().isEmpty ?? true)) {
        candidates.addAll(await (_store.db.select(_store.db.syncItems)
              ..where((t) =>
                  t.domain.equals('games') &
                  t.status.isIn(
                      ['deferred', 'deferred_ack', 'failed', 'failed_notice'])))
            .get());
      }
      if (!ref.mounted) return;
      // Un contenuto può avere checkpoint in più trasferimenti: un solo lavoro
      // per identità locale, con propagazione dell'esito agli altri checkpoint.
      final groups = <(String, int, int), Map<int, SyncItem>>{};
      for (final item in candidates) {
        groups.putIfAbsent((item.domain, item.externalId, item.localId),
            () => {})[item.id] = item;
      }
      final items = <SyncItem>[];
      _runAliases = {};
      for (final group in groups.values) {
        final rows = group.values.toList()
          ..sort((a, b) => b.id.compareTo(a.id));
        items.add(rows.first);
        if (rows.length > 1) _runAliases[rows.first.id] = rows.skip(1).toList();
      }
      if (items.isEmpty) return;
      for (final item in items.where((i) =>
          i.domain == 'shows' &&
          i.status != 'completed' &&
          i.status != 'removed')) {
        if (!ref.mounted) return;
        ref.invalidate(rawShowDetailProvider(item.externalId));
        ref.invalidate(showDetailProvider(item.externalId));
        final fresh =
            await _store.db.animeCacheDao.getFreshAnimeSeasons(item.externalId);
        if (!ref.mounted) return;
        if (fresh == null) {
          ref.invalidate(animeDataProvider(item.externalId));
        }
      }
      // Un recupero automatico a app non visibile non avvia nuovi FGS.
      if (!automatic) {
        await _begin();
      } else {
        _background = false;
        _notifications = false;
      }
      _stopped = false;
      await _drain(
          workItems: items,
          updatingGames: items.every((i) => i.domain == 'games'));
    } catch (error) {
      if (ref.mounted) {
        _emit(SyncProgress(
            phase: SyncPhase.finished,
            errors: [_message(error)],
            detail: 'I dati già salvati sono conservati.'));
      }
    }
  }

  Future<void> _drain(
      {List<SyncItem>? workItems, bool updatingGames = false}) async {
    final items = workItems ?? await _store.items(_session!);
    _progressItemIds = items.map((i) => i.id).toList();
    _updatingGames = updatingGames;
    _unprocessedItemIds
      ..clear()
      ..addAll(items
          .where((i) =>
              !i.syncTerminal &&
              !(i.syncDeferred && (_rawgCredential?.trim().isEmpty ?? true)))
          .map((i) => i.id));
    await _snapshot(active: true);
    // Due elementi; le richieste AniList rimangono nella coda condivisa.
    var cursor = 0;
    Future<void> worker() async {
      while (ref.mounted && !_stopped && cursor < items.length) {
        final item = items[cursor++];
        if (item.syncTerminal) continue;
        if (item.syncDeferred && (_rawgCredential?.trim().isEmpty ?? true)) {
          _unprocessedItemIds.remove(item.id);
          continue;
        }
        await _process(item);
        if (ref.mounted) await _updateAliases(item);
      }
    }

    await Future.wait([worker(), worker()]);
    if (ref.mounted) {
      for (final item in await _store.itemsByIds(_progressItemIds!)) {
        if (item.status == 'running' ||
            item.status == 'running_notice' ||
            item.status == 'pending') {
          await _store.update(item.id,
              item.status == 'running_notice' ? 'failed_notice' : 'failed',
              error: 'Sincronizzazione interrotta. Riprova.');
          _unprocessedItemIds.remove(item.id);
          await _updateAliases(item);
        }
      }
    }
    if (ref.mounted) await _snapshot(active: false);
  }

  Future<void> _process(SyncItem item) async {
    String outcome(String status) => item.syncNeedsAcknowledgement &&
            !_acknowledgedSessions.contains(item.sessionId)
        ? '${status}_notice'
        : status;
    int generationNow() =>
        item.domain == 'games' ? _rawgGeneration : _tmdbGeneration;
    var generation = generationNow();
    bool current() => ref.mounted && !_stopped && generation == generationNow();
    await _store.update(item.id, outcome('running'));
    if (!current()) return;
    await _snapshot(
        active: true, title: item.title, detail: 'Recupero metadati');
    ProviderSubscription<SyncService>? subscription;
    try {
      if (item.domain == 'games') {
        await ref.readFuture(rawgAuthControllerProvider.future);
      } else {
        await ref.readFuture(authControllerProvider.future);
      }
      if (!ref.mounted || _stopped) return;
      generation = generationNow();
      if (!current()) {
        throw const FormatException('Credenziali cambiate. Riprova.');
      }
      final before = await _localTitle(item);
      if (before == null) {
        await _store.update(item.id, outcome('removed'),
            error: 'Elemento rimosso durante la sincronizzazione.');
        return;
      }
      if (before != 'Sconosciuto' && item.domain != 'shows') {
        await _store.update(item.id, outcome('completed'), title: before);
        return;
      }
      if (item.domain == 'games' && (_rawgCredential?.trim().isEmpty ?? true)) {
        final acknowledged = item.status == 'deferred_ack' ||
            _acknowledgedSessions.contains(item.sessionId);
        await _store.update(
            item.id, acknowledged ? 'deferred_ack' : 'deferred');
        return;
      }
      if (item.domain == 'games'
          ? (_rawgCredential?.trim().isEmpty ?? true)
          : (_tmdbCredential?.trim().isEmpty ?? true)) {
        throw const FormatException(
            'Configura le credenziali per recuperare i metadati.');
      }
      subscription = ref.listen(syncServiceProvider, (_, __) {});
      await subscription.read().hydrateUnknownMedia(
            shows: item.domain == 'shows',
            movies: item.domain == 'movies',
            games: item.domain == 'games',
            localId: item.localId,
            strict: true,
            isCurrent: current,
            showDetailsLoader: (id) =>
                ref.readFuture(rawShowDetailProvider(id).future),
          );
      if (!current()) {
        throw const FormatException('Sincronizzazione interrotta. Riprova.');
      }
      var title = await _localTitle(item);
      if (title == null) {
        await _store.update(item.id, outcome('removed'),
            error: 'Elemento rimosso durante la sincronizzazione.');
        return;
      }
      if (title == 'Sconosciuto') {
        throw const FormatException('Metadati non disponibili. Riprova.');
      }
      await _store.update(item.id, outcome('running'), title: title);
      await _snapshot(
          active: true,
          title: title,
          detail: item.domain == 'shows'
              ? 'Stagioni, episodi e calendario'
              : 'Salvataggio metadati');
      if (item.domain == 'shows') {
        final detail =
            await ref.readFuture(showDetailProvider(item.externalId).future);
        if (!current()) {
          throw const FormatException('Credenziali cambiate. Riprova.');
        }
        if (detail.isLocalSnapshot) {
          throw const FormatException(
              'Dati salvati disponibili; aggiornamento online non riuscito.');
        }
        if (detail.isAnime &&
            (detail.animeSeasonsData == null ||
                await _store.db.animeCacheDao
                        .getFreshAnimeSeasons(item.externalId) ==
                    null)) {
          throw const FormatException(
              'Mapping cour non disponibile. Progressi conservati.');
        }
        if (!current()) {
          throw const FormatException('Sincronizzazione interrotta. Riprova.');
        }
        await _restoreCourProgress(item);
        if (!current()) {
          throw const FormatException('Sincronizzazione interrotta. Riprova.');
        }
        if (await _localTitle(item) == null) {
          await _store.update(item.id, outcome('removed'));
          return;
        }
        await ref
            .read(trackedShowsProvider.notifier)
            .syncMetadata(detail, item.localId, isCurrent: current);
        if (!current()) {
          throw const FormatException('Sincronizzazione interrotta. Riprova.');
        }
        final show = await _store.db.showsDao.getById(item.localId);
        if (show == null) {
          await _store.update(item.id, outcome('removed'));
          return;
        }
        if (show.status == MediaStatus.watching) {
          final watched =
              await _store.db.showsDao.getEpisodesByShow(item.localId);
          final bySeason = <int, Set<int>>{};
          for (final ep in watched.where((e) => e.watched)) {
            bySeason
                .putIfAbsent(ep.seasonNumber, () => {})
                .add(ep.episodeNumber);
          }
          final counts = await _store.db.showsDao.getSeasonCounts(item.localId);
          final next = computeNextToWatch(bySeason, counts,
              animeSeasonsData: detail.animeSeasonsData);
          if ((counts[next.$1] ?? 0) >= next.$2) {
            final season = await ref.readFuture(seasonDetailProvider(
                    showId: item.externalId, seasonNumber: next.$1)
                .future);
            if (season.isLocalSnapshot) {
              throw const FormatException(
                  'Episodi salvati disponibili; aggiornamento da riprovare.');
            }
          }
          if (current()) {
            await ref
                .read(trackedShowsProvider.notifier)
                .rescheduleNotification(detail);
          }
        }
      }
      if (!current()) {
        throw const FormatException('Sincronizzazione interrotta. Riprova.');
      }
      title = await _localTitle(item);
      await _store.update(
          item.id, outcome(title == null ? 'removed' : 'completed'),
          title: title);
    } catch (error) {
      if (ref.mounted) {
        await _store.update(item.id, outcome('failed'), error: _message(error));
      }
    } finally {
      subscription?.close();
      _unprocessedItemIds.remove(item.id);
      if (ref.mounted) await _snapshot(active: true);
    }
  }

  Future<String?> _localTitle(SyncItem item) async {
    final db = _store.db;
    return switch (item.domain) {
      'shows' => (await (db.select(db.trackedShows)
                ..where((t) =>
                    t.id.equals(item.localId) &
                    t.tmdbId.equals(item.externalId)))
              .getSingleOrNull())
          ?.title,
      'movies' => (await (db.select(db.trackedMovies)
                ..where((t) =>
                    t.id.equals(item.localId) &
                    t.tmdbId.equals(item.externalId)))
              .getSingleOrNull())
          ?.title,
      'games' => (await (db.select(db.trackedGames)
                ..where((t) =>
                    t.id.equals(item.localId) &
                    t.rawgId.equals(item.externalId)))
              .getSingleOrNull())
          ?.title,
      _ => null,
    };
  }

  Future<void> _restoreCourProgress(SyncItem item) async {
    if (item.progressData == null) return;
    final data = ShowSyncData.fromJson(
        jsonDecode(item.progressData!) as Map<String, dynamic>);
    if (data.coordinates != 'cour' || data.eps.isEmpty) return;
    final seasons =
        await _store.db.animeCacheDao.getFreshAnimeSeasons(item.externalId);
    if (seasons == null) {
      throw const FormatException('Mapping cour non disponibile.');
    }
    final mapped = <int, Set<int>>{};
    for (final entry in data.eps.entries) {
      if (entry.key == '0') {
        mapped
            .putIfAbsent(0, () => {})
            .addAll(RangeUtils.expandRangeToList(entry.value));
        continue;
      }
      final id = data.courIds[entry.key];
      final matches =
          seasons.where((s) => id != null && s.anilistId == id).toList();
      if (matches.length != 1) {
        throw const FormatException(
            'Cour non riconciliabile. Progressi ricevuti conservati.');
      }
      mapped
          .putIfAbsent(matches.single.seasonNumber, () => {})
          .addAll(RangeUtils.expandRangeToList(entry.value));
    }
    await _store.db.transaction(() async {
      if (await _localTitle(item) == null) return;
      final existing = await _store.db.showsDao.getEpisodesByShow(item.localId);
      final keys = {
        for (final ep in existing.where((e) => e.watched))
          (ep.seasonNumber, ep.episodeNumber)
      };
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(data.updatedAt * 1000);
      await _store.db.batch((b) {
        for (final entry in mapped.entries) {
          final season = entry.key;
          for (final number in entry.value) {
            if (keys.contains((season, number))) continue;
            final row = TrackedEpisodesCompanion.insert(
                showId: item.localId,
                seasonNumber: season,
                episodeNumber: number,
                watched: const Value(true),
                updatedAt: Value(timestamp));
            b.insert(_store.db.trackedEpisodes, row,
                onConflict: DoUpdate(
                    (_) => TrackedEpisodesCompanion(
                        watched: const Value(true),
                        updatedAt: Value(timestamp)),
                    target: [
                      _store.db.trackedEpisodes.showId,
                      _store.db.trackedEpisodes.seasonNumber,
                      _store.db.trackedEpisodes.episodeNumber
                    ]));
          }
        }
      });
    });
  }

  Future<void> _snapshot(
      {required bool active, String? title, String? detail}) async {
    if (_session == null || !ref.mounted) return;
    final revision = ++_snapshotRevision;
    final items = _progressItemIds == null
        ? await _store.items(_session!)
        : await _store.itemsByIds(_progressItemIds!);
    if (!ref.mounted) return;
    if (!active) {
      _otherSessions = (await _store.unfinishedSessions())
          .where((id) => id != _session)
          .length;
      if (!ref.mounted) return;
    }
    if (revision != _snapshotRevision) return;
    final settled =
        items.where((i) => !_unprocessedItemIds.contains(i.id)).toList();
    final deferred = settled.where((i) => i.syncDeferred).length;
    final notices = await (_store.db.select(_store.db.syncItems)
          ..where((t) =>
              t.status.equals('deferred') |
              t.status.isIn([
                'completed_notice',
                'failed_notice',
                'removed_notice',
                'running_notice'
              ])))
        .get();
    if (!ref.mounted || revision != _snapshotRevision) return;
    final needsAcknowledgement = notices.isNotEmpty;
    final errors = [
      for (final i in items)
        if (i.error != null)
          '${i.title ?? '${i.domain} ${i.externalId}'}: ${i.error}'
    ];
    final running = items
        .where((i) => i.status == 'running' || i.status == 'running_notice')
        .firstOrNull;
    final currentTitle = title ?? running?.title;
    final label = running == null
        ? null
        : switch (running.domain) {
            'shows' => 'Serie',
            'movies' => 'Film',
            _ => 'Gioco',
          };
    _emit(SyncProgress(
        phase: active ? SyncPhase.enriching : SyncPhase.finished,
        total: items.length,
        completed: settled.where((i) => i.syncCompleted).length,
        failed: settled
            .where((i) =>
                !i.syncCompleted &&
                !i.syncDeferred &&
                (!active ||
                    (i.status != 'running' &&
                        i.status != 'running_notice' &&
                        i.status != 'pending')))
            .length,
        title: currentTitle == 'Sconosciuto'
            ? '$label · ID ${running?.externalId}'
            : currentTitle,
        detail: detail ?? (running == null ? null : 'Recupero metadati'),
        errors: errors,
        deferredGames: deferred,
        needsGameAcknowledgement: needsAcknowledgement,
        updatingGames: _updatingGames));
  }

  void _emit(SyncProgress progress) {
    if (!ref.mounted) return;
    state = SyncProgress(
        phase: progress.phase,
        total: progress.total,
        completed: progress.completed,
        failed: progress.failed,
        title: progress.title,
        detail: progress.detail,
        errors: progress.errors,
        backgroundAvailable: _background,
        notificationsAllowed: _notifications,
        otherSessions: _otherSessions,
        deferredGames: progress.deferredGames,
        needsGameAcknowledgement: progress.needsGameAcknowledgement,
        updatingGames: progress.updatingGames);
    _android.publish(state);
  }

  Future<void> acknowledgeGames() async {
    if (_session == null) return;
    final notices = await (_store.db.select(_store.db.syncItems)
          ..where((t) =>
              t.status.equals('deferred') |
              t.status.isIn([
                'completed_notice',
                'failed_notice',
                'removed_notice',
                'running_notice'
              ])))
        .get();
    if (!ref.mounted) return;
    _acknowledgedSessions.add(_session!);
    _acknowledgedSessions.addAll(notices.map((i) => i.sessionId));
    await _store.db.transaction(() async {
      for (final entry in {
        'deferred': 'deferred_ack',
        'completed_notice': 'completed',
        'removed_notice': 'removed',
        'failed_notice': 'failed',
        'running_notice': 'running'
      }.entries) {
        await (_store.db.update(_store.db.syncItems)
              ..where((t) => t.status.equals(entry.key)))
            .write(SyncItemsCompanion(status: Value(entry.value)));
      }
    });
    if (ref.mounted) await _snapshot(active: busy);
  }

  Future<void> _updateAliases(SyncItem item) async {
    final aliases = _runAliases[item.id];
    if (aliases == null || aliases.isEmpty) return;
    final result = (await _store.itemsByIds([item.id])).single;
    if (result.status == 'running' || result.status == 'running_notice') return;
    await _store.db.transaction(() async {
      for (final alias in aliases) {
        String status;
        final needsNotice = alias.syncNeedsAcknowledgement &&
            !_acknowledgedSessions.contains(alias.sessionId);
        if (result.syncDeferred) {
          status = needsNotice ? 'deferred' : 'deferred_ack';
        } else {
          final base = result.status.replaceFirst('_notice', '');
          status = needsNotice ? '${base}_notice' : base;
        }
        await _store.update(alias.id, status,
            title: result.title, error: result.error);
      }
    });
  }

  void dismiss() {
    if (ref.mounted) ref.read(syncPanelOpenProvider.notifier).hide();
  }

  static String _message(Object error) {
    if (error is FormatException) return error.message;
    if (error is TmdbException && [401, 403].contains(error.statusCode)) {
      return 'Credenziali TMDB non valide.';
    }
    if (error is RawgException && [401, 403].contains(error.statusCode)) {
      return 'Credenziali RAWG non valide.';
    }
    if (error is TmdbException && error.statusCode == 404) {
      return 'Elemento non disponibile su TMDB.';
    }
    return 'Recupero non riuscito. Controlla la connessione e riprova.';
  }
}

Object? _canonical(Object? value) {
  if (value is Map<String, dynamic>) {
    final keys = value.keys.toList()..sort();
    return {for (final k in keys) k: _canonical(value[k])};
  }
  return value;
}
