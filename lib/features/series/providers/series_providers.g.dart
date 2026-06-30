// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tmdbServiceHash() => r'fde72afa43daff9ce1468f6c4438dab0b68b21b6';

/// See also [tmdbService].
@ProviderFor(tmdbService)
final tmdbServiceProvider = AutoDisposeProvider<TmdbService>.internal(
  tmdbService,
  name: r'tmdbServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tmdbServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TmdbServiceRef = AutoDisposeProviderRef<TmdbService>;
String _$anilistServiceHash() => r'cad02c8a6f80ade99617c14952a5793181e4a192';

/// See also [anilistService].
@ProviderFor(anilistService)
final anilistServiceProvider = Provider<AniListService>.internal(
  anilistService,
  name: r'anilistServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$anilistServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnilistServiceRef = ProviderRef<AniListService>;
String _$yunaServiceHash() => r'30ccc90f3b4c221c37ed18f6ff5d641bd726ab2e';

/// See also [yunaService].
@ProviderFor(yunaService)
final yunaServiceProvider = AutoDisposeProvider<YunaService>.internal(
  yunaService,
  name: r'yunaServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$yunaServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef YunaServiceRef = AutoDisposeProviderRef<YunaService>;
String _$searchShowsHash() => r'b478f10ccb1ca66de8c8b6c2f788f885454bf83e';

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

/// See also [searchShows].
@ProviderFor(searchShows)
const searchShowsProvider = SearchShowsFamily();

/// See also [searchShows].
class SearchShowsFamily extends Family<AsyncValue<List<TmdbShow>>> {
  /// See also [searchShows].
  const SearchShowsFamily();

  /// See also [searchShows].
  SearchShowsProvider call(
    String query,
  ) {
    return SearchShowsProvider(
      query,
    );
  }

  @override
  SearchShowsProvider getProviderOverride(
    covariant SearchShowsProvider provider,
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
  String? get name => r'searchShowsProvider';
}

/// See also [searchShows].
class SearchShowsProvider extends AutoDisposeFutureProvider<List<TmdbShow>> {
  /// See also [searchShows].
  SearchShowsProvider(
    String query,
  ) : this._internal(
          (ref) => searchShows(
            ref as SearchShowsRef,
            query,
          ),
          from: searchShowsProvider,
          name: r'searchShowsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchShowsHash,
          dependencies: SearchShowsFamily._dependencies,
          allTransitiveDependencies:
              SearchShowsFamily._allTransitiveDependencies,
          query: query,
        );

  SearchShowsProvider._internal(
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
    FutureOr<List<TmdbShow>> Function(SearchShowsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchShowsProvider._internal(
        (ref) => create(ref as SearchShowsRef),
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
  AutoDisposeFutureProviderElement<List<TmdbShow>> createElement() {
    return _SearchShowsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchShowsProvider && other.query == query;
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
mixin SearchShowsRef on AutoDisposeFutureProviderRef<List<TmdbShow>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchShowsProviderElement
    extends AutoDisposeFutureProviderElement<List<TmdbShow>>
    with SearchShowsRef {
  _SearchShowsProviderElement(super.provider);

  @override
  String get query => (origin as SearchShowsProvider).query;
}

String _$animeDataHash() => r'c3398489bd63f8c691e29f44b833d6f16c0059d1';

/// See also [animeData].
@ProviderFor(animeData)
const animeDataProvider = AnimeDataFamily();

/// See also [animeData].
class AnimeDataFamily extends Family<AsyncValue<List<NormalizedAnimeSeason>?>> {
  /// See also [animeData].
  const AnimeDataFamily();

  /// See also [animeData].
  AnimeDataProvider call(
    int tmdbId,
  ) {
    return AnimeDataProvider(
      tmdbId,
    );
  }

  @override
  AnimeDataProvider getProviderOverride(
    covariant AnimeDataProvider provider,
  ) {
    return call(
      provider.tmdbId,
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
  String? get name => r'animeDataProvider';
}

/// See also [animeData].
class AnimeDataProvider
    extends AutoDisposeFutureProvider<List<NormalizedAnimeSeason>?> {
  /// See also [animeData].
  AnimeDataProvider(
    int tmdbId,
  ) : this._internal(
          (ref) => animeData(
            ref as AnimeDataRef,
            tmdbId,
          ),
          from: animeDataProvider,
          name: r'animeDataProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$animeDataHash,
          dependencies: AnimeDataFamily._dependencies,
          allTransitiveDependencies: AnimeDataFamily._allTransitiveDependencies,
          tmdbId: tmdbId,
        );

  AnimeDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tmdbId,
  }) : super.internal();

  final int tmdbId;

  @override
  Override overrideWith(
    FutureOr<List<NormalizedAnimeSeason>?> Function(AnimeDataRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnimeDataProvider._internal(
        (ref) => create(ref as AnimeDataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tmdbId: tmdbId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<NormalizedAnimeSeason>?>
      createElement() {
    return _AnimeDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnimeDataProvider && other.tmdbId == tmdbId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tmdbId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnimeDataRef
    on AutoDisposeFutureProviderRef<List<NormalizedAnimeSeason>?> {
  /// The parameter `tmdbId` of this provider.
  int get tmdbId;
}

class _AnimeDataProviderElement
    extends AutoDisposeFutureProviderElement<List<NormalizedAnimeSeason>?>
    with AnimeDataRef {
  _AnimeDataProviderElement(super.provider);

  @override
  int get tmdbId => (origin as AnimeDataProvider).tmdbId;
}

String _$showDetailHash() => r'4cdbb471ff887b94c8dc8ab65d866db7bd77769c';

/// See also [showDetail].
@ProviderFor(showDetail)
const showDetailProvider = ShowDetailFamily();

/// See also [showDetail].
class ShowDetailFamily extends Family<AsyncValue<TmdbShowDetail>> {
  /// See also [showDetail].
  const ShowDetailFamily();

  /// See also [showDetail].
  ShowDetailProvider call(
    int tmdbId,
  ) {
    return ShowDetailProvider(
      tmdbId,
    );
  }

  @override
  ShowDetailProvider getProviderOverride(
    covariant ShowDetailProvider provider,
  ) {
    return call(
      provider.tmdbId,
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
  String? get name => r'showDetailProvider';
}

/// See also [showDetail].
class ShowDetailProvider extends AutoDisposeFutureProvider<TmdbShowDetail> {
  /// See also [showDetail].
  ShowDetailProvider(
    int tmdbId,
  ) : this._internal(
          (ref) => showDetail(
            ref as ShowDetailRef,
            tmdbId,
          ),
          from: showDetailProvider,
          name: r'showDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$showDetailHash,
          dependencies: ShowDetailFamily._dependencies,
          allTransitiveDependencies:
              ShowDetailFamily._allTransitiveDependencies,
          tmdbId: tmdbId,
        );

  ShowDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tmdbId,
  }) : super.internal();

  final int tmdbId;

  @override
  Override overrideWith(
    FutureOr<TmdbShowDetail> Function(ShowDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShowDetailProvider._internal(
        (ref) => create(ref as ShowDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tmdbId: tmdbId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TmdbShowDetail> createElement() {
    return _ShowDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShowDetailProvider && other.tmdbId == tmdbId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tmdbId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShowDetailRef on AutoDisposeFutureProviderRef<TmdbShowDetail> {
  /// The parameter `tmdbId` of this provider.
  int get tmdbId;
}

class _ShowDetailProviderElement
    extends AutoDisposeFutureProviderElement<TmdbShowDetail>
    with ShowDetailRef {
  _ShowDetailProviderElement(super.provider);

  @override
  int get tmdbId => (origin as ShowDetailProvider).tmdbId;
}

String _$seasonDetailHash() => r'23cf1c87fcf4354cef2c2aa359611a1dc5f8983a';

/// See also [seasonDetail].
@ProviderFor(seasonDetail)
const seasonDetailProvider = SeasonDetailFamily();

/// See also [seasonDetail].
class SeasonDetailFamily extends Family<AsyncValue<TmdbSeason>> {
  /// See also [seasonDetail].
  const SeasonDetailFamily();

  /// See also [seasonDetail].
  SeasonDetailProvider call({
    required int showId,
    required int seasonNumber,
  }) {
    return SeasonDetailProvider(
      showId: showId,
      seasonNumber: seasonNumber,
    );
  }

  @override
  SeasonDetailProvider getProviderOverride(
    covariant SeasonDetailProvider provider,
  ) {
    return call(
      showId: provider.showId,
      seasonNumber: provider.seasonNumber,
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
  String? get name => r'seasonDetailProvider';
}

/// See also [seasonDetail].
class SeasonDetailProvider extends AutoDisposeFutureProvider<TmdbSeason> {
  /// See also [seasonDetail].
  SeasonDetailProvider({
    required int showId,
    required int seasonNumber,
  }) : this._internal(
          (ref) => seasonDetail(
            ref as SeasonDetailRef,
            showId: showId,
            seasonNumber: seasonNumber,
          ),
          from: seasonDetailProvider,
          name: r'seasonDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$seasonDetailHash,
          dependencies: SeasonDetailFamily._dependencies,
          allTransitiveDependencies:
              SeasonDetailFamily._allTransitiveDependencies,
          showId: showId,
          seasonNumber: seasonNumber,
        );

  SeasonDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.showId,
    required this.seasonNumber,
  }) : super.internal();

  final int showId;
  final int seasonNumber;

  @override
  Override overrideWith(
    FutureOr<TmdbSeason> Function(SeasonDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SeasonDetailProvider._internal(
        (ref) => create(ref as SeasonDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        showId: showId,
        seasonNumber: seasonNumber,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TmdbSeason> createElement() {
    return _SeasonDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SeasonDetailProvider &&
        other.showId == showId &&
        other.seasonNumber == seasonNumber;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, showId.hashCode);
    hash = _SystemHash.combine(hash, seasonNumber.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SeasonDetailRef on AutoDisposeFutureProviderRef<TmdbSeason> {
  /// The parameter `showId` of this provider.
  int get showId;

  /// The parameter `seasonNumber` of this provider.
  int get seasonNumber;
}

class _SeasonDetailProviderElement
    extends AutoDisposeFutureProviderElement<TmdbSeason> with SeasonDetailRef {
  _SeasonDetailProviderElement(super.provider);

  @override
  int get showId => (origin as SeasonDetailProvider).showId;
  @override
  int get seasonNumber => (origin as SeasonDetailProvider).seasonNumber;
}

String _$watchedEpisodesBySeasonHash() =>
    r'eed4d8ae81e39a0b3218270cbe597ac9b56b7502';

/// See also [watchedEpisodesBySeason].
@ProviderFor(watchedEpisodesBySeason)
const watchedEpisodesBySeasonProvider = WatchedEpisodesBySeasonFamily();

/// See also [watchedEpisodesBySeason].
class WatchedEpisodesBySeasonFamily
    extends Family<AsyncValue<Map<int, Set<int>>>> {
  /// See also [watchedEpisodesBySeason].
  const WatchedEpisodesBySeasonFamily();

  /// See also [watchedEpisodesBySeason].
  WatchedEpisodesBySeasonProvider call(
    int dbShowId,
  ) {
    return WatchedEpisodesBySeasonProvider(
      dbShowId,
    );
  }

  @override
  WatchedEpisodesBySeasonProvider getProviderOverride(
    covariant WatchedEpisodesBySeasonProvider provider,
  ) {
    return call(
      provider.dbShowId,
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
  String? get name => r'watchedEpisodesBySeasonProvider';
}

/// See also [watchedEpisodesBySeason].
class WatchedEpisodesBySeasonProvider
    extends AutoDisposeStreamProvider<Map<int, Set<int>>> {
  /// See also [watchedEpisodesBySeason].
  WatchedEpisodesBySeasonProvider(
    int dbShowId,
  ) : this._internal(
          (ref) => watchedEpisodesBySeason(
            ref as WatchedEpisodesBySeasonRef,
            dbShowId,
          ),
          from: watchedEpisodesBySeasonProvider,
          name: r'watchedEpisodesBySeasonProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$watchedEpisodesBySeasonHash,
          dependencies: WatchedEpisodesBySeasonFamily._dependencies,
          allTransitiveDependencies:
              WatchedEpisodesBySeasonFamily._allTransitiveDependencies,
          dbShowId: dbShowId,
        );

  WatchedEpisodesBySeasonProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dbShowId,
  }) : super.internal();

  final int dbShowId;

  @override
  Override overrideWith(
    Stream<Map<int, Set<int>>> Function(WatchedEpisodesBySeasonRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchedEpisodesBySeasonProvider._internal(
        (ref) => create(ref as WatchedEpisodesBySeasonRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dbShowId: dbShowId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<Map<int, Set<int>>> createElement() {
    return _WatchedEpisodesBySeasonProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchedEpisodesBySeasonProvider &&
        other.dbShowId == dbShowId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dbShowId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WatchedEpisodesBySeasonRef
    on AutoDisposeStreamProviderRef<Map<int, Set<int>>> {
  /// The parameter `dbShowId` of this provider.
  int get dbShowId;
}

class _WatchedEpisodesBySeasonProviderElement
    extends AutoDisposeStreamProviderElement<Map<int, Set<int>>>
    with WatchedEpisodesBySeasonRef {
  _WatchedEpisodesBySeasonProviderElement(super.provider);

  @override
  int get dbShowId => (origin as WatchedEpisodesBySeasonProvider).dbShowId;
}

String _$watchedCountHash() => r'4fae0b2b7d28bd88218200a9c13e9bc32918bdd5';

/// See also [watchedCount].
@ProviderFor(watchedCount)
const watchedCountProvider = WatchedCountFamily();

/// See also [watchedCount].
class WatchedCountFamily extends Family<AsyncValue<int>> {
  /// See also [watchedCount].
  const WatchedCountFamily();

  /// See also [watchedCount].
  WatchedCountProvider call(
    int dbShowId,
  ) {
    return WatchedCountProvider(
      dbShowId,
    );
  }

  @override
  WatchedCountProvider getProviderOverride(
    covariant WatchedCountProvider provider,
  ) {
    return call(
      provider.dbShowId,
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
  String? get name => r'watchedCountProvider';
}

/// See also [watchedCount].
class WatchedCountProvider extends AutoDisposeStreamProvider<int> {
  /// See also [watchedCount].
  WatchedCountProvider(
    int dbShowId,
  ) : this._internal(
          (ref) => watchedCount(
            ref as WatchedCountRef,
            dbShowId,
          ),
          from: watchedCountProvider,
          name: r'watchedCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$watchedCountHash,
          dependencies: WatchedCountFamily._dependencies,
          allTransitiveDependencies:
              WatchedCountFamily._allTransitiveDependencies,
          dbShowId: dbShowId,
        );

  WatchedCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dbShowId,
  }) : super.internal();

  final int dbShowId;

  @override
  Override overrideWith(
    Stream<int> Function(WatchedCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchedCountProvider._internal(
        (ref) => create(ref as WatchedCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dbShowId: dbShowId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<int> createElement() {
    return _WatchedCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchedCountProvider && other.dbShowId == dbShowId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dbShowId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WatchedCountRef on AutoDisposeStreamProviderRef<int> {
  /// The parameter `dbShowId` of this provider.
  int get dbShowId;
}

class _WatchedCountProviderElement extends AutoDisposeStreamProviderElement<int>
    with WatchedCountRef {
  _WatchedCountProviderElement(super.provider);

  @override
  int get dbShowId => (origin as WatchedCountProvider).dbShowId;
}

String _$seasonEpisodeCountsHash() =>
    r'1f4601adce963053f5915980ce8504a85557fff8';

/// See also [seasonEpisodeCounts].
@ProviderFor(seasonEpisodeCounts)
const seasonEpisodeCountsProvider = SeasonEpisodeCountsFamily();

/// See also [seasonEpisodeCounts].
class SeasonEpisodeCountsFamily extends Family<AsyncValue<Map<int, int>>> {
  /// See also [seasonEpisodeCounts].
  const SeasonEpisodeCountsFamily();

  /// See also [seasonEpisodeCounts].
  SeasonEpisodeCountsProvider call(
    int dbShowId,
  ) {
    return SeasonEpisodeCountsProvider(
      dbShowId,
    );
  }

  @override
  SeasonEpisodeCountsProvider getProviderOverride(
    covariant SeasonEpisodeCountsProvider provider,
  ) {
    return call(
      provider.dbShowId,
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
  String? get name => r'seasonEpisodeCountsProvider';
}

/// See also [seasonEpisodeCounts].
class SeasonEpisodeCountsProvider
    extends AutoDisposeFutureProvider<Map<int, int>> {
  /// See also [seasonEpisodeCounts].
  SeasonEpisodeCountsProvider(
    int dbShowId,
  ) : this._internal(
          (ref) => seasonEpisodeCounts(
            ref as SeasonEpisodeCountsRef,
            dbShowId,
          ),
          from: seasonEpisodeCountsProvider,
          name: r'seasonEpisodeCountsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$seasonEpisodeCountsHash,
          dependencies: SeasonEpisodeCountsFamily._dependencies,
          allTransitiveDependencies:
              SeasonEpisodeCountsFamily._allTransitiveDependencies,
          dbShowId: dbShowId,
        );

  SeasonEpisodeCountsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dbShowId,
  }) : super.internal();

  final int dbShowId;

  @override
  Override overrideWith(
    FutureOr<Map<int, int>> Function(SeasonEpisodeCountsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SeasonEpisodeCountsProvider._internal(
        (ref) => create(ref as SeasonEpisodeCountsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dbShowId: dbShowId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<int, int>> createElement() {
    return _SeasonEpisodeCountsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SeasonEpisodeCountsProvider && other.dbShowId == dbShowId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dbShowId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SeasonEpisodeCountsRef on AutoDisposeFutureProviderRef<Map<int, int>> {
  /// The parameter `dbShowId` of this provider.
  int get dbShowId;
}

class _SeasonEpisodeCountsProviderElement
    extends AutoDisposeFutureProviderElement<Map<int, int>>
    with SeasonEpisodeCountsRef {
  _SeasonEpisodeCountsProviderElement(super.provider);

  @override
  int get dbShowId => (origin as SeasonEpisodeCountsProvider).dbShowId;
}

String _$watchingShowsWithEpisodesHash() =>
    r'f09eebcbc7a15c3d83e9882916ca088711690279';

/// See also [watchingShowsWithEpisodes].
@ProviderFor(watchingShowsWithEpisodes)
final watchingShowsWithEpisodesProvider =
    AutoDisposeStreamProvider<List<ShowWithWatchedEpisodes>>.internal(
  watchingShowsWithEpisodes,
  name: r'watchingShowsWithEpisodesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$watchingShowsWithEpisodesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WatchingShowsWithEpisodesRef
    = AutoDisposeStreamProviderRef<List<ShowWithWatchedEpisodes>>;
String _$upcomingEpisodesHash() => r'35e9bbac9aacaed09bcfeb0de21479b42aa29f29';

/// See also [upcomingEpisodes].
@ProviderFor(upcomingEpisodes)
final upcomingEpisodesProvider =
    AutoDisposeFutureProvider<List<UpcomingEpisodeInfo>>.internal(
  upcomingEpisodes,
  name: r'upcomingEpisodesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$upcomingEpisodesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UpcomingEpisodesRef
    = AutoDisposeFutureProviderRef<List<UpcomingEpisodeInfo>>;
String _$trackedShowsNotifierHash() =>
    r'c8361e1a045de45bb45ebdcb57fac549a9db21cb';

/// See also [TrackedShowsNotifier].
@ProviderFor(TrackedShowsNotifier)
final trackedShowsNotifierProvider = AutoDisposeStreamNotifierProvider<
    TrackedShowsNotifier, List<TrackedShow>>.internal(
  TrackedShowsNotifier.new,
  name: r'trackedShowsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trackedShowsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TrackedShowsNotifier = AutoDisposeStreamNotifier<List<TrackedShow>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
