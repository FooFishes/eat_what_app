import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/data/recommend/preference_repository.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/recommend_preferences.dart';
import 'package:eat/domain/models/taste.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  const path = '/user/recommendation-profile/preferences';

  test('读取偏好：字符串转成枚举，不认识的值丢掉', () async {
    final env = TestEnv();
    env.adapter.on('GET $path', [
      FakeAdapter.ok({
        'likedCategories': ['粉面', '东北菜'],
        'likedTags': ['甜'],
        'dislikedTags': ['辣'],
        'priceBand': 'FROM_15_TO_30',
        'maxDistance': 1500,
        'updatedAt': 1792763739329,
      }),
    ]);
    final container = await env.container();

    final prefs = await container
        .read(preferenceRepositoryProvider)
        .preferences();

    expect(prefs.likedCategories, {ShopCategory.noodles});
    expect(prefs.likedTastes, {Taste.sweet});
    expect(prefs.dislikedTastes, {Taste.spicy});
    expect(prefs.priceBand, PriceBand.from15To30);
    expect(prefs.maxDistance, 1500);
  });

  test('从未设置过：各项为空', () async {
    final env = TestEnv();
    env.adapter.on('GET $path', [
      FakeAdapter.ok({
        'likedCategories': <String>[],
        'likedTags': <String>[],
        'dislikedTags': <String>[],
        'priceBand': null,
        'maxDistance': null,
        'updatedAt': null,
      }),
    ]);
    final container = await env.container();

    final prefs = await container
        .read(preferenceRepositoryProvider)
        .preferences();

    expect(prefs.isEmpty, isTrue);
  });

  test('保存：整体覆盖，按固定顺序发送；不限的价位和距离不发送', () async {
    final env = TestEnv();
    env.adapter.on('PUT $path', [
      FakeAdapter.ok({
        'likedCategories': ['米饭炒菜', '粉面'],
        'likedTags': ['清淡'],
        'dislikedTags': ['辣', '麻'],
        'priceBand': null,
        'maxDistance': null,
        'updatedAt': 1792763739329,
      }),
    ]);
    final container = await env.container();

    final saved = await container
        .read(preferenceRepositoryProvider)
        .save(
          const RecommendPreferences(
            likedCategories: {ShopCategory.noodles, ShopCategory.rice},
            likedTastes: {Taste.light},
            dislikedTastes: {Taste.numbing, Taste.spicy},
          ),
        );

    expect(env.adapter.sent('PUT $path').single.body, {
      'likedCategories': ['米饭炒菜', '粉面'],
      'likedTags': ['清淡'],
      'dislikedTags': ['辣', '麻'],
    });
    expect(saved.dislikedTastes, {Taste.spicy, Taste.numbing});
  });

  test('保存：带上价位和最远距离', () async {
    final env = TestEnv();
    env.adapter.on('PUT $path', [FakeAdapter.ok(<String, Object?>{})]);
    final container = await env.container();

    await container
        .read(preferenceRepositoryProvider)
        .save(
          const RecommendPreferences(
            priceBand: PriceBand.under15,
            maxDistance: 2000,
          ),
        );

    expect(env.adapter.sent('PUT $path').single.body, {
      'likedCategories': <String>[],
      'likedTags': <String>[],
      'dislikedTags': <String>[],
      'priceBand': 'UNDER_15',
      'maxDistance': 2000,
    });
  });

  test('保存被拒（业务码非零）时抛出失败', () async {
    final env = TestEnv();
    env.adapter.on('PUT $path', [FakeAdapter.fail(40000, '同一个口味不能既喜欢又忌口')]);
    final container = await env.container();

    await expectLater(
      container
          .read(preferenceRepositoryProvider)
          .save(const RecommendPreferences()),
      throwsA(isA<AppFailure>()),
    );
  });

  test('清空：发送 DELETE', () async {
    final env = TestEnv();
    env.adapter.on('DELETE $path', [FakeAdapter.ok()]);
    final container = await env.container();

    await container.read(preferenceRepositoryProvider).clear();

    expect(env.adapter.sent('DELETE $path'), hasLength(1));
  });

  test('隐式口味：只取推断出的喜欢', () async {
    final env = TestEnv();
    env.adapter.on('GET /user/recommendation-profile/taste', [
      FakeAdapter.ok({
        'tags': [
          {'name': '辣', 'score': 3.2},
          {'name': '酸', 'score': -1.0},
        ],
        'categories': [
          {'name': '粉面', 'score': 2.0},
        ],
        'inferredTags': ['辣'],
        'inferredCategories': ['粉面', '未知品类'],
      }),
    ]);
    final container = await env.container();

    final taste = await container.read(preferenceRepositoryProvider).taste();

    expect(taste.inferredTastes, [Taste.spicy]);
    expect(taste.inferredCategories, [ShopCategory.noodles]);
  });

  test('可选值：按服务端顺序，忌口单独一组', () async {
    final env = TestEnv();
    env.adapter.on('GET /recommend/tags', [
      FakeAdapter.ok({
        'categories': ['粉面', '米饭炒菜'],
        'tags': ['辣', '麻', '甜', '酸', '清淡'],
        'dislikableTags': ['辣', '麻'],
      }),
    ]);
    final container = await env.container();

    final options = await container
        .read(preferenceRepositoryProvider)
        .options();

    expect(options.categories, [ShopCategory.noodles, ShopCategory.rice]);
    expect(options.tastes, Taste.values);
    expect(options.dislikable, [Taste.spicy, Taste.numbing]);
  });
}
