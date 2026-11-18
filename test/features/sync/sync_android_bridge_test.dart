import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/features/sync/domain/models/sync_progress.dart';
import 'package:showtracker/features/sync/services/sync_android_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'notifica serializzata, throttle e completamento non sovrascritto',
      (tester) async {
    final calls = <MethodCall>[];
    final first = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SyncAndroidBridge.channel, (call) async {
      calls.add(call);
      if (call.method == 'start') {
        return {'available': true, 'notifications': false};
      }
      if (calls.where((c) => c.method == 'update').length == 1) {
        await first.future;
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SyncAndroidBridge.channel, null));
    final bridge = SyncAndroidBridge();
    final support = await bridge.start();
    expect(support.available, isTrue);
    expect(support.notifications, isFalse);
    bridge.publish(const SyncProgress(
        phase: SyncPhase.enriching, total: 10, completed: 1));
    bridge.publish(const SyncProgress(
        phase: SyncPhase.enriching,
        total: 10,
        completed: 2,
        title: 'Titolo riservato',
        detail: 'Passaggio interno'));
    await tester.pump(const Duration(seconds: 1));
    expect(calls.where((c) => c.method == 'update'), hasLength(1));
    bridge.publish(const SyncProgress(
        phase: SyncPhase.finished, total: 10, completed: 10));
    await tester.pump();
    expect(calls.where((c) => c.method == 'update'), hasLength(1));
    first.complete();
    await tester.pump();
    await tester.pump();
    final updates = calls.where((c) => c.method == 'update').toList();
    expect(updates, hasLength(2));
    expect(updates.first.arguments['processed'], 2);
    expect(updates.first.arguments['body'], '2/10 elementi completati');
    expect(updates.last.arguments['finished'], isTrue);
    expect(updates.last.arguments['processed'], 10);
    bridge.dispose();
    await tester.pump(const Duration(seconds: 2));
    expect(calls.where((c) => c.method == 'update'), hasLength(2));
  });
}
