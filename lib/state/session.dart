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

/// 登录态。
sealed class SessionState {
  const SessionState();
}

/// 为什么没登录：决定登录页说什么、登录后回哪。
enum SignOutReason {
  /// 第一次打开，或者上次就没登录。
  none,

  /// 用户自己退出。登录后回发现页，不回退出前的页面。
  loggedOut,

  /// 登录过期，登录页提示「登录已过期，请重新登录」，登录后回到原来的页面。
  expired,
}

final class SignedOut extends SessionState {
  const SignedOut([this.reason = SignOutReason.none]);

  final SignOutReason reason;
}

final class SignedIn extends SessionState {
  const SignedIn({this.user, this.justRegistered = false});

  /// 还没拉到用户信息时为 null（刚登录就断网）。启动时先用缓存的，后台再刷新。
  final CurrentUser? user;

  /// 新号码刚自动注册：守卫把它从登录页送进认证引导，而不是直接回原页面（技术架构 5.4）。
  final bool justRegistered;
}

/// 登录态：启动时恢复，登录、退出、过期、刷新用户信息时更新。路由守卫跟着它跳转。
@Riverpod(keepAlive: true)
class Session extends _$Session {
  /// 有这个标记说明本机装过 App。iOS 卸载后 Keychain 里的 token 会留下来，而 `shared_preferences`
  /// 不会，所以没有标记却读到了 token，就是卸载重装，要当作没登录（技术架构 3 第 4 步）。
  static const installedKey = 'prefs.installed';

  @override
  SessionState build() => const SignedOut();

  TokenStore get _tokens => ref.read(tokenStoreProvider);
  KvStore get _kv => ref.read(kvStoreProvider);
  UserRepository get _users => ref.read(userRepositoryProvider);

  /// 启动时读出上一次的登录态：有 token 就当已登录，先用缓存的用户信息，后台再向服务端核对。
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
      // 本地存储读坏了也要能启动，按没登录处理。
      debugPrint('restore session failed: $e');
      return;
    }
    unawaited(refreshUser());
  }

  /// 登录或注册成功：存凭证、拉用户信息。用户信息拉不到也算登录成功，之后再刷新。
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

  /// 重新拉用户信息：回到前台、认证回来、服务端说没权限时都调一次。失败时保留原来的信息。
  Future<void> refreshUser() async {
    if (state is! SignedIn) return;
    try {
      final user = await _users.fetchCurrent();
      if (state case SignedIn(:final justRegistered)) {
        state = SignedIn(user: user, justRegistered: justRegistered);
      }
    } on AppFailure {
      // 过期由网络层通知 [expire]；其余失败（没网）下次再刷新。
    }
  }

  /// 认证引导已经显示过了，之后再去登录页就按普通的已登录处理。
  void finishOnboarding() {
    if (state case SignedIn(:final user, justRegistered: true)) {
      state = SignedIn(user: user);
    }
  }

  /// 网络层发现登录过期。守卫会带着当前地址去登录页。
  void expire() {
    if (state is! SignedIn) return;
    unawaited(_clearLocal());
    state = const SignedOut(SignOutReason.expired);
  }

  /// 退出登录：先告诉服务端（失败也继续），再清掉这台设备上的登录信息和个人数据。
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    await _clearLocal();
    state = const SignedOut(SignOutReason.loggedOut);
  }

  /// 清掉账号作用域的本地数据：凭证、接口缓存。设备级的偏好（同意记录、校区）留着（技术架构 9.1）。
  Future<void> _clearLocal() async {
    await _tokens.clear();
    await _kv.deletePrefix('cache.');
  }
}

/// 当前账号能做什么，由登录态派生（技术架构 8.1）。
@riverpod
AccountStatus accountStatus(Ref ref) => switch (ref.watch(sessionProvider)) {
  SignedOut() => AccountStatus.of(signedIn: false),
  SignedIn(:final user) => AccountStatus.of(signedIn: true, user: user),
};
