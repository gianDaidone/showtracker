import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/features/sync/utils/sync_compressor.dart';
import 'package:showtracker/features/sync/utils/sync_encryption.dart';
import 'package:showtracker/features/sync/services/sync_receiver.dart';

const _token = 'abcdefghijklmnopqrstuv';
const _base = 'http://192.168.1.2:8080/sync?token=$_token';

void main() {
  test(
      'il QR porta la chiave, la richiesta HTTP soltanto il token; autentica prima di restituire il payload',
      () async {
    final original = SyncCompressor.compressPayload({
      'm': {
        '7': {'st': 'completed', 'u': 100}
      }
    });
    final snapshot = await SyncEncryption.encrypt(original, _token);
    final receiver = SyncReceiver(
        createClient: () => MockClient((request) async {
              expect(request.url.fragment, isEmpty);
              expect(request.url.toString(), _base);
              expect(request.url.toString(), isNot(contains(snapshot.key)));
              return http.Response(snapshot.body, 200);
            }));
    expect(await receiver.read('$_base#k=${snapshot.key}'), original);
  });
  test(
      'nessun downgrade a LAN in chiaro, nessuna rete per URL legacy e chiave corrotta',
      () async {
    var requests = 0;
    final receiver = SyncReceiver(
        createClient: () => MockClient((_) async {
              requests++;
              return http.Response('', 200);
            }));
    await expectLater(receiver.read(_base), throwsFormatException);
    await expectLater(receiver.read('$_base#k=invalid'), throwsFormatException);
    expect(requests, 0);
    final key = await SyncEncryption.encrypt(
        SyncCompressor.compressPayload({}), _token);
    final plaintextServer = SyncReceiver(
        createClient: () => MockClient((_) async =>
            http.Response(SyncCompressor.compressPayload({}), 200)));
    await expectLater(
        plaintextServer.read('$_base#k=${key.key}'), throwsFormatException);
    expect(await receiver.read('eJw='), 'eJw=');
  });
}
