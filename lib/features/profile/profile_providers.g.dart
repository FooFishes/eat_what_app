// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 我的统计: 获赞, 上传的菜, 粉丝, 关注.
///
/// "我的" 是常驻的主页面, 切换到其他主页面后保留结果, 不重新请求. 发布成功后重新请求.

@ProviderFor(myProfile)
final myProfileProvider = MyProfileProvider._();

/// 我的统计: 获赞, 上传的菜, 粉丝, 关注.
///
/// "我的" 是常驻的主页面, 切换到其他主页面后保留结果, 不重新请求. 发布成功后重新请求.

final class MyProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile?>,
          UserProfile?,
          FutureOr<UserProfile?>
        >
    with $FutureModifier<UserProfile?>, $FutureProvider<UserProfile?> {
  /// 我的统计: 获赞, 上传的菜, 粉丝, 关注.
  ///
  /// "我的" 是常驻的主页面, 切换到其他主页面后保留结果, 不重新请求. 发布成功后重新请求.
  MyProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myProfileHash();

  @$internal
  @override
  $FutureProviderElement<UserProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserProfile?> create(Ref ref) {
    return myProfile(ref);
  }
}

String _$myProfileHash() => r'02b97837386a0066675c0827dfe5e703b6bef032';

/// 我上传的菜. 发布成功后重新请求.

@ProviderFor(MyUploads)
final myUploadsProvider = MyUploadsProvider._();

/// 我上传的菜. 发布成功后重新请求.
final class MyUploadsProvider
    extends $AsyncNotifierProvider<MyUploads, DishPages> {
  /// 我上传的菜. 发布成功后重新请求.
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

String _$myUploadsHash() => r'34093fce95a085e36b5dfaaa96672bbd534c9a61';

/// 我上传的菜. 发布成功后重新请求.

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

/// 我收藏的菜, 按收藏时间倒序.

@ProviderFor(MyFavorites)
final myFavoritesProvider = MyFavoritesProvider._();

/// 我收藏的菜, 按收藏时间倒序.
final class MyFavoritesProvider
    extends $AsyncNotifierProvider<MyFavorites, DishPages> {
  /// 我收藏的菜, 按收藏时间倒序.
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

String _$myFavoritesHash() => r'837ec128d9442a495ef3670fdae00681c4cb4a48';

/// 我收藏的菜, 按收藏时间倒序.

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
