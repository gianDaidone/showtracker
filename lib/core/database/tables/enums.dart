/// Shared tracking status for all media types.
enum MediaStatus {
  watching,
  completed,
  paused,
  dropped,
  planToWatch;

  /// Human-readable Italian label for UI display.
  String get label => switch (this) {
        MediaStatus.watching => 'In visione',
        MediaStatus.completed => 'Completato',
        MediaStatus.paused => 'In pausa',
        MediaStatus.dropped => 'Abbandonato',
        MediaStatus.planToWatch => 'Da vedere',
      };
  String get gameLabel => switch (this) {
        MediaStatus.watching => 'In gioco',
        MediaStatus.completed => 'Giocato',
        MediaStatus.paused => 'In pausa',
        MediaStatus.dropped => 'Abbandonato',
        MediaStatus.planToWatch => 'Backlog',
      };
}
