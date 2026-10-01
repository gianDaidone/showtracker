import 'dart:convert';

import 'package:http/http.dart' as http;

import 'anilist_queue.dart';
import 'models/anilist_media.dart';

class AniListService {
  static const _endpoint = 'https://graphql.anilist.co';
  static const int _maxRetries = 2;

  final AniListQueue _queue = AniListQueue();
  final http.Client _client = http.Client();

  // ── Queries ───────────────────────────────────────────────────────────────

  static const _detailsQuery = r'''
query($id: Int) {
  Media(id: $id, type: ANIME) {
    id
    title { romaji english }
    status
    format
    episodes
    season
    seasonYear
    averageScore
    nextAiringEpisode { episode airingAt timeUntilAiring }
    streamingEpisodes { title thumbnail }
  }
}
''';

  static const _searchQuery = r'''
query($search: String) {
  Page(perPage: 10) {
    media(search: $search, type: ANIME, format_in: [TV, TV_SHORT]) {
      id
      title { romaji english }
      status
      format
      episodes
      season
      seasonYear
      startDate { year month day }
      averageScore
      nextAiringEpisode { episode airingAt timeUntilAiring }
      streamingEpisodes { title thumbnail }
    }
  }
}
''';

  // ── Public API ────────────────────────────────────────────────────────────

  Future<AniListMedia?> fetchById(int id) {
    return _queue.enqueue(() async {
      final body = await _graphql(_detailsQuery, {'id': id});
      return body == null ? null : AniListMedia.fromGraphqlResponse(body);
    });
  }

  /// Serie TV che corrispondono a [title], in ordine di rilevanza AniList.
  ///
  /// Restituisce tutti i candidati e non solo il primo: titoli come
  /// "ブラッククローバー" corrispondono sia alla serie originale sia ai suoi
  /// seguiti, ed è il chiamante a sapere quale cerca.
  Future<List<AniListMedia>> searchByTitle(String title) {
    return _queue.enqueue(() async {
      final body = await _graphql(_searchQuery, {'search': title});
      if (body == null) return const <AniListMedia>[];
      return AniListMedia.listFromGraphqlPageResponse(body) ??
          const <AniListMedia>[];
    });
  }

  /// Fetches up to [ids.length] entries, with the queue's built-in concurrency limit.
  Future<List<AniListMedia>> fetchBatch(List<int> ids) async {
    final futures = ids.map(fetchById).toList();
    final results = await Future.wait(futures, eagerError: false);
    return results.whereType<AniListMedia>().toList();
  }

  void dispose() {
    _queue.dispose();
    _client.close();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _graphql(
    String query,
    Map<String, dynamic> variables, {
    int attempt = 0,
  }) async {
    final body = jsonEncode({'query': query, 'variables': variables});
    http.Response response;
    try {
      response = await _client.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: body,
      );
    } catch (_) {
      return null;
    }

    // Rate-limited: retry after waiting.
    if (response.statusCode == 429 && attempt < _maxRetries) {
      final retryAfter = int.tryParse(
            response.headers['retry-after'] ?? '',
          ) ??
          10;
      await Future.delayed(Duration(seconds: retryAfter));
      return _graphql(query, variables, attempt: attempt + 1);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
