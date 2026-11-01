import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/user/user_api.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/domain/models/notice.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository.g.dart';

/// 当前用户数据. 请求最新信息并保存到本地, 启动时先用本地副本显示.
class UserRepository {
  UserRepository(this._api, this._kv, this._assetBaseUrl);

  /// 位于 `cache.` 前缀下, 退出登录时与其他接口缓存一并删除.
  static const cacheKey = 'cache.user.current';

  final UserApi _api;
  final KvStore _kv;
  final String _assetBaseUrl;

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
      avatarUrl: resolveImageUrl(dto.avatar, _assetBaseUrl),
      earnedLikes: dto.earnedLikes ?? 0,
      fans: dto.fansCount ?? 0,
      followings: dto.followingsCount ?? 0,
      uploadedDishes: dto.uploadedFoodsCount ?? 0,
      fansVisible: dto.fansVisible ?? false,
      followingsVisible: dto.followingsVisible ?? false,
      followsMe: dto.isFollowingMe ?? false,
      followedByMe: dto.isFollowingHim ?? false,
    );
  }

  CurrentUser _toUser(UserInfoDto dto) => CurrentUser(
    id: dto.id ?? 0,
    nickname: dto.displayName?.trim().isNotEmpty == true
        ? dto.displayName!.trim()
        : '同学',
    username: dto.hasUsername == true ? dto.userName : null,
    avatarUrl: resolveImageUrl(dto.avatar, _assetBaseUrl),
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
  );
}

@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) => UserRepository(
  ref.watch(userApiProvider),
  ref.watch(kvStoreProvider),
  ref.watch(appConfigProvider).assetBaseUrl,
);
