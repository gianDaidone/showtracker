import 'dart:convert';
import 'dart:io';

void main() async {
  final apiKey = '***REMOVED***';
  var req = await HttpClient().getUrl(Uri.parse('https://api.themoviedb.org/3/tv/94664/season/0?api_key=$apiKey'));
  var res = await req.close();
  var body = await res.transform(utf8.decoder).join();
  var data = jsonDecode(body);
  
  for (var ep in data['episodes']) {
    print('Specials Ep ${ep['episode_number']}: ${ep['name']}');
  }
}
