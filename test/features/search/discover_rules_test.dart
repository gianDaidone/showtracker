import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/tables/enums.dart';
import 'package:showtracker/features/search/data/discover_rules.dart';

typedef _Item = ({int id, MediaStatus status, double? rating, int day});

void main() {
  group('mergeRecommendations', () {
    test('prima i titoli consigliati da più semi', () {
      final merged = mergeRecommendations([
        [1, 2, 3],
        [4, 3, 5],
        [3, 6],
      ], (i) => i);
      expect(merged.first, 3);
    });

    test('a parità alterna i semi invece di accodarli', () {
      final merged = mergeRecommendations([
        [1, 2, 3],
        [10, 20],
      ], (i) => i);
      expect(merged, [1, 10, 2, 20, 3]);
    });

    test('senza doppioni e senza semi restituisce una lista vuota', () {
      expect(mergeRecommendations([
        [1, 1, 2],
      ], (i) => i), [1, 2]);
      expect(mergeRecommendations(<List<int>>[], (i) => i), isEmpty);
    });
  });

  group('pickSeeds', () {
    List<int> pick(List<_Item> items, {int max = 5}) => pickSeeds(
          items,
          statusOf: (i) => i.status,
          ratingOf: (i) => i.rating,
          recencyOf: (i) => DateTime(2026, 1, i.day),
          max: max,
        ).map((i) => i.id).toList();

    test('solo in visione o completati, prima i meglio votati', () {
      expect(
        pick([
          (id: 1, status: MediaStatus.planToWatch, rating: 10, day: 1),
          (id: 2, status: MediaStatus.dropped, rating: 9, day: 1),
          (id: 3, status: MediaStatus.completed, rating: 6, day: 1),
          (id: 4, status: MediaStatus.watching, rating: 8, day: 1),
          (id: 5, status: MediaStatus.watching, rating: null, day: 9),
        ]),
        [4, 3, 5],
      );
    });

    test('a parità di voto i più recenti, fino a max', () {
      expect(
        pick([
          (id: 1, status: MediaStatus.watching, rating: null, day: 1),
          (id: 2, status: MediaStatus.watching, rating: null, day: 3),
          (id: 3, status: MediaStatus.completed, rating: null, day: 2),
        ], max: 2),
        [2, 3],
      );
    });
  });

  test('topGenreIds: i più frequenti, un voto per seme', () {
    expect(
      topGenreIds([
        [4, 4, 51],
        [3, 51],
        [51, 4],
      ]),
      [51, 4],
    );
    expect(topGenreIds([]), isEmpty);
  });
}
