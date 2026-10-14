import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/models/game_trailer.dart';
import '../data/models/rawg_game.dart';
import '../data/models/rawg_game_detail.dart';
import '../data/rawg_service.dart';
import '../data/steam_service.dart';

import 'package:http/http.dart' as http;
import '../../../core/network/tmdb_http_client.dart';
import '../../../core/auth/rawg_auth_state.dart';

part 'games_providers.g.dart';

// ── RAWG Service ──────────────────────────────────────────────────────────────

@riverpod
RawgService rawgService(Ref ref) {
  final authStateAsync = ref.watch(rawgAuthControllerProvider);
  final authState = authStateAsync.value ?? const RawgUnauthenticated();
  final client = AppInterceptor(http.Client(), rawgAuthState: authState);
  ref.onDispose(client.close);
  return RawgService(client);
}

// ── Ricerca giochi ────────────────────────────────────────────────────────────

@riverpod
Future<List<RawgGame>> searchGames(Ref ref, String query) {
  if (query.length < 2) return Future.value([]);
  return ref.watch(rawgServiceProvider).searchGames(query);
}

// ── Dettaglio gioco ───────────────────────────────────────────────────────────

@riverpod
Future<RawgGameDetail> gameDetail(Ref ref, int rawgId) {
  return ref.watch(rawgServiceProvider).getGameDetails(rawgId);
}

// ── Screenshot gioco ──────────────────────────────────────────────────────────

@riverpod
Future<List<String>> gameScreenshots(Ref ref, int rawgId) {
  return ref.watch(rawgServiceProvider).getScreenshots(rawgId);
}

// ── Trailer gioco ─────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
SteamService steamService(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return SteamService(client);
}

/// Trailer da Steam, ricavando l'app ID dai negozi RAWG; RAWG `/movies` solo
/// come riserva, perché per molti giochi è vuoto. Un gioco senza trailer
/// restituisce una lista vuota, mai un errore: la sezione semplicemente non
/// compare.
@riverpod
Future<List<GameTrailer>> gameTrailers(Ref ref, int rawgId) async {
  final rawg = ref.watch(rawgServiceProvider);
  final steam = ref.watch(steamServiceProvider);

  try {
    final appId = await rawg.getSteamAppId(rawgId);
    if (appId != null) {
      final trailers = await steam.getTrailers(appId);
      if (trailers.isNotEmpty) return trailers;
    }
  } catch (e) {
    debugPrint('Trailer Steam non disponibili per il gioco $rawgId: $e');
  }

  try {
    return await rawg.getTrailers(rawgId);
  } catch (e) {
    debugPrint('Trailer RAWG non disponibili per il gioco $rawgId: $e');
    return [];
  }
}

// ── DB: giochi tracciati (stream reattivo) ────────────────────────────────────

// keepAlive: stato globale dell'app. Con Riverpod 3 un notifier autoDispose
// eliminato durante un await fa fallire il resto del metodo (ref/state dopo
// il dispose lanciano UnmountedRefException).
@Riverpod(keepAlive: true)
class TrackedGamesNotifier extends _$TrackedGamesNotifier {
  @override
  Stream<List<TrackedGame>> build() {
    return ref.watch(gamesDaoProvider).watchAll();
  }

  Future<void> addGame(RawgGameDetail detail) async {
    await ref.read(gamesDaoProvider).insertGame(
          TrackedGamesCompanion(
            rawgId: Value(detail.id),
            title: Value(detail.name),
            coverUrl: Value(detail.coverUrl),
            status: const Value(MediaStatus.planToWatch),
            addedAt: Value(DateTime.now()),
            releaseDate: Value(detail.releaseDateParsed),
            playtime: Value(detail.playtime),
            platforms: Value(
              detail.platforms.isNotEmpty
                  ? jsonEncode(detail.platforms)
                  : null,
            ),
            voteAverage:
                Value(detail.voteAverage > 0 ? detail.voteAverage : null),
          ),
        );
  }

  Future<void> removeGame(int dbId) async {
    await ref.read(gamesDaoProvider).deleteGame(dbId);
  }

  Future<void> updateStatus(int dbId, MediaStatus status) async {
    await ref.read(gamesDaoProvider).updateStatus(dbId, status);
  }

  Future<void> markPlayed(int dbId, double rating) async {
    final dao = ref.read(gamesDaoProvider);
    await dao.updateStatus(dbId, MediaStatus.completed);
    await dao.updateRating(dbId, rating);
  }

  Future<void> markFolded(int dbId) async {
    final dao = ref.read(gamesDaoProvider);
    await dao.updateStatus(dbId, MediaStatus.dropped);
    await dao.updateRating(dbId, null);
  }

  Future<void> resetToBacklog(int dbId) async {
    final dao = ref.read(gamesDaoProvider);
    await dao.updateStatus(dbId, MediaStatus.planToWatch);
    await dao.updateRating(dbId, null);
  }
}
