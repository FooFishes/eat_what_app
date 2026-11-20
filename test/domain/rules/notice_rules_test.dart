import 'package:eat/domain/models/notice.dart';
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
  int? dishId,
}) => Notice(
  id: 1,
  kind: kind,
  targetDomain: domain,
  targetId: targetId,
  memberCount: members,
  latestAt: DateTime(2026, 11, 1),
  actors: actors,
  detail: detail,
  dishId: dishId,
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

  test('回复带菜 id 时进菜品详情并滚到根评论；没带菜 id 的回复和评论赞不跳转', () {
    final reply = _notice(
      NoticeKind.reply,
      domain: 'comments',
      targetId: 300,
      dishId: 42,
    );
    expect(NoticeRules.sentenceOf(reply), '回复了你');
    expect(
      NoticeRules.targetOf(reply),
      isA<DishTarget>()
          .having((t) => t.dishId, 'dishId', 42)
          .having((t) => t.comment, 'comment', 300),
    );
    final oldReply = _notice(
      NoticeKind.reply,
      domain: 'comments',
      targetId: 300,
    );
    expect(NoticeRules.targetOf(oldReply), isA<NoTarget>());
    final like = _notice(
      NoticeKind.commentLike,
      domain: 'comments',
      targetId: 300,
    );
    expect(NoticeRules.sentenceOf(like), '赞了你的评论');
    expect(
      NoticeRules.targetOf(like),
      isA<CommentTarget>().having((t) => t.commentId, 'commentId', 300),
    );
    final oddLike = _notice(NoticeKind.commentLike, domain: 'foods');
    expect(NoticeRules.targetOf(oddLike), isA<NoTarget>());
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

  test('封禁消息写原因，不跳转', () {
    final banned = _notice(
      NoticeKind.accountBanned,
      domain: 'bans',
      actors: const [],
      detail: BanDetail(reason: '刷赞', until: DateTime(2026, 11, 30)),
    );
    expect(NoticeRules.sentenceOf(banned), '你的账号已被封禁');
    expect(NoticeRules.contentOf(banned), '原因：刷赞');
    expect(NoticeRules.targetOf(banned), isA<NoTarget>());
  });

  test('新设备登录写设备名，没有名称时写设备类型，点了去登录设备', () {
    final named = _notice(
      NoticeKind.newDeviceLogin,
      domain: 'sessions',
      actors: const [],
      detail: const NewDeviceDetail(deviceName: 'Pixel 8', platform: 'ANDROID'),
    );
    expect(NoticeRules.sentenceOf(named), '你的账号已在新设备上登录');
    expect(NoticeRules.contentOf(named), 'Pixel 8');
    expect(NoticeRules.noteOf(named), '不是本人登录时，可以让它下线');
    expect(NoticeRules.targetOf(named), isA<DevicesTarget>());
    expect(NoticeRules.actionOf(named), '查看登录设备');
    final unnamed = _notice(
      NoticeKind.newDeviceLogin,
      domain: 'sessions',
      actors: const [],
      detail: const NewDeviceDetail(platform: 'IOS'),
    );
    expect(NoticeRules.contentOf(unnamed), '苹果设备');
  });

  test('内容被删除写菜名或评论摘要和原因，不跳转', () {
    final dish = _notice(
      NoticeKind.contentRemoved,
      actors: const [],
      detail: const ContentRemovedDetail(
        comment: false,
        title: '番茄牛腩饭',
        reason: '不是实拍',
      ),
    );
    expect(NoticeRules.sentenceOf(dish), '你上传的「番茄牛腩饭」已被删除');
    expect(NoticeRules.contentOf(dish), '原因：不是实拍');
    expect(NoticeRules.targetOf(dish), isA<NoTarget>());
    final comment = _notice(
      NoticeKind.contentRemoved,
      domain: 'comments',
      actors: const [],
      detail: const ContentRemovedDetail(comment: true, title: '汤很鲜'),
    );
    expect(NoticeRules.sentenceOf(comment), '你的评论「汤很鲜」已被删除');
    expect(NoticeRules.contentOf(comment), isNull);
  });

  test('认不出的类型不跳转', () {
    final other = _notice(NoticeKind.fromApi('dinner'));
    expect(other.kind, NoticeKind.other);
    expect(NoticeRules.targetOf(other), isA<NoTarget>());
    expect(NoticeRules.sentenceOf(other), '你有一条新消息');
  });
}
