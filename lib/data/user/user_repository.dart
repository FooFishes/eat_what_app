import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/core/storage/cache_store.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/user/user_api.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/people.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository.g.dart';

/// 用户数据仓库, 负责管理当前用户信息, 他人公开资料, 关注关系, 隐私设置及屏蔽列表.
///
/// 当前用户信息和本人的资料会持久化至本地缓存, 以便应用启动时优先使用本地副本展示.
class UserRepository {
  UserRepository(this._api, this._kv, this._cache);

  /// 位于 `cache.` 前缀下, 退出登录时与其他接口缓存一并删除.
  static const cacheKey = 'cache.user.current';

  static const _profileGroup = 'profile';

  /// 本人的设置 (隐私, 个性化推荐), 每项一条记录. 账号作用域的缓存在退出登录和登录过期时都会删除, 所以键里不带用户 id.
  static const _settingsGroup = 'settings';

  final UserApi _api;
  final KvStore _kv;
  final CacheStore _cache;

  Future<CurrentUser> fetchCurrent() async {
    final dto = await _api.info();
    await _kv.write(cacheKey, jsonEncode(dto.toJson()));
    return _toUser(dto);
  }

  /// 读取本地缓存的当前用户信息; 若无缓存则返回 null, 若缓存损坏则在删除该记录后返回 null.
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

  /// 获取指定用户的公开资料与统计数据, "我的" 页面亦通过该接口获取个人统计信息.
  ///
  /// [cache] 为 true 时把结果存入本地缓存, 只给本人的资料用, 每个账号存一份.
  Future<UserProfile> profile(
    int userId, {
    bool cache = false,
    CancelToken? cancelToken,
  }) async {
    final dto = await _api.profile(userId, cancelToken: cancelToken);
    if (cache) {
      await _cache.write(
        _profileGroup,
        '$userId',
        jsonEncode(dto.toJson()),
        maxEntries: 1,
      );
    }
    return _toProfile(userId, dto);
  }

  /// 读取本地缓存的资料, 没有缓存或缓存无法解析时返回 null.
  Future<UserProfile?> cachedProfile(int userId) async {
    final raw = await _cache.read(_profileGroup, '$userId');
    if (raw == null) return null;
    try {
      return _toProfile(
        userId,
        UserProfileDto.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } on Object {
      return null;
    }
  }

  UserProfile _toProfile(int userId, UserProfileDto dto) => UserProfile(
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
    title: _text(dto.title),
    earnedLikes: dto.earnedLikes,
    fans: dto.fansCount,
    followings: dto.followingsCount,
    fansVisible: dto.fansVisible ?? false,
    followingsVisible: dto.followingsVisible ?? false,
    followsMe: dto.isFollowingMe ?? false,
    followedByMe: dto.isFollowingHim ?? false,
    blocked: dto.blocked ?? false,
  );

  /// 保存昵称, 签名和头像; [avatarKey] 为 null 时保持原头像不变.
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

  /// 读取当前用户的隐私设置.
  ///
  /// 后端未提供单独的隐私查询接口, 因此通过查询本人公开资料中的两项可见性字段获取当前设置.
  Future<PrivacySettings> privacy(int myId, {CancelToken? cancelToken}) async {
    final dto = await _api.profile(myId, cancelToken: cancelToken);
    final settings = PrivacySettings(
      followingsPublic: dto.followingsVisible ?? true,
      fansPublic: dto.fansVisible ?? true,
    );
    await _cachePrivacy(settings);
    return settings;
  }

  /// 读取本地缓存的隐私设置, 没有缓存或缓存无法解析时返回 null.
  Future<PrivacySettings?> cachedPrivacy() => _readSetting(
    'privacy',
    (json) => PrivacySettings(
      followingsPublic: json['followings'] as bool,
      fansPublic: json['fans'] as bool,
    ),
  );

  Future<void> setPrivacy(PrivacySettings settings) async {
    await _api.changePrivacy(
      following: settings.followingsPublic,
      follower: settings.fansPublic,
    );
    await _cachePrivacy(settings);
  }

  Future<void> _cachePrivacy(PrivacySettings settings) => _writeSetting(
    'privacy',
    {'followings': settings.followingsPublic, 'fans': settings.fansPublic},
  );

  Future<void> _writeSetting(String key, Object json) =>
      _cache.write(_settingsGroup, key, jsonEncode(json), maxEntries: 4);

  Future<T?> _readSetting<T>(String key, T Function(dynamic json) parse) async {
    final raw = await _cache.read(_settingsGroup, key);
    if (raw == null) return null;
    try {
      return parse(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

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

  Future<bool> personalized({CancelToken? cancelToken}) async {
    final value = await _api.personalized(cancelToken: cancelToken);
    await _writeSetting('personalized', value);
    return value;
  }

  /// 读取本地缓存的个性化推荐开关, 没有缓存时返回 null.
  Future<bool?> cachedPersonalized() =>
      _readSetting('personalized', (json) => json as bool);

  Future<void> setPersonalized({required bool personalized}) async {
    await _api.setPersonalized(personalized: personalized);
    await _writeSetting('personalized', personalized);
  }

  /// 换绑手机第一步, 向当前绑定的手机号发送验证码.
  Future<void> sendOldMobileCode(CaptchaTicket? ticket) =>
      _api.sendOldMobileCode(captchaHeaders: ticket?.headers ?? const {});

  /// 换绑手机第二步, 向新号码 [mobile] 发送验证码; [oldCode] 为旧号码验证码, 若已完成校验则传 null.
  Future<void> sendNewMobileCode(
    String mobile, {
    String? oldCode,
    CaptchaTicket? ticket,
  }) => _api.sendNewMobileCode(
    oldCode: oldCode,
    mobile: mobile,
    captchaHeaders: ticket?.headers ?? const {},
  );

  /// 换绑手机第三步, 提交新号码及其验证码; 成功后本机登录会话保持有效.
  Future<void> commitMobileChange(String mobile, String code) =>
      _api.commitMobileChange(mobile: mobile, code: code);

  /// 补绑手机第一步, 向 [mobile] 发送验证码 (仅适用于尚未绑定手机号的账号).
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
            title: _text(dto.title),
            since: dateFromMillis(dto.createdAt),
            followsMe: dto.isFollowingMe ?? false,
            followedByMe: dto.isFollowingHim ?? false,
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
    title: _text(dto.title),
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
UserRepository userRepository(Ref ref) => UserRepository(
  ref.watch(userApiProvider),
  ref.watch(kvStoreProvider),
  ref.watch(cacheStoreProvider),
);
