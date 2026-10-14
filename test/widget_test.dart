import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:showtracker/app.dart';
import 'package:showtracker/core/riverpod_utils.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(retry: noProviderRetry, child: ShowTrackerApp()),
    );
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
