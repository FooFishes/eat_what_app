// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 已开放的校区, 来自 `/campus/list`.

@ProviderFor(campuses)
final campusesProvider = CampusesProvider._();

/// 已开放的校区, 来自 `/campus/list`.

final class CampusesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Campus>>,
          List<Campus>,
          FutureOr<List<Campus>>
        >
    with $FutureModifier<List<Campus>>, $FutureProvider<List<Campus>> {
  /// 已开放的校区, 来自 `/campus/list`.
  CampusesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'campusesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$campusesHash();

  @$internal
  @override
  $FutureProviderElement<List<Campus>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Campus>> create(Ref ref) {
    return campuses(ref);
  }
}

String _$campusesHash() => r'f5205c6bd2214e92c06e1766e9552a6d5170777d';

/// 全部商圈. 用于附近页的商圈胶囊.

@ProviderFor(hubs)
final hubsProvider = HubsProvider._();

/// 全部商圈. 用于附近页的商圈胶囊.

final class HubsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Hub>>,
          List<Hub>,
          FutureOr<List<Hub>>
        >
    with $FutureModifier<List<Hub>>, $FutureProvider<List<Hub>> {
  /// 全部商圈. 用于附近页的商圈胶囊.
  HubsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hubsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hubsHash();

  @$internal
  @override
  $FutureProviderElement<List<Hub>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Hub>> create(Ref ref) {
    return hubs(ref);
  }
}

String _$hubsHash() => r'7e1161c0dcdfe6ae86ce142d60b40922118c5305';

/// 地点, 饭点和场景的选择, 保存在本机.
///
/// 属于设备级偏好, 退出登录时不清除. 场景和校区一样一直记住, 饭点只保持到当前时间段结束.

@ProviderFor(PlaceAndMeal)
final placeAndMealProvider = PlaceAndMealProvider._();

/// 地点, 饭点和场景的选择, 保存在本机.
///
/// 属于设备级偏好, 退出登录时不清除. 场景和校区一样一直记住, 饭点只保持到当前时间段结束.
final class PlaceAndMealProvider
    extends $NotifierProvider<PlaceAndMeal, PlaceChoice> {
  /// 地点, 饭点和场景的选择, 保存在本机.
  ///
  /// 属于设备级偏好, 退出登录时不清除. 场景和校区一样一直记住, 饭点只保持到当前时间段结束.
  PlaceAndMealProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeAndMealProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeAndMealHash();

  @$internal
  @override
  PlaceAndMeal create() => PlaceAndMeal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceChoice value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceChoice>(value),
    );
  }
}

String _$placeAndMealHash() => r'e679bb39834227ba4c8038e3207bf5cf65ba4eb3';

/// 地点, 饭点和场景的选择, 保存在本机.
///
/// 属于设备级偏好, 退出登录时不清除. 场景和校区一样一直记住, 饭点只保持到当前时间段结束.

abstract class _$PlaceAndMeal extends $Notifier<PlaceChoice> {
  PlaceChoice build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlaceChoice, PlaceChoice>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlaceChoice, PlaceChoice>,
              PlaceChoice,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 当前的校区, 饭点和场景.
///
/// - 校区: 依次取上次选择的校区, 离定位最近的校区, 默认校区.
/// - 饭点: 手动选择且未过期时使用手动选择, 否则按当前时间.
/// - 场景: 上次的选择, 没选过时为堂食.
///
/// 时间段结束 ([mealPeriodEnd]) 和回到前台时, 由发现页触发重算.
/// 这里不启动定时器: 该 Provider 常驻, 定时器会一直存在.

@ProviderFor(currentPlace)
final currentPlaceProvider = CurrentPlaceProvider._();

/// 当前的校区, 饭点和场景.
///
/// - 校区: 依次取上次选择的校区, 离定位最近的校区, 默认校区.
/// - 饭点: 手动选择且未过期时使用手动选择, 否则按当前时间.
/// - 场景: 上次的选择, 没选过时为堂食.
///
/// 时间段结束 ([mealPeriodEnd]) 和回到前台时, 由发现页触发重算.
/// 这里不启动定时器: 该 Provider 常驻, 定时器会一直存在.

final class CurrentPlaceProvider
    extends $FunctionalProvider<CurrentPlace, CurrentPlace, CurrentPlace>
    with $Provider<CurrentPlace> {
  /// 当前的校区, 饭点和场景.
  ///
  /// - 校区: 依次取上次选择的校区, 离定位最近的校区, 默认校区.
  /// - 饭点: 手动选择且未过期时使用手动选择, 否则按当前时间.
  /// - 场景: 上次的选择, 没选过时为堂食.
  ///
  /// 时间段结束 ([mealPeriodEnd]) 和回到前台时, 由发现页触发重算.
  /// 这里不启动定时器: 该 Provider 常驻, 定时器会一直存在.
  CurrentPlaceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentPlaceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentPlaceHash();

  @$internal
  @override
  $ProviderElement<CurrentPlace> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CurrentPlace create(Ref ref) {
    return currentPlace(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CurrentPlace value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CurrentPlace>(value),
    );
  }
}

String _$currentPlaceHash() => r'fa584c95955166fcbed11fcfc3c0ccae61a8988f';
