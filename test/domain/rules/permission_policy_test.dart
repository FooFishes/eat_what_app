import 'package:eat/domain/models/account_status.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = CurrentUser(
  id: 1,
  nickname: '同学',
  hasPassword: false,
  verified: false,
  banned: false,
);

void main() {
  group('账号状态', () {
    test('没登录、没认证、已认证、封禁中', () {
      expect(AccountStatus.of(signedIn: false), isA<SignedOutStatus>());
      expect(
        AccountStatus.of(signedIn: true, user: _user),
        isA<UnverifiedStatus>(),
      );
      const verified = CurrentUser(
        id: 1,
        nickname: '同学',
        hasPassword: false,
        verified: true,
        banned: false,
      );
      expect(
        AccountStatus.of(signedIn: true, user: verified),
        isA<VerifiedStatus>(),
      );
      final banned = AccountStatus.of(
        signedIn: true,
        user: const CurrentUser(
          id: 1,
          nickname: '同学',
          hasPassword: false,
          verified: true,
          banned: true,
          banReason: '刷赞',
        ),
      );
      expect(banned, isA<BannedStatus>());
      expect((banned as BannedStatus).reason, '刷赞');
    });

    test('登录了但还没拉到用户信息时按没认证处理，宁可多拦一次', () {
      expect(AccountStatus.of(signedIn: true), isA<UnverifiedStatus>());
    });

    test('受限会话还没拉到用户信息时按封禁中处理，拉到后以 banned 为准', () {
      expect(
        AccountStatus.of(signedIn: true, restricted: true),
        isA<BannedStatus>(),
      );
      expect(
        AccountStatus.of(signedIn: true, user: _user, restricted: true),
        isA<UnverifiedStatus>(),
      );
    });

    test('封禁带上原因、开始和截止时间', () {
      final status = AccountStatus.of(
        signedIn: true,
        user: CurrentUser(
          id: 1,
          nickname: '同学',
          hasPassword: false,
          verified: false,
          banned: true,
          banReason: '刷赞',
          bannedAt: DateTime(2026, 11, 1),
          banUntil: DateTime(2026, 11, 30),
        ),
      ) as BannedStatus;
      expect(status.reason, '刷赞');
      expect(status.since, DateTime(2026, 11, 1));
      expect(status.until, DateTime(2026, 11, 30));
    });
  });

  group('产品 7.2 的权限表', () {
    const interactions = [
      Capability.like,
      Capability.favorite,
      Capability.tasteTag,
      Capability.myTag,
      Capability.comment,
      Capability.reply,
      Capability.rateShop,
      Capability.follow,
      Capability.publishDish,
      Capability.createShop,
      Capability.editOwnDish,
    ];

    /// 所有已登录状态都能做, 只拦没登录 (含游客).
    const openToAll = [
      Capability.report,
      Capability.reportShopError,
      Capability.viewInbox,
      Capability.viewProfile,
      Capability.feedback,
    ];

    test('已认证全部能做', () {
      for (final capability in Capability.values) {
        expect(
          checkPermission(const VerifiedStatus(), capability),
          isA<Allowed>(),
          reason: '$capability',
        );
      }
    });

    test('没认证不能互动和发布，要先认证；能编辑资料', () {
      for (final capability in interactions) {
        expect(
          checkPermission(const UnverifiedStatus(), capability),
          isA<NeedsVerification>(),
          reason: '$capability',
        );
      }
      expect(
        checkPermission(const UnverifiedStatus(), Capability.editProfile),
        isA<Allowed>(),
      );
    });

    test('封禁中除了上面几项什么都不能做，连资料也不能改，不引导去认证', () {
      const banned = BannedStatus(reason: '刷赞');
      for (final capability in Capability.values) {
        if (capability.openToBanned) continue;
        final result = checkPermission(banned, capability);
        expect(result, isA<BlockedByBan>(), reason: '$capability');
        expect((result as BlockedByBan).status.reason, '刷赞');
      }
    });

    test('后端没给受限会话登记的接口：没认证能做，封禁中拦住', () {
      const restrictedOnly = [
        Capability.editProfile,
        Capability.deleteComment,
        Capability.viewHistory,
        Capability.viewFollows,
        Capability.unfollow,
        Capability.changePrivacy,
        Capability.changePassword,
        Capability.setUsername,
        Capability.verify,
      ];
      for (final capability in restrictedOnly) {
        expect(
          checkPermission(const UnverifiedStatus(), capability),
          isA<Allowed>(),
          reason: '$capability',
        );
        expect(
          checkPermission(const BannedStatus(), capability),
          isA<BlockedByBan>(),
          reason: '$capability',
        );
      }
      expect(
        {...interactions, ...restrictedOnly, ...openToAll},
        Capability.values.toSet(),
        reason: '新增的操作要归到其中一类',
      );
    });

    test('举报、信息有误、看消息、看他人主页、反馈：没认证和封禁中都能做', () {
      for (final capability in openToAll) {
        expect(
          checkPermission(const UnverifiedStatus(), capability),
          isA<Allowed>(),
          reason: '$capability',
        );
        expect(
          checkPermission(const BannedStatus(), capability),
          isA<Allowed>(),
          reason: '$capability',
        );
      }
    });

    test('没登录（含游客）先去登录', () {
      for (final capability in Capability.values) {
        expect(
          checkPermission(const SignedOutStatus(), capability),
          isA<NeedsSignIn>(),
        );
      }
    });
  });

  test('登录面板的动作词', () {
    expect(Capability.viewInbox.verb, '看消息');
    expect(Capability.viewProfile.verb, '看主页');
    expect(Capability.feedback.verb, '反馈');
  });
}
