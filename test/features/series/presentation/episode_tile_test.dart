import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/theme/app_theme.dart';
import 'package:showtracker/features/series/data/models/tmdb_episode.dart';
import 'package:showtracker/features/series/presentation/widgets/episode_tile.dart';

void main() {
  TmdbEpisode episode({String? airDate = '2020-01-01'}) => TmdbEpisode(
        name: 'Il primo episodio',
        episodeNumber: 1,
        airDate: airDate,
      );

  Future<void> mount(WidgetTester tester, EpisodeTile tile) =>
      tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark(), home: Scaffold(body: tile)),
      );

  testWidgets('episodio andato in onda consente la marcatura', (tester) async {
    bool? marked;
    await mount(
        tester,
        EpisodeTile(
          episode: episode(),
          isWatched: false,
          onToggle: (value) => marked = value,
        ));
    await tester.tap(find.byType(Checkbox));
    expect(marked, isTrue);
    expect(find.text('Il primo episodio'), findsOneWidget);
  });

  testWidgets('episodio futuro non espone la marcatura', (tester) async {
    var called = false;
    await mount(
        tester,
        EpisodeTile(
          episode: episode(airDate: '2099-01-01'),
          isWatched: false,
          onToggle: (_) => called = true,
        ));
    expect(find.byType(Checkbox), findsNothing);
    expect(called, isFalse);
  });

  testWidgets('sola lettura non espone checkbox anche se già uscito',
      (tester) async {
    await mount(tester, EpisodeTile(episode: episode(), isWatched: true));
    expect(find.byType(Checkbox), findsNothing);
    final title = tester.widget<Text>(find.text('Il primo episodio'));
    expect(title.style!.decoration, TextDecoration.lineThrough);
  });

  testWidgets('episodio visto può tornare non visto', (tester) async {
    bool? marked;
    await mount(
        tester,
        EpisodeTile(
          episode: episode(),
          isWatched: true,
          onToggle: (value) => marked = value,
        ));
    await tester.tap(find.byType(Checkbox));
    expect(marked, isFalse);
  });

  testWidgets('tap sul titolo apre il dettaglio senza cambiare il visto',
      (tester) async {
    var opened = false;
    var toggled = false;
    await mount(
        tester,
        EpisodeTile(
          episode: episode(),
          isWatched: false,
          onToggle: (_) => toggled = true,
          onTap: () => opened = true,
        ));
    await tester.tap(find.text('Il primo episodio'));
    expect(opened, isTrue);
    expect(toggled, isFalse);
  });
}
