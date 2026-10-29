import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/features/update/data/install_permission.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('showtracker/install_permission');
  late List<String> calls;

  setUp(() async {
    calls = [];
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  for (final result in [true, false, null]) {
    test('isGranted risposta $result', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
          (call) async {
        calls.add(call.method);
        return result;
      });
      expect(await InstallPermission.isGranted(), result ?? false);
      expect(calls, ['canRequestPackageInstalls']);
    });
  }

  test('canale assente lascia decidere alla piattaforma', () async {
    expect(await InstallPermission.isGranted(), isTrue);
  });

  test('PlatformException non viene nascosta come permesso concesso', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel, (_) async => throw PlatformException(code: 'test-error'));
    await expectLater(
        InstallPermission.isGranted(), throwsA(isA<PlatformException>()));
  });

  for (final opened in [false, null]) {
    test('impostazioni non aperte ($opened) terminano senza aspettare resume',
        () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
          (call) async {
        calls.add(call.method);
        return opened;
      });
      expect(await InstallPermission.requestViaSettings(), isFalse);
      expect(calls, ['openInstallSettings']);
    });
  }

  for (final granted in [true, false]) {
    testWidgets(
        'attende il ritorno dalle impostazioni e ricontrolla permesso $granted',
        (tester) async {
      final opened = Completer<void>();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
          (call) async {
        calls.add(call.method);
        if (call.method == 'openInstallSettings') {
          opened.complete();
          return true;
        }
        return granted;
      });
      var completed = false;
      final result = InstallPermission.requestViaSettings().then((value) {
        completed = true;
        return value;
      });
      await tester.pump();
      await opened.future;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(completed, isFalse);
      expect(calls, ['openInstallSettings']);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(await result, granted);
      expect(calls, ['openInstallSettings', 'canRequestPackageInstalls']);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(calls, ['openInstallSettings', 'canRequestPackageInstalls']);
    });
  }

  testWidgets(
      'errore apertura rimuove il listener e una nuova richiesta funziona',
      (tester) async {
    var fails = true;
    final opened = Completer<void>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call.method);
      if (fails) throw PlatformException(code: 'settings-unavailable');
      if (call.method == 'openInstallSettings') opened.complete();
      return true;
    });
    await expectLater(InstallPermission.requestViaSettings(),
        throwsA(isA<PlatformException>()));
    fails = false;
    final result = InstallPermission.requestViaSettings();
    await tester.pump();
    await opened.future;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(await result, isTrue);
    expect(calls, [
      'openInstallSettings',
      'openInstallSettings',
      'canRequestPackageInstalls'
    ]);
  });
}
