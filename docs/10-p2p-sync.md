# Sincronizzazione P2P

## Componenti e ciclo di vita

| Componente | File sotto `lib/features/sync/` |
| --- | --- |
| Export, import e hydration | `services/sync_service.dart` |
| Server HTTP temporaneo e handler | `services/local_sync_server.dart` |
| Payload manualmente serializzato | `domain/models/sync_payload.dart` |
| Range e compressione | `utils/range_utils.dart`, `utils/sync_compressor.dart` |
| QR/scanner e invio/ricezione | `presentation/sync_screen.dart` |
| Recovery app-level | `providers/metadata_recovery_provider.dart` |

- Nessun backend cloud; il dispositivo mittente espone uno snapshot LAN.
- `LocalSyncServer.start` ferma la sessione precedente, genera token e avvia
  Shelf sul solo IPv4 privato selezionato, porta 8080; cerca IP Wi-Fi con fallback
  alle interfacce locali. Sessione massima cinque minuti e chiusura anche al dispose.
- QR contiene `http://{ip}:8080/sync?token={token}#k={chiave}`. La chiave
  AES non viene inviata nella richiesta HTTP.
- Handler separato dal socket per test; token errato → 403; risposta testo
  con envelope cifrato STSYNC2:, no-store e senza CORS wildcard; richieste browser con
  Origin e query/token duplicati rifiutati.
- `SyncScreen.dispose` avvia lo stop del server. La recovery appartiene al
  container app e prosegue dopo l'uscita dalla schermata.

## Contratto del payload

Esempio illustrativo del JSON prima della compressione:

```json
{
  "s": {"123": {"st": "watching", "u": 1800000000, "e": {"1": "1-3,5"}}},
  "g": {"456": {"st": "planToWatch", "u": 1800000000}},
  "m": {"789": {"st": "completed", "u": 1800000000}}
}
```

| Campo | Significato |
| --- | --- |
| `s`, `g`, `m` | Mappe serie, giochi e film; domini vuoti omessi |
| Chiave della mappa | ID esterno come stringa: TMDB o RAWG |
| `st` | Nome persistito di `MediaStatus` |
| `u` | `updatedAt ?? addedAt`, secondi Unix |
| `e` | Per serie: stagione/cour stringa → range degli episodi visti |

- Export raggruppa episodi visti con una lettura, poi `RangeUtils` compatta i range.
- QR diretto legacy: JSON → UTF-8 → zlib → base64, leggibile da chi acquisisce il QR.
- LAN v2: bytes zlib cifrati AES-256-GCM, nonce 12 byte e tag 16 byte, envelope
  STSYNC2: + base64. Chiave nuova per ogni export, nonce casuale e token legato
  come AAD. Implementazione standard del package cryptography, senza cipher proprietario.
- Non trasferisce titoli, poster, mapping cour, cache, credenziali, note, rating
  o playtime. Non è un export completo né un backup ripristinabile identico.
- Non contiene tombstone di rimozione o eventi “non visto”; non propaga quelle
  azioni come cancellazioni remote.
- Il JSON legacy non contiene un campo versione; l’envelope LAN è versionato
  STSYNC2:. Il proprietario ha approvato l’aggiornamento di entrambi i peer:
  gli URL LAN legacy in chiaro sono rifiutati, senza downgrade; i QR diretti restano compatibili.
- Il ricevitore supporta anche payload base64 diretto, oltre all'URL HTTP.

## Import e conflitti

`SyncService.importData` esegue tutti i domini in una transazione.

| Dato | Risoluzione attuale |
| --- | --- |
| Media assente | Inserire placeholder `Sconosciuto`, stato e timestamp ricevuti |
| Stato media esistente | Applicare solo se `incomingDate.isAfter(existingDate)` |
| Timestamp uguali | Conservare stato locale |
| Episodi visti serie | Unione con i visti locali, anche se lo stato remoto è più vecchio |
| Episodi già visti | Non riscrivere soltanto per un nuovo timestamp parent |
| Film legacy `watching` | Normalizzare a `planToWatch` |
| Stato non riconosciuto | Fallback `watching` serie/giochi, `planToWatch` film |
| ID/coordinate o struttura non validi | Rifiutare tutto prima della transazione |

