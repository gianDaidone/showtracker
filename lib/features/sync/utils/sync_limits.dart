/// Budget condivisi per import, export, rete e decompressione.
abstract final class SyncLimits {
  static const encodedBytes = 2 * 1024 * 1024;
  static const inflatedBytes = 8 * 1024 * 1024;
  static const records = 10000;
  static const seasonsPerShow = 1000;
  static const episodesPerRange = 20000;
  static const episodesTotal = 100000;
  static const maxCoordinate = 1000000;
  static const sessionDuration = Duration(minutes: 5);
}
