import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/features/sync/utils/sync_encryption.dart';
import 'package:showtracker/features/sync/utils/sync_compressor.dart';

void main() {
  test(
      'AES-GCM roundtrip: ciphertext non espone ID/stati, chiave e nonce nuovi per ogni snapshot',
      () async {
    final payload = SyncCompressor.compressPayload({
      's': {
        '123': {'st': 'watching', 'u': 123}
      }
    });
    final first = await SyncEncryption.encrypt(payload, 'token-one');
    final second = await SyncEncryption.encrypt(payload, 'token-one');
    expect(first.key, isNot(second.key));
    expect(first.body, isNot(second.body));
    final firstNonce =
        base64Decode(first.body.substring(SyncEncryption.prefix.length))
            .take(12)
            .toList();
    final secondNonce =
        base64Decode(second.body.substring(SyncEncryption.prefix.length))
            .take(12)
            .toList();
    expect(firstNonce, hasLength(12));
    expect(firstNonce, isNot(orderedEquals(secondNonce)));
    expect(first.body, isNot(contains(payload)));
    expect(await SyncEncryption.decrypt(first.body, first.key, 'token-one'),
        payload);
    expect(first.key.length, 43);
  });
  test(
      'chiave/token/ciphertext/tag/nonce alterati o vecchio protocollo rifiutati',
      () async {
    final encrypted = await SyncEncryption.encrypt(
        SyncCompressor.compressPayload({}), 'session');
    final other = await SyncEncryption.encrypt(
        SyncCompressor.compressPayload({}), 'session');
    await expectLater(
        SyncEncryption.decrypt(encrypted.body, other.key, 'session'),
        throwsFormatException);
    await expectLater(
        SyncEncryption.decrypt(encrypted.body, encrypted.key, 'other-session'),
        throwsFormatException);
    await expectLater(SyncEncryption.decrypt('eJw=', encrypted.key, 'session'),
        throwsFormatException);
    final bytes =
        base64Decode(encrypted.body.substring(SyncEncryption.prefix.length));
    for (final index in [0, 12, bytes.length - 1]) {
      final altered = [...bytes]..[index] ^= 1;
      await expectLater(
          SyncEncryption.decrypt(SyncEncryption.prefix + base64Encode(altered),
              encrypted.key, 'session'),
          throwsFormatException);
    }
  });
}
