import 'dart:io';

void main() async {
  HttpClient client = HttpClient()
    ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
  
  HttpClientRequest request = await client.postUrl(Uri.parse('https://yuna.robbb.in/graphql'));
  request.headers.set('Content-Type', 'application/json');
  request.write('{"query": "query { mappings(tmdbId: 94664) { anilistId malId tmdbSeason } }"}');
  
  HttpClientResponse response = await request.close();
  String reply = await response.transform(SystemEncoding().decoder).join();
  print(reply);
}
