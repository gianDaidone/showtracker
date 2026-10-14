// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rawg_auth_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RawgAuthController)
final rawgAuthControllerProvider = RawgAuthControllerProvider._();

final class RawgAuthControllerProvider
    extends $AsyncNotifierProvider<RawgAuthController, RawgAuthState> {
  RawgAuthControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'rawgAuthControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$rawgAuthControllerHash();

  @$internal
  @override
  RawgAuthController create() => RawgAuthController();
}

String _$rawgAuthControllerHash() =>
    r'8118d4ab9f28c5be0b3cdbfd2dfcfb7a68ed7dc5';

abstract class _$RawgAuthController extends $AsyncNotifier<RawgAuthState> {
  FutureOr<RawgAuthState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RawgAuthState>, RawgAuthState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<RawgAuthState>, RawgAuthState>,
        AsyncValue<RawgAuthState>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
