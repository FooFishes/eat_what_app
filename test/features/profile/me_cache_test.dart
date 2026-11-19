import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/state/session.dart';
import 'package:eat/state/social.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

Map<String, Object?> _profile(String name, {int fans = 3}) => {
  'id': 42,
  'displayName': name,
  'level': 2,
  'earnedLikes': 40,
  'fansCount': fans,
  'followingsCount': 5,
};

Map<String, Object?> _uploads(List<String> names) => {
  ...pageJson([
    for (final (i, name) in names.indexed) foodJson(id: i + 1, name: name),
  ]),
  'totalItems': names.length,
};

/// 等后台的重新请求发出.
Future<void> _settle() => Future<void>(() {});

void main() {
  /// 第一次打开: 没有缓存, 等接口返回, 结果存下来.
  Future<void> firstOpen(TestEnv env) async {
    env.adapter
      ..on('GET /user/userInfo', [FakeAdapter.ok(_profile('旧名字'))])
      ..on('GET /foods/my', [
        FakeAdapter.ok(_uploads(['虾仁云吞'])),
      ]);
    final container = await env.container(
      session: const SignedIn(user: testUser),
    );
    await container.read(userProfileProvider(42).future);
    await container.read(myUploadsProvider.future);
    container.dispose();
    env.adapter.requests.clear();
  }

  test('再次打开先给上次存下的资料和上传, 后台请求回来后换成新的', () async {
    final env = TestEnv();
    await firstOpen(env);
    env.adapter
      ..on('GET /user/userInfo', [FakeAdapter.ok(_profile('新名字', fans: 9))])
      ..on('GET /foods/my', [
        FakeAdapter.ok(_uploads(['紫菜汤', '虾仁云吞'])),
      ]);
    final container = await env.container(
      session: const SignedIn(user: testUser),
    );
    addTearDown(container.dispose);
    container
      ..listen(userProfileProvider(42), (_, _) {})
      ..listen(myUploadsProvider, (_, _) {});

    final cached = await container.read(userProfileProvider(42).future);
    final cachedUploads = await container.read(myUploadsProvider.future);
    expect((cached.nickname, cached.fans), ('旧名字', 3));
    expect(cachedUploads.pages.items.map((d) => d.name), ['虾仁云吞']);
    expect(cachedUploads.pages.total, 1);

    await _settle();
    final fresh = await container.read(userProfileProvider(42).future);
    final freshUploads = await container.read(myUploadsProvider.future);
    expect((fresh.nickname, fresh.fans), ('新名字', 9));
    expect(freshUploads.pages.items.map((d) => d.name), ['紫菜汤', '虾仁云吞']);
    expect(env.adapter.sent('GET /user/userInfo'), hasLength(1));
    expect(env.adapter.sent('GET /foods/my'), hasLength(1));
  });

  test('后台请求失败时保留缓存', () async {
    final env = TestEnv();
    await firstOpen(env);
    env.adapter
      ..on('GET /user/userInfo', [const FakeResponse.offline()])
      ..on('GET /foods/my', [const FakeResponse.offline()]);
    final container = await env.container(
      session: const SignedIn(user: testUser),
    );
    addTearDown(container.dispose);
    container
      ..listen(userProfileProvider(42), (_, _) {})
      ..listen(myUploadsProvider, (_, _) {});

    await container.read(userProfileProvider(42).future);
    await container.read(myUploadsProvider.future);
    await _settle();
    await expectLater(
      container.read(userProfileProvider(42).future),
      throwsA(anything),
    );
    await expectLater(
      container.read(myUploadsProvider.future),
      throwsA(anything),
    );

    expect(container.read(userProfileProvider(42)).value?.nickname, '旧名字');
    expect(
      container.read(myUploadsProvider).value?.pages.items.single.name,
      '虾仁云吞',
    );
  });

  test('他人的资料不存缓存', () async {
    final env = TestEnv();
    env.adapter.on('GET /user/userInfo', [
      FakeAdapter.ok({'id': 7, 'displayName': '别人'}),
    ]);
    final container = await env.container(
      session: const SignedIn(user: testUser),
    );
    addTearDown(container.dispose);

    await container.read(userProfileProvider(7).future);

    expect(env.kv.values.keys, isNot(contains('cache.profile.7')));
  });
}
