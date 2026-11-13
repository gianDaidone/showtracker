import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/auth/rawg_auth_state.dart';
import '../../../core/constants/api_keys.dart';
import '../../../core/riverpod_utils.dart';
import '../../../core/services/coalescing_refresh.dart';
import '../services/sync_service.dart';

/// Il proprietario non dipende dai client: i cambi credenziali accodano un nuovo
/// passaggio, invece di disporre il coordinatore durante una richiesta.
final metadataRecoveryProvider = Provider<MetadataRecovery>((ref) {
  final recovery = MetadataRecovery(ref);
  ref.onDispose(recovery.dispose);
  ref.listen(rawgAuthControllerProvider, (_, next) {
    if (!next.isLoading) recovery.rawgChanged(next.value);
  }, fireImmediately: true);
  ref.listen(authControllerProvider, (_, next) {
    if (!next.isLoading) recovery.tmdbChanged(next.value);
  }, fireImmediately: true);
  return recovery;
});

enum _Domain { shows, movies, games }

class MetadataRecovery {
  MetadataRecovery(this._ref) {
    _games = CoalescingRefresh(() => _run(_Domain.games));
    _movies = CoalescingRefresh(() => _run(_Domain.movies));
    _shows = CoalescingRefresh(() => _run(_Domain.shows));
  }

  final Ref _ref;
  late final CoalescingRefresh _games;
  late final CoalescingRefresh _movies;
  late final CoalescingRefresh _shows;
  bool _disposed = false;
  String? _rawgCredential;
  String? _tmdbCredential;
  int _rawgGeneration = 0;
  int _tmdbGeneration = 0;

  String? _rawgKey(RawgAuthState? auth) {
    if (auth == null) return null;
    final key = auth is RawgAuthenticated ? auth.apiKey : ApiKeys.rawg;
    return key.trim().isEmpty ? null : key;
  }

  String? _tmdbKey(AuthState? auth) {
    if (auth == null) return null;
    return switch (auth) {
      AuthenticatedWithManualKey(:final apiKey) =>
        apiKey.trim().isEmpty ? null : apiKey,
      AuthenticatedWithSession(:final sessionId) =>
        ApiKeys.tmdb.isEmpty ? null : '${ApiKeys.tmdb}:$sessionId',
      Unauthenticated() => ApiKeys.tmdb.isEmpty ? null : ApiKeys.tmdb,
    };
  }

  void rawgChanged(RawgAuthState? auth) {
    final credential = _rawgKey(auth);
    if (credential == _rawgCredential) return;
    _rawgCredential = credential;
    _rawgGeneration++;
    if (credential != null) unawaited(recoverGames());
  }

  void tmdbChanged(AuthState? auth) {
    final credential = _tmdbKey(auth);
    if (credential == _tmdbCredential) return;
    _tmdbCredential = credential;
    _tmdbGeneration++;
    if (credential != null) unawaited(recoverMovies());
  }

  Future<void> recoverGames() =>
      _disposed ? Future<void>.value() : _games.request();
  Future<void> recoverMovies() =>
      _disposed ? Future<void>.value() : _movies.request();
  Future<void> recoverShows() =>
      _disposed ? Future<void>.value() : _shows.request();

  Future<void> recoverAfterImport() async {
    await Future.wait([recoverShows(), recoverMovies(), recoverGames()]);
  }

  Future<void> _run(_Domain domain) async {
    if (_disposed) return;
    ProviderSubscription<SyncService>? subscription;
    try {
      final games = domain == _Domain.games;
      if (games) {
        final auth = await _ref.readFuture(rawgAuthControllerProvider.future);
        if (_disposed || _rawgKey(auth) == null) return;
      } else {
        final auth = await _ref.readFuture(authControllerProvider.future);
        if (_disposed || _tmdbKey(auth) == null) return;
      }
      final generation = games ? _rawgGeneration : _tmdbGeneration;
      bool isCurrent() =>
          !_disposed &&
          generation == (games ? _rawgGeneration : _tmdbGeneration);
      // Mantiene in vita il service e i suoi client anche lasciando la pagina
      // QR. Un cambio auth può invalidarli: isCurrent ferma le richieste residue
      // e il passaggio trailing acquisisce il nuovo interceptor.
      subscription = _ref.listen(syncServiceProvider, (_, __) {});
      final service = subscription.read();
      await service.hydrateUnknownMedia(
        games: games,
        movies: domain == _Domain.movies,
        shows: domain == _Domain.shows,
        isCurrent: isCurrent,
      );
    } catch (_) {
      // Nessun retry automatico: login, apertura libreria o prossimo avvio
      // riprovano i soli placeholder rimasti. Non loggare URL/credenziali.
      debugPrint(
          'Recupero metadati ${domain.name} non riuscito; dati locali conservati.');
    } finally {
      subscription?.close();
    }
  }

  void dispose() {
    _disposed = true;
    _rawgGeneration++;
    _tmdbGeneration++;
  }
}
