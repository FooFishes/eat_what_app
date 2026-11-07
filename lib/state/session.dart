import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/data/sessions/session_rotation.dart';
import 'package:eat/data/user/user_repository.dart';
import 'package:eat/domain/models/account_status.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session.g.dart';

sealed class SessionState {
  const SessionState();
}

/// 未登录的原因. 决定登录页的提示和登录后的去向.
enum SignOutReason {
  /// 首次启动, 或上次运行时已处于未登录状态.
  none,

  /// 用户主动退出. 登录后进入发现页, 不返回退出前的页面.
  loggedOut,

  /// 登录过期. 登录页显示过期提示, 登录后返回原页面.
  expired,
}

final class SignedOut extends SessionState {
  const SignedOut([this.reason = SignOutReason.none]);

  final SignOutReason reason;
}

/// 游客: 在登录页点了 "去逛逛", 没有登录也能浏览.
///
/// 只保存在内存中. 关闭 App 后再打开, 退出登录和登录过期后都回到 [SignedOut], 要再点一次 "去逛逛".
/// 产品希望大家登录使用, 游客只是先看看的入口, 所以不记住上次是游客.
final class Guest extends SessionState {
  const Guest();
}

final class SignedIn extends SessionState {
  const SignedIn({
    this.user,
    this.justRegistered = false,
    this.restricted = false,
  });

  /// 当前用户信息. 登录后尚未获取成功时为 null, 例如登录后立即断网.
  ///
  /// 启动时先使用缓存的用户信息, 再在后台刷新.
  final CurrentUser? user;

  /// 新号码刚完成自动注册. 守卫据此把页面从登录页导向认证引导, 而不是返回原页面.
  final bool justRegistered;

  /// 本次登录得到的是受限会话, 即登录时账号已被封禁. 只保存在内存中, 重启后为 false.
  ///
  /// 账号状态以 [user] 的 `banned` 为准, 本字段只在尚未获取用户信息时使用.
  final bool restricted;
}

/// 登录态. 路由守卫根据它决定跳转.
///
/// 启动时恢复. 登录, "去逛逛", 退出, 过期和刷新用户信息时更新.
@Riverpod(keepAlive: true)
class Session extends _$Session {
  /// 本机安装过 App 的标记.
  ///
  /// iOS 卸载 App 后 Keychain 中的 token 仍会保留, `shared_preferences` 的数据则被删除.
  /// 因此读到 token 却没有该标记, 说明 App 被卸载重装, 按未登录处理.
  static const installedKey = 'prefs.installed';

  @override
  SessionState build() => const SignedOut();

  TokenStore get _tokens => ref.read(tokenStoreProvider);
  KvStore get _kv => ref.read(kvStoreProvider);
  UserRepository get _users => ref.read(userRepositoryProvider);

  /// 启动时恢复上一次的登录态.
  ///
  /// 存在 token 即视为已登录. 先使用缓存的用户信息, 再在后台向服务端核对.
  Future<void> restore() async {
    try {
      if (await _kv.read(installedKey) == null) {
        await _tokens.clear();
        await _kv.write(installedKey, '1');
        return;
      }
      if (await _tokens.load() == null) return;
      state = SignedIn(user: await _users.readCached());
    } on Object catch (e) {
      // 本地存储读取失败时按未登录处理, 以保证应用能够启动.
      debugPrint('restore session failed: $e');
      return;
    }
    unawaited(refreshUser());
  }

  /// 登录或注册成功后保存凭证并获取用户信息.
  ///
  /// 获取用户信息失败不影响登录结果, 之后再刷新.
  Future<void> signIn(SignInResult result) async {
    await _tokens.save(result.token);
    CurrentUser? user;
    try {
      user = await _users.fetchCurrent();
    } on AppFailure catch (e) {
      if (e.kind == FailureKind.sessionExpired) return;
    }
    state = SignedIn(
      user: user,
      justRegistered: result.newUser,
      restricted: result.restricted,
    );
  }

  /// 重新获取用户信息. 回到前台, 认证完成和服务端返回无权限时调用.
  ///
  /// 失败时保留原有信息.
  Future<void> refreshUser() async {
    if (state is! SignedIn) return;
    try {
      final user = await _users.fetchCurrent();
      if (state case SignedIn(:final justRegistered, :final restricted)) {
        state = SignedIn(
          user: user,
          justRegistered: justRegistered,
          restricted: restricted,
        );
      }
    } on AppFailure {
      // 登录过期由网络层调用 [expire] 处理. 其他失败 (如网络不可达) 等待下次刷新.
    }
  }

  /// 在登录页点 "去逛逛" 后成为游客. 已登录时不变.
  ///
  /// 同意记录由登录页先写入, 本方法只更新登录态.
  void browse() {
    if (state is SignedIn) return;
    state = const Guest();
  }

  /// 标记认证引导已显示. 之后守卫按普通的已登录状态处理, 不再导向认证引导.
  void finishOnboarding() {
    if (state case SignedIn(
      :final user,
      :final restricted,
      justRegistered: true,
    )) {
      state = SignedIn(user: user, restricted: restricted);
    }
  }

  /// 网络层发现登录过期时调用. 守卫随后带上当前地址跳转登录页.
  void expire() {
    if (state is! SignedIn) return;
    unawaited(_clearLocal());
    state = const SignedOut(SignOutReason.expired);
  }

  /// 退出登录: 先通知服务端, 再清除本机的凭证和账号数据.
  ///
  /// 通知服务端失败不影响退出.
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    await _clearLocal();
    state = const SignedOut(SignOutReason.loggedOut);
  }

  /// 服务端已让所有设备的会话失效 (如刚设置了用户名) 时调用. 清除本机登录态, 不再通知服务端.
  ///
  /// 和主动退出一样, 登录后进入发现页.
  Future<void> reauthenticate() async {
    await _clearLocal();
    state = const SignedOut(SignOutReason.loggedOut);
  }

  /// 下线其他设备或换绑手机后, 采用服务端换发的会话.
  ///
  /// 换发完成时保存新凭证并刷新用户信息, 返回 true. 未能获取新凭证时清除本机登录态并回到登录页, 返回 false.
  Future<bool> adoptRotation(Rotation rotation) async {
    switch (rotation) {
      case RotationReady(:final token, :final restricted):
        await _tokens.save(token);
        if (state case SignedIn(:final user, :final justRegistered)) {
          state = SignedIn(
            user: user,
            justRegistered: justRegistered,
            restricted: restricted,
          );
        }
        await refreshUser();
        return true;
      case RotationNeedsSignIn():
        await reauthenticate();
        return false;
    }
  }

  /// 清除账号作用域的本地数据: 凭证和接口缓存.
  ///
  /// 设备级偏好 (同意记录, 校区选择) 保留.
  Future<void> _clearLocal() async {
    await _tokens.clear();
    await _kv.deletePrefix('cache.');
  }
}

/// 当前账号状态, 由登录态派生. 决定哪些操作需要拦截.
///
/// 游客也是未登录. 游客能进哪些页面由路由的标记决定, 这里不区分.
@riverpod
AccountStatus accountStatus(Ref ref) => switch (ref.watch(sessionProvider)) {
  SignedOut() || Guest() => AccountStatus.of(signedIn: false),
  SignedIn(:final user, :final restricted) => AccountStatus.of(
    signedIn: true,
    user: user,
    restricted: restricted,
  ),
};
