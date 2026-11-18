import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:showtracker/core/router/app_router.dart';
import '../../support/app_test_harness.dart';

void main() {
  testWidgets('mostrare il QR di export non avvia la fotocamera',
      (tester) async {
    const channel =
        MethodChannel('dev.steenbakker.mobile_scanner/scanner/method');
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final app = (await tester.runAsync(() => AppTestHarness.create()))!;
    addTearDown(() => app.dispose(tester));
    await app.pump(tester);
    app.container.read(appRouterProvider).go('/sync');
    await app.flush(tester);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(calls.where((name) => name == 'start'), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
