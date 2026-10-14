// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movies_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(searchMovies)
final searchMoviesProvider = SearchMoviesFamily._();

final class SearchMoviesProvider extends $FunctionalProvider<
        AsyncValue<List<TmdbMovie>>, List<TmdbMovie>, FutureOr<List<TmdbMovie>>>
    with $FutureModifier<List<TmdbMovie>>, $FutureProvider<List<TmdbMovie>> {
  SearchMoviesProvider._(
      {required SearchMoviesFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'searchMoviesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$searchMoviesHash();

  @override
  String toString() {
    return r'searchMoviesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TmdbMovie>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<TmdbMovie>> create(Ref ref) {
    final argument = this.argument as String;
    return searchMovies(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchMoviesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchMoviesHash() => r'bdb87f3d3b2acba46200969e2eaeafa04394fc58';

final class SearchMoviesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TmdbMovie>>, String> {
  SearchMoviesFamily._()
      : super(
          retry: null,
          name: r'searchMoviesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  SearchMoviesProvider call(
    String query,
  ) =>
      SearchMoviesProvider._(argument: query, from: this);

  @override
  String toString() => r'searchMoviesProvider';
}

@ProviderFor(movieDetail)
final movieDetailProvider = MovieDetailFamily._();

final class MovieDetailProvider extends $FunctionalProvider<
        AsyncValue<TmdbMovieDetail>, TmdbMovieDetail, FutureOr<TmdbMovieDetail>>
    with $FutureModifier<TmdbMovieDetail>, $FutureProvider<TmdbMovieDetail> {
  MovieDetailProvider._(
      {required MovieDetailFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'movieDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$movieDetailHash();

  @override
  String toString() {
    return r'movieDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TmdbMovieDetail> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TmdbMovieDetail> create(Ref ref) {
    final argument = this.argument as int;
    return movieDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MovieDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$movieDetailHash() => r'6071c179926675ec602869873929d4bb2894aebe';

final class MovieDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TmdbMovieDetail>, int> {
  MovieDetailFamily._()
      : super(
          retry: null,
          name: r'movieDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  MovieDetailProvider call(
    int tmdbId,
  ) =>
      MovieDetailProvider._(argument: tmdbId, from: this);

  @override
  String toString() => r'movieDetailProvider';
}

@ProviderFor(TrackedMoviesNotifier)
final trackedMoviesProvider = TrackedMoviesNotifierProvider._();

final class TrackedMoviesNotifierProvider
    extends $StreamNotifierProvider<TrackedMoviesNotifier, List<TrackedMovy>> {
  TrackedMoviesNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'trackedMoviesProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$trackedMoviesNotifierHash();

  @$internal
  @override
  TrackedMoviesNotifier create() => TrackedMoviesNotifier();
}

String _$trackedMoviesNotifierHash() =>
    r'ac64976269de46e85b1bc994662cd23f94eaaafc';

abstract class _$TrackedMoviesNotifier
    extends $StreamNotifier<List<TrackedMovy>> {
  Stream<List<TrackedMovy>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<TrackedMovy>>, List<TrackedMovy>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<TrackedMovy>>, List<TrackedMovy>>,
        AsyncValue<List<TrackedMovy>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(upcomingMovies)
final upcomingMoviesProvider = UpcomingMoviesProvider._();

final class UpcomingMoviesProvider extends $FunctionalProvider<
        AsyncValue<List<TrackedMovy>>,
        List<TrackedMovy>,
        Stream<List<TrackedMovy>>>
    with
        $FutureModifier<List<TrackedMovy>>,
        $StreamProvider<List<TrackedMovy>> {
  UpcomingMoviesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'upcomingMoviesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$upcomingMoviesHash();

  @$internal
  @override
  $StreamProviderElement<List<TrackedMovy>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<TrackedMovy>> create(Ref ref) {
    return upcomingMovies(ref);
  }
}

String _$upcomingMoviesHash() => r'50ac20dcfcbec062e50468fda6358282ffcf6578';