- Il merge episodi non è last-write-wins per episodio: il payload non contiene
  timestamp individuali né marcature false.
- Per episodi aggiunti si usa il timestamp parent ricevuto.
- Il codice ripristina il timestamp remoto dopo `updateStatus`, che normalmente
  lo aggiornerebbe all'ora corrente.
- Timestamp wire sono al secondo; clock dei dispositivi non sono riconciliati.
- Validazione strutturale e budget prima di ogni import; snapshot copiato prima
  della transazione. Errori DB tardivi annullano anche modifiche dei domini precedenti.
- Formato valido legacy invariato; la permissivita su frammenti malformati non
  e piu supportata. Limiti e politica timestamp in [08](08-security-permissions.md).

## Recupero dei metadati

`metadataRecoveryProvider` possiede tre `CoalescingRefresh`, uno per dominio.

1. Startup installa listener delle credenziali indipendenti dal prompt notifiche.
2. Cambio chiave RAWG accoda giochi; cambio credenziale TMDB accoda film.
3. Import accoda tutti i domini; apertura librerie film/giochi ritenta placeholder.
4. Ogni passaggio attende credenziali, controlla chiave effettiva e mantiene una
   subscription al servizio/client corrente.
5. Una generazione credenziale arresta il lavoro ormai obsoleto; il passaggio
   successivo acquisisce il nuovo client.

### Contratti film/giochi

- Senza chiave effettiva nessuna richiesta remota per quel dominio.
- Accettare soltanto titoli utili: scartare vuoti e placeholder equivalenti.
- Update con condizione ID locale + ID esterno + titolo ancora `Sconosciuto`.
- Non ricreare record rimossi durante il fetch e non sovrascrivere modifiche personali.
- Preservare stato, rating/note e `updatedAt` LWW.
- Giochi: piattaforme JSON, voto RAWG normalizzato su 10; rileggere playtime dopo
  la rete e riempirlo soltanto se ancora null, dentro la transazione finale.
- Errore: lasciare placeholder ritentabile; nessun retry automatico Riverpod.

### Hydration serie

Update condizionato a ID locale + TMDB ID + titolo ancora Sconosciuto. Non
ripristina record rimossi ne sovrascrive un titolo aggiornato durante la rete.
Per anime aggiorna metadati descrittivi, senza totali o coordinate episodio TMDB
grezze: attende la pipeline cour per quegli allineamenti. Preserva timestamp e
campi personali; test dedicati in hydration_safety_test.

## Sicurezza e limiti

- Token casuale di 16 byte e chiave AES casuale di 32 byte nel solo fragment QR.
  Contenuto LAN cifrato/autenticato; IP, token e metadati HTTP restano osservabili.
  Nessuna autenticazione reciproca: chi acquisisce il QR possiede la chiave.
- URL, redirect, token, dimensioni, decompressione, range e tipi sono limitati
  prima dell'import. Contratto autorevole e rischi residui in [08](08-security-permissions.md).
- Server è temporaneo e lo snapshot non si aggiorna a ogni mutazione successiva.
- Socket/IP/camera/connettività reali richiedono prova manuale su due dispositivi.

La matrice di compatibilità, le garanzie AES-GCM e i limiti di identificazione
sono riassunti nell’[audit attivo](security-reliability-audit.md).
Comunicare il cambiamento con le [note release](github-release-notes.md).

## Test pertinenti

`test/features/sync/sync_codec_test.dart`, `sync_service_test.dart`,
`local_sync_server_test.dart`, `hydration_safety_test.dart`,
`metadata_recovery_test.dart`, `metadata_recovery_screen_test.dart`,
`sync_encryption_test.dart`, `encrypted_receiver_test.dart`,
`local_sync_lifecycle_test.dart`, `sync_security_test.dart`.
I test handler non aprono socket LAN; i test recovery usano confini simulati.
