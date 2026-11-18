/// Keep HTTPS URLs byte-for-byte stable. Upgrade only documented legacy CDN
/// origins; arbitrary HTTP URLs are not fetched as application media.
String? secureMediaUrl(String? value) {
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty || uri.userInfo.isNotEmpty) return null;
  if (uri.scheme == 'https' && uri.port == 443) return value;
  const legacy = {
    'image.tmdb.org',
    'media.rawg.io',
    'steamstatic.com',
    'steamcdn-a.akamaihd.net',
    'steamuserimages-a.akamaihd.net'
  };
  if (uri.scheme == 'http' &&
      !uri.hasPort &&
      legacy.any((host) => uri.host == host || uri.host.endsWith('.$host'))) {
    return uri.replace(scheme: 'https').toString();
  }
  return null;
}
