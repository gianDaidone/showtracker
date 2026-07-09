import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants.dart';

import 'dart:async';
import 'package:app_links/app_links.dart';

// State model for Auth
class AuthState {
  final bool isLoading;
  final String? sessionId;
  final String? customApiKey;

  const AuthState({
    this.isLoading = true,
    this.sessionId,
    this.customApiKey,
  });

  bool get isAuthenticated => sessionId != null || customApiKey != null;

  AuthState copyWith({
    bool? isLoading,
    String? sessionId,
    String? customApiKey,
    bool clearSessionId = false,
    bool clearCustomApiKey = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      sessionId: clearSessionId ? null : (sessionId ?? this.sessionId),
      customApiKey: clearCustomApiKey ? null : (customApiKey ?? this.customApiKey),
    );
  }
}

// Secure Storage Provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  
  static const _sessionIdKey = 'tmdb_session_id';
  static const _customApiKeyKey = 'tmdb_custom_api_key';

  AuthNotifier(this._storage) : super(const AuthState()) {
    _init();
    _initAppLinks();
  }

  void _initAppLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      handleAuthRedirect(uri);
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final sessionId = await _storage.read(key: _sessionIdKey);
    final customApiKey = await _storage.read(key: _customApiKeyKey);
    
    state = state.copyWith(
      isLoading: false,
      sessionId: sessionId,
      customApiKey: customApiKey,
    );
  }

  Future<void> saveCustomApiKey(String key) async {
    await _storage.write(key: _customApiKeyKey, value: key);
    state = state.copyWith(customApiKey: key, clearSessionId: true);
    await _storage.delete(key: _sessionIdKey); // Clear session if setting custom key
  }

  Future<void> saveSessionId(String sessionId) async {
    await _storage.write(key: _sessionIdKey, value: sessionId);
    state = state.copyWith(sessionId: sessionId, clearCustomApiKey: true);
    await _storage.delete(key: _customApiKeyKey); // Clear custom key if setting session
  }

  Future<void> logout() async {
    await _storage.delete(key: _sessionIdKey);
    await _storage.delete(key: _customApiKeyKey);
    state = state.copyWith(clearSessionId: true, clearCustomApiKey: true);
  }

  // --- TMDB Auth Flow Methods ---

  Future<String> _createRequestToken() async {
    final url = Uri.parse('https://api.themoviedb.org/3/authentication/token/new?api_key=$kTmdbApiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['request_token'];
    } else {
      throw Exception('Failed to create request token');
    }
  }

  Future<void> startLoginFlow() async {
    try {
      final requestToken = await _createRequestToken();
      final authUrl = Uri.parse('https://www.themoviedb.org/authenticate/$requestToken?redirect_to=showtracker://auth');
      
      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch browser');
      }
    } catch (e) {
      print('Error starting login flow: $e');
      rethrow;
    }
  }

  Future<void> handleAuthRedirect(Uri uri) async {
    if (uri.scheme == 'showtracker' && uri.host == 'auth') {
      final requestToken = uri.queryParameters['request_token'];
      final approved = uri.queryParameters['approved'];

      if (approved == 'true' && requestToken != null) {
        // Exchange for session id
        final sessionUrl = Uri.parse('https://api.themoviedb.org/3/authentication/session/new?api_key=$kTmdbApiKey');
        final response = await http.post(
          sessionUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'request_token': requestToken}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final sessionId = data['session_id'];
          await saveSessionId(sessionId);
        } else {
          print('Failed to create session: ${response.body}');
        }
      }
    }
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storage);
});
