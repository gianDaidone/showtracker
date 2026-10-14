/// Trailer di un gioco, da Steam o da RAWG.
class GameTrailer {
  final String name;
  final String? previewUrl;
  final String videoUrl;

  /// `true` per gli stream HLS (`.m3u8`) di Steam: l'URL ha una query string,
  /// quindi il player non riesce a dedurre il formato dall'estensione.
  final bool isHls;

  const GameTrailer({
    required this.name,
    required this.videoUrl,
    this.previewUrl,
    this.isHls = false,
  });

  /// Elemento di `movies` in Steam `appdetails`. I trailer recenti hanno solo
  /// gli stream (`hls_h264`, `dash_*`); quelli caricati prima del 2025 anche
  /// gli mp4 in `mp4`. `null` se non c'è niente di riproducibile.
  static GameTrailer? tryParseSteam(Map<String, dynamic> json) {
    final hls = _nonEmpty(json['hls_h264']);
    final mp4 = json['mp4'] as Map<String, dynamic>? ?? const {};
    final mp4Url = _nonEmpty(mp4['max']) ?? _nonEmpty(mp4['480']);
    final url = hls ?? mp4Url;
    if (url == null) return null;

    return GameTrailer(
      name: _nonEmpty(json['name']) ?? 'Trailer',
      videoUrl: url,
      previewUrl: _nonEmpty(json['thumbnail']),
      isHls: hls != null,
    );
  }

  /// Elemento di RAWG `/games/{id}/movies`: `data` contiene gli mp4 diretti
  /// (presi da Steam) in due qualità, `"480"` e `"max"`.
  static GameTrailer? tryParseRawg(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    final url = _nonEmpty(data['max']) ?? _nonEmpty(data['480']);
    if (url == null) return null;

    return GameTrailer(
      name: _nonEmpty(json['name']) ?? 'Trailer',
      videoUrl: url,
      previewUrl: _nonEmpty(json['preview']),
    );
  }

  static String? _nonEmpty(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
