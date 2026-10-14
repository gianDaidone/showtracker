// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tmdbService)
final tmdbServiceProvider = TmdbServiceProvider._();

final class TmdbServiceProvider
    extends $FunctionalProvider<TmdbService, TmdbService, TmdbService>
    with $Provider<TmdbService> {
  TmdbServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'tmdbServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$tmdbServiceHash();

  @$internal
  @override
  $ProviderElement<TmdbService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TmdbService create(Ref ref) {
    return tmdbService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TmdbService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TmdbService>(value),
    );
  }
}

String _$tmdbServiceHash() => r'96b81faf1b58f6894c39baadbcb296eea26857ad';

@ProviderFor(anilistService)
final anilistServiceProvider = AnilistServiceProvider._();

final class AnilistServiceProvider
    extends $FunctionalProvider<AniListService, AniListService, AniListService>
    with $Provider<AniListService> {
  AnilistServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'anilistServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$anilistServiceHash();

  @$internal
  @override
  $ProviderElement<AniListService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AniListService create(Ref ref) {
    return anilistService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AniListService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AniListService>(value),
    );
  }
}

String _$anilistServiceHash() => r'7051fdf02611315d0463ca9efbc8535cefca56f8';

@ProviderFor(yunaService)
final yunaServiceProvider = YunaServiceProvider._();

final class YunaServiceProvider
    extends $FunctionalProvider<YunaService, YunaService, YunaService>
    with $Provider<YunaService> {
  YunaServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'yunaServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$yunaServiceHash();

  @$internal
  @override
  $ProviderElement<YunaService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  YunaService create(Ref ref) {
    return yunaService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(YunaService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<YunaService>(value),
    );
  }
}

String _$yunaServiceHash() => r'667288d87224ed936eb9abc07c6242eed4a7e58c';

@ProviderFor(searchShows)
final searchShowsProvider = SearchShowsFamily._();

