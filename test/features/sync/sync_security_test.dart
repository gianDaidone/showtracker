import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart';
import 'package:showtracker/features/sync/services/sync_receiver.dart';
import 'package:showtracker/features/sync/services/local_sync_server.dart';
import 'package:showtracker/features/sync/domain/models/sync_payload.dart';
import 'package:showtracker/features/sync/utils/sync_compressor.dart';
import 'package:showtracker/features/sync/utils/sync_limits.dart';
import 'package:showtracker/features/sync/utils/sync_encryption.dart';

const _token = 'abcdefghijklmnopqrstuv';
const _baseUrl = 'http://192.168.1.23:8080/sync?token=$_token';
final _url = '$_baseUrl#k=${'A' * 43}';

void main() {
  test('QR accetta solo IPv4 RFC1918, endpoint, porta e token attesi', () {
    for (final host in [
      '192.168.1.23',
      '10.0.2.2',
      '172.16.0.2',
      '172.31.255.2'
    ]) {
      expect(
          validateSyncUri(_url.replaceFirst('192.168.1.23', host)).host, host);
    }
    for (final url in [
      'https://192.168.1.23:8080/sync?token=$_token',
      ...[
        'example.com',
        'localhost',
        '127.0.0.1',
        '169.254.169.254',
        '8.8.8.8',
        '[::1]',
        '172.32.1.1',
        '192.168.1.23.example.com'
      ].map((host) => 'http://$host:8080/sync?token=$_token'),
      _url.replaceFirst(':8080', ':80'),
      _url.replaceFirst('/sync', '/admin'),
      _url.replaceFirst('192.', 'user:pass@192.'),
      '$_url#fragment',
      '$_baseUrl&token=$_token#k=${'A' * 43}',
      '$_baseUrl&other=1#k=${'A' * 43}',
      _url.replaceFirst(_token, 'short'),
    ]) {
      expect(() => validateSyncUri(url), throwsFormatException, reason: url);
    }
  });

  test('URL invalido non crea neppure un client; payload legacy non usa rete',
      () async {
    var calls = 0;
    final receiver = SyncReceiver(createClient: () {
      calls++;
      return MockClient((_) async => http.Response('', 200));
    });
    await expectLater(
        receiver.read('http://example.com/file'), throwsFormatException);
    expect(await receiver.read('eJw='), 'eJw=');
    expect(calls, 0);
  });

  test('redirect rifiutato senza seguire Location, richiesta senza credenziali',
      () async {
    var calls = 0;
    final receiver = SyncReceiver(
        createClient: () => MockClient((request) async {
              calls++;
              expect(request.followRedirects, isFalse);
              expect(request.maxRedirects, 0);
              expect(request.headers['authorization'], isNull);
              return http.Response('', 302,
                  headers: {'location': 'http://example.com/steal'});
            }));
    await expectLater(receiver.read(_url), throwsFormatException);
    expect(calls, 1);
  });

  test('download rifiuta Content-Length e stream sovradimensionati', () async {
    for (final declared in [true, false]) {
      final receiver = SyncReceiver(
          createClient: () =>
              MockClient.streaming((request, _) async => http.StreamedResponse(
                    Stream.fromIterable([
                      List.filled(SyncEncryption.wireBytes, 65),
                      [65]
                    ]),
                    200,
                    contentLength:
                        declared ? SyncEncryption.wireBytes + 1 : null,
                  )));
      await expectLater(receiver.read(_url), throwsFormatException);
    }
  });

  test('compression bomb e input oltre budget rifiutati', () {
    final bomb = base64Encode(
        zlib.encode(List.filled(SyncLimits.inflatedBytes + 1, 65)));
    expect(() => SyncCompressor.decompressPayload(bomb), throwsFormatException);
    expect(
        () => SyncCompressor.decompressPayload(
            'A' * (SyncLimits.encodedBytes + 1)),
        throwsFormatException);
    for (final range in [
      '1-9999999999',
      '0',
      '-1',
      '5-3',
      '1-20001',
      '999999999999999999999'
    ]) {
      expect(() => RangeUtils.expandRangeToList(range), throwsFormatException);
    }
  });

  test('tipi, identificatori, coordinate e timestamp ostili rifiutati', () {
    for (final bad in <Map<String, dynamic>>[
      {'v': 99},
      {'s': null},
      {
        's': {
          '0': {'st': 'watching', 'u': 1}
        }
      },
      {
        's': {
          '01': {'st': 'watching', 'u': 1}
        }
      },
      {
        'g': {
          '1': {'st': 'watching', 'u': -1}
        }
      },
      {
        'g': {
          '1': {'st': 'watching', 'u': 99999999999}
        }
      },
      {
        'm': {
          '1': {'st': [], 'u': 1}
        }
      },
      {
        's': {
          '1': {
            'st': 'watching',
            'u': 1,
            'e': {'-1': '1'}
          }
        }
      },
      {
        's': {
          '1': {
            'st': 'watching',
            'u': 1,
            'e': {'1': '1-999999999'}
          }
        }
      },
      {
        'g': {
          for (var i = 1; i <= SyncLimits.records + 1; i++)
            '$i': {'st': 'watching', 'u': 1}
        }
      },
    ]) {
      expect(() => SyncPayload.fromJson(bad), throwsFormatException);
    }
  });

  test('token duplicati, browser e sessioni scadute non accedono allo snapshot',
      () async {
    final now = DateTime.utc(2026, 1, 1);
    var clock = now;
    final handler = createSyncHandler(
        token: _token,
        base64Payload: 'secret',
        expiresAt: now.add(const Duration(minutes: 5)),
        clock: () => clock);
    expect(
        (await handler(Request('GET', Uri.parse(_baseUrl)))).statusCode, 200);
    expect(
        (await handler(Request('GET', Uri.parse('$_baseUrl&token=$_token'))))
            .statusCode,
        403);
    expect(
        (await handler(Request('GET', Uri.parse(_baseUrl),
                headers: {'origin': 'http://hostile.example'})))
            .statusCode,
        403);
    clock = now.add(const Duration(minutes: 5));
    expect(
        (await handler(Request('GET', Uri.parse(_baseUrl)))).statusCode, 403);
  });
}
