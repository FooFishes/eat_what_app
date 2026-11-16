import 'package:eat/router/guard.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

/// 按前缀判断地址是否在路由表中. 判断较粗略, 只满足守卫测试的需要.
bool _known(Uri uri) => const [
  '/discover',
  '/nearby',
  '/me',
  '/settings',
  '/verify',
  '/publish',
  '/login',
].any((p) => uri.path == p || uri.path.startsWith('$p/'));

/// 粗略的开放程度表, 只满足守卫测试的需要. 不在 [_known] 中的地址为 null.
RouteAccess? _accessOf(Uri uri) {
  if (!_known(uri)) return null;
  if (uri.path.startsWith(Paths.login)) return RouteAccess.public;
  if (uri.path == Paths.discover ||
      uri.path == Paths.nearby ||
      uri.path == Paths.me ||
      uri.path == Paths.settings) {
    return RouteAccess.guest;
  }
  return RouteAccess.signedIn;
}

String? _redirect(
  String location,
  SessionState session, {
  RouteAccess access = RouteAccess.signedIn,
  bool forceUpdate = false,
  bool down = false,
}) => resolveRedirect(
  location: Uri.parse(location),
  access: access,
  session: session,
  canMatch: _known,
  forceUpdate: forceUpdate,
  down: down,
);

void main() {
  group('没登录', () {
    test('去要登录的页面，带着原地址去登录页', () {
      expect(
        _redirect('/settings/account', const SignedOut()),
        '/login?from=%2Fsettings%2Faccount',
      );
    });

    test('原地址带参数时整个编码进 from', () {
      final target = _redirect('/me?tab=1', const SignedOut());
      expect(Uri.parse(target!).queryParameters['from'], '/me?tab=1');
    });

    test('要去的就是发现页时不记原地址', () {
      expect(_redirect(Paths.discover, const SignedOut()), Paths.login);
    });

    test('登录过期再带 expired=1', () {
      final target = Uri.parse(
        _redirect('/me', const SignedOut(SignOutReason.expired))!,
      );
      expect(target.path, Paths.login);
      expect(target.queryParameters, {'from': '/me', 'expired': '1'});
    });

    test('自己退出的不记原地址', () {
      expect(
        _redirect('/settings', const SignedOut(SignOutReason.loggedOut)),
        Paths.login,
      );
    });

    test('谁都能进的页面不拦', () {
      expect(
        _redirect(
          '/login/phone',
          const SignedOut(),
          access: RouteAccess.public,
        ),
        isNull,
      );
    });

    test('没点「先逛逛」时，游客能进的页面也去登录页', () {
      expect(
        _redirect('/nearby', const SignedOut(), access: RouteAccess.guest),
        '/login?from=%2Fnearby',
      );
    });
  });

  group('游客', () {
    const guest = Guest();

    test('游客能进的页面和谁都能进的页面不拦', () {
      expect(_redirect('/me', guest, access: RouteAccess.guest), isNull);
      expect(_redirect('/login', guest, access: RouteAccess.public), isNull);
    });

    test('停在登录页不跳走，随时能回登录页', () {
      expect(
        _redirect('/login?from=%2Fsettings', guest, access: RouteAccess.public),
        isNull,
      );
    });

    test('从地址栏或链接进只给登录用户的页面，带着原地址去登录页', () {
      expect(
        _redirect('/settings/account', guest),
        '/login?from=%2Fsettings%2Faccount',
      );
    });
  });

  group('已登录', () {
    const signedIn = SignedIn();

    test('普通页面不拦', () {
      expect(_redirect('/me', signedIn), isNull);
      expect(_redirect('/verify', signedIn), isNull);
    });

    test('还在登录页时回到原地址，没有就去发现页', () {
      expect(
        _redirect(
          '/login/phone?from=%2Fsettings',
          signedIn,
          access: RouteAccess.public,
        ),
        '/settings',
      );
      expect(
        _redirect('/login', signedIn, access: RouteAccess.public),
        Paths.discover,
      );
    });

    test('新号码刚注册，先进认证引导，原地址接着带上', () {
      const registered = SignedIn(justRegistered: true);
      expect(
        Uri.parse(
          _redirect(
            '/login/phone?from=%2Fme',
            registered,
            access: RouteAccess.public,
          )!,
        ),
        Uri.parse('/verify?onboarding=1&from=%2Fme'),
      );
      expect(
        _redirect('/login/phone', registered, access: RouteAccess.public),
        '/verify?onboarding=1',
      );
    });
  });

  group('「先逛逛」后去的地址', () {
    test('游客能进的原地址照去', () {
      expect(browseTarget('/me?tab=1', _accessOf), '/me?tab=1');
    });

    test('原地址游客看不了，去发现页', () {
      expect(browseTarget('/settings/account', _accessOf), Paths.discover);
    });

    test('没有原地址、站外地址、对不上路由的地址，都去发现页', () {
      for (final from in [null, 'https://evil.example/x', '/no-such-page']) {
        expect(browseTarget(from, _accessOf), Paths.discover);
      }
    });
  });

  group('登录后回去的地址只接受站内、对得上路由的路径', () {
    for (final from in [
      'https://evil.example/x',
      '//evil.example/x',
      'evil.example',
      '/login',
      '/login/password',
      '/no-such-page',
    ]) {
      test(from, () => expect(safeReturnPath(from, _known), isNull));
    }

    test('站内路径原样返回', () {
      expect(safeReturnPath('/me?tab=1', _known), '/me?tab=1');
    });
  });

  group('强制更新和停服维护', () {
    const signedIn = SignedIn();

    test('低于强制更新线时任何页面都去更新页', () {
      for (final session in const [SignedOut(), Guest(), signedIn]) {
        expect(
          _redirect('/me', session, forceUpdate: true),
          Paths.update,
          reason: '$session',
        );
      }
      expect(
        _redirect(
          Paths.login,
          const SignedOut(),
          access: RouteAccess.public,
          forceUpdate: true,
        ),
        Paths.update,
      );
    });

    test('已在更新页时不再跳转，未登录也能停留', () {
      expect(
        _redirect(
          Paths.update,
          const SignedOut(),
          access: RouteAccess.public,
          forceUpdate: true,
        ),
        isNull,
      );
    });

    test('停服维护时任何页面都去维护页', () {
      expect(_redirect('/settings', signedIn, down: true), Paths.maintenance);
      expect(
        _redirect(
          Paths.maintenance,
          const SignedOut(),
          access: RouteAccess.public,
          down: true,
        ),
        isNull,
      );
    });

    test('强制更新先于停服维护', () {
      expect(
        _redirect('/me', signedIn, forceUpdate: true, down: true),
        Paths.update,
      );
      expect(
        _redirect(
          Paths.maintenance,
          signedIn,
          access: RouteAccess.public,
          forceUpdate: true,
          down: true,
        ),
        Paths.update,
      );
    });

    test('不需要更新或维护结束后离开更新页和维护页，回到发现页', () {
      for (final path in [Paths.update, Paths.maintenance]) {
        expect(
          _redirect(path, signedIn, access: RouteAccess.public),
          Paths.discover,
        );
      }
    });

    test('配置正常时按登录态判断', () {
      expect(
        _redirect('/settings/account', const SignedOut()),
        '/login?from=%2Fsettings%2Faccount',
      );
    });
  });
}
