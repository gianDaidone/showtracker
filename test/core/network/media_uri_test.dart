import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/network/media_uri.dart';

void main() {
  test('HTTPS generico invariato, upgrade limitato ai CDN legacy noti', () {
    const https = 'https://example.com/image?a=1%20two&b=3';
    expect(secureMediaUrl(https), https);
    expect(secureMediaUrl('http://cdn.akamai.steamstatic.com/video.mp4'),
        'https://cdn.akamai.steamstatic.com/video.mp4');
    for (final url in [
      'http://example.com/image',
      'file:///tmp/image',
      'https://user:secret@example.com/image',
      'http://steamstatic.com.attacker.example/video',
      'https://example.com:8080/image'
    ]) {
      expect(secureMediaUrl(url), isNull);
    }
  });
}
