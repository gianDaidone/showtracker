import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/models/rawg_game.dart';
import '../data/models/rawg_game_detail.dart';
import '../data/rawg_service.dart';

import 'package:http/http.dart' as http;
import '../../../core/network/tmdb_http_client.dart';
import '../../../core/auth/rawg_auth_state.dart';

part 'games_providers.g.dart';

// ── RAWG Service ──────────────────────────────────────────────────────────────

@riverpod
RawgService rawgService(RawgServiceRef ref) {
  final authStateAsync = ref.watch(rawgAuthControllerProvider);
  final authState = authStateAsync.valueOrNull ?? const RawgUnauthenticated();
  final client = AppInterceptor(http.Client(), rawgAuthState: authState);
  ref.onDispose(client.close);
  return RawgService(client);
}

// ── Ricerca giochi ────────────────────────────────────────────────────────────

@riverpod
Future<List<RawgGame>> searchGames(SearchGamesRef ref, String query) {
  if (query.length < 2) return Future.value([]);
  return ref.watch(rawgServiceProvider).searchGames(query);
}

// ── Dettaglio gioco ───────────────────────────────────────────────────────────

@riverpod
Future<RawgGameDetail> gameDetail(GameDetailRef ref, int rawgId) {
  return ref.watch(rawgServiceProvider).getGameDetails(rawgId);
}

// ── Screenshot gioco ──────────────────────────────────────────────────────────

@riverpod
Future<List<String>> gameScreenshots(GameScreenshotsRef ref, int rawgId) {
  return ref.watch(rawgServiceProvider).getScreenshots(rawgId);
}

// ── DB: giochi tracciati (stream reattivo) ────────────────────────────────────

@riverpod
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
