enum SyncPhase { idle, preparing, importing, enriching, finished }

class SyncProgress {
  const SyncProgress({
    this.phase = SyncPhase.idle,
    this.total,
    this.completed = 0,
    this.failed = 0,
    this.title,
    this.detail,
    this.errors = const [],
    this.backgroundAvailable = true,
    this.notificationsAllowed = true,
    this.otherSessions = 0,
    this.deferredGames = 0,
    this.needsGameAcknowledgement = false,
    this.updatingGames = false,
  });

  final SyncPhase phase;
  final int? total;
  final int completed;
  final int failed;
  final String? title;
  final String? detail;
  final List<String> errors;
  final bool backgroundAvailable;
  final bool notificationsAllowed;
  final int otherSessions;
  final int deferredGames;
  final bool needsGameAcknowledgement;
  final bool updatingGames;

  bool get hasActivity => active || needsGameAcknowledgement;
  int get processed => completed + failed + deferredGames;

  bool get active => phase != SyncPhase.idle && phase != SyncPhase.finished;
  double? get fraction => total == null
      ? null
      : total == 0
          ? 1
          : (processed / total!).clamp(0, 1);
  String get heading => needsGameAcknowledgement
      ? 'Elenco giochi salvato'
      : active
          ? updatingGames
              ? 'Aggiornamento giochi'
              : 'Sincronizzazione in corso'
          : failed == 0 && errors.isEmpty
              ? 'Sincronizzazione completata'
              : 'Sincronizzazione da completare';
  String get counter => total == null
      ? 'Preparazione…'
      : '${completed + deferredGames}/$total ${updatingGames ? 'giochi aggiornati' : 'elementi completati'}${failed == 0 ? '' : ' · $failed non completati'}';

  String get scopeLabel =>
      updatingGames ? 'Solo i giochi in attesa' : 'Serie, film e giochi';
  String get activityLabel => total != null && total! - processed == 1 && active
      ? updatingGames
          ? 'Ultimo gioco in corso…'
          : 'Ultimo elemento in corso…'
      : scopeLabel;
}
