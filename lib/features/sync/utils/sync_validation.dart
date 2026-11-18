import 'range_utils.dart';
import 'sync_limits.dart';

/// Valida l'intero documento prima di qualsiasi scrittura. Il wire legacy
/// valido e il fallback per nomi di stato legacy rimangono supportati.
void validateSyncJson(Map<String, dynamic> json, {DateTime? now}) {
  void invalid() => throw const FormatException(
      'Dati di trasferimento non validi o troppo grandi.');
  if (json.keys.any((key) => !{'v', 's', 'g', 'm'}.contains(key))) invalid();
  final version = json.containsKey('v') ? json['v'] : 1;
  if (version is! int || (version != 1 && version != 2)) invalid();
  var records = 0;
  var episodes = 0;
  final latest = (now ?? DateTime.now())
          .add(const Duration(days: 1))
          .millisecondsSinceEpoch ~/
      1000;
  for (final domain in ['s', 'g', 'm']) {
    final data = json[domain];
    if (data == null && !json.containsKey(domain)) continue;
    if (data is! Map<String, dynamic>) invalid();
    final entries = data as Map<String, dynamic>;
    records += entries.length;
    if (records > SyncLimits.records) invalid();
    for (final entry in entries.entries) {
      final id = int.tryParse(entry.key);
      if (id == null ||
          id <= 0 ||
          id > 2147483647 ||
          id.toString() != entry.key) {
        invalid();
      }
      final value = entry.value;
      if (value is! Map<String, dynamic>) invalid();
      final row = value as Map<String, dynamic>;
      if (row.keys.any((key) => !{
            'st',
            'u',
            if (domain == 's') 'e',
            if (domain == 's' && version == 2) ...['c', 'a']
          }.contains(key))) {
        invalid();
      }
      if (domain == 's' && version == 2) {
        if (row['c'] != 'tmdb' && row['c'] != 'cour') invalid();
        final ids = row['a'];
        if (ids != null) {
          if (row['c'] != 'cour' || ids is! Map<String, dynamic>) invalid();
          final entries = (ids as Map<String, dynamic>).entries;
          if (entries.length > SyncLimits.seasonsPerShow) invalid();
          for (final e in entries) {
            final n = int.tryParse(e.key);
            if (n == null ||
                n <= 0 ||
                n > SyncLimits.maxCoordinate ||
                n.toString() != e.key ||
                e.value is! int ||
                (e.value as int) <= 0 ||
                (e.value as int) > 2147483647) {
              invalid();
            }
          }
        }
      }
      final status = row['st'];
      final timestamp = row['u'];
      if (status is! String ||
          status.isEmpty ||
          status.length > 32 ||
          timestamp is! int ||
          timestamp < 0 ||
          timestamp > latest) {
        invalid();
      }
      if (!row.containsKey('e')) continue;
      final seasons = row['e'];
      if (seasons is! Map<String, dynamic>) invalid();
      final seasonEntries = seasons as Map<String, dynamic>;
      if (seasonEntries.length > SyncLimits.seasonsPerShow) invalid();
      for (final season in seasonEntries.entries) {
        final coordinate = int.tryParse(season.key);
        if (coordinate == null ||
            coordinate < 0 ||
            coordinate > SyncLimits.maxCoordinate ||
            coordinate.toString() != season.key ||
            season.value is! String) {
          invalid();
        }
        episodes += RangeUtils.expandRangeToList(season.value as String).length;
        if (episodes > SyncLimits.episodesTotal) invalid();
      }
    }
  }
}
