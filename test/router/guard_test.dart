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

String? _redirect(
  String location,
  SessionState session, {
  bool isPublic = false,
}) => resolveRedirect(
  location: Uri.parse(location),
  isPublic: isPublic,
  session: session,
  canMatch: _known,
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

    test('「未登录可进」的页面不拦', () {
      expect(
        _redirect('/login/phone', const SignedOut(), isPublic: true),
        isNull,
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
        _redirect('/login/phone?from=%2Fsettings', signedIn, isPublic: true),
        '/settings',
      );
      expect(_redirect('/login', signedIn, isPublic: true), Paths.discover);
    });

    test('新号码刚注册，先进认证引导，原地址接着带上', () {
      const registered = SignedIn(justRegistered: true);
      expect(
        Uri.parse(
          _redirect('/login/phone?from=%2Fme', registered, isPublic: true)!,
        ),
        Uri.parse('/verify?onboarding=1&from=%2Fme'),
      );
      expect(
        _redirect('/login/phone', registered, isPublic: true),
        '/verify?onboarding=1',
      );
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
}
