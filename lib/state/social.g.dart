// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 指定用户的公开资料与统计数据, 由 "我的", 他人主页, 粉丝和关注列表的每一行共用.
///
/// - 他人资料在离开页面后保留 5 分钟, 从列表点击进入他人主页时可直接复用.
/// - 当前登录用户的资料保持常驻, 切换回 "我的" 页面时不重新请求, 仅在发布成功后重新请求.
/// - 当前登录用户的资料另存本地缓存. 第一次读取时有缓存就先给缓存, 再在后台请求新的; 请求失败时保留缓存.
/// - 关注和屏蔽成功后, 由 [Follows] 触发重新请求双方的资料以更新统计.

@ProviderFor(userProfile)
final userProfileProvider = UserProfileFamily._();

/// 指定用户的公开资料与统计数据, 由 "我的", 他人主页, 粉丝和关注列表的每一行共用.
///
/// - 他人资料在离开页面后保留 5 分钟, 从列表点击进入他人主页时可直接复用.
/// - 当前登录用户的资料保持常驻, 切换回 "我的" 页面时不重新请求, 仅在发布成功后重新请求.
/// - 当前登录用户的资料另存本地缓存. 第一次读取时有缓存就先给缓存, 再在后台请求新的; 请求失败时保留缓存.
/// - 关注和屏蔽成功后, 由 [Follows] 触发重新请求双方的资料以更新统计.

final class UserProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile>,
          UserProfile,
          FutureOr<UserProfile>
        >
    with $FutureModifier<UserProfile>, $FutureProvider<UserProfile> {
  /// 指定用户的公开资料与统计数据, 由 "我的", 他人主页, 粉丝和关注列表的每一行共用.
  ///
  /// - 他人资料在离开页面后保留 5 分钟, 从列表点击进入他人主页时可直接复用.
  /// - 当前登录用户的资料保持常驻, 切换回 "我的" 页面时不重新请求, 仅在发布成功后重新请求.
  /// - 当前登录用户的资料另存本地缓存. 第一次读取时有缓存就先给缓存, 再在后台请求新的; 请求失败时保留缓存.
  /// - 关注和屏蔽成功后, 由 [Follows] 触发重新请求双方的资料以更新统计.
  UserProfileProvider._({
    required UserProfileFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'userProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @override
  String toString() {
    return r'userProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UserProfile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserProfile> create(Ref ref) {
    final argument = this.argument as int;
    return userProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userProfileHash() => r'42cd56c7076930d0ee8e858f37aaaeb748aed305';

/// 指定用户的公开资料与统计数据, 由 "我的", 他人主页, 粉丝和关注列表的每一行共用.
///
/// - 他人资料在离开页面后保留 5 分钟, 从列表点击进入他人主页时可直接复用.
/// - 当前登录用户的资料保持常驻, 切换回 "我的" 页面时不重新请求, 仅在发布成功后重新请求.
/// - 当前登录用户的资料另存本地缓存. 第一次读取时有缓存就先给缓存, 再在后台请求新的; 请求失败时保留缓存.
/// - 关注和屏蔽成功后, 由 [Follows] 触发重新请求双方的资料以更新统计.

final class UserProfileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UserProfile>, int> {
  UserProfileFamily._()
    : super(
        retry: null,
        name: r'userProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 指定用户的公开资料与统计数据, 由 "我的", 他人主页, 粉丝和关注列表的每一行共用.
  ///
  /// - 他人资料在离开页面后保留 5 分钟, 从列表点击进入他人主页时可直接复用.
  /// - 当前登录用户的资料保持常驻, 切换回 "我的" 页面时不重新请求, 仅在发布成功后重新请求.
  /// - 当前登录用户的资料另存本地缓存. 第一次读取时有缓存就先给缓存, 再在后台请求新的; 请求失败时保留缓存.
  /// - 关注和屏蔽成功后, 由 [Follows] 触发重新请求双方的资料以更新统计.

  UserProfileProvider call(int userId) =>
      UserProfileProvider._(argument: userId, from: this);

  @override
  String toString() => r'userProfileProvider';
}

/// 关注关系的本地覆盖值, 以对方的 id 为键, 用于乐观更新.
///
/// - 点击后先修改覆盖值, 他人主页和列表中的同一个人同步变化.
/// - 请求成功后重新请求双方的资料, 以更新粉丝和关注数. 失败时恢复原值.
/// - 切换账号时全部清空.

@ProviderFor(Follows)
final followsProvider = FollowsProvider._();

/// 关注关系的本地覆盖值, 以对方的 id 为键, 用于乐观更新.
///
/// - 点击后先修改覆盖值, 他人主页和列表中的同一个人同步变化.
/// - 请求成功后重新请求双方的资料, 以更新粉丝和关注数. 失败时恢复原值.
/// - 切换账号时全部清空.
final class FollowsProvider extends $NotifierProvider<Follows, Map<int, bool>> {
  /// 关注关系的本地覆盖值, 以对方的 id 为键, 用于乐观更新.
  ///
  /// - 点击后先修改覆盖值, 他人主页和列表中的同一个人同步变化.
  /// - 请求成功后重新请求双方的资料, 以更新粉丝和关注数. 失败时恢复原值.
  /// - 切换账号时全部清空.
  FollowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'followsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followsHash();

  @$internal
  @override
  Follows create() => Follows();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<int, bool>>(value),
    );
  }
}

String _$followsHash() => r'0b0dd672de2f2df1d95fc1c483f5798f9dfa405a';

/// 关注关系的本地覆盖值, 以对方的 id 为键, 用于乐观更新.
///
/// - 点击后先修改覆盖值, 他人主页和列表中的同一个人同步变化.
/// - 请求成功后重新请求双方的资料, 以更新粉丝和关注数. 失败时恢复原值.
/// - 切换账号时全部清空.

abstract class _$Follows extends $Notifier<Map<int, bool>> {
  Map<int, bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<int, bool>, Map<int, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<int, bool>, Map<int, bool>>,
              Map<int, bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
