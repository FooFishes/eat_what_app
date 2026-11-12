import 'dart:convert';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/data/user/user_repository.dart';
import 'package:eat/domain/models/account_status.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

const _token = AuthToken(name: 'satoken', value: 'tk');

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  group('启动时恢复', () {
    test('第一次启动（或 iOS 卸载重装）时清掉残留的 token，按没登录处理', () async {
      final container = await env.container();
      env.secure.values
        ..['auth.tokenName'] = 'satoken'
        ..['auth.tokenValue'] = 'left-over';

      await container.read(sessionProvider.notifier).restore();
      expect(container.read(sessionProvider), isA<SignedOut>());
      expect(env.secure.values, isEmpty);
      expect(env.kv.values[Session.installedKey], isNotNull);
    });

    test('有 token 就当已登录，先用缓存的用户信息，后台再核对', () async {
      env.kv.values[Session.installedKey] = '1';
      env.kv.values[UserRepository.cacheKey] = jsonEncode(userInfoJson());
      env.adapter.on('GET /user/info', [
        FakeAdapter.ok(userInfoJson(verified: true, method: 'email')),
      ]);
      final container = await env.container(token: _token);

      await container.read(sessionProvider.notifier).restore();
      final restored = container.read(sessionProvider) as SignedIn;
      expect(restored.user?.nickname, '天凉被破王');
      expect(restored.user?.verified, isFalse, reason: '先用缓存');

      await pumpEventQueue();
      final refreshed = container.read(sessionProvider) as SignedIn;
      expect(refreshed.user?.verified, isTrue);
      expect(refreshed.user?.verifyMethod, VerifyMethod.schoolEmail);
      expect(container.read(accountStatusProvider), isA<VerifiedStatus>());
    });

    test('后台核对时发现过期，回到没登录，并记下是过期', () async {
      env.kv.values[Session.installedKey] = '1';
      env.adapter.on('GET /user/info', [FakeAdapter.fail(20001)]);
      final container = await env.container(token: _token);

      await container.read(sessionProvider.notifier).restore();
      await pumpEventQueue();
      final state = container.read(sessionProvider);
      expect(state, isA<SignedOut>());
      expect((state as SignedOut).reason, SignOutReason.expired);
      expect(env.secure.values, isEmpty);
    });
  });

  test('登录成功：存凭证、拉用户信息', () async {
    env.adapter.on('GET /user/info', [FakeAdapter.ok(userInfoJson())]);
    final container = await env.container();

    await container
        .read(sessionProvider.notifier)
        .signIn(const SignInResult(token: _token, newUser: true));
    final state = container.read(sessionProvider) as SignedIn;
    expect(state.justRegistered, isTrue);
    expect(state.user?.phone, '13812345678');
    expect(env.secure.values['auth.tokenValue'], 'tk');
    expect(
      env.adapter.sent('GET /user/info').single.headers['satoken'],
      'Bearer tk',
    );
    expect(container.read(accountStatusProvider), isA<UnverifiedStatus>());

    container.read(sessionProvider.notifier).finishOnboarding();
    expect(
      (container.read(sessionProvider) as SignedIn).justRegistered,
      isFalse,
    );
  });

  test('刚登录就断网也算登录成功，用户信息之后再拉', () async {
    env.adapter.on('GET /user/info', [const FakeResponse.offline()]);
    final container = await env.container();

    await container
        .read(sessionProvider.notifier)
        .signIn(const SignInResult(token: _token, newUser: false));
    expect((container.read(sessionProvider) as SignedIn).user, isNull);
  });

  test('任何接口返回登录过期，都清掉登录态和缓存', () async {
    env.kv.values[UserRepository.cacheKey] = '{}';
    env.kv.values['prefs.installed'] = '1';
    env.adapter.on('GET /anything', [FakeAdapter.fail(20001)]);
    final container = await env.container(
      session: const SignedIn(user: testUser),
      token: _token,
    );

    await expectLater(
      container.read(apiClientProvider).get('/anything'),
      throwsA(isA<AppFailure>()),
    );
    await pumpEventQueue();
    final state = container.read(sessionProvider) as SignedOut;
    expect(state.reason, SignOutReason.expired);
    expect(env.secure.values, isEmpty);
    expect(env.kv.values.keys, ['prefs.installed']);
  });

  test('没权限时重新拉用户信息，按新状态处理', () async {
    env.adapter
      ..on('POST /foods/like', [FakeAdapter.fail(20004)])
      ..on('GET /user/info', [FakeAdapter.ok(userInfoJson(verified: true))]);
    final container = await env.container(
      session: const SignedIn(user: testUser),
      token: _token,
    );

    await expectLater(
      container.read(apiClientProvider).post('/foods/like'),
      throwsA(isA<AppFailure>()),
    );
    await pumpEventQueue();
    expect(container.read(accountStatusProvider), isA<VerifiedStatus>());
  });

  test('带凭证的请求收到封禁码：清掉登录态和缓存，原因记为封禁', () async {
    env.kv.values[UserRepository.cacheKey] = '{}';
    env.kv.values['prefs.installed'] = '1';
    env.adapter.on('GET /anything', [FakeAdapter.fail(30002)]);
    final container = await env.container(
      session: const SignedIn(user: testUser),
      token: _token,
    );

    await expectLater(
      container.read(apiClientProvider).get('/anything'),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.kind,
          'kind',
          FailureKind.sessionExpired,
        ),
      ),
    );
    await pumpEventQueue();
    final state = container.read(sessionProvider) as SignedOut;
    expect(state.reason, SignOutReason.banned);
    expect(env.secure.values, isEmpty);
    expect(env.kv.values.keys, ['prefs.installed']);
  });

  group('游客', () {
    test('点「先逛逛」后成为游客，账号状态按没登录处理', () async {
      final container = await env.container();

      container.read(sessionProvider.notifier).browse();
      expect(container.read(sessionProvider), isA<Guest>());
      expect(container.read(accountStatusProvider), isA<SignedOutStatus>());
    });

    test('已登录时点「先逛逛」不变', () async {
      final container = await env.container(
        session: const SignedIn(user: testUser),
      );

      container.read(sessionProvider.notifier).browse();
      expect(container.read(sessionProvider), isA<SignedIn>());
    });

    test('游客不走登录过期流程', () async {
      final container = await env.container(session: const Guest());

      container.read(sessionProvider.notifier).expire();
      expect(container.read(sessionProvider), isA<Guest>());
    });

    test('游客不落盘：下次打开回到没登录', () async {
      env.kv.values[Session.installedKey] = '1';
      final first = await env.container();
      first.read(sessionProvider.notifier).browse();
      first.dispose();

      final next = await env.container();
      await next.read(sessionProvider.notifier).restore();
      expect(next.read(sessionProvider), isA<SignedOut>());
    });
  });

  test('退出登录：通知服务端、清凭证和缓存，同意记录和设备级偏好留着', () async {
    env.kv.values
      ..[UserRepository.cacheKey] = '{}'
      ..[PrivacyConsentStore.key] = '{"version":"2026-10"}'
      ..['prefs.installed'] = '1';
    env.adapter.on('POST /auth/logout', [FakeAdapter.ok()]);
    final container = await env.container(
      session: const SignedIn(user: testUser),
      token: _token,
    );

    await container.read(sessionProvider.notifier).logout();
    expect(env.adapter.sent('POST /auth/logout'), hasLength(1));
    final state = container.read(sessionProvider) as SignedOut;
    expect(state.reason, SignOutReason.loggedOut);
    expect(env.secure.values, isEmpty);
    expect(
      env.kv.values.keys,
      unorderedEquals([PrivacyConsentStore.key, 'prefs.installed']),
    );
  });

  test('用户信息转领域模型时补默认值，头像地址原样使用', () async {
    env.adapter.on('GET /user/info', [
      FakeAdapter.ok({
        'id': 7,
        'displayName': '',
        'avatar': 'https://img.test/avatars/7.jpg',
        'hasUsername': true,
        'userName': 'chi_fan',
      }),
    ]);
    final container = await env.container();

    final user = await container.read(userRepositoryProvider).fetchCurrent();
    expect(user.nickname, '同学');
    expect(user.username, 'chi_fan');
    expect(user.avatarUrl, 'https://img.test/avatars/7.jpg');
    expect(user.verified, isFalse);
    expect(user.hasPassword, isFalse);
  });
}
