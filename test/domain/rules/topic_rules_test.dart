import 'package:eat/domain/models/topic.dart';
import 'package:eat/domain/rules/topic_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 22, 12);
  final topic = Topic(
    id: 7,
    name: '期末续命餐',
    startsAt: DateTime(2026, 10, 20),
    endsAt: DateTime(2026, 10, 27),
  );

  test('结束时刻是次日零点时，结束日取前一天；不在今年时带年份', () {
    expect(TopicRules.range(topic, now), '10 月 20 日–10 月 26 日');
    expect(
      TopicRules.range(topic, DateTime(2027, 1, 5)),
      '2026 年 10 月 20 日–2026 年 10 月 26 日',
    );
  });

  test('正在进行的写「本周专题」，结束后写「专题」', () {
    expect(TopicRules.isCurrent(topic, now), isTrue);
    expect(TopicRules.kind(topic, now), '本周专题');
    expect(TopicRules.dishHint(topic, now), '收进了本周专题「期末续命餐」');

    final later = DateTime(2026, 10, 27);
    expect(TopicRules.isCurrent(topic, later), isFalse);
    expect(TopicRules.kind(topic, later), '往期专题');
    expect(TopicRules.dishHint(topic, later), '收进了专题「期末续命餐」');
  });
}
