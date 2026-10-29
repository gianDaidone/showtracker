import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/features/series/presentation/next_episodes_screen.dart';

import 'support/app_test_harness.dart';

void main() {
  testWidgets('App smoke test: avvio autenticato con database vuoto',
      (tester) async {
    final app = await tester.runAsync(
      () => AppTestHarness.create(rescheduleAtStartup: true),
    );
    addTearDown(() => app!.dispose(tester));

    await app!.pump(tester);

    expect(find.byType(NextEpisodesScreen), findsOneWidget);
    expect(find.text('Da Vedere'), findsOneWidget);
    expect(find.text('In Uscita'), findsOneWidget);
    expect(find.text('Nessuna serie in visione'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
