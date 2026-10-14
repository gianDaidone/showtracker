import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/features/games/data/game_search_ranking.dart';
import 'package:showtracker/features/games/data/models/rawg_game.dart';

// Casi presi da risposte reali di RAWG (ottobre 2026), ridotti ai giochi che
// contano: `relevance` = ordine di default, `popular` = search_precise + -added.

var _nextId = 1;
RawgGame g(String name, int added) =>
    RawgGame(id: _nextId++, slug: '', name: name, added: added);

List<String> top(List<RawgGame> games, int n) =>
    games.take(n).map((g) => g.name).toList();

void main() {
  test('"gta": i Grand Theft Auto prima dei giochini con GTA nel nome', () {
    final gta5 = g('Grand Theft Auto V', 22753);
    final gta4 = g('Grand Theft Auto IV', 13266);
    final sa = g('Grand Theft Auto: San Andreas', 12245);
    final relevance = [
      g('Grand Theft Auto', 1960),
      g('GTA-bankrob', 2),
      g('GTA-like Game', 0),
      g('GTA: Soviet Russia', 3),
      g('GTA+', 0),
    ];
    final ranked = rankGameSearch('gta', relevance, [gta5, gta4, sa]);

    expect(top(ranked, 4), [
      'Grand Theft Auto V',
      'Grand Theft Auto',
      'Grand Theft Auto IV',
      'Grand Theft Auto: San Andreas',
    ]);
  });

  test('"portal 2": Portal 2 primo, non il gioco più popolare con un "2"', () {
    final relevance = [
      g('Portal 2', 20985),
      g('Postal 2: Apocalypse Weekend', 202),
      g('Portal Reloaded', 179),
      g('Portal 2: In Motion', 10),
    ];
    final popular = [
      g('Grand Theft Auto V', 22753),
      g('Left 4 Dead 2', 17552),
      g('Red Dead Redemption 2', 17062),
    ];
    final ranked = rankGameSearch('portal 2', relevance, popular);

    // Prima tutti i titoli con entrambe le parole, anche se quasi sconosciuti
    expect(top(ranked, 2), ['Portal 2', 'Portal 2: In Motion']);
  });

  test('"celeste": i giochi con la parola cercata prima di quelli popolari', () {
    final relevance = [
      g('Celeste', 6205),
      g('Celeste 2.7', 3),
      g('Superhot: Mind Control Delete', 3885),
    ];
    final ranked = rankGameSearch('celeste', relevance, [
      g('Counter-Strike: Condition Zero Deleted Scenes', 5746),
    ]);

    expect(top(ranked, 2), ['Celeste', 'Celeste 2.7']);
  });

  test('"cod" e "rdr2": le sigle trovano Call of Duty e Red Dead Redemption 2',
      () {
    final cod = rankGameSearch('cod', [
      g('Cod of Duty', 0),
      g('COD', 0),
    ], [
      g('Call of Duty: Black Ops III', 7289),
      g('Call of Duty: Black Ops II', 6187),
    ]);
    expect(top(cod, 2),
        ['Call of Duty: Black Ops III', 'Call of Duty: Black Ops II']);

    final rdr = rankGameSearch('rdr2', [
      g('RDR2: Companion', 3),
      g('Dead Rising 2: CASE ZERO', 653),
    ], [
      g('Red Dead Redemption 2', 17062),
    ]);
    expect(rdr.first.name, 'Red Dead Redemption 2');
  });

  test('"witcher 3": i numeri romani contano come le cifre', () {
    final ranked = rankGameSearch('witcher 3', [
      g('Doom 3', 3985),
      g('The Witcher III Remake', 50),
    ]);
    expect(ranked.first.name, 'The Witcher III Remake');
  });

  test('un gioco presente in entrambe le liste compare una volta sola', () {
    final celeste = g('Celeste', 6205);
    final ranked = rankGameSearch('celeste', [celeste], [celeste]);
    expect(ranked, hasLength(1));
  });
}
