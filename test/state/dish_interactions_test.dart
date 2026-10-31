import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/state/dish_interactions.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

const _dish = Dish(
  id: 1,
  name: '鲜虾蟹籽云吞',
  shopId: 7,
  stage: StageColor.broth,
  likes: 12,
);

void main() {
  test('点赞先改本地，请求成功就留着', () async {
    final env = TestEnv();
    env.adapter.on('POST /foods/1/like', [FakeAdapter.ok()]);
    final container = await env.container(
      session: const SignedIn(user: testUser),
    );
    final notifier = container.read(dishInteractionsProvider.notifier);

    final failure = await notifier.toggleLike(_dish);

    expect(failure, isNull);
    final now = notifier.of(_dish);
    expect(now.liked, isTrue);
    expect(now.likes, 13);
    expect(env.adapter.sent('POST /foods/1/like'), hasLength(1));
  });

  test('请求失败退回原值，返回失败原因', () async {
    final env = TestEnv();
    env.adapter.on('POST /foods/1/favorite', [const FakeResponse.offline()]);
    final container = await env.container(
      session: const SignedIn(user: testUser),
    );
    final notifier = container.read(dishInteractionsProvider.notifier);

    final failure = await notifier.toggleFavorite(_dish);

    expect(failure?.kind, FailureKind.network);
    expect(notifier.of(_dish).favorite, isFalse);
  });

  test('拉到最新详情后清掉覆盖值', () async {
    final env = TestEnv();
    env.adapter.on('POST /foods/1/like', [FakeAdapter.ok()]);
    final container = await env.container(
      session: const SignedIn(user: testUser),
    );
    final notifier = container.read(dishInteractionsProvider.notifier);

    await notifier.toggleLike(_dish);
    notifier.forget(1);

    expect(notifier.of(_dish).liked, isFalse);
  });
}
