import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/services/notification_service.dart';

void main() {
  test('stagione ed episodio per esteso, con il titolo', () {
    expect(
      NotificationService.episodeBody(
        seasonNumber: 2,
        episodeNumber: 1,
        episodeName: 'Lo scoppio della guerra',
        seasonName: 'Stagione 2',
      ),
      'Stagione 2, episodio 1: «Lo scoppio della guerra» è disponibile oggi!',
    );
  });

  test('il titolo segnaposto di TMDB viene omesso', () {
    for (final placeholder in ['Episodio 1', 'Episode 1', '']) {
      expect(
        NotificationService.episodeBody(
          seasonNumber: 2,
          episodeNumber: 1,
          episodeName: placeholder,
          seasonName: 'Stagione 2',
        ),
        'Stagione 2, episodio 1 è disponibile oggi!',
      );
    }
  });

  test('senza nome di stagione usa "Stagione N", non "S02"', () {
    expect(
      NotificationService.episodeBody(
        seasonNumber: 3,
        episodeNumber: 12,
        episodeName: '',
      ),
      'Stagione 3, episodio 12 è disponibile oggi!',
    );
  });

  test('normalizza spazi senza cancellare titoli che contengono Episode', () {
    expect(
        NotificationService.episodeBody(
            seasonNumber: 2,
            episodeNumber: 4,
            episodeName: '  Episode 4: Il ritorno  ',
            seasonName: '  Arco finale  '),
        'Arco finale, episodio 4: «Episode 4: Il ritorno» è disponibile oggi!');
    expect(
        NotificationService.episodeBody(
            seasonNumber: 2,
            episodeNumber: 4,
            episodeName: '  ePiSoDiO 4  ',
            seasonName: '  '),
        'Stagione 2, episodio 4 è disponibile oggi!');
  });

  test('nomi di stagione propri e parti degli anime restano invariati', () {
    expect(
      NotificationService.episodeBody(
        seasonNumber: 4,
        episodeNumber: 5,
        episodeName: '',
        seasonName: 'Stagione 1 Parte 2',
      ),
      'Stagione 1 Parte 2, episodio 5 è disponibile oggi!',
    );
  });
}
