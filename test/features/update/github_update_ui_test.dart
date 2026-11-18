import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/core/router/app_router.dart';
import 'package:showtracker/core/theme/app_theme.dart';
import 'package:showtracker/features/update/data/app_version.dart';
import 'package:showtracker/features/update/data/github_release_service.dart';
import 'package:showtracker/features/update/presentation/app_update_section.dart';
import 'package:showtracker/features/update/presentation/update_dialogs.dart';

import '../../support/app_test_harness.dart';

const _release = GithubRelease(
  version: AppVersion(2, 0, 0),
  tagName: 'v2.0.0',
  apkUrl: 'https://github.com/example/repo/releases/download/v2/app.apk',
  apkName: 'app.apk',
);

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Profilo: aggiornamento GitHub e sync LAN disponibili',
      (tester) async {
    final app = await tester.runAsync(() => AppTestHarness.create());
    addTearDown(() => app!.dispose(tester));
    await app!.pump(tester);
    app.container.read(appRouterProvider).go('/settings');
    await app.flush(tester);
    expect(find.text('Cerca aggiornamenti'), findsOneWidget);
    expect(find.text('Trasferimento / Sync'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('montare la riga non avvia controlli automatici', (tester) async {
    await tester.pumpWidget(ProviderScope(
      retry: noProviderRetry,
      child: MaterialApp(
          theme: AppTheme.dark(), home: const Scaffold(body: AppUpdateTile())),
    ));
    await tester.pump();
    expect(find.text('Cerca aggiornamenti'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('download su richiesta e annullamento conservati',
      (tester) async {
    const stream = MethodChannel('sk.fourq.ota_update/stream');
    const method = MethodChannel('sk.fourq.ota_update/method');
    final calls = <String>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(stream,
        (call) async {
      calls.add(call.method);
      if (call.method == 'listen') {
        expect((call.arguments as Map)['url'], _release.apkUrl);
        expect((call.arguments as Map)['filename'], 'showtracker-2.0.0.apk');
      }
      return null;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(method,
        (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(stream, null);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(method, null);
    });
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Builder(
          builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        const UpdateDownloadDialog(release: _release)),
                child: const Text('Apri'),
              )),
    ));
    expect(calls, isEmpty);
    await tester.tap(find.text('Apri'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, ['listen']);
    expect(find.text('Download versione 2.0.0'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(calls, contains('cancel'));
    expect(find.byType(AlertDialog), findsNothing);
  });
}
