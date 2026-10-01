/// Versione semantica `major.minor.patch` usata per confrontare la versione
/// installata con il `tag_name` dell'ultima release GitHub.
///
/// Il prefisso `v`, il numero di build (`+5`) e l'eventuale suffisso di
/// pre-release (`-beta`) vengono ignorati: contano solo i tre numeri.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  /// `"v1.0.1"`, `"1.0.0+5"`, `"1.2"` → versione; `null` se non è numerica.
  static AppVersion? tryParse(String raw) {
    var s = raw.trim();
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
    s = s.split('+').first.split('-').first;
    if (s.isEmpty) return null;

    final parts = s.split('.');
    if (parts.length > 3) return null;
    final numbers = <int>[];
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null || n < 0) return null;
      numbers.add(n);
    }
    while (numbers.length < 3) {
      numbers.add(0);
    }
    return AppVersion(numbers[0], numbers[1], numbers[2]);
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <(AppVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
