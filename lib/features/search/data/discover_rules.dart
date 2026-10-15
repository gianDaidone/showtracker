import 'dart:math' as math;

import '../../../core/database/tables/enums.dart';

/// Le liste "da scoprire" mostrate in Cerca quando la barra è vuota.
enum DiscoverList {
  forYou('Per te'),
  trending('Di tendenza'),
  topRated('Più votati');

  const DiscoverList(this.label);
  final String label;
}

/// I titoli tracciati da cui partono i consigli "Per te": quelli che l'utente
/// sta seguendo o ha finito (non i "da vedere", che non ha ancora visto, né
/// gli abbandonati), prima i meglio votati e a parità i più recenti.
List<T> pickSeeds<T>(
  Iterable<T> tracked, {
  required MediaStatus Function(T item) statusOf,
  required double? Function(T item) ratingOf,
  required DateTime Function(T item) recencyOf,
  int max = 5,
}) {
  final candidates = tracked.where((t) {
    final status = statusOf(t);
    return status == MediaStatus.watching || status == MediaStatus.completed;
  }).toList()
    ..sort((a, b) {
      final byRating = (ratingOf(b) ?? -1).compareTo(ratingOf(a) ?? -1);
      if (byRating != 0) return byRating;
      return recencyOf(b).compareTo(recencyOf(a));
    });
  return candidates.take(max).toList();
}

/// Unisce i consigli di più titoli seme: prima quelli consigliati da più semi,
/// a parità nell'ordine in cui compaiono prendendone uno per seme a turno,
/// così un seme con molti consigli non riempie da solo la testa della lista.
List<T> mergeRecommendations<T>(
  List<List<T>> perSeed,
  Object Function(T item) idOf,
) {
  final byId = <Object, T>{};
  final count = <Object, int>{};
  final position = <Object, int>{};
  final longest = perSeed.fold(0, (m, l) => math.max(m, l.length));
  for (var i = 0; i < longest; i++) {
    for (final list in perSeed) {
      if (i >= list.length) continue;
      final id = idOf(list[i]);
      count[id] = (count[id] ?? 0) + 1;
      if (!byId.containsKey(id)) {
        byId[id] = list[i];
        position[id] = position.length;
      }
    }
  }
  final ids = byId.keys.toList()
    ..sort((a, b) {
      final byCount = count[b]!.compareTo(count[a]!);
      return byCount != 0 ? byCount : position[a]!.compareTo(position[b]!);
    });
  return [for (final id in ids) byId[id] as T];
}

/// I [max] generi più frequenti tra i semi (ognuno conta una volta per
/// seme), a parità nell'ordine in cui compaiono.
List<int> topGenreIds(List<List<int>> perSeed, {int max = 2}) {
  final count = <int, int>{};
  for (final genres in perSeed) {
    for (final g in genres.toSet()) {
      count[g] = (count[g] ?? 0) + 1;
    }
  }
  final order = count.keys.toList();
  final ids = [...order]..sort((a, b) {
      final byCount = count[b]!.compareTo(count[a]!);
      return byCount != 0 ? byCount : order.indexOf(a).compareTo(order.indexOf(b));
    });
  return ids.take(max).toList();
}
