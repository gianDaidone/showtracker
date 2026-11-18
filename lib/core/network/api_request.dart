import 'dart:async';
import 'package:http/http.dart' as http;

/// Confine API: HTTPS, niente redirect, budget risposta e cancellazione su
/// timeout. Nessun retry: AniList mantiene la propria coda e policy 429.
Future<http.Response> apiRequest(
  http.Client client,
  String method,
  Uri uri, {
  Map<String, String>? headers,
  String? body,
  Duration timeout = const Duration(seconds: 20),
  int maxBytes = 4 * 1024 * 1024,
}) async {
  if (uri.scheme != 'https' || uri.userInfo.isNotEmpty || uri.port != 443) {
    throw const FormatException('Destinazione API non sicura.');
  }
  final abort = Completer<void>();
  final request = http.AbortableRequest(method, uri, abortTrigger: abort.future)
    ..followRedirects = false
    ..maxRedirects = 0;
  if (headers != null) request.headers.addAll(headers);
  if (body != null) request.body = body;
  Future<http.Response> read() async {
    final response = await client.send(request);
    if ((response.contentLength ?? 0) > maxBytes) {
      throw const FormatException('Risposta API troppo grande.');
    }
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > maxBytes) {
        throw const FormatException('Risposta API troppo grande.');
      }
      bytes.addAll(chunk);
    }
    return http.Response.bytes(bytes, response.statusCode,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
        request: response.request);
  }

  try {
    return await read().timeout(timeout,
        onTimeout: () => throw TimeoutException('Richiesta API scaduta.'));
  } on http.ClientException {
    // Il client può includere nella URI anche api_key/session_id.
    throw http.ClientException('Connessione API non riuscita.');
  } finally {
    if (!abort.isCompleted) abort.complete();
  }
}
