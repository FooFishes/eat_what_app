import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';

/// 路由的访问权限级别, 声明在路由的 `metadata` 中. 守卫仅读取该标记, 不另行维护路径白名单.
///
/// go_router 的 `metadata` 会被子路由继承, 因此父路由设为 [guest] 时, 仅限登录用户的子路由需显式覆盖为 [signedIn].
enum RouteAccess {
  /// 允许所有用户访问, 如登录页.
  public,

  /// 允许游客与已登录用户访问. 游客指本次启动后在登录页选择 "先逛逛" 的用户.
  guest,

  /// 仅限已登录用户访问, 未显式声明权限的页面均默认为此级别.
  signedIn;

  static const _key = 'access';

  /// 读取路由 `metadata` 中的访问权限标记, 未配置时默认返回 [signedIn].
  static RouteAccess of(Map<String, dynamic>? metadata) =>
      metadata?[_key] as RouteAccess? ?? signedIn;
}

/// 公开页面的路由 `metadata` 标记, 允许所有用户访问.
const publicRoute = <String, dynamic>{RouteAccess._key: RouteAccess.public};

/// 游客可访问页面的路由 `metadata` 标记.
const guestRoute = <String, dynamic>{RouteAccess._key: RouteAccess.guest};

/// 仅限已登录用户的路由 `metadata` 标记, 仅用于覆盖父路由继承的权限, 其余默认页面无需标注.
const signedInRoute = <String, dynamic>{RouteAccess._key: RouteAccess.signedIn};

/// 顶层路由守卫, 根据远程配置, 当前登录态与页面权限返回访问 [location] 时的重定向地址, 无需重定向时返回 null.
///
/// [access] 为目标页面的访问权限, [canMatch] 用于判断站内地址能否匹配路由表.
/// [forceUpdate] 表示本机版本低于强制更新线, [down] 表示停服维护中, 两者都来自远程配置.
///
/// 按顺序判断: 强制更新, 停服维护, 登录态 (技术架构 5.3).
/// 不需要更新或不在维护时访问更新页和维护页会被导回发现页, 维护结束后停在维护页的用户随之离开.
///
/// 游客停留在登录页时不执行重定向, 以便随时返回登录操作; 点击 "先逛逛" 后的跳转由登录页自行处理, 见 [browseTarget].
String? resolveRedirect({
  required Uri location,
  required RouteAccess access,
  required SessionState session,
  required bool Function(Uri location) canMatch,
  bool forceUpdate = false,
  bool down = false,
}) {
  final path = location.path;
  if (forceUpdate) return path == Paths.update ? null : Paths.update;
  if (down) return path == Paths.maintenance ? null : Paths.maintenance;
  if (path == Paths.update || path == Paths.maintenance) return Paths.discover;
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

/// 构造未登录访问 [location] 时重定向的登录页地址.
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

/// 计算在登录页点击 "先逛逛" 后的目标地址.
///
/// 若 [from] 可匹配路由表且允许游客访问则前往 [from], 否则前往发现页.
/// [accessOf] 用于查询站内地址的访问权限, 不能匹配路由表时返回 null.
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

/// 校验并返回登录后的回跳地址. 仅接受可匹配路由表的非登录页站内路径.
///
/// `from` 来自地址栏查询参数且可被外部构造, 若不校验则可能在登录后将用户重定向至外部站点.
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
