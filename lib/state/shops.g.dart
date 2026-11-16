// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shops.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 指定店铺的资料, 用于菜品详情的店卡和餐厅详情页展示.
///
/// 离开页面后仍会缓存 5 分钟, 期间重新进入不会重复发起请求.

@ProviderFor(shop)
final shopProvider = ShopFamily._();

/// 指定店铺的资料, 用于菜品详情的店卡和餐厅详情页展示.
///
/// 离开页面后仍会缓存 5 分钟, 期间重新进入不会重复发起请求.

final class ShopProvider
    extends $FunctionalProvider<AsyncValue<Shop>, Shop, FutureOr<Shop>>
    with $FutureModifier<Shop>, $FutureProvider<Shop> {
  /// 指定店铺的资料, 用于菜品详情的店卡和餐厅详情页展示.
  ///
  /// 离开页面后仍会缓存 5 分钟, 期间重新进入不会重复发起请求.
  ShopProvider._({required ShopFamily super.from, required int super.argument})
    : super(
        retry: null,
        name: r'shopProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shopHash();

  @override
  String toString() {
    return r'shopProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Shop> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Shop> create(Ref ref) {
    final argument = this.argument as int;
    return shop(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shopHash() => r'c6f2d60e45fd6a8ea6248a8c91f59cf6fd9ee6ba';

/// 指定店铺的资料, 用于菜品详情的店卡和餐厅详情页展示.
///
/// 离开页面后仍会缓存 5 分钟, 期间重新进入不会重复发起请求.

final class ShopFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Shop>, int> {
  ShopFamily._()
    : super(
        retry: null,
        name: r'shopProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 指定店铺的资料, 用于菜品详情的店卡和餐厅详情页展示.
  ///
  /// 离开页面后仍会缓存 5 分钟, 期间重新进入不会重复发起请求.

  ShopProvider call(int shopId) => ShopProvider._(argument: shopId, from: this);

  @override
  String toString() => r'shopProvider';
}

/// 商圈 id 对应的名称. 商圈列表尚未获取或没有对应商圈时为 null.
///
/// 店铺自带商圈名 (`Shop.hubName`). 只有不带商圈名的数据 (如菜品) 需要按 id 查找.

@ProviderFor(hubName)
final hubNameProvider = HubNameFamily._();

/// 商圈 id 对应的名称. 商圈列表尚未获取或没有对应商圈时为 null.
///
/// 店铺自带商圈名 (`Shop.hubName`). 只有不带商圈名的数据 (如菜品) 需要按 id 查找.

final class HubNameProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// 商圈 id 对应的名称. 商圈列表尚未获取或没有对应商圈时为 null.
  ///
  /// 店铺自带商圈名 (`Shop.hubName`). 只有不带商圈名的数据 (如菜品) 需要按 id 查找.
  HubNameProvider._({
    required HubNameFamily super.from,
    required int? super.argument,
  }) : super(
         retry: null,
         name: r'hubNameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hubNameHash();

  @override
  String toString() {
    return r'hubNameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    final argument = this.argument as int?;
    return hubName(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HubNameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hubNameHash() => r'24cae425bbe142010ccb4c13702d1d992cb4a913';

/// 商圈 id 对应的名称. 商圈列表尚未获取或没有对应商圈时为 null.
///
/// 店铺自带商圈名 (`Shop.hubName`). 只有不带商圈名的数据 (如菜品) 需要按 id 查找.

final class HubNameFamily extends $Family
    with $FunctionalFamilyOverride<String?, int?> {
  HubNameFamily._()
    : super(
        retry: null,
        name: r'hubNameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 商圈 id 对应的名称. 商圈列表尚未获取或没有对应商圈时为 null.
  ///
  /// 店铺自带商圈名 (`Shop.hubName`). 只有不带商圈名的数据 (如菜品) 需要按 id 查找.

  HubNameProvider call(int? hubId) =>
      HubNameProvider._(argument: hubId, from: this);

  @override
  String toString() => r'hubNameProvider';
}

/// 格式化当前位置到 [point] 的距离文字; 若没有定位或用户离校区过远则返回 null.

@ProviderFor(distanceTo)
final distanceToProvider = DistanceToFamily._();

/// 格式化当前位置到 [point] 的距离文字; 若没有定位或用户离校区过远则返回 null.

final class DistanceToProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// 格式化当前位置到 [point] 的距离文字; 若没有定位或用户离校区过远则返回 null.
  DistanceToProvider._({
    required DistanceToFamily super.from,
    required GcjPoint? super.argument,
  }) : super(
         retry: null,
         name: r'distanceToProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$distanceToHash();

  @override
  String toString() {
    return r'distanceToProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    final argument = this.argument as GcjPoint?;
    return distanceTo(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DistanceToProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$distanceToHash() => r'593b3c7f5beff5a8d864be72c46364ee605225ed';

/// 格式化当前位置到 [point] 的距离文字; 若没有定位或用户离校区过远则返回 null.

final class DistanceToFamily extends $Family
    with $FunctionalFamilyOverride<String?, GcjPoint?> {
  DistanceToFamily._()
    : super(
        retry: null,
        name: r'distanceToProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 格式化当前位置到 [point] 的距离文字; 若没有定位或用户离校区过远则返回 null.

  DistanceToProvider call(GcjPoint? point) =>
      DistanceToProvider._(argument: point, from: this);

  @override
  String toString() => r'distanceToProvider';
}
