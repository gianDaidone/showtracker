import 'dart:convert';
import 'package:http/http.dart' as http;

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

  Future<List<RawgGame>> searchGames(String query) async {
    if (query.length < 2) return [];
    final data = await _get(_uri('/games', {
      'search': query,
      'page_size': '20',
    }));
    return ((data['results'] as List<dynamic>?) ?? [])
        .map((e) => RawgGame.fromJson(e as Map<String, dynamic>))
        .toList();
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
