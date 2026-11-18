import 'dart:async';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/core/network/api_request.dart';
import 'package:showtracker/core/network/tmdb_http_client.dart';
import 'package:showtracker/core/auth/auth_state.dart';

class _ClosableClient extends MockClient {
  _ClosableClient() : super((_) async => http.Response('{}', 200));
  bool closed = false;
  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  test('chiusura interceptor termina il client e rifiuta richieste obsolete',
      () async {
    final inner = _ClosableClient();
    final client = AppInterceptor(inner,
        tmdbAuthState: const AuthenticatedWithManualKey('fixture'));
    client.close();
    expect(inner.closed, isTrue);
    await expectLater(client.get(Uri.https('api.themoviedb.org', '/3/tv/1')),
        throwsA(isA<http.ClientException>()));
  });
  test('credenziali mai iniettate in HTTP o porte alternative', () async {
    var calls = 0;
    final client = AppInterceptor(MockClient((_) async {
      calls++;
      return http.Response('{}', 200);
    }), tmdbAuthState: const AuthenticatedWithManualKey('fixture'));
    addTearDown(client.close);
    for (final uri in [
      Uri.parse('http://api.themoviedb.org/3/tv/1'),
      Uri.parse('https://api.themoviedb.org:8443/3/tv/1')
    ]) {
      await expectLater(client.get(uri), throwsFormatException);
    }
    expect(calls, 0);
  });
  test(
      'redirect disabilitati anche dopo iniezione e budget streaming rispettato',
      () async {
    final client = AppInterceptor(MockClient.streaming((request, _) async {
      expect(request.followRedirects, isFalse);
      expect(request, isA<http.AbortableRequest>());
      return http.StreamedResponse(
          Stream.fromIterable([
            [1, 2],
            [3, 4]
          ]),
          200);
    }), tmdbAuthState: const AuthenticatedWithManualKey('fixture'));
    addTearDown(client.close);
    await expectLater(
        apiRequest(client, 'GET', Uri.https('api.themoviedb.org', '/3/tv/1'),
            maxBytes: 3),
        throwsFormatException);
  });
  test('timeout completa abortTrigger senza retry', () {
    fakeAsync((clock) {
      var aborted = false;
      Object? error;
      final client = MockClient.streaming((request, _) {
        (request as http.AbortableRequest)
            .abortTrigger!
            .then((_) => aborted = true);
        return Completer<http.StreamedResponse>().future;
      });
      apiRequest(client, 'GET', Uri.https('api.themoviedb.org', '/3/tv/1'))
          .then<void>((_) {}, onError: (Object e) {
        error = e;
      });
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 20));
      clock.flushMicrotasks();
      expect(error, isA<TimeoutException>());
      expect(aborted, isTrue);
      client.close();
    });
  });
}
