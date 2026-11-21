// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 已开放的校区列表, 数据来自 `/campus/list`.

@ProviderFor(campuses)
final campusesProvider = CampusesProvider._();

/// 已开放的校区列表, 数据来自 `/campus/list`.

final class CampusesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Campus>>,
          List<Campus>,
          FutureOr<List<Campus>>
        >
    with $FutureModifier<List<Campus>>, $FutureProvider<List<Campus>> {
  /// 已开放的校区列表, 数据来自 `/campus/list`.
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

/// 全部商圈列表, 用于附近页的商圈胶囊筛选.

@ProviderFor(hubs)
final hubsProvider = HubsProvider._();

/// 全部商圈列表, 用于附近页的商圈胶囊筛选.

final class HubsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Hub>>,
          List<Hub>,
          FutureOr<List<Hub>>
        >
    with $FutureModifier<List<Hub>>, $FutureProvider<List<Hub>> {
  /// 全部商圈列表, 用于附近页的商圈胶囊筛选.
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

/// 单个商圈. 先在 [hubs] 里找; 列表里没有 (列表只取了第一页) 或列表加载失败时, 按 id 查商圈详情.

@ProviderFor(hub)
final hubProvider = HubFamily._();

/// 单个商圈. 先在 [hubs] 里找; 列表里没有 (列表只取了第一页) 或列表加载失败时, 按 id 查商圈详情.

final class HubProvider
    extends $FunctionalProvider<AsyncValue<Hub?>, Hub?, FutureOr<Hub?>>
    with $FutureModifier<Hub?>, $FutureProvider<Hub?> {
  /// 单个商圈. 先在 [hubs] 里找; 列表里没有 (列表只取了第一页) 或列表加载失败时, 按 id 查商圈详情.
  HubProvider._({required HubFamily super.from, required int super.argument})
    : super(
        retry: null,
        name: r'hubProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hubHash();

  @override
  String toString() {
    return r'hubProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Hub?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Hub?> create(Ref ref) {
    final argument = this.argument as int;
    return hub(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HubProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hubHash() => r'a191dad745688e370144a71fe666a482b971a73b';

/// 单个商圈. 先在 [hubs] 里找; 列表里没有 (列表只取了第一页) 或列表加载失败时, 按 id 查商圈详情.

final class HubFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Hub?>, int> {
  HubFamily._()
    : super(
        retry: null,
        name: r'hubProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// 单个商圈. 先在 [hubs] 里找; 列表里没有 (列表只取了第一页) 或列表加载失败时, 按 id 查商圈详情.

  HubProvider call(int id) => HubProvider._(argument: id, from: this);

  @override
  String toString() => r'hubProvider';
}

/// 管理持久化在本机的校区, 饭点与用餐场景选择.
///
/// 属于设备级偏好, 退出登录时不清除; 场景与校区一样长期保留, 手动选择的饭点仅保持到当前时间段结束.

@ProviderFor(PlaceAndMeal)
final placeAndMealProvider = PlaceAndMealProvider._();

/// 管理持久化在本机的校区, 饭点与用餐场景选择.
///
/// 属于设备级偏好, 退出登录时不清除; 场景与校区一样长期保留, 手动选择的饭点仅保持到当前时间段结束.
final class PlaceAndMealProvider
    extends $NotifierProvider<PlaceAndMeal, PlaceChoice> {
  /// 管理持久化在本机的校区, 饭点与用餐场景选择.
  ///
  /// 属于设备级偏好, 退出登录时不清除; 场景与校区一样长期保留, 手动选择的饭点仅保持到当前时间段结束.
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

String _$placeAndMealHash() => r'25f312f24d2fa48bd80bd61644ec372741aeb545';

/// 管理持久化在本机的校区, 饭点与用餐场景选择.
///
/// 属于设备级偏好, 退出登录时不清除; 场景与校区一样长期保留, 手动选择的饭点仅保持到当前时间段结束.

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

/// 计算当前生效的校区, 饭点与用餐场景.
///
/// - 校区: 手动选择的校区仍在列表中时使用它, 否则按定位自动选择 ([CampusRules.nearest]).
/// - 饭点: 手动选择且未过期时使用手动选择, 否则按当前时间推算.
/// - 场景: 采用上次选择, 没选过时为堂食.
///
/// 当时间段结束 ([mealPeriodEnd]) 或应用回到前台时, 由发现页触发重算;
/// 此处不自行启动定时器, 避免常驻 Provider 持有长期定时器.

@ProviderFor(currentPlace)
final currentPlaceProvider = CurrentPlaceProvider._();

/// 计算当前生效的校区, 饭点与用餐场景.
///
/// - 校区: 手动选择的校区仍在列表中时使用它, 否则按定位自动选择 ([CampusRules.nearest]).
/// - 饭点: 手动选择且未过期时使用手动选择, 否则按当前时间推算.
/// - 场景: 采用上次选择, 没选过时为堂食.
///
/// 当时间段结束 ([mealPeriodEnd]) 或应用回到前台时, 由发现页触发重算;
/// 此处不自行启动定时器, 避免常驻 Provider 持有长期定时器.

final class CurrentPlaceProvider
    extends $FunctionalProvider<CurrentPlace, CurrentPlace, CurrentPlace>
    with $Provider<CurrentPlace> {
  /// 计算当前生效的校区, 饭点与用餐场景.
  ///
  /// - 校区: 手动选择的校区仍在列表中时使用它, 否则按定位自动选择 ([CampusRules.nearest]).
  /// - 饭点: 手动选择且未过期时使用手动选择, 否则按当前时间推算.
  /// - 场景: 采用上次选择, 没选过时为堂食.
  ///
  /// 当时间段结束 ([mealPeriodEnd]) 或应用回到前台时, 由发现页触发重算;
  /// 此处不自行启动定时器, 避免常驻 Provider 持有长期定时器.
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

String _$currentPlaceHash() => r'f6f6802ff22cc71fa84c720019bde2fe9368b390';
