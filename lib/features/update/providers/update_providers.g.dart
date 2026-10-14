// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(githubReleaseService)
final githubReleaseServiceProvider = GithubReleaseServiceProvider._();

final class GithubReleaseServiceProvider extends $FunctionalProvider<
    GithubReleaseService,
    GithubReleaseService,
    GithubReleaseService> with $Provider<GithubReleaseService> {
  GithubReleaseServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'githubReleaseServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$githubReleaseServiceHash();

  @$internal
  @override
  $ProviderElement<GithubReleaseService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GithubReleaseService create(Ref ref) {
    return githubReleaseService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GithubReleaseService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GithubReleaseService>(value),
    );
  }
}

String _$githubReleaseServiceHash() =>
    r'8a190ac71cde4c89a332c1f061cb2491d6e87c42';

@ProviderFor(packageInfo)
final packageInfoProvider = PackageInfoProvider._();

final class PackageInfoProvider extends $FunctionalProvider<
        AsyncValue<PackageInfo>, PackageInfo, FutureOr<PackageInfo>>
    with $FutureModifier<PackageInfo>, $FutureProvider<PackageInfo> {
  PackageInfoProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'packageInfoProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$packageInfoHash();

  @$internal
  @override
  $FutureProviderElement<PackageInfo> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PackageInfo> create(Ref ref) {
    return packageInfo(ref);
  }
}

String _$packageInfoHash() => r'f1c17d5174896e536210506ee5ade32f9766a6b9';
