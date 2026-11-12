import 'package:eat/domain/models/account_status.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = CurrentUser(
  id: 1,
  nickname: '同学',
  hasPassword: false,
  verified: false,
);

void main() {
  group('账号状态', () {
    test('没登录、没认证、已认证', () {
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
      );
      expect(
        AccountStatus.of(signedIn: true, user: verified),
        isA<VerifiedStatus>(),
      );
    });

    test('登录了但还没拉到用户信息时按没认证处理，宁可多拦一次', () {
      expect(AccountStatus.of(signedIn: true), isA<UnverifiedStatus>());
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
      Capability.editDish,
      Capability.editShop,
    ];

    /// 所有已登录状态都能做, 只拦没登录 (含游客).
    const openToAll = [
      Capability.report,
      Capability.reportShopError,
      Capability.viewInbox,
      Capability.viewProfile,
      Capability.viewFavorites,
      Capability.dismissShop,
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

    test('改资料、看足迹和账号设置：没认证也能做', () {
      const accountOnly = [
        Capability.editProfile,
        Capability.deleteComment,
        Capability.viewHistory,
        Capability.viewFollows,
        Capability.viewGrowth,
        Capability.unfollow,
        Capability.changePrivacy,
        Capability.changePassword,
        Capability.setUsername,
        Capability.verify,
      ];
      for (final capability in accountOnly) {
        expect(
          checkPermission(const UnverifiedStatus(), capability),
          isA<Allowed>(),
          reason: '$capability',
        );
      }
      expect(
        {...interactions, ...accountOnly, ...openToAll},
        Capability.values.toSet(),
        reason: '新增的操作要归到其中一类',
      );
    });

    test('举报、信息有误、看消息、看他人主页、反馈：没认证也能做', () {
      for (final capability in openToAll) {
        expect(
          checkPermission(const UnverifiedStatus(), capability),
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

  test('登录对话框的动作词', () {
    expect(Capability.viewInbox.verb, '看消息');
    expect(Capability.viewProfile.verb, '看主页');
    expect(Capability.feedback.verb, '反馈');
  });
}
