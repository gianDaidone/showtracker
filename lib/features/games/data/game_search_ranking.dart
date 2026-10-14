import 'dart:math' as math;

import 'models/rawg_game.dart';

/// Riordina i risultati di ricerca RAWG.
///
/// RAWG da solo non basta: l'ordine di default (rilevanza) funziona con i
/// titoli completi ma non con le sigle — con "gta" mette in testa giochini con
/// "GTA" nel nome e GTA V non è nemmeno tra i primi dieci. `ordering=-added`
/// (popolarità) sistema le sigle ma, siccome RAWG abbina anche una sola delle
/// parole cercate, con "portal 2" mette primo GTA V e con "celeste" porta su
/// Counter-Strike. Quindi uniamo le due liste ([relevance] = ordine di default,
/// [popular] = `search_precise` + `-added`) e ordiniamo così:
///
/// 1. prima i giochi il cui titolo contiene **tutte** le parole cercate, o le
///    cui iniziali formano la sigla cercata ("gta" → Grand Theft Auto V,
///    "rdr2" → Red Dead Redemption 2, "cod" → Call of Duty);
/// 2. dentro ciascun gruppo, per punteggio: corrispondenza del titolo,
///    popolarità (`added`, in scala logaritmica), posizione nella lista di
///    rilevanza, con una penalità per i giochi che non ha quasi nessuno
///    (caricamenti amatoriali con titoli tipo "GTA+" o "COD").
///
/// Pesi tarati su ricerche reali: gta, cod, rdr2, witcher 3, portal 2,
/// celeste, inside, zelda, mario kart, fifa, elden ring, hollow knight,
/// minecraft, resident evil 4, the last of us, doom.
List<RawgGame> rankGameSearch(
  String query,
  List<RawgGame> relevance, [
  List<RawgGame> popular = const [],
]) {
  final queryTokens = _tokens(query);
  if (queryTokens.isEmpty) return [...relevance, ...popular];

  final relevanceRank = <int, int>{
    for (var i = 0; i < relevance.length; i++) relevance[i].id: i,
  };
  final pool = <int, RawgGame>{};
  for (final g in [...relevance, ...popular]) {
    pool.putIfAbsent(g.id, () => g);
  }

  final scored = [
    for (final g in pool.values)
      (game: g, score: _score(g, queryTokens, relevanceRank[g.id], relevance.length)),
  ];
  scored.sort((a, b) {
    final byGroup = (b.score.fullMatch ? 1 : 0) - (a.score.fullMatch ? 1 : 0);
    return byGroup != 0 ? byGroup : b.score.value.compareTo(a.score.value);
  });
  return [for (final s in scored) s.game];
}

({bool fullMatch, double value}) _score(
  RawgGame game,
  List<String> queryTokens,
  int? relevanceRank,
  int relevanceLength,
) {
  final nameTokens = _tokens(game.name);

  // Parole cercate presenti nel titolo; l'ultima basta come prefisso, perché
  // la ricerca parte mentre l'utente sta ancora scrivendo.
  var hits = 0;
  for (var i = 0; i < queryTokens.length; i++) {
    final w = queryTokens[i];
    final isLast = i == queryTokens.length - 1;
    if (nameTokens.contains(w) ||
        (isLast && nameTokens.any((n) => n.startsWith(w)))) {
      hits++;
    }
  }
  final fraction = hits / queryTokens.length;
  var fullMatch = fraction == 1;
  var value = 3 * fraction;

  final queryText = queryTokens.join(' ');
  final nameText = nameTokens.join(' ');
  if (nameText == queryText) {
    value += 2;
  } else if (nameText.startsWith(queryText)) {
    value += 1;
  }

  final queryJoined = queryTokens.join();
  final initials = _initials(nameTokens);
  if (queryJoined.length >= 2 && initials.startsWith(queryJoined)) {
    value += 2.5;
    fullMatch = true;
  }

  value += 4.5 * math.log(game.added + 1) / math.log(25000);
  if (relevanceRank != null && relevanceLength > 0) {
    value += 1 - relevanceRank / relevanceLength;
  }
  if (game.added < 5) value -= 1.5;

  return (fullMatch: fullMatch, value: value);
}

const _roman = {
  'ii': '2', 'iii': '3', 'iv': '4', 'v': '5', 'vi': '6',
  'vii': '7', 'viii': '8', 'ix': '9', 'x': '10',
};

/// Parole minuscole senza punteggiatura, con i numeri romani convertiti
/// ("The Witcher III" e "witcher 3" devono coincidere).
List<String> _tokens(String s) => s
    .toLowerCase()
    .split(RegExp(r'[^0-9a-z]+'))
    .where((w) => w.isNotEmpty)
    .map((w) => _roman[w] ?? w)
    .toList();

/// Iniziali delle parole, con i numeri interi: "red dead redemption 2" → "rdr2".
String _initials(List<String> tokens) =>
    tokens.map((w) => RegExp(r'^\d+$').hasMatch(w) ? w : w[0]).join();
