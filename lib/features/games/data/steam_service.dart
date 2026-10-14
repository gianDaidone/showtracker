import 'dart:convert';
import 'package:http/http.dart' as http;

import 'models/game_trailer.dart';

/// Endpoint pubblico (non documentato) dello store Steam: niente chiave,
/// circa 200 richieste ogni 5 minuti per IP.
class SteamService {
  final http.Client _client;
  static const _base = 'https://store.steampowered.com/api';

  SteamService(this._client);

  Future<List<GameTrailer>> getTrailers(int appId) async {
    final response = await _client.get(Uri.parse('$_base/appdetails').replace(
      queryParameters: {'appids': '$appId', 'filters': 'movies'},
    ));
    if (response.statusCode != 200) {
      throw SteamException('Errore Steam ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final app = json['$appId'] as Map<String, dynamic>?;
    if (app == null || app['success'] != true) return [];

    final data = app['data'];
    // Senza video Steam restituisce `data: []` invece di un oggetto
    if (data is! Map<String, dynamic>) return [];

    return ((data['movies'] as List<dynamic>?) ?? [])
        .map((m) => GameTrailer.tryParseSteam(m as Map<String, dynamic>))
        .whereType<GameTrailer>()
        .toList();
  }
}

class SteamException implements Exception {
  final String message;
  SteamException(this.message);

  @override
  String toString() => message;
}
