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

String _$showDetailHash() => r'6a7efb40d5809c49e84a3b01ac23c09f2c513ec1';

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

String _$seasonDetailHash() => r'05abb7df786bae87fb61a332a5a51f15216b68f8';

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

/// Emette una mappa stagione→episodi per i soli episodi marcati come visti.
///
/// Copied from [watchedEpisodesBySeason].
@ProviderFor(watchedEpisodesBySeason)
const watchedEpisodesBySeasonProvider = WatchedEpisodesBySeasonFamily();

/// Emette una mappa stagione→episodi per i soli episodi marcati come visti.
///
/// Copied from [watchedEpisodesBySeason].
class WatchedEpisodesBySeasonFamily
    extends Family<AsyncValue<Map<int, Set<int>>>> {
  /// Emette una mappa stagione→episodi per i soli episodi marcati come visti.
  ///
  /// Copied from [watchedEpisodesBySeason].
  const WatchedEpisodesBySeasonFamily();

  /// Emette una mappa stagione→episodi per i soli episodi marcati come visti.
  ///
  /// Copied from [watchedEpisodesBySeason].
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

/// Emette una mappa stagione→episodi per i soli episodi marcati come visti.
///
/// Copied from [watchedEpisodesBySeason].
class WatchedEpisodesBySeasonProvider
    extends AutoDisposeStreamProvider<Map<int, Set<int>>> {
  /// Emette una mappa stagione→episodi per i soli episodi marcati come visti.
  ///
  /// Copied from [watchedEpisodesBySeason].
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

/// Emette il conteggio totale degli episodi visti per una serie (usato nel card).
///
/// Copied from [watchedCount].
@ProviderFor(watchedCount)
const watchedCountProvider = WatchedCountFamily();

/// Emette il conteggio totale degli episodi visti per una serie (usato nel card).
///
/// Copied from [watchedCount].
class WatchedCountFamily extends Family<AsyncValue<int>> {
  /// Emette il conteggio totale degli episodi visti per una serie (usato nel card).
  ///
  /// Copied from [watchedCount].
  const WatchedCountFamily();

  /// Emette il conteggio totale degli episodi visti per una serie (usato nel card).
  ///
  /// Copied from [watchedCount].
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

/// Emette il conteggio totale degli episodi visti per una serie (usato nel card).
///
/// Copied from [watchedCount].
class WatchedCountProvider extends AutoDisposeStreamProvider<int> {
  /// Emette il conteggio totale degli episodi visti per una serie (usato nel card).
  ///
  /// Copied from [watchedCount].
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

/// Mappa stagione→episodeCount letta dal DB locale (nessuna chiamata API).
///
/// Copied from [seasonEpisodeCounts].
@ProviderFor(seasonEpisodeCounts)
const seasonEpisodeCountsProvider = SeasonEpisodeCountsFamily();

/// Mappa stagione→episodeCount letta dal DB locale (nessuna chiamata API).
///
/// Copied from [seasonEpisodeCounts].
class SeasonEpisodeCountsFamily extends Family<AsyncValue<Map<int, int>>> {
  /// Mappa stagione→episodeCount letta dal DB locale (nessuna chiamata API).
  ///
  /// Copied from [seasonEpisodeCounts].
  const SeasonEpisodeCountsFamily();

  /// Mappa stagione→episodeCount letta dal DB locale (nessuna chiamata API).
  ///
  /// Copied from [seasonEpisodeCounts].
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

/// Mappa stagione→episodeCount letta dal DB locale (nessuna chiamata API).
///
/// Copied from [seasonEpisodeCounts].
class SeasonEpisodeCountsProvider
    extends AutoDisposeFutureProvider<Map<int, int>> {
  /// Mappa stagione→episodeCount letta dal DB locale (nessuna chiamata API).
  ///
  /// Copied from [seasonEpisodeCounts].
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

/// Emette serie+episodi visti in un'unica query JOIN (elimina gli skeleton
/// del tab "Da Vedere" causati dai N stream separati per card).
///
/// Copied from [watchingShowsWithEpisodes].
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
String _$upcomingEpisodesHash() => r'cb7d365e883671cae7542671b0dc8efe242a6ca7';

/// Calcola la lista degli episodi in uscita per tutte le serie tracciate.
/// Legge next_episode_to_air da TMDB (già incluso nella risposta di showDetail).
///
/// Copied from [upcomingEpisodes].
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
    r'68b57cbc1a73bd56d7e3e143a3e14b3e9b8e246b';

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
