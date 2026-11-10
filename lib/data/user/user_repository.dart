import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/idempotency.dart';
import 'package:eat/core/network/recovery_capability.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/sessions/session_rotation.dart';
import 'package:eat/data/user/user_api.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/people.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository.g.dart';

/// 用户数据: 当前用户, 他人的公开资料, 关注, 隐私和屏蔽.
///
/// 当前用户的信息保存到本地, 启动时使用本地副本显示.
class UserRepository {
  UserRepository(this._api, this._kv);

  /// 位于 `cache.` 前缀下, 退出登录时与其他接口缓存一并删除.
  static const cacheKey = 'cache.user.current';

  final UserApi _api;
  final KvStore _kv;

  Future<CurrentUser> fetchCurrent() async {
    final dto = await _api.info();
    await _kv.write(cacheKey, jsonEncode(dto.toJson()));
    return _toUser(dto);
  }

  /// 上次获取的用户信息. 没有缓存或缓存损坏时返回 null, 损坏的缓存同时删除.
  Future<CurrentUser?> readCached() async {
    final raw = await _kv.read(cacheKey);
    if (raw == null) return null;
    try {
      return _toUser(
        UserInfoDto.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } on Object {
      await _kv.delete(cacheKey);
      return null;
    }
  }

  /// 指定用户的公开资料和统计. "我的" 页面也用它获取自己的统计.
  Future<UserProfile> profile(int userId, {CancelToken? cancelToken}) async {
    final dto = await _api.profile(userId, cancelToken: cancelToken);
    return UserProfile(
      id: userId,
      nickname: dto.displayName?.trim().isNotEmpty == true
          ? dto.displayName!.trim()
          : '同学',
      avatarUrl: imageUrl(dto.avatar),
      earnedLikes: dto.earnedLikes ?? 0,
      fans: dto.fansCount ?? 0,
      followings: dto.followingsCount ?? 0,
      uploadedDishes: dto.uploadedFoodsCount ?? 0,
      fansVisible: dto.fansVisible ?? false,
      followingsVisible: dto.followingsVisible ?? false,
      followsMe: dto.isFollowingMe ?? false,
      followedByMe: dto.isFollowingHim ?? false,
      level: dto.level,
    );
  }

  /// 保存昵称, 签名和头像. [avatarKey] 为 null 时不修改头像.
  Future<void> updateProfile({
    required String nickname,
    required String signature,
    String? avatarKey,
  }) => _api.updateInfo(
    displayName: nickname.trim(),
    signature: signature.trim(),
    avatar: avatarKey,
  );

  Future<void> setFollowing(int userId, {required bool following}) =>
      following ? _api.follow(userId) : _api.unfollow(userId);

  Future<Paged<UserBrief>> followers(
    int userId, {
    int page = 1,
    CancelToken? cancelToken,
  }) async => _briefs(
    await _api.followers(userId, page: page, cancelToken: cancelToken),
  );

  Future<Paged<UserBrief>> followings(
    int userId, {
    int page = 1,
    CancelToken? cancelToken,
  }) async => _briefs(
    await _api.followings(userId, page: page, cancelToken: cancelToken),
  );

  /// 当前用户的隐私设置.
  ///
  /// 接口没有单独读取隐私设置的方法. 查看自己的公开资料时, 两项可见性即为自己的设置.
  Future<PrivacySettings> privacy(int myId, {CancelToken? cancelToken}) async {
    final dto = await _api.profile(myId, cancelToken: cancelToken);
    return PrivacySettings(
      followingsPublic: dto.followingsVisible ?? true,
      fansPublic: dto.fansVisible ?? true,
    );
  }

  Future<void> setPrivacy(PrivacySettings settings) => _api.changePrivacy(
    following: settings.followingsPublic,
    follower: settings.fansPublic,
  );

  Future<Paged<UserBrief>> blocked({
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final result = await _api.blocks(page: page, cancelToken: cancelToken);
    return Paged(
      items: [
        for (final dto in result.items)
          if (dto.userId case final id?)
            UserBrief(id: id, nickname: _text(dto.displayName)),
      ],
      page: result.page,
      hasNext: result.hasNext,
    );
  }

  Future<bool> isBlocked(int userId, {CancelToken? cancelToken}) =>
      _api.blocked(userId, cancelToken: cancelToken);

  Future<void> setBlocked(int userId, {required bool blocked}) =>
      blocked ? _api.block(userId) : _api.unblock(userId);

  Future<bool> personalized({CancelToken? cancelToken}) =>
      _api.personalized(cancelToken: cancelToken);

  Future<void> setPersonalized({required bool personalized}) =>
      _api.setPersonalized(personalized: personalized);

  /// 开始换绑到 [mobile], 返回换绑的命令. 新号码已注册过其他账号时失败.
  Future<MobileChange> startMobileChange(String mobile) async {
    final dto = await _api.prepareMobileChange(
      commandId: newIdempotencyKey(),
      mobile: mobile,
    );
    final id = dto.commandId;
    if (id == null) {
      throw const AppFailure(FailureKind.unknown, serverMessage: 'no command');
    }
    return MobileChange(
      commandId: id,
      mobile: mobile,
      oldProofRequired: dto.oldProofRequired ?? true,
    );
  }

  /// 给新手机 ([oldPhone] 为 false) 或旧手机发验证码.
  Future<void> sendMobileChangeCode(
    MobileChange change, {
    required bool oldPhone,
    CaptchaTicket? ticket,
  }) => _api.sendMobileChangeCode(
    change.commandId,
    type: oldPhone ? 'OLD_PHONE' : 'NEW_PHONE',
    captchaHeaders: ticket?.headers ?? const {},
  );

  /// 提交换绑. 成功后本机的会话会换发, 返回换发的结果.
  Future<Rotation> commitMobileChange(
    MobileChange change, {
    required String newCode,
    String? oldCode,
    String? password,
  }) async {
    final capability = newRecoveryCapability();
    final committed = await _api.commitMobileChange(
      change.commandId,
      newCode: newCode,
      oldCode: oldCode,
      password: password,
      recoveryCapability: capability,
    );
    if (rotationOf(committed.replacement) case final ready?) return ready;
    if (committed.currentDevice == 'REAUTHENTICATION_REQUIRED') {
      return const RotationNeedsSignIn();
    }
    return awaitRotation(
      () => _api.resumeMobileChange(
        change.commandId,
        recoveryCapability: capability,
      ),
    );
  }

  Paged<UserBrief> _briefs(Paged<FansDto> page) => Paged(
    items: [
      for (final dto in page.items)
        if (dto.id case final id?)
          UserBrief(
            id: id,
            nickname: _text(dto.displayName) ?? '同学',
            avatarUrl: imageUrl(dto.avatar),
            since: dateFromMillis(dto.createdAt),
          ),
    ],
    page: page.page,
    hasNext: page.hasNext,
  );

  static String? _text(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  CurrentUser _toUser(UserInfoDto dto) => CurrentUser(
    id: dto.id ?? 0,
    nickname: dto.displayName?.trim().isNotEmpty == true
        ? dto.displayName!.trim()
        : '同学',
    username: dto.hasUsername == true ? dto.userName : null,
    avatarUrl: imageUrl(dto.avatar),
    phone: dto.phone?.isNotEmpty == true ? dto.phone : null,
    signature: dto.signature?.isNotEmpty == true ? dto.signature : null,
    hasPassword: dto.hasPassword ?? false,
    verified: dto.verified ?? false,
    verifyMethod: switch (dto.method) {
      'sso' => VerifyMethod.sso,
      'school_email' => VerifyMethod.schoolEmail,
      _ => null,
    },
    verifiedEmail: dto.verifiedEmail,
    banned: dto.banned ?? false,
    banReason: dto.banReason?.isNotEmpty == true ? dto.banReason : null,
    bannedAt: dateFromMillis(dto.bannedAt),
    banUntil: dateFromMillis(dto.banUntil),
  );
}

@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) =>
    UserRepository(ref.watch(userApiProvider), ref.watch(kvStoreProvider));
