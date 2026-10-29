import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/core/auth/auth_state.dart';
import 'package:showtracker/core/auth/rawg_auth_state.dart';
import 'package:showtracker/core/constants/api_keys.dart';
import 'package:showtracker/core/network/tmdb_http_client.dart';

void main() {
  late List<http.Request> requests;
  late MockClient inner;

  setUp(() {
    requests = [];
    inner = MockClient((request) async {
      requests.add(request);
      return http.Response('ok', 200, headers: {'x-test': 'preserved'});
    });
  });
  tearDown(() => inner.close());

  test('chiavi manuali solo sugli host esatti e query esistente conservata',
      () async {
    final client = AppInterceptor(
      inner,
      tmdbAuthState: const AuthenticatedWithManualKey('tmdb-test-key'),
      rawgAuthState: const RawgAuthenticated('rawg-test-key'),
    );
    await client.get(Uri.parse(
        'https://api.themoviedb.org/3/search/tv?query=caff%C3%A8&page=2&language=it-IT&api_key=old'));
    await client.get(
        Uri.parse('https://api.rawg.io/api/games?search=zelda&page=3&key=old'));
    expect(requests[0].url.queryParameters, {
      'query': 'caffè',
      'page': '2',
      'language': 'it-IT',
      'api_key': 'tmdb-test-key',
    });
    expect(requests[1].url.queryParameters, {
      'search': 'zelda',
      'page': '3',
      'key': 'rawg-test-key',
    });
    expect(requests[0].url.path, '/3/search/tv');
    expect(requests[1].url.path, '/api/games');
  });

  test('sessione TMDB usa chiave app e session_id senza contaminare RAWG',
      () async {
    final client = AppInterceptor(
      inner,
      tmdbAuthState: const AuthenticatedWithSession('session-test'),
      rawgAuthState: const RawgAuthenticated('rawg-test'),
    );
    await client.get(Uri.parse(
        'https://api.themoviedb.org/3/account?session_id=old&page=2'));
    await client.get(Uri.parse('https://api.rawg.io/api/games'));
    expect(requests[0].url.queryParameters,
        {'session_id': 'session-test', 'page': '2', 'api_key': ApiKeys.tmdb});
    expect(requests[1].url.queryParameters, {'key': 'rawg-test'});
  });

  test('stati non autenticati usano fallback; auth null non riscrive la URL',
      () async {
    final fallback = AppInterceptor(
      inner,
      tmdbAuthState: const Unauthenticated(),
      rawgAuthState: const RawgUnauthenticated(),
    );
    await fallback.get(Uri.parse('https://api.themoviedb.org/3/tv/1'));
    await fallback.get(Uri.parse('https://api.rawg.io/api/games'));
    expect(requests[0].url.queryParameters, {'api_key': ApiKeys.tmdb});
    expect(requests[1].url.queryParameters, {'key': ApiKeys.rawg});
    final passthrough = AppInterceptor(inner);
    final url = Uri.parse('https://api.themoviedb.org/3/tv/1?language=it-IT');
    await passthrough.get(url);
    expect(requests[2].url, url);
  });

  test('host estranei o simili non ricevono credenziali', () async {
    final client = AppInterceptor(
      inner,
      tmdbAuthState: const AuthenticatedWithSession('private-session'),
      rawgAuthState: const RawgAuthenticated('private-rawg-key'),
    );
    for (final host in [
      'api.github.com',
      'images.example.com',
      'api.themoviedb.org.example.com',
      'api.rawg.io.example.com'
    ]) {
      final url = Uri.https(host, '/resource', {'page': '1'});
      await client.get(url);
      expect(requests.last.url, url);
      expect(requests.last.headers.containsKey('authorization'), isFalse);
    }
  });

  test('riscrittura mantiene metodo, header, byte body e encoding', () async {
    final client = AppInterceptor(inner,
        tmdbAuthState: const AuthenticatedWithManualKey('test-key'));
    final request = http.Request(
        'POST', Uri.parse('https://api.themoviedb.org/3/rating?language=it-IT'))
      ..headers['x-custom'] = 'test-header'
      ..encoding = latin1
      ..body = 'caffè';
    final bytes = request.bodyBytes;
    final response = await client.send(request);
    expect(requests.single.method, 'POST');
    expect(requests.single.headers['x-custom'], 'test-header');
    expect(requests.single.headers['content-type'],
        request.headers['content-type']);
    expect(requests.single.bodyBytes, bytes);
    expect(requests.single.encoding.name, latin1.name);
    expect(requests.single.url.queryParameters['language'], 'it-IT');
    expect(response.statusCode, 200);
    expect(response.headers['x-test'], 'preserved');
    expect(await response.stream.bytesToString(), 'ok');
  });
}
