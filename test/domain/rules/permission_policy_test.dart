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

    test('封禁中什么都不能做，连资料也不能改，不引导去认证', () {
      const banned = BannedStatus(reason: '刷赞');
      for (final capability in Capability.values) {
        final result = checkPermission(banned, capability);
        expect(result, isA<BlockedByBan>(), reason: '$capability');
        expect((result as BlockedByBan).status.reason, '刷赞');
      }
    });

    test('没登录先去登录', () {
      for (final capability in Capability.values) {
        expect(
          checkPermission(const SignedOutStatus(), capability),
          isA<NeedsSignIn>(),
        );
      }
    });
  });
}
