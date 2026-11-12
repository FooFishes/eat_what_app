import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/models/report.dart';
import 'package:eat/domain/rules/notice_rules.dart';
import 'package:flutter_test/flutter_test.dart';

const _xiaolin = NoticeActor(id: 5, name: '小林');
const _momo = NoticeActor(id: 6, name: 'Momo');

Notice _notice(
  NoticeKind kind, {
  String domain = 'foods',
  int targetId = 42,
  int members = 1,
  List<NoticeActor> actors = const [_xiaolin],
  NoticeDetail? detail,
}) => Notice(
  id: 1,
  kind: kind,
  targetDomain: domain,
  targetId: targetId,
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

  test('赞、收藏、评论去菜品详情，写「你上传的菜」', () {
    final like = _notice(NoticeKind.like, members: 12, actors: [_momo]);
    expect(
      NoticeRules.targetOf(like),
      isA<DishTarget>().having((t) => t.dishId, 'dishId', 42),
    );
    expect(NoticeRules.actorsOf(like), 'Momo 等 12 人');
    expect(NoticeRules.sentenceOf(like), '赞了你上传的菜');
    expect(NoticeRules.sentenceOf(_notice(NoticeKind.favorite)), '收藏了你上传的菜');
    final comment = _notice(NoticeKind.comment);
    expect(NoticeRules.sentenceOf(comment), '评论了你上传的菜');
    expect(NoticeRules.targetOf(comment), isA<DishTarget>());
  });

  test('回复和评论赞没有菜 id，不跳转', () {
    final reply = _notice(NoticeKind.reply, domain: 'comments', targetId: 300);
    expect(NoticeRules.sentenceOf(reply), '回复了你');
    expect(NoticeRules.targetOf(reply), isA<NoTarget>());
    final like = _notice(
      NoticeKind.commentLike,
      domain: 'comments',
      targetId: 300,
    );
    expect(NoticeRules.sentenceOf(like), '赞了你的评论');
    expect(NoticeRules.targetOf(like), isA<NoTarget>());
  });

  test('处理结果按类型和结论写，带上运营的回复，点击先取提交记录', () {
    final catalog = _notice(
      NoticeKind.caseResult,
      domain: 'catalog_error',
      actors: const [],
      detail: const CaseResultDetail(
        caseId: 5,
        kind: CaseKind.catalogError,
        outcome: 'ACCEPTED',
        reasonCode: 'WRONG_LOCATION',
        reply: '已修正',
      ),
    );
    expect(NoticeRules.sentenceOf(catalog), '你反馈的店铺位置问题已修正');
    expect(NoticeRules.replyOf(catalog), '已修正');
    expect(
      NoticeRules.targetOf(catalog),
      isA<CaseTarget>().having((t) => t.caseId, 'caseId', 5),
    );

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
    expect(NoticeRules.targetOf(report), isA<NoTarget>());
  });

  test('提交记录关于菜或店时跳过去，其余不跳转', () {
    expect(
      NoticeRules.targetOfCase(
        const CaseSubject(kind: CaseSubjectKind.dish, id: 3),
      ),
      isA<DishTarget>().having((t) => t.dishId, 'dishId', 3),
    );
    expect(
      NoticeRules.targetOfCase(
        const CaseSubject(kind: CaseSubjectKind.shop, id: 7),
      ),
      isA<ShopTarget>().having((t) => t.shopId, 'shopId', 7),
    );
    expect(
      NoticeRules.targetOfCase(
        const CaseSubject(kind: CaseSubjectKind.comment, id: 9),
      ),
      isA<NoTarget>(),
    );
    expect(NoticeRules.targetOfCase(null), isA<NoTarget>());
  });

  test('公告用标题做正文，内容另起一行，不跳转', () {
    final notice = _notice(
      NoticeKind.announcement,
      domain: 'announcements',
      actors: const [],
      detail: const AnnouncementDetail(title: '食堂二楼周末停业', content: '周六周日暂停营业。'),
    );
    expect(NoticeRules.actorsOf(notice), isNull);
    expect(NoticeRules.sentenceOf(notice), '食堂二楼周末停业');
    expect(NoticeRules.contentOf(notice), '周六周日暂停营业。');
    expect(NoticeRules.targetOf(notice), isA<NoTarget>());
  });

  test('认不出的类型不跳转', () {
    final other = _notice(NoticeKind.fromApi('dinner'));
    expect(other.kind, NoticeKind.other);
    expect(NoticeRules.targetOf(other), isA<NoTarget>());
    expect(NoticeRules.sentenceOf(other), '你有一条新消息');
  });
}
