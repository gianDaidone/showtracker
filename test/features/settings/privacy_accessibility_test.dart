import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/features/sync/providers/sync_controller.dart';
import 'package:showtracker/features/sync/domain/models/sync_progress.dart';
import 'package:showtracker/core/theme/app_theme.dart';
import 'package:showtracker/core/widgets/secret_key_dialog.dart';
import 'package:showtracker/features/settings/presentation/privacy_info_screen.dart';

class _IdleSync extends SyncController {
  @override
  SyncProgress build() => const SyncProgress();
}

void main() {
  testWidgets('privacy con testo 200% su display stretto resta scorrevole',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
        retry: noProviderRetry,
        overrides: [syncControllerProvider.overrideWith(_IdleSync.new)],
        child: MaterialApp(
            theme: AppTheme.dark(),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!),
            home: const PrivacyInfoScreen())));
    await tester.pumpAndSettle();
    expect(find.textContaining('100%'), findsNothing);
    await tester.scrollUntilVisible(find.text('Licenze open source'), 400);
    expect(find.text('Licenze open source'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chiave nascosta, salvataggio monouso e errore privo di segreti',
      (tester) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: SecretKeyDialog(
            title: 'Chiave',
            onSave: (key) {
              calls++;
              return pending.future;
            })));
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    await tester.enterText(find.byType(TextField), 'secret-fixture');
    await tester.tap(find.text('Salva'));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(calls, 1);
    pending.completeError(Exception('secret-fixture'));
    await tester.pump();
    expect(find.textContaining('Salvataggio non riuscito'), findsOneWidget);
    expect(find.textContaining('Exception:'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
