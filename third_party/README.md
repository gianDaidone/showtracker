# third_party

## home_widget

Copia di [`home_widget`](https://pub.dev/packages/home_widget) **0.10.0**, usata
tramite `dependency_overrides` in `pubspec.yaml`. Differenze rispetto al pacchetto
pubblicato:

- `android/build.gradle`: `apply plugin: 'kotlin-android'` diventa
  `pluginManager.apply('kotlin-android')`. Il comportamento è identico (il plugin
  viene applicato solo se `android.builtInKotlin` è disattivato), ma Flutter
  cerca la forma `apply plugin:` con una regex e, non vedendo l'`if` intorno,
  stampava a ogni build "Your app uses the following plugins that apply Kotlin
  Gradle Plugin (KGP): home_widget".
- `pubspec.yaml`: tolti `resolution: workspace` (il pacchetto upstream vive in un
  workspace pub) e `screenshots`; copiati solo `lib/`, `android/`, `ios/`.

Segnalazione upstream: https://github.com/ABausG/home_widget/issues/461 (chiusa
come duplicato, nessuna correzione al 2026-10-07).

**Quando una nuova versione di home_widget non usa più `apply plugin:
'kotlin-android'`, cancella questa cartella e il blocco `dependency_overrides`.**
