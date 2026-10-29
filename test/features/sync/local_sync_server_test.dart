import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:showtracker/features/sync/services/local_sync_server.dart';

void main() {
  final handler = createSyncHandler(
      token: 'test-token', base64Payload: 'compressed-test-payload');

  test('GET /sync con token corretto restituisce il payload e gli header',
      () async {
    final response = await handler(
        Request('GET', Uri.parse('http://localhost/sync?token=test-token')));
    expect(response.statusCode, 200);
    expect(await response.readAsString(), 'compressed-test-payload');
    expect(response.headers['content-type'], startsWith('text/plain'));
    expect(response.headers['access-control-allow-origin'], '*');
  });

  test('token mancante o errato non espone il payload', () async {
    for (final query in ['', '?token=wrong', '?token=']) {
      final response = await handler(
          Request('GET', Uri.parse('http://localhost/sync$query')));
      expect(response.statusCode, 403);
      expect(await response.readAsString(), 'Invalid token');
    }
  });

  test('route diversa non restituisce il payload anche con token valido',
      () async {
    final response = await handler(
        Request('GET', Uri.parse('http://localhost/other?token=test-token')));
    expect(response.statusCode, 404);
    expect(await response.readAsString(),
        isNot(contains('compressed-test-payload')));
  });

  test('handler separati non condividono credenziali o payload', () async {
    final other =
        createSyncHandler(token: 'other-token', base64Payload: 'other-payload');
    final denied = await other(
        Request('GET', Uri.parse('http://localhost/sync?token=test-token')));
    expect(denied.statusCode, 403);
    final response = await handler(
        Request('GET', Uri.parse('http://localhost/sync?token=test-token')));
    expect(await response.readAsString(), 'compressed-test-payload');
  });
}
