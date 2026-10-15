import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/paged_search.dart';
import 'game_search_ranking.dart';
import 'models/game_trailer.dart';
import 'models/rawg_game.dart';
import 'models/rawg_game_detail.dart';

class RawgService {
  final http.Client _client;
  static const _base = 'https://api.rawg.io/api';

  RawgService(this._client);

  Uri _uri(String path, [Map<String, String>? params]) {
    return Uri.parse('$_base$path').replace(
      queryParameters: params,
    );
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final response = await _client.get(uri);
    
    if (response.statusCode >= 500) {
      throw RawgException('Il servizio RAWG è temporaneamente non disponibile (Errore ${response.statusCode}). Riprova più tardi.');
    }
    
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RawgException('Errore RAWG ${response.statusCode}: ${response.reasonPhrase ?? ""}');
    }
    
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static const _searchPageSize = 40;

  /// Pagina [page] della ricerca, già riordinata con [rankGameSearch].
  ///
  /// La prima pagina unisce due richieste parallele — ordine di rilevanza e
  /// `search_precise` + `-added` (popolarità) — perché nessuna delle due da
  /// sola mette in testa il gioco giusto per ogni tipo di ricerca. Le
  /// successive proseguono solo la lista di rilevanza: i doppioni con la
  /// prima li scarta chi le accoda (`PagedSearchNotifier`).
  Future<SearchPage<RawgGame>> searchGames(String query, {int page = 1}) async {
    if (query.length < 2) return const SearchPage(items: [], hasMore: false);

    Future<Map<String, dynamic>> fetch(Map<String, String> extra, int page) =>
        _get(_uri('/games', {
          'search': query,
          'page': '$page',
          'page_size': '$_searchPageSize',
          ...extra,
        }));
    List<RawgGame> parse(Map<String, dynamic> data) =>
        ((data['results'] as List<dynamic>?) ?? [])
            .map((e) => RawgGame.fromJson(e as Map<String, dynamic>))
            .toList();

    if (page > 1) {
      final data = await fetch(const {}, page);
      return SearchPage(
        items: rankGameSearch(query, parse(data)),
        hasMore: data['next'] != null,
        totalCount: data['count'] as int?,
      );
    }

    final [relevance, popular] = await Future.wait([
      fetch(const {}, 1),
      fetch(const {'search_precise': 'true', 'ordering': '-added'}, 1),
    ]);
    return SearchPage(
      items: rankGameSearch(query, parse(relevance), parse(popular)),
      hasMore: relevance['next'] != null,
      totalCount: relevance['count'] as int?,
    );
  }

  /// Le liste "da scoprire" si fermano qui (10 × 40 giochi): RAWG ha una
  /// quota mensile per chiave, e oltre i primi 400 nessuno scorre davvero.
  static const discoverMaxPages = 10;

  /// Pagina [page] di `/games` ordinata per [ordering] (es. `-added`), con
  /// filtri facoltativi su date di uscita (`AAAA-MM-GG,AAAA-MM-GG`) e generi.
  Future<SearchPage<RawgGame>> discoverGames({
    required String ordering,
    String? dates,
    List<int> genreIds = const [],
    int page = 1,
  }) async {
    final data = await _get(_uri('/games', {
      'ordering': ordering,
      if (dates != null) 'dates': dates,
      if (genreIds.isNotEmpty) 'genres': genreIds.join(','),
      'page': '$page',
      'page_size': '$_searchPageSize',
    }));
    return SearchPage(
      items: ((data['results'] as List<dynamic>?) ?? [])
          .map((e) => RawgGame.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: data['next'] != null && page < discoverMaxPages,
      totalCount: data['count'] as int?,
    );
  }

  Future<RawgGameDetail> getGameDetails(int id) async {
    final data = await _get(_uri('/games/$id'));
    return RawgGameDetail.fromJson(data);
  }

  Future<List<String>> getScreenshots(int id) async {
    try {
      final data = await _get(_uri('/games/$id/screenshots'));
      return ((data['results'] as List<dynamic>?) ?? [])
          .map((s) => s['image'] as String)
          .where((url) => url.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Per molti giochi è vuoto: RAWG non aggiorna più i trailer da Steam.
  Future<List<GameTrailer>> getTrailers(int id) async {
    final data = await _get(_uri('/games/$id/movies'));
    return ((data['results'] as List<dynamic>?) ?? [])
        .map((m) => GameTrailer.tryParseRawg(m as Map<String, dynamic>))
        .whereType<GameTrailer>()
        .toList();
  }

  /// App ID Steam del gioco, ricavato dal link allo store; `null` se il gioco
  /// non è su Steam.
  Future<int?> getSteamAppId(int id) async {
    final data = await _get(_uri('/games/$id/stores'));
    for (final s in (data['results'] as List<dynamic>?) ?? []) {
      final match = _steamAppUrl.firstMatch(s['url'] as String? ?? '');
      if (match != null) return int.parse(match.group(1)!);
    }
    return null;
  }

  static final _steamAppUrl =
      RegExp(r'store\.steampowered\.com/app/(\d+)');
}

class RawgException implements Exception {
  final String message;
  RawgException(this.message);

  @override
  String toString() => message;
}
