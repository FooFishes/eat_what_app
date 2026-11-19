// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 当前用户上传的菜品列表, 发布成功后会自动刷新.
///
/// "我的" 为常驻主页面, 切换到其他主页面后保留已加载结果而不会重新请求.
/// 账号封禁期间改用他人主页接口读取, 因为受限会话无法调用 `/foods/my`, 但可调用 `/foods/by-user/{id}`.
/// 第一页另存本地缓存: 第一次读取时有缓存就先给缓存, 再在后台请求新的; 请求失败时保留缓存.

@ProviderFor(MyUploads)
final myUploadsProvider = MyUploadsProvider._();

/// 当前用户上传的菜品列表, 发布成功后会自动刷新.
///
/// "我的" 为常驻主页面, 切换到其他主页面后保留已加载结果而不会重新请求.
/// 账号封禁期间改用他人主页接口读取, 因为受限会话无法调用 `/foods/my`, 但可调用 `/foods/by-user/{id}`.
/// 第一页另存本地缓存: 第一次读取时有缓存就先给缓存, 再在后台请求新的; 请求失败时保留缓存.
final class MyUploadsProvider
    extends $AsyncNotifierProvider<MyUploads, DishPages> {
  /// 当前用户上传的菜品列表, 发布成功后会自动刷新.
  ///
  /// "我的" 为常驻主页面, 切换到其他主页面后保留已加载结果而不会重新请求.
  /// 账号封禁期间改用他人主页接口读取, 因为受限会话无法调用 `/foods/my`, 但可调用 `/foods/by-user/{id}`.
  /// 第一页另存本地缓存: 第一次读取时有缓存就先给缓存, 再在后台请求新的; 请求失败时保留缓存.
  MyUploadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myUploadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myUploadsHash();

  @$internal
  @override
  MyUploads create() => MyUploads();
}

String _$myUploadsHash() => r'306b9cd85e3d25a68588473c026c152831b74bd9';

/// 当前用户上传的菜品列表, 发布成功后会自动刷新.
///
/// "我的" 为常驻主页面, 切换到其他主页面后保留已加载结果而不会重新请求.
/// 账号封禁期间改用他人主页接口读取, 因为受限会话无法调用 `/foods/my`, 但可调用 `/foods/by-user/{id}`.
/// 第一页另存本地缓存: 第一次读取时有缓存就先给缓存, 再在后台请求新的; 请求失败时保留缓存.

abstract class _$MyUploads extends $AsyncNotifier<DishPages> {
  FutureOr<DishPages> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DishPages>, DishPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DishPages>, DishPages>,
              AsyncValue<DishPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 当前用户收藏的菜品列表, 按收藏时间倒序排列.

@ProviderFor(MyFavorites)
final myFavoritesProvider = MyFavoritesProvider._();

/// 当前用户收藏的菜品列表, 按收藏时间倒序排列.
final class MyFavoritesProvider
    extends $AsyncNotifierProvider<MyFavorites, DishPages> {
  /// 当前用户收藏的菜品列表, 按收藏时间倒序排列.
  MyFavoritesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myFavoritesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myFavoritesHash();

  @$internal
  @override
  MyFavorites create() => MyFavorites();
}

String _$myFavoritesHash() => r'9241a8eb5fc3737374f3e95c2046998440bea26a';

/// 当前用户收藏的菜品列表, 按收藏时间倒序排列.

abstract class _$MyFavorites extends $AsyncNotifier<DishPages> {
  FutureOr<DishPages> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DishPages>, DishPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DishPages>, DishPages>,
              AsyncValue<DishPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 当前用户赞过的菜品列表, 按点赞时间倒序排列.

@ProviderFor(MyLikes)
final myLikesProvider = MyLikesProvider._();

/// 当前用户赞过的菜品列表, 按点赞时间倒序排列.
final class MyLikesProvider extends $AsyncNotifierProvider<MyLikes, DishPages> {
  /// 当前用户赞过的菜品列表, 按点赞时间倒序排列.
  MyLikesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myLikesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myLikesHash();

