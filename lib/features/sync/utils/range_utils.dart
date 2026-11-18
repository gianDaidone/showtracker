import 'sync_limits.dart';

class RangeUtils {
  /// Converts a list of integers (e.g., [1, 2, 3, 5]) into a range string ("1-3,5").
  static String compactListToRange(List<int> numbers) {
    if (numbers.isEmpty) return '';

    final sorted = List<int>.from(numbers)..sort();
    final ranges = <String>[];

    int start = sorted.first;
    int prev = start;

    for (int i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      if (current == prev + 1) {
        prev = current;
      } else {
        if (start == prev) {
          ranges.add(start.toString());
        } else {
          ranges.add('$start-$prev');
        }
        start = current;
        prev = current;
      }
    }

    // Add the last range
    if (start == prev) {
      ranges.add(start.toString());
    } else {
      ranges.add('$start-$prev');
    }

    return ranges.join(',');
  }

  /// Expands a range string ("1-3,5") back to a list of integers ([1, 2, 3, 5]).
  static List<int> expandRangeToList(String rangeStr) {
    if (rangeStr.trim().isEmpty) return [];
    if (rangeStr.length > 128000) {
      throw const FormatException('Range troppo lungo.');
    }

    final result = <int>[];
    final parts = rangeStr.split(',');

    for (final part in parts) {
      if (!RegExp(r'^\d+(?:-\d+)?$').hasMatch(part)) {
        throw const FormatException('Range episodi non valido.');
      }
      final bounds = part.split('-');
      final start = int.tryParse(bounds.first);
      final end = int.tryParse(bounds.last);
      if (start == null ||
          end == null ||
          start < 1 ||
          end < start ||
          end > SyncLimits.maxCoordinate ||
          end - start + 1 > SyncLimits.episodesPerRange - result.length) {
        throw const FormatException(
            'Range episodi non valido o troppo grande.');
      }
      for (var value = start; value <= end; value++) {
        result.add(value);
      }
    }

    return result;
  }
}
