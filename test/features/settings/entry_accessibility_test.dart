import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/auth/auth_state.dart';
import 'package:showtracker/core/router/app_router.dart';
import '../../support/app_test_harness.dart';

void main() {
  for (final onboarding in [true, false]) {
    testWidgets(
        'ingresso con testo 200% e display stretto: onboarding=$onboarding',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      const links = MethodChannel('com.llfbandit.app_links/events');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(links, (_) async => null);
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(links, null));
      final app = (await tester.runAsync(() => AppTestHarness.create(
          auth: onboarding
              ? const Unauthenticated()
              : const AuthenticatedWithManualKey('fixture'))))!;
      addTearDown(() => app.dispose(tester));
      await app.pump(tester);
      if (!onboarding) {
        app.container.read(appRouterProvider).go('/games');
        await app.flush(tester);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pump();
        await tester.scrollUntilVisible(find.text('Salva e Attiva'), 300,
            scrollable: find.ancestor(of: find.text('Salva e Attiva'),
                matching: find.byType(Scrollable)).first);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
