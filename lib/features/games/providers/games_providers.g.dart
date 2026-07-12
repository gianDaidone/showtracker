// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'games_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$rawgServiceHash() => r'c862379f1a483856e80607bf5f442af460786d52';

/// See also [rawgService].
@ProviderFor(rawgService)
final rawgServiceProvider = AutoDisposeProvider<RawgService>.internal(
  rawgService,
  name: r'rawgServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$rawgServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RawgServiceRef = AutoDisposeProviderRef<RawgService>;
String _$searchGamesHash() => r'e19ac6dbe58a41aac8ebeb2dacadde53b4dfa01b';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [searchGames].
@ProviderFor(searchGames)
const searchGamesProvider = SearchGamesFamily();

/// See also [searchGames].
class SearchGamesFamily extends Family<AsyncValue<List<RawgGame>>> {
  /// See also [searchGames].
  const SearchGamesFamily();

  /// See also [searchGames].
  SearchGamesProvider call(
    String query,
  ) {
    return SearchGamesProvider(
      query,
    );
  }

  @override
  SearchGamesProvider getProviderOverride(
    covariant SearchGamesProvider provider,
  ) {
    return call(
      provider.query,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchGamesProvider';
}

/// See also [searchGames].
class SearchGamesProvider extends AutoDisposeFutureProvider<List<RawgGame>> {
  /// See also [searchGames].
  SearchGamesProvider(
    String query,
  ) : this._internal(
          (ref) => searchGames(
            ref as SearchGamesRef,
            query,
          ),
          from: searchGamesProvider,
          name: r'searchGamesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchGamesHash,
          dependencies: SearchGamesFamily._dependencies,
          allTransitiveDependencies:
              SearchGamesFamily._allTransitiveDependencies,
          query: query,
        );

  SearchGamesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<RawgGame>> Function(SearchGamesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchGamesProvider._internal(
        (ref) => create(ref as SearchGamesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<RawgGame>> createElement() {
    return _SearchGamesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchGamesProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchGamesRef on AutoDisposeFutureProviderRef<List<RawgGame>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchGamesProviderElement
    extends AutoDisposeFutureProviderElement<List<RawgGame>>
    with SearchGamesRef {
  _SearchGamesProviderElement(super.provider);

  @override
  String get query => (origin as SearchGamesProvider).query;
}

String _$gameDetailHash() => r'43a11d9a4595b2e31bb11896806ae340c8656549';

/// See also [gameDetail].
@ProviderFor(gameDetail)
const gameDetailProvider = GameDetailFamily();

/// See also [gameDetail].
class GameDetailFamily extends Family<AsyncValue<RawgGameDetail>> {
  /// See also [gameDetail].
  const GameDetailFamily();

  /// See also [gameDetail].
  GameDetailProvider call(
    int rawgId,
  ) {
    return GameDetailProvider(
      rawgId,
    );
  }

  @override
  GameDetailProvider getProviderOverride(
    covariant GameDetailProvider provider,
  ) {
    return call(
      provider.rawgId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'gameDetailProvider';
}

/// See also [gameDetail].
class GameDetailProvider extends AutoDisposeFutureProvider<RawgGameDetail> {
  /// See also [gameDetail].
  GameDetailProvider(
    int rawgId,
  ) : this._internal(
          (ref) => gameDetail(
            ref as GameDetailRef,
            rawgId,
          ),
          from: gameDetailProvider,
          name: r'gameDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$gameDetailHash,
          dependencies: GameDetailFamily._dependencies,
          allTransitiveDependencies:
              GameDetailFamily._allTransitiveDependencies,
          rawgId: rawgId,
        );

  GameDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.rawgId,
  }) : super.internal();

  final int rawgId;

  @override
  Override overrideWith(
    FutureOr<RawgGameDetail> Function(GameDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GameDetailProvider._internal(
        (ref) => create(ref as GameDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        rawgId: rawgId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RawgGameDetail> createElement() {
    return _GameDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GameDetailProvider && other.rawgId == rawgId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, rawgId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GameDetailRef on AutoDisposeFutureProviderRef<RawgGameDetail> {
  /// The parameter `rawgId` of this provider.
  int get rawgId;
}

class _GameDetailProviderElement
    extends AutoDisposeFutureProviderElement<RawgGameDetail>
    with GameDetailRef {
  _GameDetailProviderElement(super.provider);

  @override
  int get rawgId => (origin as GameDetailProvider).rawgId;
}

String _$gameScreenshotsHash() => r'716e2dda248ce7099a9982f692947b054ef22a12';

/// See also [gameScreenshots].
@ProviderFor(gameScreenshots)
const gameScreenshotsProvider = GameScreenshotsFamily();

/// See also [gameScreenshots].
class GameScreenshotsFamily extends Family<AsyncValue<List<String>>> {
  /// See also [gameScreenshots].
  const GameScreenshotsFamily();

  /// See also [gameScreenshots].
  GameScreenshotsProvider call(
    int rawgId,
  ) {
    return GameScreenshotsProvider(
      rawgId,
    );
  }

  @override
  GameScreenshotsProvider getProviderOverride(
    covariant GameScreenshotsProvider provider,
  ) {
    return call(
      provider.rawgId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'gameScreenshotsProvider';
}

/// See also [gameScreenshots].
class GameScreenshotsProvider extends AutoDisposeFutureProvider<List<String>> {
  /// See also [gameScreenshots].
  GameScreenshotsProvider(
    int rawgId,
  ) : this._internal(
          (ref) => gameScreenshots(
            ref as GameScreenshotsRef,
            rawgId,
          ),
          from: gameScreenshotsProvider,
          name: r'gameScreenshotsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$gameScreenshotsHash,
          dependencies: GameScreenshotsFamily._dependencies,
          allTransitiveDependencies:
              GameScreenshotsFamily._allTransitiveDependencies,
          rawgId: rawgId,
        );

  GameScreenshotsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.rawgId,
  }) : super.internal();

  final int rawgId;

  @override
  Override overrideWith(
    FutureOr<List<String>> Function(GameScreenshotsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GameScreenshotsProvider._internal(
        (ref) => create(ref as GameScreenshotsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        rawgId: rawgId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<String>> createElement() {
    return _GameScreenshotsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GameScreenshotsProvider && other.rawgId == rawgId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, rawgId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GameScreenshotsRef on AutoDisposeFutureProviderRef<List<String>> {
  /// The parameter `rawgId` of this provider.
  int get rawgId;
}

class _GameScreenshotsProviderElement
    extends AutoDisposeFutureProviderElement<List<String>>
    with GameScreenshotsRef {
  _GameScreenshotsProviderElement(super.provider);

  @override
  int get rawgId => (origin as GameScreenshotsProvider).rawgId;
}

String _$trackedGamesNotifierHash() =>
    r'10d95cd99fb30e326fba1a11cb70e33db0e91fbd';

/// See also [TrackedGamesNotifier].
@ProviderFor(TrackedGamesNotifier)
final trackedGamesNotifierProvider = AutoDisposeStreamNotifierProvider<
    TrackedGamesNotifier, List<TrackedGame>>.internal(
  TrackedGamesNotifier.new,
  name: r'trackedGamesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trackedGamesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TrackedGamesNotifier = AutoDisposeStreamNotifier<List<TrackedGame>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
