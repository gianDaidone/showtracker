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
    
    final result = <int>[];
    final parts = rangeStr.split(',');
    
    for (final part in parts) {
      if (part.contains('-')) {
        final bounds = part.split('-');
        if (bounds.length == 2) {
          final start = int.tryParse(bounds[0]);
          final end = int.tryParse(bounds[1]);
          if (start != null && end != null && start <= end) {
            for (int i = start; i <= end; i++) {
              result.add(i);
            }
          }
        }
      } else {
        final num = int.tryParse(part);
        if (num != null) {
          result.add(num);
        }
      }
    }
    
    return result;
  }
}