final class SearchShowsProvider extends $FunctionalProvider<
        AsyncValue<List<TmdbShow>>, List<TmdbShow>, FutureOr<List<TmdbShow>>>
    with $FutureModifier<List<TmdbShow>>, $FutureProvider<List<TmdbShow>> {
  SearchShowsProvider._(
      {required SearchShowsFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'searchShowsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$searchShowsHash();

  @override
  String toString() {
    return r'searchShowsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TmdbShow>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<TmdbShow>> create(Ref ref) {
    final argument = this.argument as String;
    return searchShows(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchShowsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchShowsHash() => r'7ed4d9418aa9bafdb0cf53325306d77f6b3833dd';

final class SearchShowsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TmdbShow>>, String> {
  SearchShowsFamily._()
      : super(
          retry: null,
          name: r'searchShowsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  SearchShowsProvider call(
    String query,
  ) =>
      SearchShowsProvider._(argument: query, from: this);

  @override
  String toString() => r'searchShowsProvider';
}

@ProviderFor(animeData)
final animeDataProvider = AnimeDataFamily._();

final class AnimeDataProvider extends $FunctionalProvider<
        AsyncValue<List<NormalizedAnimeSeason>?>,
        List<NormalizedAnimeSeason>?,
        FutureOr<List<NormalizedAnimeSeason>?>>
    with
        $FutureModifier<List<NormalizedAnimeSeason>?>,
        $FutureProvider<List<NormalizedAnimeSeason>?> {
  AnimeDataProvider._(
      {required AnimeDataFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'animeDataProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$animeDataHash();

  @override
  String toString() {
    return r'animeDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<NormalizedAnimeSeason>?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<NormalizedAnimeSeason>?> create(Ref ref) {
    final argument = this.argument as int;
    return animeData(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AnimeDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$animeDataHash() => r'f2ced8dfaa2550ca4f77e3f405fa9e690294f6ab';

final class AnimeDataFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<NormalizedAnimeSeason>?>, int> {
  AnimeDataFamily._()
      : super(
          retry: null,
          name: r'animeDataProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  AnimeDataProvider call(
    int tmdbId,
  ) =>
      AnimeDataProvider._(argument: tmdbId, from: this);

  @override
  String toString() => r'animeDataProvider';
}

@ProviderFor(showDetail)
final showDetailProvider = ShowDetailFamily._();

final class ShowDetailProvider extends $FunctionalProvider<
        AsyncValue<TmdbShowDetail>, TmdbShowDetail, FutureOr<TmdbShowDetail>>
    with $FutureModifier<TmdbShowDetail>, $FutureProvider<TmdbShowDetail> {
  ShowDetailProvider._(
      {required ShowDetailFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'showDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$showDetailHash();

  @override
  String toString() {
    return r'showDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TmdbShowDetail> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TmdbShowDetail> create(Ref ref) {
    final argument = this.argument as int;
    return showDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ShowDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$showDetailHash() => r'8c087a74d235c01d71d4da29cbb0bd909c63e314';

final class ShowDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TmdbShowDetail>, int> {
  ShowDetailFamily._()
      : super(
          retry: null,
          name: r'showDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  ShowDetailProvider call(
    int tmdbId,
  ) =>
      ShowDetailProvider._(argument: tmdbId, from: this);

  @override
  String toString() => r'showDetailProvider';
}

@ProviderFor(seasonDetail)
final seasonDetailProvider = SeasonDetailFamily._();

final class SeasonDetailProvider extends $FunctionalProvider<
        AsyncValue<TmdbSeason>, TmdbSeason, FutureOr<TmdbSeason>>
    with $FutureModifier<TmdbSeason>, $FutureProvider<TmdbSeason> {
  SeasonDetailProvider._(
      {required SeasonDetailFamily super.from,
      required ({
        int showId,
        int seasonNumber,
      })
          super.argument})
      : super(
          retry: null,
          name: r'seasonDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$seasonDetailHash();

  @override
  String toString() {
    return r'seasonDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<TmdbSeason> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TmdbSeason> create(Ref ref) {
    final argument = this.argument as ({
      int showId,
      int seasonNumber,
    });
    return seasonDetail(
      ref,
      showId: argument.showId,
      seasonNumber: argument.seasonNumber,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SeasonDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$seasonDetailHash() => r'95927f7a72a3cce887dfc55d4dddb45efc8959d6';

final class SeasonDetailFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<TmdbSeason>,
            ({
              int showId,
              int seasonNumber,
            })> {
  SeasonDetailFamily._()
      : super(
          retry: null,
          name: r'seasonDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  SeasonDetailProvider call({
    required int showId,
    required int seasonNumber,
  }) =>
      SeasonDetailProvider._(argument: (
        showId: showId,
        seasonNumber: seasonNumber,
      ), from: this);

  @override
  String toString() => r'seasonDetailProvider';
}

@ProviderFor(TrackedShowsNotifier)
final trackedShowsProvider = TrackedShowsNotifierProvider._();

final class TrackedShowsNotifierProvider
    extends $StreamNotifierProvider<TrackedShowsNotifier, List<TrackedShow>> {
  TrackedShowsNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'trackedShowsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$trackedShowsNotifierHash();

  @$internal
  @override
  TrackedShowsNotifier create() => TrackedShowsNotifier();
}

String _$trackedShowsNotifierHash() =>
    r'5d25f1b6ab8877e4de0293ae098ef4240ef4bef8';

abstract class _$TrackedShowsNotifier
    extends $StreamNotifier<List<TrackedShow>> {
  Stream<List<TrackedShow>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<TrackedShow>>, List<TrackedShow>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<TrackedShow>>, List<TrackedShow>>,
        AsyncValue<List<TrackedShow>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(watchedEpisodesBySeason)
final watchedEpisodesBySeasonProvider = WatchedEpisodesBySeasonFamily._();

final class WatchedEpisodesBySeasonProvider extends $FunctionalProvider<
        AsyncValue<Map<int, Set<int>>>,
        Map<int, Set<int>>,
        Stream<Map<int, Set<int>>>>
    with
        $FutureModifier<Map<int, Set<int>>>,
        $StreamProvider<Map<int, Set<int>>> {
  WatchedEpisodesBySeasonProvider._(
      {required WatchedEpisodesBySeasonFamily super.from,
      required int super.argument})
      : super(
          retry: null,
          name: r'watchedEpisodesBySeasonProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$watchedEpisodesBySeasonHash();

  @override
  String toString() {
    return r'watchedEpisodesBySeasonProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<int, Set<int>>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Map<int, Set<int>>> create(Ref ref) {
    final argument = this.argument as int;
    return watchedEpisodesBySeason(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WatchedEpisodesBySeasonProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchedEpisodesBySeasonHash() =>
    r'7e8e40542edf4afa55c0195ad91ebc63bec09c29';

final class WatchedEpisodesBySeasonFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<int, Set<int>>>, int> {
  WatchedEpisodesBySeasonFamily._()
      : super(
          retry: null,
          name: r'watchedEpisodesBySeasonProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  WatchedEpisodesBySeasonProvider call(
    int dbShowId,
  ) =>
      WatchedEpisodesBySeasonProvider._(argument: dbShowId, from: this);

  @override
  String toString() => r'watchedEpisodesBySeasonProvider';
}

@ProviderFor(watchedCount)
final watchedCountProvider = WatchedCountFamily._();

final class WatchedCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  WatchedCountProvider._(
      {required WatchedCountFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'watchedCountProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$watchedCountHash();

  @override
  String toString() {
    return r'watchedCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as int;
    return watchedCount(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WatchedCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchedCountHash() => r'f73e0ce27c0438b7def6a205a803e265ca6c6da3';

final class WatchedCountFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, int> {
  WatchedCountFamily._()
      : super(
          retry: null,
          name: r'watchedCountProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  WatchedCountProvider call(
    int dbShowId,
  ) =>
      WatchedCountProvider._(argument: dbShowId, from: this);

  @override
  String toString() => r'watchedCountProvider';
}

@ProviderFor(seasonEpisodeCounts)
final seasonEpisodeCountsProvider = SeasonEpisodeCountsFamily._();

final class SeasonEpisodeCountsProvider extends $FunctionalProvider<
        AsyncValue<Map<int, int>>, Map<int, int>, FutureOr<Map<int, int>>>
    with $FutureModifier<Map<int, int>>, $FutureProvider<Map<int, int>> {
  SeasonEpisodeCountsProvider._(
      {required SeasonEpisodeCountsFamily super.from,
      required int super.argument})
      : super(
          retry: null,
          name: r'seasonEpisodeCountsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$seasonEpisodeCountsHash();

  @override
  String toString() {
    return r'seasonEpisodeCountsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<int, int>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Map<int, int>> create(Ref ref) {
    final argument = this.argument as int;
    return seasonEpisodeCounts(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SeasonEpisodeCountsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$seasonEpisodeCountsHash() =>
    r'9f69d5655b139e66722dde187700ad084cee8829';

final class SeasonEpisodeCountsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<int, int>>, int> {
  SeasonEpisodeCountsFamily._()
      : super(
          retry: null,
          name: r'seasonEpisodeCountsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  SeasonEpisodeCountsProvider call(
    int dbShowId,
  ) =>
      SeasonEpisodeCountsProvider._(argument: dbShowId, from: this);

  @override
  String toString() => r'seasonEpisodeCountsProvider';
}

@ProviderFor(watchingShowsWithEpisodes)
final watchingShowsWithEpisodesProvider = WatchingShowsWithEpisodesProvider._();

final class WatchingShowsWithEpisodesProvider extends $FunctionalProvider<
        AsyncValue<List<ShowWithWatchedEpisodes>>,
        List<ShowWithWatchedEpisodes>,
        Stream<List<ShowWithWatchedEpisodes>>>
    with
        $FutureModifier<List<ShowWithWatchedEpisodes>>,
        $StreamProvider<List<ShowWithWatchedEpisodes>> {
  WatchingShowsWithEpisodesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'watchingShowsWithEpisodesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$watchingShowsWithEpisodesHash();

  @$internal
  @override
  $StreamProviderElement<List<ShowWithWatchedEpisodes>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<ShowWithWatchedEpisodes>> create(Ref ref) {
    return watchingShowsWithEpisodes(ref);
  }
}

String _$watchingShowsWithEpisodesHash() =>
    r'6d0312e43b58074d1e9e557aeb43c9e8eb724393';

@ProviderFor(upcomingEpisodes)
final upcomingEpisodesProvider = UpcomingEpisodesProvider._();

final class UpcomingEpisodesProvider extends $FunctionalProvider<
        AsyncValue<List<UpcomingEpisodeInfo>>,
        List<UpcomingEpisodeInfo>,
        FutureOr<List<UpcomingEpisodeInfo>>>
    with
        $FutureModifier<List<UpcomingEpisodeInfo>>,
        $FutureProvider<List<UpcomingEpisodeInfo>> {
  UpcomingEpisodesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'upcomingEpisodesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$upcomingEpisodesHash();

  @$internal
  @override
  $FutureProviderElement<List<UpcomingEpisodeInfo>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<UpcomingEpisodeInfo>> create(Ref ref) {
    return upcomingEpisodes(ref);
  }
}

String _$upcomingEpisodesHash() => r'994a9f36a80f3d731f3a6fb22a663052ea5cd8f4';
