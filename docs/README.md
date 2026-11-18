# Contesto tecnico per lo sviluppo

Verificato sul sorgente il **2026-11-16**. Questa raccolta descrive ShowTracker;
il codice resta la fonte di verità. I percorsi citati sono relativi alla root.

## Quale documento leggere

| Task | Documento principale | Sorgenti e test di ingresso |
| --- | --- | --- |
| Orientarsi, aggiungere una feature, modificare l'avvio | [01 — Architettura](01-architecture.md) | `lib/main.dart`, `lib/core/services/startup_coordinator.dart`, `test/core/startup_coordinator_test.dart` |
| Modificare comportamenti, stati o discovery | [02 — Specifiche funzionali](02-functional-specs.md) | `lib/features/`, `test/features/`, `test/watch_next_rules_test.dart` |
| Cambiare schema, DAO, query o cache | [03 — Dati locali](03-data-local-storage.md) | `lib/core/database/`, `test/core/database/` |
| Integrare API o modificare errori/fallback | [04 — Servizi e API](04-services-api.md) | `lib/core/network/`, `lib/features/series/data/`, `lib/features/games/data/` |
| Modificare provider, route, widget o tema | [05 — Stato e UI](05-ui-state-management.md) | `lib/core/router/`, `lib/core/shell/`, `lib/core/theme/`, `test/core/router/` |
| Configurare ambiente, codegen, test o release | [06 — Sviluppo](06-development-rules.md) | `pubspec.yaml`, `build.yaml`, `.github/workflows/test.yml`, [guida test](../test/README.md) |
| Verificare APK, firma e aggiornamenti GitHub | [Checklist release](github-release-checklist.md) | `tool/verify_apk.py`, `tool/audit_native_libraries.py` |
| Scrivere o rifattorizzare Dart/Flutter | [07 — Regole di codice](07-clean-code-best-practices.md) | `analysis_options.yaml`, `lib/core/riverpod_utils.dart`, `lib/core/widgets/` |
| Modificare auth, permessi, input o dati sensibili | [08 — Sicurezza](08-security-permissions.md) | `lib/core/auth/`, `lib/core/network/tmdb_http_client.dart`, `android/app/src/main/AndroidManifest.xml` |
| Modificare anime, cour o numerazione episodi | [09 — Pipeline anime](09-anime-pipeline.md) | `lib/features/series/providers/series_providers.dart`, `test/features/series/` |
| Modificare QR, import/export, conflitti o placeholder | [10 — Sync P2P](10-p2p-sync.md) | `lib/features/sync/`, `test/features/sync/` |
| Modificare notifiche, widget home o aggiornamenti APK | [11 — Integrazioni Android](11-android-integrations.md) | `lib/widgets_manager.dart`, `android/app/src/main/`, `test/widgets_manager_test.dart`, `test/features/update/` |
| Valutare prestazioni e misure precedenti | [Audit prestazionale storico](performance-audit.md) | `test/core/database/pipeline_performance_test.dart`, `test/features/series/visibility_performance_test.dart` |

## Vincoli da leggere prima di intervenire

- Dati personali autorevoli nel DB locale; le API forniscono metadati.
- Ogni container/scope Riverpod usa `retry: noProviderRetry`.
- Non modificare manualmente `*.g.dart` e `*.drift.dart`.
- Per la lista e il conteggio “Da Vedere”, usare `visibleWatchingShowsProvider`
  e `lib/features/series/data/watch_next_rules.dart`.
- Numeri cour anime e stagioni TMDB non sono intercambiabili.
- Conservare i fallback persistiti: il refresh scade le cache senza eliminarle.
- Non sincronizzare metadati o notifiche da snapshot locali parziali.
- Il container globale di produzione deve restare vivo per i widget Android.
- UI italiana, Material 3, solo tema scuro.
- Non installare/disinstallare runner di test con l'identità dell'app personale.

## Come mantenere questi documenti

- Ogni contratto ha un documento principale; altrove inserire rimandi.
- Aggiornare la guida pertinente insieme al cambiamento del codice.
- Distinguere comportamento implementato, regole da preservare e limiti noti.
- Verificare simboli e percorsi prima di riutilizzarli; non dedurre funzionalità
  da commenti, dipendenze presenti o documentazione upstream.
- `performance-audit.md` conserva risultati datati: non certifica la build attuale.
- [test/README.md](../test/README.md) possiede fixture, copertura e checklist test;
  [third_party/README.md](../third_party/README.md) possiede la patch vendorizzata.

## Sicurezza, affidabilità e release GitHub

- [Report principale](security-reliability-audit.md): correzioni conservate, evidenze e problemi aperti.
- [Checklist GitHub e comandi canonici](github-release-checklist.md).
- [Note della prossima release](github-release-notes.md), ancora in bozza.
- [Chiarimento AniList](anilist-terms-clarification.md).
- [Privacy, flussi e condizioni API](privacy-and-services.md), pertinenti anche a GitHub.
- [Procedura e registro delle prove native](native-release-validation.md), con build, esiti e limiti distinti.
