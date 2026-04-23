import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thin wrapper around [http.Client] with JSON helpers and error handling.
/// Feature-specific API clients (TmdbClient, RawgClient, etc.) extend this.
class AppHttpClient {
  final http.Client _client;

  AppHttpClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final response = await _client.get(uri, headers: headers);
    _assertSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _assertSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        statusCode: response.statusCode,
        message: response.reasonPhrase ?? 'Unknown error',
      );
    }
  }

  void dispose() => _client.close();
}

class HttpException implements Exception {
  final int statusCode;
  final String message;
  const HttpException({required this.statusCode, required this.message});

  @override
  String toString() => 'HttpException($statusCode): $message';
}
