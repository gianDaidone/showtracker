import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rawg_auth_state.g.dart';

const _storage = FlutterSecureStorage();
const _rawgKey = 'rawg_api_key';

sealed class RawgAuthState {
  const RawgAuthState();
}

class RawgUnauthenticated extends RawgAuthState {
  const RawgUnauthenticated();
}

class RawgAuthenticated extends RawgAuthState {
  final String apiKey;
  const RawgAuthenticated(this.apiKey);
}

// keepAlive: stato globale dell'app. Con Riverpod 3 un notifier autoDispose
// eliminato durante un await fa fallire il resto del metodo (ref/state dopo
// il dispose lanciano UnmountedRefException).
@Riverpod(keepAlive: true)
class RawgAuthController extends _$RawgAuthController {
  Future<void> _pendingWrite = Future.value();
  int _credentialGeneration = 0;

  Future<void> _mutate(Future<void> Function() write, RawgAuthState next) {
    final generation = ++_credentialGeneration;
    state = const AsyncLoading();
    final task = _pendingWrite.then((_) async {
      try {
        await write();
        if (ref.mounted && generation == _credentialGeneration) {
          state = AsyncData(next);
        }
      } catch (_) {
        if (ref.mounted && generation == _credentialGeneration) {
          state = const AsyncData(RawgUnauthenticated());
        }
        rethrow;
      }
    });
    _pendingWrite = task.catchError((Object _) {});
    return task;
  }

  @override
  Future<RawgAuthState> build() async {
    return _loadInitialState();
  }

  Future<RawgAuthState> _loadInitialState() async {
    try {
      final key = await _storage.read(key: _rawgKey);
      if (key != null && key.isNotEmpty) {
        return RawgAuthenticated(key);
      }
    } catch (_) {}
    return const RawgUnauthenticated();
  }

  Future<void> loginWithKey(String apiKey) async {
    if (apiKey.trim().isEmpty) throw const FormatException('Chiave vuota.');
    await _mutate(() async {
      await _storage.write(key: _rawgKey, value: apiKey);
    }, RawgAuthenticated(apiKey));
  }

  Future<void> logout() async {
    await _mutate(() async {
      await _storage.delete(key: _rawgKey);
    }, const RawgUnauthenticated());
  }
}
