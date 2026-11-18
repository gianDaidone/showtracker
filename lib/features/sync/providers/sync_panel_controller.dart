import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncPanelOpenProvider = NotifierProvider<SyncPanelController, bool>(
  SyncPanelController.new,
);

/// La visibilità non modifica il lavoro né conferma gli avvisi.
class SyncPanelController extends Notifier<bool> {
  @override
  bool build() => true;

  void show() => state = true;
  void hide() => state = false;
}
