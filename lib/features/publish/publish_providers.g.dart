// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 获取当前校区内营业中的可选店铺列表; [keyword] 为空时列出附近店铺, 否则按店名或地址搜索.
///
/// - 列表按与用户的距离升序排列; 无定位时按与校区中心的距离排列, 两者均缺失时按创建时间倒序.
/// - 搜店接口包含已关门店铺, 此处统一过滤排除.

@ProviderFor(pickableShops)
final pickableShopsProvider = PickableShopsFamily._();

/// 获取当前校区内营业中的可选店铺列表; [keyword] 为空时列出附近店铺, 否则按店名或地址搜索.
///
/// - 列表按与用户的距离升序排列; 无定位时按与校区中心的距离排列, 两者均缺失时按创建时间倒序.
/// - 搜店接口包含已关门店铺, 此处统一过滤排除.

final class PickableShopsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Shop>>,
          List<Shop>,
          FutureOr<List<Shop>>
        >
    with $FutureModifier<List<Shop>>, $FutureProvider<List<Shop>> {
  /// 获取当前校区内营业中的可选店铺列表; [keyword] 为空时列出附近店铺, 否则按店名或地址搜索.
  ///
  /// - 列表按与用户的距离升序排列; 无定位时按与校区中心的距离排列, 两者均缺失时按创建时间倒序.
  /// - 搜店接口包含已关门店铺, 此处统一过滤排除.
  PickableShopsProvider._({
    required PickableShopsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pickableShopsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pickableShopsHash();

  @override
  String toString() {
    return r'pickableShopsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Shop>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Shop>> create(Ref ref) {
    final argument = this.argument as String;
    return pickableShops(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PickableShopsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pickableShopsHash() => r'ac61c6912f6e4bcb0d5b61b850f5fe701694b71e';

/// 获取当前校区内营业中的可选店铺列表; [keyword] 为空时列出附近店铺, 否则按店名或地址搜索.
///
/// - 列表按与用户的距离升序排列; 无定位时按与校区中心的距离排列, 两者均缺失时按创建时间倒序.
/// - 搜店接口包含已关门店铺, 此处统一过滤排除.

final class PickableShopsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Shop>>, String> {
  PickableShopsFamily._()
    : super(
        retry: null,
        name: r'pickableShopsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 获取当前校区内营业中的可选店铺列表; [keyword] 为空时列出附近店铺, 否则按店名或地址搜索.
  ///
  /// - 列表按与用户的距离升序排列; 无定位时按与校区中心的距离排列, 两者均缺失时按创建时间倒序.
  /// - 搜店接口包含已关门店铺, 此处统一过滤排除.

  PickableShopsProvider call(String keyword) =>
      PickableShopsProvider._(argument: keyword, from: this);

  @override
  String toString() => r'pickableShopsProvider';
}

/// 当前用户所在的商圈, 用于选店页的位置提示; 无定位或不在任何商圈内时返回 null.

@ProviderFor(myHub)
final myHubProvider = MyHubProvider._();

/// 当前用户所在的商圈, 用于选店页的位置提示; 无定位或不在任何商圈内时返回 null.

final class MyHubProvider
    extends $FunctionalProvider<AsyncValue<Hub?>, Hub?, FutureOr<Hub?>>
    with $FutureModifier<Hub?>, $FutureProvider<Hub?> {
  /// 当前用户所在的商圈, 用于选店页的位置提示; 无定位或不在任何商圈内时返回 null.
  MyHubProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myHubProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myHubHash();

  @$internal
  @override
  $FutureProviderElement<Hub?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Hub?> create(Ref ref) {
    return myHub(ref);
  }
}

String _$myHubHash() => r'30801ea7c162f9ef6f0eb76904ef25536364c232';

/// 获取地图中心坐标所属的商圈, 用于新建店铺时自动确定商圈.

@ProviderFor(hubAt)
final hubAtProvider = HubAtFamily._();

/// 获取地图中心坐标所属的商圈, 用于新建店铺时自动确定商圈.

final class HubAtProvider
    extends $FunctionalProvider<AsyncValue<Hub?>, Hub?, FutureOr<Hub?>>
    with $FutureModifier<Hub?>, $FutureProvider<Hub?> {
  /// 获取地图中心坐标所属的商圈, 用于新建店铺时自动确定商圈.
  HubAtProvider._({
    required HubAtFamily super.from,
    required GcjPoint super.argument,
  }) : super(
         retry: null,
         name: r'hubAtProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hubAtHash();

  @override
  String toString() {
    return r'hubAtProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Hub?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Hub?> create(Ref ref) {
    final argument = this.argument as GcjPoint;
    return hubAt(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HubAtProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hubAtHash() => r'ab05209d56ed9b3cb37591fce54c1858cb7aa031';

/// 获取地图中心坐标所属的商圈, 用于新建店铺时自动确定商圈.

final class HubAtFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Hub?>, GcjPoint> {
  HubAtFamily._()
    : super(
        retry: null,
        name: r'hubAtProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 获取地图中心坐标所属的商圈, 用于新建店铺时自动确定商圈.

  HubAtProvider call(GcjPoint point) =>
      HubAtProvider._(argument: point, from: this);

  @override
  String toString() => r'hubAtProvider';
}

/// 查询新建店铺时可能重复的已有店铺 (包含已关门店铺), 涵盖地图地点 [poi] 关联店铺及 [point] 200 m 内的同名店铺.
///
/// 仅用于表单内防重提示而非强制拦截, 并在输入防抖后发起查询.

@ProviderFor(shopDuplicates)
final shopDuplicatesProvider = ShopDuplicatesFamily._();

/// 查询新建店铺时可能重复的已有店铺 (包含已关门店铺), 涵盖地图地点 [poi] 关联店铺及 [point] 200 m 内的同名店铺.
///
/// 仅用于表单内防重提示而非强制拦截, 并在输入防抖后发起查询.

final class ShopDuplicatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShopDuplicate>>,
          List<ShopDuplicate>,
          FutureOr<List<ShopDuplicate>>
        >
    with
        $FutureModifier<List<ShopDuplicate>>,
        $FutureProvider<List<ShopDuplicate>> {
  /// 查询新建店铺时可能重复的已有店铺 (包含已关门店铺), 涵盖地图地点 [poi] 关联店铺及 [point] 200 m 内的同名店铺.
  ///
  /// 仅用于表单内防重提示而非强制拦截, 并在输入防抖后发起查询.
  ShopDuplicatesProvider._({
    required ShopDuplicatesFamily super.from,
    required (String, GcjPoint, String?) super.argument,
  }) : super(
         retry: null,
         name: r'shopDuplicatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shopDuplicatesHash();

  @override
  String toString() {
    return r'shopDuplicatesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ShopDuplicate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ShopDuplicate>> create(Ref ref) {
    final argument = this.argument as (String, GcjPoint, String?);
    return shopDuplicates(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopDuplicatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shopDuplicatesHash() => r'79fb9cc4d861bb9cc753eeaa4b09c54a20ed6907';

/// 查询新建店铺时可能重复的已有店铺 (包含已关门店铺), 涵盖地图地点 [poi] 关联店铺及 [point] 200 m 内的同名店铺.
///
/// 仅用于表单内防重提示而非强制拦截, 并在输入防抖后发起查询.

final class ShopDuplicatesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ShopDuplicate>>,
          (String, GcjPoint, String?)
        > {
  ShopDuplicatesFamily._()
    : super(
        retry: null,
        name: r'shopDuplicatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 查询新建店铺时可能重复的已有店铺 (包含已关门店铺), 涵盖地图地点 [poi] 关联店铺及 [point] 200 m 内的同名店铺.
  ///
  /// 仅用于表单内防重提示而非强制拦截, 并在输入防抖后发起查询.

  ShopDuplicatesProvider call(String name, GcjPoint point, String? poi) =>
      ShopDuplicatesProvider._(argument: (name, point, poi), from: this);

  @override
  String toString() => r'shopDuplicatesProvider';
}

/// 检索与 [keyword] 匹配的地图候选地点, 优先在当前位置附近搜索, 无定位时回退至校区中心附近.
///
/// 当 [keyword] 为空时返回空列表, 检索异常时抛出错误状态.

@ProviderFor(mapPlaces)
final mapPlacesProvider = MapPlacesFamily._();

/// 检索与 [keyword] 匹配的地图候选地点, 优先在当前位置附近搜索, 无定位时回退至校区中心附近.
///
/// 当 [keyword] 为空时返回空列表, 检索异常时抛出错误状态.

final class MapPlacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MapPlace>>,
          List<MapPlace>,
          FutureOr<List<MapPlace>>
        >
    with $FutureModifier<List<MapPlace>>, $FutureProvider<List<MapPlace>> {
  /// 检索与 [keyword] 匹配的地图候选地点, 优先在当前位置附近搜索, 无定位时回退至校区中心附近.
  ///
  /// 当 [keyword] 为空时返回空列表, 检索异常时抛出错误状态.
  MapPlacesProvider._({
    required MapPlacesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mapPlacesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mapPlacesHash();

  @override
  String toString() {
    return r'mapPlacesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MapPlace>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MapPlace>> create(Ref ref) {
    final argument = this.argument as String;
    return mapPlaces(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MapPlacesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mapPlacesHash() => r'bec9f99f32758ce81b16ebeabbe349dad56f4ba3';

/// 检索与 [keyword] 匹配的地图候选地点, 优先在当前位置附近搜索, 无定位时回退至校区中心附近.
///
/// 当 [keyword] 为空时返回空列表, 检索异常时抛出错误状态.

final class MapPlacesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MapPlace>>, String> {
  MapPlacesFamily._()
    : super(
        retry: null,
        name: r'mapPlacesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 检索与 [keyword] 匹配的地图候选地点, 优先在当前位置附近搜索, 无定位时回退至校区中心附近.
  ///
  /// 当 [keyword] 为空时返回空列表, 检索异常时抛出错误状态.

  MapPlacesProvider call(String keyword) =>
      MapPlacesProvider._(argument: keyword, from: this);

  @override
  String toString() => r'mapPlacesProvider';
}

/// 对指定店铺内的菜名查重, 若已存在同名菜品则返回该菜品, 否则返回 null.
///
/// 查重接口还会返回菜名相近的菜, 这里只取同名的.

@ProviderFor(sameNameDish)
final sameNameDishProvider = SameNameDishFamily._();

/// 对指定店铺内的菜名查重, 若已存在同名菜品则返回该菜品, 否则返回 null.
///
/// 查重接口还会返回菜名相近的菜, 这里只取同名的.

final class SameNameDishProvider
    extends
        $FunctionalProvider<
          AsyncValue<DishDuplicate?>,
          DishDuplicate?,
          FutureOr<DishDuplicate?>
        >
    with $FutureModifier<DishDuplicate?>, $FutureProvider<DishDuplicate?> {
  /// 对指定店铺内的菜名查重, 若已存在同名菜品则返回该菜品, 否则返回 null.
  ///
  /// 查重接口还会返回菜名相近的菜, 这里只取同名的.
  SameNameDishProvider._({
    required SameNameDishFamily super.from,
    required (int, String) super.argument,
  }) : super(
         retry: null,
         name: r'sameNameDishProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sameNameDishHash();

  @override
  String toString() {
    return r'sameNameDishProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DishDuplicate?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DishDuplicate?> create(Ref ref) {
    final argument = this.argument as (int, String);
    return sameNameDish(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SameNameDishProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sameNameDishHash() => r'8258439a326da26a9c47d2a274b59059dc2350fb';

/// 对指定店铺内的菜名查重, 若已存在同名菜品则返回该菜品, 否则返回 null.
///
/// 查重接口还会返回菜名相近的菜, 这里只取同名的.

final class SameNameDishFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DishDuplicate?>, (int, String)> {
  SameNameDishFamily._()
    : super(
        retry: null,
        name: r'sameNameDishProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 对指定店铺内的菜名查重, 若已存在同名菜品则返回该菜品, 否则返回 null.
  ///
  /// 查重接口还会返回菜名相近的菜, 这里只取同名的.

  SameNameDishProvider call(int shopId, String name) =>
      SameNameDishProvider._(argument: (shopId, name), from: this);

  @override
  String toString() => r'sameNameDishProvider';
}

/// 发布和编辑菜品时可选的分类, 口味, 饭点和数量上限.
///
/// 请求失败时使用内置值, 不打断填写. 每次打开加菜页重新请求.

@ProviderFor(dishOptions)
final dishOptionsProvider = DishOptionsProvider._();

/// 发布和编辑菜品时可选的分类, 口味, 饭点和数量上限.
///
/// 请求失败时使用内置值, 不打断填写. 每次打开加菜页重新请求.

final class DishOptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DishOptions>,
          DishOptions,
          FutureOr<DishOptions>
        >
    with $FutureModifier<DishOptions>, $FutureProvider<DishOptions> {
  /// 发布和编辑菜品时可选的分类, 口味, 饭点和数量上限.
  ///
  /// 请求失败时使用内置值, 不打断填写. 每次打开加菜页重新请求.
  DishOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dishOptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dishOptionsHash();

  @$internal
  @override
  $FutureProviderElement<DishOptions> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DishOptions> create(Ref ref) {
    return dishOptions(ref);
  }
}

String _$dishOptionsHash() => r'0baf6f7b3c3705c9cce30e2fb6b117ff90e3ec83';

/// 按 id 读取待编辑菜品详情, 供编辑页未从详情页带入菜品对象时 (如在 Web 端刷新) 使用.

@ProviderFor(dishToEdit)
final dishToEditProvider = DishToEditFamily._();

/// 按 id 读取待编辑菜品详情, 供编辑页未从详情页带入菜品对象时 (如在 Web 端刷新) 使用.

final class DishToEditProvider
    extends $FunctionalProvider<AsyncValue<Dish>, Dish, FutureOr<Dish>>
    with $FutureModifier<Dish>, $FutureProvider<Dish> {
  /// 按 id 读取待编辑菜品详情, 供编辑页未从详情页带入菜品对象时 (如在 Web 端刷新) 使用.
  DishToEditProvider._({
    required DishToEditFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'dishToEditProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dishToEditHash();

  @override
  String toString() {
    return r'dishToEditProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Dish> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Dish> create(Ref ref) {
    final argument = this.argument as int;
    return dishToEdit(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DishToEditProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dishToEditHash() => r'ad7666735026f144ef01713b2a4cac9df85b2719';

/// 按 id 读取待编辑菜品详情, 供编辑页未从详情页带入菜品对象时 (如在 Web 端刷新) 使用.

final class DishToEditFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Dish>, int> {
  DishToEditFamily._()
    : super(
        retry: null,
        name: r'dishToEditProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 按 id 读取待编辑菜品详情, 供编辑页未从详情页带入菜品对象时 (如在 Web 端刷新) 使用.

  DishToEditProvider call(int dishId) =>
      DishToEditProvider._(argument: dishId, from: this);

  @override
  String toString() => r'dishToEditProvider';
}

/// 管理加菜页表单草稿及照片上传队列的控制器, 随页面销毁而释放且不持久化.
///
/// - 编辑模式下传入 [original] 以预填分类, 口味, 招牌菜, 饭点与外卖; 发布新菜时该参数为 null.
/// - 照片和口味的上限取自 [dishOptionsProvider], 由页面保持其存活.
/// - 添加照片后立即按并发上限在后台排队上传, 失败的照片支持单张重试.
/// - 一次添加多张照片时一次申请这些照片的上传地址.
/// - 应用从后台恢复至前台时, 对尚未自动重试过的失败照片触发一次自动重试.
/// - 进入后台时仍在排队或上传的照片, 回到前台后才失败的, 也自动重试一次.

@ProviderFor(Draft)
final draftProvider = DraftFamily._();

/// 管理加菜页表单草稿及照片上传队列的控制器, 随页面销毁而释放且不持久化.
///
/// - 编辑模式下传入 [original] 以预填分类, 口味, 招牌菜, 饭点与外卖; 发布新菜时该参数为 null.
/// - 照片和口味的上限取自 [dishOptionsProvider], 由页面保持其存活.
/// - 添加照片后立即按并发上限在后台排队上传, 失败的照片支持单张重试.
/// - 一次添加多张照片时一次申请这些照片的上传地址.
/// - 应用从后台恢复至前台时, 对尚未自动重试过的失败照片触发一次自动重试.
/// - 进入后台时仍在排队或上传的照片, 回到前台后才失败的, 也自动重试一次.
final class DraftProvider extends $NotifierProvider<Draft, PublishDraft> {
  /// 管理加菜页表单草稿及照片上传队列的控制器, 随页面销毁而释放且不持久化.
  ///
  /// - 编辑模式下传入 [original] 以预填分类, 口味, 招牌菜, 饭点与外卖; 发布新菜时该参数为 null.
  /// - 照片和口味的上限取自 [dishOptionsProvider], 由页面保持其存活.
  /// - 添加照片后立即按并发上限在后台排队上传, 失败的照片支持单张重试.
  /// - 一次添加多张照片时一次申请这些照片的上传地址.
  /// - 应用从后台恢复至前台时, 对尚未自动重试过的失败照片触发一次自动重试.
  /// - 进入后台时仍在排队或上传的照片, 回到前台后才失败的, 也自动重试一次.
  DraftProvider._({
    required DraftFamily super.from,
    required Dish? super.argument,
  }) : super(
         retry: null,
         name: r'draftProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$draftHash();

  @override
  String toString() {
    return r'draftProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Draft create() => Draft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PublishDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PublishDraft>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DraftProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$draftHash() => r'7cfc326c4d0138765bb3db8411c7428df5f49e71';

/// 管理加菜页表单草稿及照片上传队列的控制器, 随页面销毁而释放且不持久化.
///
/// - 编辑模式下传入 [original] 以预填分类, 口味, 招牌菜, 饭点与外卖; 发布新菜时该参数为 null.
/// - 照片和口味的上限取自 [dishOptionsProvider], 由页面保持其存活.
/// - 添加照片后立即按并发上限在后台排队上传, 失败的照片支持单张重试.
/// - 一次添加多张照片时一次申请这些照片的上传地址.
/// - 应用从后台恢复至前台时, 对尚未自动重试过的失败照片触发一次自动重试.
/// - 进入后台时仍在排队或上传的照片, 回到前台后才失败的, 也自动重试一次.

final class DraftFamily extends $Family
    with
        $ClassFamilyOverride<
          Draft,
          PublishDraft,
          PublishDraft,
          PublishDraft,
          Dish?
        > {
  DraftFamily._()
    : super(
        retry: null,
        name: r'draftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 管理加菜页表单草稿及照片上传队列的控制器, 随页面销毁而释放且不持久化.
  ///
  /// - 编辑模式下传入 [original] 以预填分类, 口味, 招牌菜, 饭点与外卖; 发布新菜时该参数为 null.
  /// - 照片和口味的上限取自 [dishOptionsProvider], 由页面保持其存活.
  /// - 添加照片后立即按并发上限在后台排队上传, 失败的照片支持单张重试.
  /// - 一次添加多张照片时一次申请这些照片的上传地址.
  /// - 应用从后台恢复至前台时, 对尚未自动重试过的失败照片触发一次自动重试.
  /// - 进入后台时仍在排队或上传的照片, 回到前台后才失败的, 也自动重试一次.

  DraftProvider call({Dish? original}) =>
      DraftProvider._(argument: original, from: this);

  @override
  String toString() => r'draftProvider';
}

/// 管理加菜页表单草稿及照片上传队列的控制器, 随页面销毁而释放且不持久化.
///
/// - 编辑模式下传入 [original] 以预填分类, 口味, 招牌菜, 饭点与外卖; 发布新菜时该参数为 null.
/// - 照片和口味的上限取自 [dishOptionsProvider], 由页面保持其存活.
/// - 添加照片后立即按并发上限在后台排队上传, 失败的照片支持单张重试.
/// - 一次添加多张照片时一次申请这些照片的上传地址.
/// - 应用从后台恢复至前台时, 对尚未自动重试过的失败照片触发一次自动重试.
/// - 进入后台时仍在排队或上传的照片, 回到前台后才失败的, 也自动重试一次.

abstract class _$Draft extends $Notifier<PublishDraft> {
  late final _$args = ref.$arg as Dish?;
  Dish? get original => _$args;

  PublishDraft build({Dish? original});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PublishDraft, PublishDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PublishDraft, PublishDraft>,
              PublishDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(original: _$args));
  }
}
