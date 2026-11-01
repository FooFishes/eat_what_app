import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/auth/auth_repository.dart';
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

final class SignedIn extends SessionState {
  const SignedIn({this.user, this.justRegistered = false});

  /// 当前用户信息. 登录后尚未获取成功时为 null, 例如登录后立即断网.
  ///
  /// 启动时先使用缓存的用户信息, 再在后台刷新.
  final CurrentUser? user;

  /// 新号码刚完成自动注册. 守卫据此把页面从登录页导向认证引导, 而不是返回原页面.
  final bool justRegistered;
}

/// 登录态. 路由守卫根据它决定跳转.
///
/// 启动时恢复. 登录, 退出, 过期和刷新用户信息时更新.
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
    state = SignedIn(user: user, justRegistered: result.newUser);
  }

  /// 重新获取用户信息. 回到前台, 认证完成和服务端返回无权限时调用.
  ///
  /// 失败时保留原有信息.
  Future<void> refreshUser() async {
    if (state is! SignedIn) return;
    try {
      final user = await _users.fetchCurrent();
      if (state case SignedIn(:final justRegistered)) {
        state = SignedIn(user: user, justRegistered: justRegistered);
      }
    } on AppFailure {
      // 登录过期由网络层调用 [expire] 处理. 其他失败 (如网络不可达) 等待下次刷新.
    }
  }

  /// 标记认证引导已显示. 之后守卫按普通的已登录状态处理, 不再导向认证引导.
  void finishOnboarding() {
    if (state case SignedIn(:final user, justRegistered: true)) {
      state = SignedIn(user: user);
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

  /// 清除账号作用域的本地数据: 凭证和接口缓存.
  ///
  /// 设备级偏好 (同意记录, 校区选择) 保留.
  Future<void> _clearLocal() async {
    await _tokens.clear();
    await _kv.deletePrefix('cache.');
  }
}

/// 当前账号状态, 由登录态派生. 决定哪些操作需要拦截.
@riverpod
AccountStatus accountStatus(Ref ref) => switch (ref.watch(sessionProvider)) {
  SignedOut() => AccountStatus.of(signedIn: false),
  SignedIn(:final user) => AccountStatus.of(signedIn: true, user: user),
};
