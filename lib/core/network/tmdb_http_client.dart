import 'package:http/http.dart' as http;
import '../auth/auth_state.dart';
import '../constants.dart';

class TmdbInterceptor extends http.BaseClient {
  final http.Client _inner;
  final AuthState _authState;

  TmdbInterceptor(this._inner, this._authState);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.host == 'api.themoviedb.org') {
      final queryParams = Map<String, String>.from(request.url.queryParameters);
      
      switch (_authState) {
        case AuthenticatedWithManualKey(:final apiKey):
          queryParams['api_key'] = apiKey;
          break;
        case AuthenticatedWithSession(:final sessionId):
          queryParams['api_key'] = kTmdbApiKey; 
          queryParams['session_id'] = sessionId;
          break;
        case Unauthenticated():
          queryParams['api_key'] = kTmdbApiKey; 
          break;
      }

      final newUrl = request.url.replace(queryParameters: queryParams);
      
      if (request is http.Request) {
        final newRequest = http.Request(request.method, newUrl)
          ..headers.addAll(request.headers)
          ..bodyBytes = request.bodyBytes
          ..encoding = request.encoding;
        return _inner.send(newRequest);
      }
    }
    
    return _inner.send(request);
  }
}
