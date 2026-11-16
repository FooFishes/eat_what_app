// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 维护当前设备位置, 在进入发现页与附近页时触发定位更新.
///
/// 若尚未申请过系统定位权限, 不会主动弹出系统授权框, 而是交由页面先行展示权限说明.

@ProviderFor(CurrentLocation)
final currentLocationProvider = CurrentLocationProvider._();

/// 维护当前设备位置, 在进入发现页与附近页时触发定位更新.
///
/// 若尚未申请过系统定位权限, 不会主动弹出系统授权框, 而是交由页面先行展示权限说明.
final class CurrentLocationProvider
    extends $NotifierProvider<CurrentLocation, LocationState> {
  /// 维护当前设备位置, 在进入发现页与附近页时触发定位更新.
  ///
  /// 若尚未申请过系统定位权限, 不会主动弹出系统授权框, 而是交由页面先行展示权限说明.
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

/// 维护当前设备位置, 在进入发现页与附近页时触发定位更新.
///
/// 若尚未申请过系统定位权限, 不会主动弹出系统授权框, 而是交由页面先行展示权限说明.

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
