import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/auth/auth_state.dart';
import 'package:showtracker/core/auth/rawg_auth_state.dart';
import 'package:showtracker/core/riverpod_utils.dart';

class _UnreadableStorage extends MapBase<String, String> {
  int reads = 0;

  @override
  String? operator [](Object? key) {
    reads++;
    throw PlatformException(code: 'storage-unavailable');
  }

  @override
  void operator []=(String key, String value) => throw UnimplementedError();
  @override
  void clear() => throw UnimplementedError();
  @override
  Iterable<String> get keys => const [];
  @override
  String? remove(Object? key) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  late ProviderContainer container;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    container = ProviderContainer(retry: noProviderRetry);
  });
  tearDown(() => container.dispose());

  test('senza credenziali TMDB e RAWG sono disconnessi', () async {
    expect(await container.read(authControllerProvider.future),
        isA<Unauthenticated>());
    expect(await container.read(rawgAuthControllerProvider.future),
        isA<RawgUnauthenticated>());
  });

  test('ripristina sessione TMDB con precedenza sulla chiave manuale',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      'tmdb_session_id': 'session-test',
      'tmdb_manual_key': 'manual-test',
    });
    final state = await container.read(authControllerProvider.future);
    expect((state as AuthenticatedWithSession).sessionId, 'session-test');
  });

  test('sessione vuota usa la chiave manuale', () async {
    FlutterSecureStorage.setMockInitialValues({
      'tmdb_session_id': '',
      'tmdb_manual_key': 'manual-test',
    });
    final state = await container.read(authControllerProvider.future);
    expect((state as AuthenticatedWithManualKey).apiKey, 'manual-test');
  });

  test('login manuale persiste la chiave e rimuove la sessione', () async {
    await container.read(authControllerProvider.future);
    await storage.write(key: 'tmdb_session_id', value: 'old-session');
    await container
        .read(authControllerProvider.notifier)
        .loginWithManualKey('new-key');
    expect(await storage.read(key: 'tmdb_manual_key'), 'new-key');
    expect(await storage.read(key: 'tmdb_session_id'), isNull);
    expect(container.read(authControllerProvider).requireValue,
        isA<AuthenticatedWithManualKey>());
  });

  test('login con sessione rimuove la vecchia chiave', () async {
    await container.read(authControllerProvider.future);
    await storage.write(key: 'tmdb_manual_key', value: 'old-key');
    await container
        .read(authControllerProvider.notifier)
        .loginWithSession('new-session');
    expect(await storage.read(key: 'tmdb_session_id'), 'new-session');
    expect(await storage.read(key: 'tmdb_manual_key'), isNull);
    expect(container.read(authControllerProvider).requireValue,
        isA<AuthenticatedWithSession>());
  });

  test('logout TMDB elimina solo le proprie credenziali', () async {
    FlutterSecureStorage.setMockInitialValues({
      'tmdb_session_id': 'session',
      'tmdb_manual_key': 'key',
      'rawg_api_key': 'rawg-key',
    });
    await container.read(authControllerProvider.future);
    await container.read(authControllerProvider.notifier).logout();
    expect(await storage.read(key: 'tmdb_session_id'), isNull);
    expect(await storage.read(key: 'tmdb_manual_key'), isNull);
    expect(await storage.read(key: 'rawg_api_key'), 'rawg-key');
    expect(container.read(authControllerProvider).requireValue,
        isA<Unauthenticated>());
  });

  test('RAWG ripristina, sostituisce e rimuove la sua chiave', () async {
    FlutterSecureStorage.setMockInitialValues({'rawg_api_key': 'old-rawg'});
    final initial = await container.read(rawgAuthControllerProvider.future);
    expect((initial as RawgAuthenticated).apiKey, 'old-rawg');
    final notifier = container.read(rawgAuthControllerProvider.notifier);
    await notifier.loginWithKey('new-rawg');
    expect(await storage.read(key: 'rawg_api_key'), 'new-rawg');
    await notifier.logout();
    expect(await storage.read(key: 'rawg_api_key'), isNull);
    expect(container.read(rawgAuthControllerProvider).requireValue,
        isA<RawgUnauthenticated>());
  });

  test('errore secure storage degrada a disconnesso', () async {
    final broken = _UnreadableStorage();
    FlutterSecureStorage.setMockInitialValues(broken);
    expect(await container.read(authControllerProvider.future),
        isA<Unauthenticated>());
    expect(await container.read(rawgAuthControllerProvider.future),
        isA<RawgUnauthenticated>());
    expect(broken.reads, 2);
  });
}
