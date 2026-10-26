import 'dart:convert';

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/user/user_api.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository.g.dart';

/// 当前用户：拉最新的、存一份到本地，启动时先用本地那份显示。
class UserRepository {
  UserRepository(this._api, this._kv, this._assetBaseUrl);

  /// 在 `cache.` 下，退出登录时和别的接口缓存一起删掉。
  static const cacheKey = 'cache.user.current';

  final UserApi _api;
  final KvStore _kv;
  final String _assetBaseUrl;

  Future<CurrentUser> fetchCurrent() async {
    final dto = await _api.info();
    await _kv.write(cacheKey, jsonEncode(dto.toJson()));
    return _toUser(dto);
  }

  /// 上一次拉到的用户信息；没有或者读坏了返回 null。
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

  CurrentUser _toUser(UserInfoDto dto) => CurrentUser(
    id: dto.id ?? 0,
    nickname: dto.userName?.trim().isNotEmpty == true
        ? dto.userName!.trim()
        : '同学',
    username: dto.hasUsername == true ? dto.loginUsername : null,
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
