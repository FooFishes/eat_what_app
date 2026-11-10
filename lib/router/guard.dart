import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';

/// 页面的开放程度, 写在路由的 `metadata` 上. 守卫只读取该标记, 不维护路径白名单.
///
/// go_router 的 `metadata` 会被子路由继承, 父路由标了 [guest] 时, 只给登录用户的子路由要标回 [signedIn].
enum RouteAccess {
  /// 谁都能进, 如登录页.
  public,

  /// 游客和登录用户能进. 游客指这次打开 App 后在登录页点过 "先逛逛" 的人.
  guest,

  /// 只有登录后能进. 不标记的页面都属于这一档.
  signedIn;

  static const _key = 'access';

  /// 路由 `metadata` 中的标记. 没有标记时为 [signedIn].
  static RouteAccess of(Map<String, dynamic>? metadata) =>
      metadata?[_key] as RouteAccess? ?? signedIn;
}

/// 谁都能进的页面, 用作路由的 `metadata`.
const publicRoute = <String, dynamic>{RouteAccess._key: RouteAccess.public};

/// 游客也能进的页面.
const guestRoute = <String, dynamic>{RouteAccess._key: RouteAccess.guest};

/// 只有登录后能进的页面. 只用来覆盖从父路由继承的标记, 其余页面不标.
const signedInRoute = <String, dynamic>{RouteAccess._key: RouteAccess.signedIn};

// TODO: 强制更新和停服维护的跳转未实现. 远程配置接口上线后在此加入对应规则.
/// 顶层守卫. 返回访问 [location] 时应重定向到的地址, 无需重定向时返回 null.
///
/// [access] 是目标页面的开放程度. [canMatch] 判断站内地址能否匹配路由表.
///
/// 游客停在登录页时不跳走, 这样游客随时能回登录页. 点 "先逛逛" 后由登录页自己跳转, 见 [browseTarget].
String? resolveRedirect({
  required Uri location,
  required RouteAccess access,
  required SessionState session,
  required bool Function(Uri location) canMatch,
}) {
  switch (session) {
    case SignedOut(:final reason):
      if (access == RouteAccess.public) return null;
      return _login(location, reason);
    case Guest():
      if (access != RouteAccess.signedIn) return null;
      return _login(location, SignOutReason.none);
    case SignedIn(:final justRegistered):
      if (!isLoginPath(location.path)) return null;
      final from = safeReturnPath(location.queryParameters['from'], canMatch);
      if (justRegistered) {
        return Uri(
          path: Paths.verify,
          queryParameters: {'onboarding': '1', 'from': ?from},
        ).toString();
      }
      return from ?? Paths.discover;
  }
}

/// 未登录时访问 [location] 被导向的登录页地址.
String _login(Uri location, SignOutReason reason) {
  // 用户主动退出时不记录原地址. 目标是发现页时也不记录, 因为登录后默认进入发现页.
  final remember =
      reason != SignOutReason.loggedOut && location.path != Paths.discover;
  return Uri(
    path: Paths.login,
    queryParameters: {
      if (remember) 'from': location.toString(),
      if (reason == SignOutReason.expired) 'expired': '1',
    }.nullIfEmpty,
  ).toString();
}

/// 在登录页点 "先逛逛" 后去的地址.
///
/// [from] 能匹配路由表, 且游客能进时去 [from], 否则去发现页.
/// [accessOf] 返回站内地址对应页面的开放程度, 不能匹配路由表时返回 null.
String browseTarget(
  String? from,
  RouteAccess? Function(Uri location) accessOf,
) {
  final path = safeReturnPath(from, (uri) => accessOf(uri) != null);
  if (path == null) return Paths.discover;
  return switch (accessOf(Uri.parse(path))) {
    RouteAccess.public || RouteAccess.guest => path,
    RouteAccess.signedIn || null => Paths.discover,
  };
}

bool isLoginPath(String path) =>
    path == Paths.login || path.startsWith('${Paths.login}/');

/// 登录后返回的地址. 只接受能匹配路由表的站内路径, 且不能是登录页本身.
///
/// `from` 来自地址栏, 任何人都能构造. 不校验时, 构造的链接可以在登录后把用户带到外站.
String? safeReturnPath(String? from, bool Function(Uri location) canMatch) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  final uri = Uri.tryParse(from);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (isLoginPath(uri.path)) return null;
  return canMatch(uri) ? from : null;
}

extension on Map<String, String> {
  Map<String, String>? get nullIfEmpty => isEmpty ? null : this;
}
