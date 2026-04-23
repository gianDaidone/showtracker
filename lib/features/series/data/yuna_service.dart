import 'dart:convert';

import 'package:http/http.dart' as http;

class YunaService {
  static const _base = 'https://relations.yuna.moe/api/v2/themoviedb';

  /// Returns the list of AniList IDs that correspond to [tmdbId].
  /// Returns an empty list if no mapping is found.
  Future<List<int>> getAniListIds(int tmdbId) async {
    http.Response response;
    try {
      response = await http
          .get(Uri.parse('$_base/?id=$tmdbId'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return [];
    }

    if (response.statusCode == 404 || response.statusCode == 204) return [];
    if (response.statusCode != 200) return [];

    try {
      final body = jsonDecode(response.body);
      if (body is! List) return [];
      return body
          .whereType<Map>()
          .map((e) => e['anilist'])
          .whereType<int>()
          .toList();
    } catch (_) {
      return [];
    }
  }
}
