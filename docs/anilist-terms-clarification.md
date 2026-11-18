# AniList: requisito verificato e applicabilità da chiarire

Verifica mirata del **2026-11-17**, separata dalle prove di aggiornamento.

## Fonte ufficiale e requisito specifico

[Terms of Use, punto 5](https://docs.anilist.co/guide/terms-of-use).
La pagina diretta ha restituito 403 al tool; il contenuto è stato letto anche
nel **repository ufficiale AniList/docs**, non soltanto da un risultato di ricerca:
[sorgente alla revisione 03281c0](https://github.com/AniList/docs/blob/03281c0a4bbf0c7f2097e0c935cddaed1096aa65/docs/guide/terms-of-use.md),
ultima modifica del file rilevata il 18 agosto 2026.

> Use of the AniList API within competing, non-complementary services of the same nature is prohibited.

Il punto cita esplicitamente i servizi lista/tracker di anime e manga e precisa
che la restrizione riguarda **sia dati utente sia metadati dei media**. Questo è
un divieto verificato per quella categoria, non un semplice dubbio sull’esistenza
di una clausola. Gratuità e uso dei soli metadati non sono esenzioni da quel punto.

La versione corrente letta non contiene la vecchia formulazione che prospettava
autorizzazioni su richiesta in presenza di sync continuativa: non presentarla
come un’eccezione automaticamente disponibile o già soddisfatta.

## Perché riguarda ShowTracker

Fatti verificati sul codice:

- L’app permette tracking di anime con stati e progressi locali; non è soltanto
  un visualizzatore generico di cataloghi.
- AniListService contatta graphql.anilist.co tramite AniListQueue per ricerca,
  episodi/cour e programmazione delle uscite. Le query Media includono metadati
  quali episodes e nextAiringEpisode.
- Non è implementato login AniList o sync delle liste con un account AniList.
  L’integrazione è di metadati per un tracker autonomo multi-catalogo.

**Inferenza da chiarire:** queste caratteristiche rendono concretamente rilevante
la categoria di tracker concorrente non complementare. Non è stata ottenuta
una qualificazione ufficiale di ShowTracker da AniList né una deroga scritta;
non si afferma che AniList abbia accertato formalmente una violazione di questa app.
Il proprietario ha dichiarato che l’autorizzazione è da verificare o richiedere.

Conclusione: clausola verificata; applicabilità puntuale/possibile autorizzazione
non risolte. Prima della distribuzione pubblica serve chiarimento con AniList
basato sul funzionamento reale descritto sopra, senza supporre esenzioni per
GitHub, uso non commerciale o assenza di dati utente remoti. Nessuna richiesta
esterna inviata, nessuna funzionalità disabilitata e nessun nuovo sviluppo avviato.
