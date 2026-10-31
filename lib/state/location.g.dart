// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 当前位置：进发现页、附近页时定位一次。还没问过系统时不主动弹权限框，先由页面给说明。

@ProviderFor(CurrentLocation)
final currentLocationProvider = CurrentLocationProvider._();

/// 当前位置：进发现页、附近页时定位一次。还没问过系统时不主动弹权限框，先由页面给说明。
final class CurrentLocationProvider
    extends $NotifierProvider<CurrentLocation, LocationState> {
  /// 当前位置：进发现页、附近页时定位一次。还没问过系统时不主动弹权限框，先由页面给说明。
  CurrentLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentLocationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentLocationHash();

  @$internal
  @override
  CurrentLocation create() => CurrentLocation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationState>(value),
    );
  }
}

String _$currentLocationHash() => r'ca4f821594b9a7b17082e936270ff9f04c3cdb77';

/// 当前位置：进发现页、附近页时定位一次。还没问过系统时不主动弹权限框，先由页面给说明。

abstract class _$CurrentLocation extends $Notifier<LocationState> {
  LocationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LocationState, LocationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocationState, LocationState>,
              LocationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
