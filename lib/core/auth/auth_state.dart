import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state.g.dart';

const _storage = FlutterSecureStorage();
const _sessionKey = 'tmdb_session_id';
const _manualKey = 'tmdb_manual_key';

sealed class AuthState {
  const AuthState();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthenticatedWithSession extends AuthState {
  final String sessionId;
  const AuthenticatedWithSession(this.sessionId);
}

class AuthenticatedWithManualKey extends AuthState {
  final String apiKey;
  const AuthenticatedWithManualKey(this.apiKey);
}

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<AuthState> build() async {
    return _loadInitialState();
  }

  Future<AuthState> _loadInitialState() async {
    try {
      final sessionId = await _storage.read(key: _sessionKey);
      if (sessionId != null && sessionId.isNotEmpty) {
        return AuthenticatedWithSession(sessionId);
      }

      final manualKey = await _storage.read(key: _manualKey);
      if (manualKey != null && manualKey.isNotEmpty) {
        return AuthenticatedWithManualKey(manualKey);
      }
    } catch (e) {
      // Fallback in case of storage error
    }

    return const Unauthenticated();
  }

  Future<void> loginWithSession(String sessionId) async {
    await _storage.write(key: _sessionKey, value: sessionId);
    await _storage.delete(key: _manualKey);
    state = AsyncValue.data(AuthenticatedWithSession(sessionId));
  }

  Future<void> loginWithManualKey(String apiKey) async {
    await _storage.write(key: _manualKey, value: apiKey);
    await _storage.delete(key: _sessionKey);
    state = AsyncValue.data(AuthenticatedWithManualKey(apiKey));
  }

  Future<void> logout() async {
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _manualKey);
    state = const AsyncValue.data(Unauthenticated());
  }
}
