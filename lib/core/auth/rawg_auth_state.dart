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

@riverpod
class RawgAuthController extends _$RawgAuthController {
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
    await _storage.write(key: _rawgKey, value: apiKey);
    state = AsyncValue.data(RawgAuthenticated(apiKey));
  }

  Future<void> logout() async {
    await _storage.delete(key: _rawgKey);
    state = const AsyncValue.data(RawgUnauthenticated());
  }
}