  @$internal
  @override
  MyLikes create() => MyLikes();
}

String _$myLikesHash() => r'737356d19b58a1776af76613601e80825b96a05e';

/// 当前用户赞过的菜品列表, 按点赞时间倒序排列.

abstract class _$MyLikes extends $AsyncNotifier<DishPages> {
  FutureOr<DishPages> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DishPages>, DishPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DishPages>, DishPages>,
              AsyncValue<DishPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 当前用户收藏的店铺列表, 已关门的店铺排在最后.

@ProviderFor(MyFavoriteShops)
final myFavoriteShopsProvider = MyFavoriteShopsProvider._();

/// 当前用户收藏的店铺列表, 已关门的店铺排在最后.
final class MyFavoriteShopsProvider
    extends $AsyncNotifierProvider<MyFavoriteShops, ListPages<Shop>> {
  /// 当前用户收藏的店铺列表, 已关门的店铺排在最后.
  MyFavoriteShopsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myFavoriteShopsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myFavoriteShopsHash();

  @$internal
  @override
  MyFavoriteShops create() => MyFavoriteShops();
}

String _$myFavoriteShopsHash() => r'af503c70caca042aa64df00a8203927f8ebc24e7';

/// 当前用户收藏的店铺列表, 已关门的店铺排在最后.

abstract class _$MyFavoriteShops extends $AsyncNotifier<ListPages<Shop>> {
  FutureOr<ListPages<Shop>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ListPages<Shop>>, ListPages<Shop>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ListPages<Shop>>, ListPages<Shop>>,
              AsyncValue<ListPages<Shop>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 他人主页的 "上传" 菜品列表, 离开页面后缓存保留 5 分钟.

@ProviderFor(UserUploads)
final userUploadsProvider = UserUploadsFamily._();

/// 他人主页的 "上传" 菜品列表, 离开页面后缓存保留 5 分钟.
final class UserUploadsProvider
    extends $AsyncNotifierProvider<UserUploads, DishPages> {
  /// 他人主页的 "上传" 菜品列表, 离开页面后缓存保留 5 分钟.
  UserUploadsProvider._({
    required UserUploadsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'userUploadsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userUploadsHash();

  @override
  String toString() {
    return r'userUploadsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserUploads create() => UserUploads();

  @override
  bool operator ==(Object other) {
    return other is UserUploadsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userUploadsHash() => r'fb385cedc951c56d7ac03646402f022adbaab4a9';

/// 他人主页的 "上传" 菜品列表, 离开页面后缓存保留 5 分钟.

final class UserUploadsFamily extends $Family
    with
        $ClassFamilyOverride<
          UserUploads,
          AsyncValue<DishPages>,
          DishPages,
          FutureOr<DishPages>,
          int
        > {
  UserUploadsFamily._()
    : super(
        retry: null,
        name: r'userUploadsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 他人主页的 "上传" 菜品列表, 离开页面后缓存保留 5 分钟.

  UserUploadsProvider call(int userId) =>
      UserUploadsProvider._(argument: userId, from: this);

  @override
  String toString() => r'userUploadsProvider';
}

/// 他人主页的 "上传" 菜品列表, 离开页面后缓存保留 5 分钟.

abstract class _$UserUploads extends $AsyncNotifier<DishPages> {
  late final _$args = ref.$arg as int;
  int get userId => _$args;

  FutureOr<DishPages> build(int userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DishPages>, DishPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DishPages>, DishPages>,
              AsyncValue<DishPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// [userId] 的粉丝或关注列表.
///
/// 若对方未公开该列表则请求失败, 此时 [AppFailure.code] 为 `BizCodes.permissionDenied`, 页面据此显示 "对方未公开".

@ProviderFor(FollowList)
final followListProvider = FollowListFamily._();

/// [userId] 的粉丝或关注列表.
///
/// 若对方未公开该列表则请求失败, 此时 [AppFailure.code] 为 `BizCodes.permissionDenied`, 页面据此显示 "对方未公开".
final class FollowListProvider
    extends $AsyncNotifierProvider<FollowList, ListPages<UserBrief>> {
  /// [userId] 的粉丝或关注列表.
  ///
  /// 若对方未公开该列表则请求失败, 此时 [AppFailure.code] 为 `BizCodes.permissionDenied`, 页面据此显示 "对方未公开".
  FollowListProvider._({
    required FollowListFamily super.from,
    required (int, FollowListKind) super.argument,
  }) : super(
         retry: null,
         name: r'followListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$followListHash();

  @override
  String toString() {
    return r'followListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  FollowList create() => FollowList();

  @override
  bool operator ==(Object other) {
    return other is FollowListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$followListHash() => r'2e6657246ee4dd4fe43e383cf0f3dbab96ec0f48';

/// [userId] 的粉丝或关注列表.
///
/// 若对方未公开该列表则请求失败, 此时 [AppFailure.code] 为 `BizCodes.permissionDenied`, 页面据此显示 "对方未公开".

final class FollowListFamily extends $Family
    with
        $ClassFamilyOverride<
          FollowList,
          AsyncValue<ListPages<UserBrief>>,
          ListPages<UserBrief>,
          FutureOr<ListPages<UserBrief>>,
          (int, FollowListKind)
        > {
  FollowListFamily._()
    : super(
        retry: null,
        name: r'followListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [userId] 的粉丝或关注列表.
  ///
  /// 若对方未公开该列表则请求失败, 此时 [AppFailure.code] 为 `BizCodes.permissionDenied`, 页面据此显示 "对方未公开".

  FollowListProvider call(int userId, FollowListKind kind) =>
      FollowListProvider._(argument: (userId, kind), from: this);

  @override
  String toString() => r'followListProvider';
}

/// [userId] 的粉丝或关注列表.
///
/// 若对方未公开该列表则请求失败, 此时 [AppFailure.code] 为 `BizCodes.permissionDenied`, 页面据此显示 "对方未公开".

abstract class _$FollowList extends $AsyncNotifier<ListPages<UserBrief>> {
  late final _$args = ref.$arg as (int, FollowListKind);
  int get userId => _$args.$1;
  FollowListKind get kind => _$args.$2;

  FutureOr<ListPages<UserBrief>> build(int userId, FollowListKind kind);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ListPages<UserBrief>>, ListPages<UserBrief>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ListPages<UserBrief>>,
                ListPages<UserBrief>
              >,
              AsyncValue<ListPages<UserBrief>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// 当前用户是否已屏蔽 [userId], 供他人主页 "更多" 菜单显示 "屏蔽" 或 "解除屏蔽".
///
/// 该状态直接取自对方用户资料, 不单独发起请求.

@ProviderFor(BlockState)
final blockStateProvider = BlockStateFamily._();

/// 当前用户是否已屏蔽 [userId], 供他人主页 "更多" 菜单显示 "屏蔽" 或 "解除屏蔽".
///
/// 该状态直接取自对方用户资料, 不单独发起请求.
final class BlockStateProvider
    extends $AsyncNotifierProvider<BlockState, bool> {
  /// 当前用户是否已屏蔽 [userId], 供他人主页 "更多" 菜单显示 "屏蔽" 或 "解除屏蔽".
  ///
  /// 该状态直接取自对方用户资料, 不单独发起请求.
  BlockStateProvider._({
    required BlockStateFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'blockStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$blockStateHash();

  @override
  String toString() {
    return r'blockStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BlockState create() => BlockState();

  @override
  bool operator ==(Object other) {
    return other is BlockStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$blockStateHash() => r'0082280f9599e14ee42b9b92b78b30127138d304';

/// 当前用户是否已屏蔽 [userId], 供他人主页 "更多" 菜单显示 "屏蔽" 或 "解除屏蔽".
///
/// 该状态直接取自对方用户资料, 不单独发起请求.

final class BlockStateFamily extends $Family
    with
        $ClassFamilyOverride<
          BlockState,
          AsyncValue<bool>,
          bool,
          FutureOr<bool>,
          int
        > {
  BlockStateFamily._()
    : super(
        retry: null,
        name: r'blockStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 当前用户是否已屏蔽 [userId], 供他人主页 "更多" 菜单显示 "屏蔽" 或 "解除屏蔽".
  ///
  /// 该状态直接取自对方用户资料, 不单独发起请求.

  BlockStateProvider call(int userId) =>
      BlockStateProvider._(argument: userId, from: this);

  @override
  String toString() => r'blockStateProvider';
}

/// 当前用户是否已屏蔽 [userId], 供他人主页 "更多" 菜单显示 "屏蔽" 或 "解除屏蔽".
///
/// 该状态直接取自对方用户资料, 不单独发起请求.

abstract class _$BlockState extends $AsyncNotifier<bool> {
  late final _$args = ref.$arg as int;
  int get userId => _$args;

  FutureOr<bool> build(int userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 当前用户的自定义标签列表. 仅认证用户支持编写标签, 未认证时不发起请求而直接返回空列表.

@ProviderFor(MyTags)
final myTagsProvider = MyTagsProvider._();

/// 当前用户的自定义标签列表. 仅认证用户支持编写标签, 未认证时不发起请求而直接返回空列表.
final class MyTagsProvider extends $AsyncNotifierProvider<MyTags, List<MyTag>> {
  /// 当前用户的自定义标签列表. 仅认证用户支持编写标签, 未认证时不发起请求而直接返回空列表.
  MyTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myTagsHash();

  @$internal
  @override
  MyTags create() => MyTags();
}

String _$myTagsHash() => r'37714cd052efc49aa7ff6f8d930f4088a30d07c1';

/// 当前用户的自定义标签列表. 仅认证用户支持编写标签, 未认证时不发起请求而直接返回空列表.

abstract class _$MyTags extends $AsyncNotifier<List<MyTag>> {
  FutureOr<List<MyTag>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<MyTag>>, List<MyTag>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MyTag>>, List<MyTag>>,
              AsyncValue<List<MyTag>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 使用当前用户标签 [tagId] 标记过的菜品列表.

@ProviderFor(TagDishes)
final tagDishesProvider = TagDishesFamily._();

/// 使用当前用户标签 [tagId] 标记过的菜品列表.
final class TagDishesProvider
    extends $AsyncNotifierProvider<TagDishes, DishPages> {
  /// 使用当前用户标签 [tagId] 标记过的菜品列表.
  TagDishesProvider._({
    required TagDishesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'tagDishesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tagDishesHash();

  @override
  String toString() {
    return r'tagDishesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TagDishes create() => TagDishes();

  @override
  bool operator ==(Object other) {
    return other is TagDishesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tagDishesHash() => r'798bc285ced63e013aff2fbbf1b9a95d602a8b16';

/// 使用当前用户标签 [tagId] 标记过的菜品列表.

final class TagDishesFamily extends $Family
    with
        $ClassFamilyOverride<
          TagDishes,
          AsyncValue<DishPages>,
          DishPages,
          FutureOr<DishPages>,
          int
        > {
  TagDishesFamily._()
    : super(
        retry: null,
        name: r'tagDishesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 使用当前用户标签 [tagId] 标记过的菜品列表.

  TagDishesProvider call(int tagId) =>
      TagDishesProvider._(argument: tagId, from: this);

  @override
  String toString() => r'tagDishesProvider';
}

/// 使用当前用户标签 [tagId] 标记过的菜品列表.

abstract class _$TagDishes extends $AsyncNotifier<DishPages> {
  late final _$args = ref.$arg as int;
  int get tagId => _$args;

  FutureOr<DishPages> build(int tagId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DishPages>, DishPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DishPages>, DishPages>,
              AsyncValue<DishPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 浏览足迹分栏列表, 按最近浏览时间倒序排列.

@ProviderFor(Footprints)
final footprintsProvider = FootprintsFamily._();

/// 浏览足迹分栏列表, 按最近浏览时间倒序排列.
final class FootprintsProvider
    extends $AsyncNotifierProvider<Footprints, ListPages<Footprint>> {
  /// 浏览足迹分栏列表, 按最近浏览时间倒序排列.
  FootprintsProvider._({
    required FootprintsFamily super.from,
    required FootprintKind super.argument,
  }) : super(
         retry: null,
         name: r'footprintsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$footprintsHash();

  @override
  String toString() {
    return r'footprintsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Footprints create() => Footprints();

  @override
  bool operator ==(Object other) {
    return other is FootprintsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$footprintsHash() => r'f3b3b145c08ffbe5c5592a7374d4afb919a10680';

/// 浏览足迹分栏列表, 按最近浏览时间倒序排列.

final class FootprintsFamily extends $Family
    with
        $ClassFamilyOverride<
          Footprints,
          AsyncValue<ListPages<Footprint>>,
          ListPages<Footprint>,
          FutureOr<ListPages<Footprint>>,
          FootprintKind
        > {
  FootprintsFamily._()
    : super(
        retry: null,
        name: r'footprintsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 浏览足迹分栏列表, 按最近浏览时间倒序排列.

  FootprintsProvider call(FootprintKind kind) =>
      FootprintsProvider._(argument: kind, from: this);

  @override
  String toString() => r'footprintsProvider';
}

/// 浏览足迹分栏列表, 按最近浏览时间倒序排列.

abstract class _$Footprints extends $AsyncNotifier<ListPages<Footprint>> {
  late final _$args = ref.$arg as FootprintKind;
  FootprintKind get kind => _$args;

  FutureOr<ListPages<Footprint>> build(FootprintKind kind);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ListPages<Footprint>>, ListPages<Footprint>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ListPages<Footprint>>,
                ListPages<Footprint>
              >,
              AsyncValue<ListPages<Footprint>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 当前用户的等级进度, 每次进入等级页时重新请求.

@ProviderFor(growthProgress)
final growthProgressProvider = GrowthProgressProvider._();

/// 当前用户的等级进度, 每次进入等级页时重新请求.

final class GrowthProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<GrowthProgress>,
          GrowthProgress,
          FutureOr<GrowthProgress>
        >
    with $FutureModifier<GrowthProgress>, $FutureProvider<GrowthProgress> {
  /// 当前用户的等级进度, 每次进入等级页时重新请求.
  GrowthProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'growthProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$growthProgressHash();

  @$internal
  @override
  $FutureProviderElement<GrowthProgress> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GrowthProgress> create(Ref ref) {
    return growthProgress(ref);
  }
}

String _$growthProgressHash() => r'2a518e771adf0fa4b6300427bcabb661fbeed532';

/// 当前用户的经验值明细列表, 按入账时间倒序排列.

@ProviderFor(ExperienceLedger)
final experienceLedgerProvider = ExperienceLedgerProvider._();

/// 当前用户的经验值明细列表, 按入账时间倒序排列.
final class ExperienceLedgerProvider
    extends
        $AsyncNotifierProvider<ExperienceLedger, ListPages<ExperienceEntry>> {
  /// 当前用户的经验值明细列表, 按入账时间倒序排列.
  ExperienceLedgerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'experienceLedgerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$experienceLedgerHash();

  @$internal
  @override
  ExperienceLedger create() => ExperienceLedger();
}

String _$experienceLedgerHash() => r'aceb0598009563ec59fd3ae3f6202138007c52eb';

/// 当前用户的经验值明细列表, 按入账时间倒序排列.

abstract class _$ExperienceLedger
    extends $AsyncNotifier<ListPages<ExperienceEntry>> {
  FutureOr<ListPages<ExperienceEntry>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ListPages<ExperienceEntry>>,
              ListPages<ExperienceEntry>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ListPages<ExperienceEntry>>,
                ListPages<ExperienceEntry>
              >,
              AsyncValue<ListPages<ExperienceEntry>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 保存个人资料; 若更换了头像则先上传头像文件, 再提交昵称, 签名和头像信息.
///
/// 保存成功后刷新当前用户及 "我的" 页面资料, 失败时抛出 [AppFailure].

@ProviderFor(ProfileSaver)
final profileSaverProvider = ProfileSaverProvider._();

/// 保存个人资料; 若更换了头像则先上传头像文件, 再提交昵称, 签名和头像信息.
///
/// 保存成功后刷新当前用户及 "我的" 页面资料, 失败时抛出 [AppFailure].
final class ProfileSaverProvider extends $NotifierProvider<ProfileSaver, bool> {
  /// 保存个人资料; 若更换了头像则先上传头像文件, 再提交昵称, 签名和头像信息.
  ///
  /// 保存成功后刷新当前用户及 "我的" 页面资料, 失败时抛出 [AppFailure].
  ProfileSaverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSaverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSaverHash();

  @$internal
  @override
  ProfileSaver create() => ProfileSaver();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$profileSaverHash() => r'8cbdac00301ab28866f5d8d2fe223b9bfd9b657c';

/// 保存个人资料; 若更换了头像则先上传头像文件, 再提交昵称, 签名和头像信息.
///
/// 保存成功后刷新当前用户及 "我的" 页面资料, 失败时抛出 [AppFailure].

abstract class _$ProfileSaver extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
