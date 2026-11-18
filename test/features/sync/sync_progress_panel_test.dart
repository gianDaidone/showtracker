import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/core/theme/app_theme.dart';
import 'package:showtracker/features/sync/domain/models/sync_progress.dart';
import 'package:showtracker/features/sync/presentation/sync_progress_panel.dart';
import 'package:showtracker/features/sync/presentation/sync_status_action.dart';
import 'package:showtracker/features/sync/providers/sync_controller.dart';

class _Progress extends SyncController {
  @override
  SyncProgress build() => const SyncProgress(phase: SyncPhase.preparing);
  void update(SyncProgress progress) {
    state = progress;
  }

  @override
  Future<void> acknowledgeGames() async {
    state = const SyncProgress(
        phase: SyncPhase.finished, total: 1, deferredGames: 1);
  }
}

Widget _app(_Progress controller, {double textScale = 1}) => ProviderScope(
    retry: noProviderRetry,
    overrides: [syncControllerProvider.overrideWith(() => controller)],
    child: MaterialApp(
        theme: AppTheme.dark(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: SyncProgressHost(child: child!)),
        home: Builder(
            builder: (context) => Scaffold(
                appBar: AppBar(
                    actions: const [SyncStatusAction(), Icon(Icons.search)]),
                body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => Scaffold(
                                appBar:
                                    AppBar(actions: const [SyncStatusAction()]),
                                body: const Text('Dettaglio')))),
                    child: const Text('Apri dettaglio'))))));

void main() {
  testWidgets(
      'banner in alto, nessun ridimensionamento, chiusura e riapertura dall’icona',
      (tester) async {
    final controller = _Progress();
    await tester.pumpWidget(_app(controller));
    expect(find.text('Sincronizzazione in corso'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Sincronizzazione in corso')).dy,
        lessThan(90));
    final before = tester.getSize(find.byType(Scaffold));
    await tester.tap(find.byTooltip('Riduci sincronizzazione'));
    await tester.pump();
    expect(find.text('Sincronizzazione in corso'), findsNothing);
    expect(tester.getSize(find.byType(Scaffold)), before);
    expect(find.byTooltip('Sincronizzazione'), findsOneWidget);
    await tester.tap(find.text('Apri dettaglio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Dettaglio'), findsOneWidget);
    await tester.tap(find.byTooltip('Sincronizzazione').last);
    await tester.pump();
    controller.update(const SyncProgress(
        phase: SyncPhase.enriching,
        total: 10,
        completed: 2,
        title: 'Titolo riservato',
        detail: 'Passaggio interno'));
    await tester.pump();
    expect(find.text('2/10 elementi completati'), findsOneWidget);
    expect(find.text('Titolo riservato'), findsNothing);
    expect(find.text('Passaggio interno'), findsNothing);
    controller.update(const SyncProgress(
        phase: SyncPhase.finished, total: 10, completed: 10));
    await tester.pump();
    expect(find.text('Sincronizzazione in corso'), findsNothing);
    expect(find.byType(SyncStatusAction).hitTestable(), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'avviso riapre il pannello ridotto e solo Ho capito rimuove l’icona',
      (tester) async {
    final controller = _Progress();
    await tester.pumpWidget(_app(controller));
    await tester.tap(find.byTooltip('Riduci sincronizzazione'));
    await tester.pump();
    controller.update(const SyncProgress(
        phase: SyncPhase.finished,
        total: 1,
        deferredGames: 1,
        needsGameAcknowledgement: true));
    await tester.pump();
    expect(find.text('Configura la chiave API per completare i tuoi giochi'),
        findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.tap(find.byTooltip('Riduci sincronizzazione'));
    await tester.pump();
    expect(find.text('Ho capito'), findsNothing);
    expect(
        find.byTooltip('Sincronizzazione: conferma richiesta'), findsOneWidget);
    await tester.tap(find.byTooltip('Sincronizzazione: conferma richiesta'));
    await tester.pump();
    await tester.tap(find.text('Ho capito'));
    await tester.pump();
    expect(find.text('Ho capito'), findsNothing);
    expect(
        find.byTooltip('Sincronizzazione: conferma richiesta'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('avviso con testo 200% resta scorrevole', (tester) async {
    final controller = _Progress();
    await tester.pumpWidget(_app(controller, textScale: 2));
    controller.update(const SyncProgress(
        phase: SyncPhase.finished,
        total: 1,
        deferredGames: 1,
        needsGameAcknowledgement: true));
    await tester.pump();
    await tester.ensureVisible(find.text('Ho capito'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Ho capito'));
    await tester.pump();
    expect(
        find.byTooltip('Sincronizzazione: conferma richiesta'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('ripresa giochi e ultimo elemento hanno testi generali espliciti',
      (tester) async {
    final controller = _Progress();
    await tester.pumpWidget(_app(controller));
    controller.update(const SyncProgress(
        phase: SyncPhase.enriching, total: 54, completed: 53));
    await tester.pump();
    expect(find.text('Ultimo elemento in corso…'), findsOneWidget);
    controller.update(const SyncProgress(
        phase: SyncPhase.enriching,
        total: 3,
        completed: 1,
        updatingGames: true));
    await tester.pump();
    expect(find.text('Aggiornamento giochi'), findsOneWidget);
    expect(find.text('1/3 giochi aggiornati'), findsOneWidget);
    expect(find.text('Solo i giochi in attesa'), findsOneWidget);
    expect(find.text('1/54 elementi completati'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
