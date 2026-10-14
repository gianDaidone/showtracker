// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'games_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rawgService)
final rawgServiceProvider = RawgServiceProvider._();

final class RawgServiceProvider
    extends $FunctionalProvider<RawgService, RawgService, RawgService>
    with $Provider<RawgService> {
  RawgServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'rawgServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$rawgServiceHash();

  @$internal
  @override
  $ProviderElement<RawgService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RawgService create(Ref ref) {
    return rawgService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RawgService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RawgService>(value),
    );
  }
}

String _$rawgServiceHash() => r'8c4574e2544702cba3a70c65335652255d601b3d';

@ProviderFor(searchGames)
final searchGamesProvider = SearchGamesFamily._();

final class SearchGamesProvider extends $FunctionalProvider<
        AsyncValue<List<RawgGame>>, List<RawgGame>, FutureOr<List<RawgGame>>>
    with $FutureModifier<List<RawgGame>>, $FutureProvider<List<RawgGame>> {
  SearchGamesProvider._(
      {required SearchGamesFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'searchGamesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$searchGamesHash();

  @override
  String toString() {
    return r'searchGamesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<RawgGame>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<RawgGame>> create(Ref ref) {
    final argument = this.argument as String;
    return searchGames(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchGamesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchGamesHash() => r'43eb32c905b9f292fd21f42530849e962b78304f';

final class SearchGamesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<RawgGame>>, String> {
  SearchGamesFamily._()
      : super(
          retry: null,
          name: r'searchGamesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  SearchGamesProvider call(
    String query,
  ) =>
      SearchGamesProvider._(argument: query, from: this);

  @override
  String toString() => r'searchGamesProvider';
}

@ProviderFor(gameDetail)
final gameDetailProvider = GameDetailFamily._();

final class GameDetailProvider extends $FunctionalProvider<
        AsyncValue<RawgGameDetail>, RawgGameDetail, FutureOr<RawgGameDetail>>
    with $FutureModifier<RawgGameDetail>, $FutureProvider<RawgGameDetail> {
  GameDetailProvider._(
      {required GameDetailFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'gameDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$gameDetailHash();

  @override
  String toString() {
    return r'gameDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RawgGameDetail> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<RawgGameDetail> create(Ref ref) {
    final argument = this.argument as int;
    return gameDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GameDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gameDetailHash() => r'29cbaa877c1ef79426d904157aedff9d95be6602';

final class GameDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RawgGameDetail>, int> {
  GameDetailFamily._()
      : super(
          retry: null,
          name: r'gameDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  GameDetailProvider call(
    int rawgId,
  ) =>
      GameDetailProvider._(argument: rawgId, from: this);

  @override
  String toString() => r'gameDetailProvider';
}

@ProviderFor(gameScreenshots)
final gameScreenshotsProvider = GameScreenshotsFamily._();

final class GameScreenshotsProvider extends $FunctionalProvider<
        AsyncValue<List<String>>, List<String>, FutureOr<List<String>>>
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  GameScreenshotsProvider._(
      {required GameScreenshotsFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'gameScreenshotsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$gameScreenshotsHash();

  @override
  String toString() {
    return r'gameScreenshotsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument = this.argument as int;
    return gameScreenshots(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GameScreenshotsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gameScreenshotsHash() => r'd92c71e551b15de2cbd7f1adb0ce927f80b838f5';

final class GameScreenshotsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<String>>, int> {
  GameScreenshotsFamily._()
      : super(
          retry: null,
          name: r'gameScreenshotsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  GameScreenshotsProvider call(
    int rawgId,
  ) =>
      GameScreenshotsProvider._(argument: rawgId, from: this);

  @override
  String toString() => r'gameScreenshotsProvider';
}

@ProviderFor(steamService)
final steamServiceProvider = SteamServiceProvider._();

final class SteamServiceProvider
    extends $FunctionalProvider<SteamService, SteamService, SteamService>
    with $Provider<SteamService> {
  SteamServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'steamServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$steamServiceHash();

  @$internal
  @override
  $ProviderElement<SteamService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SteamService create(Ref ref) {
    return steamService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SteamService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SteamService>(value),
    );
  }
}

String _$steamServiceHash() => r'1c54f2f15efe29809dbf4bd09041cff7351a57e1';

/// Trailer da Steam, ricavando l'app ID dai negozi RAWG; RAWG `/movies` solo
/// come riserva, perché per molti giochi è vuoto. Un gioco senza trailer
/// restituisce una lista vuota, mai un errore: la sezione semplicemente non
/// compare.

@ProviderFor(gameTrailers)
final gameTrailersProvider = GameTrailersFamily._();

/// Trailer da Steam, ricavando l'app ID dai negozi RAWG; RAWG `/movies` solo
/// come riserva, perché per molti giochi è vuoto. Un gioco senza trailer
/// restituisce una lista vuota, mai un errore: la sezione semplicemente non
/// compare.

final class GameTrailersProvider extends $FunctionalProvider<
        AsyncValue<List<GameTrailer>>,
        List<GameTrailer>,
        FutureOr<List<GameTrailer>>>
    with
        $FutureModifier<List<GameTrailer>>,
        $FutureProvider<List<GameTrailer>> {
  /// Trailer da Steam, ricavando l'app ID dai negozi RAWG; RAWG `/movies` solo
  /// come riserva, perché per molti giochi è vuoto. Un gioco senza trailer
  /// restituisce una lista vuota, mai un errore: la sezione semplicemente non
  /// compare.
  GameTrailersProvider._(
      {required GameTrailersFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'gameTrailersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$gameTrailersHash();

  @override
  String toString() {
    return r'gameTrailersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<GameTrailer>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<GameTrailer>> create(Ref ref) {
    final argument = this.argument as int;
    return gameTrailers(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GameTrailersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gameTrailersHash() => r'2baddf9494bdd8135550d27a2758a081ade80cd5';

/// Trailer da Steam, ricavando l'app ID dai negozi RAWG; RAWG `/movies` solo
/// come riserva, perché per molti giochi è vuoto. Un gioco senza trailer
/// restituisce una lista vuota, mai un errore: la sezione semplicemente non
/// compare.

final class GameTrailersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<GameTrailer>>, int> {
  GameTrailersFamily._()
      : super(
          retry: null,
          name: r'gameTrailersProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Trailer da Steam, ricavando l'app ID dai negozi RAWG; RAWG `/movies` solo
  /// come riserva, perché per molti giochi è vuoto. Un gioco senza trailer
  /// restituisce una lista vuota, mai un errore: la sezione semplicemente non
  /// compare.

  GameTrailersProvider call(
    int rawgId,
  ) =>
      GameTrailersProvider._(argument: rawgId, from: this);

  @override
  String toString() => r'gameTrailersProvider';
}

@ProviderFor(TrackedGamesNotifier)
final trackedGamesProvider = TrackedGamesNotifierProvider._();

final class TrackedGamesNotifierProvider
    extends $StreamNotifierProvider<TrackedGamesNotifier, List<TrackedGame>> {
  TrackedGamesNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'trackedGamesProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$trackedGamesNotifierHash();

  @$internal
  @override
  TrackedGamesNotifier create() => TrackedGamesNotifier();
}

String _$trackedGamesNotifierHash() =>
    r'21db1fbc29354e6bf918c1444f5a40c24db8608b';

abstract class _$TrackedGamesNotifier
    extends $StreamNotifier<List<TrackedGame>> {
  Stream<List<TrackedGame>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<TrackedGame>>, List<TrackedGame>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<TrackedGame>>, List<TrackedGame>>,
        AsyncValue<List<TrackedGame>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
