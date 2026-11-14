import 'package:eat/data/growth/growth_repository.dart';
import 'package:eat/domain/models/growth.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/growth_fixtures.dart';

void main() {
  late TestEnv env;
  late GrowthRepository repo;

  setUp(() async {
    env = TestEnv();
    final container = await env.container();
    repo = container.read(growthRepositoryProvider);
  });

  test('进度带等级、门槛和距下一级的经验', () async {
    env.adapter.on('GET /user/level', [FakeAdapter.ok(growthJson())]);

    final progress = await repo.progress();

    expect(progress.level, 3);
    expect(progress.totalExperience, 125);
    expect(progress.toNextLevel, 125);
    expect(progress.isMaxLevel, isFalse);
    expect(progress.levelProgress, closeTo(25 / 150, 1e-9));
    expect(progress.dailyExperience, 5);
  });

  test('满级时没有下一级，进度算满', () async {
    env.adapter.on('GET /user/level', [
      FakeAdapter.ok(
        growthJson(level: 10, total: 16020, start: 16000, next: null),
      ),
    ]);

    final progress = await repo.progress();

    expect(progress.isMaxLevel, isTrue);
    expect(progress.toNextLevel, 0);
    expect(progress.levelProgress, 1);
  });

  test('明细带分页参数，日期按所属那天，名称用服务端的显示名，缺 id 或日期的不列', () async {
    env.adapter.on('GET /user/level/logs', [
      FakeAdapter.ok(
        pageJson([
          experienceJson(),
          experienceJson(
            id: 2,
            source: 'new_thing',
            sourceName: '发布菜品',
            experience: 10,
          ),
          experienceJson(id: 3, source: 'other_thing', sourceName: null),
          {...experienceJson(id: 4), 'id': null},
          {...experienceJson(id: 5), 'day': null},
        ], hasNext: true),
      ),
    ]);

    final page = await repo.ledger(page: 2);

    expect(env.adapter.sent('GET /user/level/logs').single.query, {
      'page': 2,
      'pageSize': 20,
    });
    expect(page.hasNext, isTrue);
    expect(page.items.map((e) => e.id), ['1', '2', '3']);
    expect(page.items[0].source, ExperienceSource.dailyUse);
    expect(page.items[0].label, '每日使用');
    expect(page.items[0].date, DateTime(2026, 11, 10));
    expect(page.items[1].source, ExperienceSource.other);
    expect(page.items[1].label, '发布菜品');
    expect(page.items[1].amount, 10);
    expect(page.items[2].label, '获得经验');
  });
}
