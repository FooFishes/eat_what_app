import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/rules/notice_rules.dart';
import 'package:flutter_test/flutter_test.dart';

const _xiaolin = NoticeActor(id: 5, name: '小林');
const _momo = NoticeActor(id: 6, name: 'Momo');

Notice _notice(
  NoticeKind kind, {
  String domain = 'foods',
  int targetId = 42,
  bool unavailable = false,
  int members = 1,
  List<NoticeActor> actors = const [_xiaolin],
  NoticeDetail? detail,
}) => Notice(
  id: 'card-1',
  kind: kind,
  targetDomain: domain,
  targetId: targetId,
  targetUnavailable: unavailable,
  memberCount: members,
  latestAt: DateTime(2026, 11, 1),
  actors: actors,
  detail: detail,
);

void main() {
  test('按今天、本周、更早分组，本周从周一开始', () {
    // 2026-11-04 是周三.
    final now = DateTime(2026, 11, 4, 12);
    expect(NoticeRules.groupOf(DateTime(2026, 11, 4, 0, 1), now), '今天');
    expect(NoticeRules.groupOf(DateTime(2026, 11, 2, 9), now), '本周');
    expect(NoticeRules.groupOf(DateTime(2026, 11, 1, 23), now), '更早');
  });

  test('一个人关注时去对方的主页，可以回关', () {
    final follow = _notice(NoticeKind.follow, domain: 'users', targetId: 1);
    expect(
      NoticeRules.targetOf(follow),
      isA<UserTarget>().having((t) => t.userId, 'userId', 5),
    );
    expect(NoticeRules.followBackUserOf(follow), 5);
    expect(NoticeRules.actorsOf(follow), '小林');
    expect(NoticeRules.sentenceOf(follow), '关注了你');
  });

  test('多人合并的关注写「等 n 人」，去我的粉丝列表，不显示回关', () {
    final follow = _notice(
      NoticeKind.follow,
      domain: 'users',
      members: 3,
      actors: [_momo, _xiaolin],
    );
    expect(NoticeRules.targetOf(follow), isA<MyFansTarget>());
    expect(NoticeRules.followBackUserOf(follow), isNull);
    expect(NoticeRules.actorsOf(follow), 'Momo 等 3 人');
  });

  test('赞、收藏、标签去菜品详情，写「你上传的菜」', () {
    final like = _notice(NoticeKind.like, members: 12, actors: [_momo]);
    expect(
      NoticeRules.targetOf(like),
      isA<DishTarget>().having((t) => t.dishId, 'dishId', 42),
    );
    expect(NoticeRules.actorsOf(like), 'Momo 等 12 人');
    expect(NoticeRules.sentenceOf(like), '赞了你上传的菜');
    expect(NoticeRules.sentenceOf(_notice(NoticeKind.favorite)), '收藏了你上传的菜');
    expect(NoticeRules.sentenceOf(_notice(NoticeKind.tag)), '给你上传的菜加了标签');
  });

  test('菜已删除，或赞的是旧版活动内容时不跳转', () {
    expect(
      NoticeRules.targetOf(_notice(NoticeKind.like, unavailable: true)),
      isA<NoTarget>(),
    );
    final old = _notice(NoticeKind.like, domain: 'activity_posts');
    expect(NoticeRules.targetOf(old), isA<NoTarget>());
    expect(NoticeRules.sentenceOf(old), '赞了你的内容');
  });

  test('专题收录写菜名和专题名，去专题页；专题撤下后不跳转', () {
    const included = TopicIncludedDetail(
      dishId: 42,
      dishName: '玉米鲜肉饺子',
      topicId: 7,
      topicName: '期末续命餐',
    );
    final notice = _notice(
      NoticeKind.topicIncluded,
      domain: 'topics',
      actors: const [],
      detail: included,
    );
    expect(NoticeRules.actorsOf(notice), isNull);
    expect(NoticeRules.sentenceOf(notice), '你上传的「玉米鲜肉饺子」已被收录到专题「期末续命餐」');
    expect(
      NoticeRules.targetOf(notice),
      isA<TopicTarget>().having((t) => t.topicId, 'topicId', 7),
    );

    final withdrawn = _notice(
      NoticeKind.topicIncluded,
      domain: 'topics',
      actors: const [],
      detail: const TopicIncludedDetail(
        dishName: '菜品已不可用',
        topicName: '专题已不可用',
      ),
    );
    expect(NoticeRules.targetOf(withdrawn), isA<NoTarget>());
    expect(NoticeRules.sentenceOf(withdrawn), '你上传的菜已被收录到专题，该专题已撤下');
  });

  test('审核通过去菜或店，未通过不跳转', () {
    final dish = _notice(
      NoticeKind.moderationResult,
      actors: const [],
      detail: const ModerationDetail(shop: false, approved: true),
    );
    expect(NoticeRules.targetOf(dish), isA<DishTarget>());
    expect(NoticeRules.sentenceOf(dish), '你上传的菜已通过审核');
    final shop = _notice(
      NoticeKind.moderationResult,
      domain: 'restaurant',
      actors: const [],
      detail: const ModerationDetail(shop: true, approved: false),
    );
    expect(NoticeRules.targetOf(shop), isA<NoTarget>());
    expect(NoticeRules.sentenceOf(shop), '你新建的店未通过审核');
  });

  test('处理结果按类型和结论写，带上运营的回复，不跳转', () {
    final catalog = _notice(
      NoticeKind.caseResult,
      domain: 'catalog_error',
      actors: const [],
      detail: const CaseResultDetail(
        kind: CaseKind.catalogError,
        outcome: 'ACCEPTED',
        reasonCode: 'WRONG_LOCATION',
        reply: '已修正',
      ),
    );
    expect(NoticeRules.sentenceOf(catalog), '你反馈的店铺位置问题已修正');
    expect(NoticeRules.replyOf(catalog), '已修正');
    expect(NoticeRules.targetOf(catalog), isA<NoTarget>());

    final report = _notice(
      NoticeKind.caseResult,
      domain: 'report',
      actors: const [],
      detail: const CaseResultDetail(
        kind: CaseKind.report,
        outcome: 'ACCEPTED',
      ),
    );
    expect(NoticeRules.sentenceOf(report), '你举报的内容已处理');
    expect(NoticeRules.replyOf(report), isNull);
  });

  test('评论和回复去菜品详情并带上评论 id；评论已删除时不跳转', () {
    final reply = _notice(
      NoticeKind.reply,
      detail: const CommentDetail(dishId: 42, commentId: 300),
    );
    expect(
      NoticeRules.targetOf(reply),
      isA<DishTarget>()
          .having((t) => t.dishId, 'dishId', 42)
          .having((t) => t.commentId, 'commentId', 300),
    );
    final deleted = _notice(
      NoticeKind.comment,
      detail: const CommentDetail(
        dishId: 42,
        commentId: 300,
        unavailable: true,
      ),
    );
    expect(NoticeRules.targetOf(deleted), isA<NoTarget>());
  });

  test('认不出的类型不跳转', () {
    final other = _notice(NoticeKind.fromApi('dinner'));
    expect(other.kind, NoticeKind.other);
    expect(NoticeRules.targetOf(other), isA<NoTarget>());
    expect(NoticeRules.sentenceOf(other), '你有一条新消息');
  });
}
