import 'package:http/http.dart' as http;
import '../auth/auth_state.dart';
import '../auth/rawg_auth_state.dart';
import '../constants/api_keys.dart';

class AppInterceptor extends http.BaseClient {
  final http.Client _inner;
  final AuthState? _tmdbAuthState;
  final RawgAuthState? _rawgAuthState;

  AppInterceptor(this._inner, {AuthState? tmdbAuthState, RawgAuthState? rawgAuthState})
      : _tmdbAuthState = tmdbAuthState,
        _rawgAuthState = rawgAuthState;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.host == 'api.themoviedb.org' && _tmdbAuthState != null) {
      final queryParams = Map<String, String>.from(request.url.queryParameters);
      
      switch (_tmdbAuthState) {
        case AuthenticatedWithManualKey(:final apiKey):
          queryParams['api_key'] = apiKey;
          break;
        case AuthenticatedWithSession(:final sessionId):
          queryParams['api_key'] = ApiKeys.tmdb; 
          queryParams['session_id'] = sessionId;
          break;
        case Unauthenticated():
          queryParams['api_key'] = ApiKeys.tmdb; 
          break;
        case null:
          break;
      }

      return _sendReplaced(request, queryParams);
    }
    
    if (request.url.host == 'api.rawg.io' && _rawgAuthState != null) {
      final queryParams = Map<String, String>.from(request.url.queryParameters);
      
      switch (_rawgAuthState) {
        case RawgAuthenticated(:final apiKey):
          queryParams['key'] = apiKey;
          break;
        case RawgUnauthenticated():
          queryParams['key'] = ApiKeys.rawg;
          break;
        case null:
          break;
      }

      return _sendReplaced(request, queryParams);
    }
    
    return _inner.send(request);
  }

  Future<http.StreamedResponse> _sendReplaced(http.BaseRequest request, Map<String, String> queryParams) {
    final newUrl = request.url.replace(queryParameters: queryParams);
      
    if (request is http.Request) {
      final newRequest = http.Request(request.method, newUrl)
        ..headers.addAll(request.headers)
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding;
      return _inner.send(newRequest);
    }
    
    return _inner.send(request);
  }
}
