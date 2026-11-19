import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/user/user_repository.dart';
import 'package:eat/domain/models/people.dart';
import 'package:eat/state/published.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'social.g.dart';

/// 当前登录用户的 id, 未登录或尚未获取用户信息时为 null.
int? _myId(Ref ref) =>
    ref.watch(sessionProvider.select((s) => s is SignedIn ? s.user?.id : null));

/// 指定用户的公开资料与统计数据, 由 "我的" 和他人主页共用.
///
/// - 他人资料在离开页面后保留 5 分钟, 从列表点击进入他人主页时可直接复用.
/// - 当前登录用户的资料保持常驻, 切换回 "我的" 页面时不重新请求, 仅在发布成功后重新请求.
/// - 当前登录用户的资料另存本地缓存. 第一次读取时有缓存就先给缓存, 再在后台请求新的; 请求失败时保留缓存.
/// - 关注和屏蔽成功后, 由 [Follows] 触发重新请求双方的资料以更新统计.
@riverpod
Future<UserProfile> userProfile(Ref ref, int userId) async {
  final users = ref.watch(userRepositoryProvider);
  if (userId != _myId(ref)) {
    ref.cacheFor(const Duration(minutes: 5));
    return users.profile(userId, cancelToken: ref.cancelToken());
  }
  ref.keepAlive();
  ref.watch(publishedCountProvider);
  return ref.cacheFirst(
    () => users.cachedProfile(userId),
    () => users.profile(userId, cache: true, cancelToken: ref.cancelToken()),
  );
}

/// 关注关系的本地覆盖值, 以对方的 id 为键, 用于乐观更新.
///
/// - 点击后先修改覆盖值, 他人主页和列表中的同一个人同步变化.
/// - 请求成功后重新请求双方的资料, 以更新粉丝和关注数. 失败时恢复原值.
/// - 切换账号时全部清空.
@Riverpod(keepAlive: true)
class Follows extends _$Follows {
  @override
  Map<int, bool> build() {
    _myId(ref);
    return const {};
  }

  final _pending = <int>{};

  /// 当前用户与 [userId] 的关注关系. [followedByMe] 是服务端给的值, 本地覆盖值优先.
  FollowState stateOf(
    int userId, {
    required bool followedByMe,
    required bool followsMe,
  }) => FollowState.of(
    followedByMe: state[userId] ?? followedByMe,
    followsMe: followsMe,
  );

  /// 关注或取消关注. 成功返回 null, 失败时恢复原值并返回失败原因.
  ///
  /// 同一用户的上一次请求未完成时忽略本次调用, 避免连续点击发出相反的请求.
  Future<AppFailure?> set(int userId, {required bool following}) async {
    if (!_pending.add(userId)) return null;
    final before = state[userId];
    state = {...state, userId: following};
    try {
      await ref
          .read(userRepositoryProvider)
          .setFollowing(userId, following: following);
      if (ref.mounted) refresh(userId, keepOverride: true);
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = {...state}..remove(userId);
        if (before != null) state = {...state, userId: before};
      }
      return e;
    } finally {
      _pending.remove(userId);
    }
  }

  /// 关系在别处发生变化 (如屏蔽后关注解除) 时, 重新请求双方的资料.
  ///
  /// [keepOverride] 为 false 时同时清除覆盖值, 以服务端结果为准.
  void refresh(int userId, {bool keepOverride = false}) {
    if (!keepOverride && state.containsKey(userId)) {
      state = {...state}..remove(userId);
    }
    ref.invalidate(userProfileProvider(userId));
    final me = ref.read(sessionProvider);
    if (me case SignedIn(user: final user?)) {
      ref.invalidate(userProfileProvider(user.id));
    }
  }
}
