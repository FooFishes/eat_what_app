import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/common/convert.dart';
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
      signature: switch (dto.signature?.trim()) {
        final text? when text.isNotEmpty => text,
        _ => null,
      },
      level: dto.level,
      earnedLikes: dto.earnedLikes,
      fans: dto.fansCount,
      followings: dto.followingsCount,
      fansVisible: dto.fansVisible ?? false,
      followingsVisible: dto.followingsVisible ?? false,
      followsMe: dto.isFollowingMe ?? false,
      followedByMe: dto.isFollowingHim ?? false,
      blocked: dto.blocked ?? false,
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

  /// 换绑第一步: 给当前绑定的号码发验证码.
  Future<void> sendOldMobileCode(CaptchaTicket? ticket) =>
      _api.sendOldMobileCode(captchaHeaders: ticket?.headers ?? const {});

  /// 换绑第二步: 给新号码 [mobile] 发验证码. [oldCode] 是旧号码收到的验证码, 已验证过时为 null.
  Future<void> sendNewMobileCode(
    String mobile, {
    String? oldCode,
    CaptchaTicket? ticket,
  }) => _api.sendNewMobileCode(
    oldCode: oldCode,
    mobile: mobile,
    captchaHeaders: ticket?.headers ?? const {},
  );

  /// 换绑第三步: 提交新号码和它的验证码. 本机的会话不变.
  Future<void> commitMobileChange(String mobile, String code) =>
      _api.commitMobileChange(mobile: mobile, code: code);

  /// 补绑手机: 给 [mobile] 发验证码. 只用于还没有手机号的账号.
  Future<void> sendBindCode(String mobile, CaptchaTicket? ticket) =>
      _api.sendBindCode(mobile, captchaHeaders: ticket?.headers ?? const {});

  Future<void> bindMobile(String mobile, String code) =>
      _api.bindMobile(mobile: mobile, code: code);

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
      'email' => VerifyMethod.schoolEmail,
      _ => null,
    },
    verifiedEmail: dto.verifiedEmail,
    level: dto.level,
    banned: dto.banned ?? false,
    banReason: dto.banReason?.trim().isNotEmpty == true
        ? dto.banReason!.trim()
        : null,
    banUntil: switch (dto.banUntil) {
      final ms? when dto.banned == true => DateTime.fromMillisecondsSinceEpoch(
        ms,
      ),
      _ => null,
    },
  );
}

@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) =>
    UserRepository(ref.watch(userApiProvider), ref.watch(kvStoreProvider));
