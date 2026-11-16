import 'dart:convert';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/remote_config/remote_config_api.dart';
import 'package:eat/domain/models/client_config.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_config_repository.g.dart';

/// 本机保存的远程配置快照及其 `ETag`.
class const RemoteConfigSnapshot({
  required final ClientConfig config,
  final String? etag,
});

/// 一次远程配置请求的结果.
sealed class RemoteConfigFetch {
  const RemoteConfigFetch();
}

/// 服务端返回 304, 本机快照仍是最新.
final class RemoteConfigUnchanged extends RemoteConfigFetch {
  const RemoteConfigUnchanged();
}

/// 获取到新配置, 已写入本机快照.
final class RemoteConfigFetched extends RemoteConfigFetch {
  const RemoteConfigFetched(this.snapshot);

  final RemoteConfigSnapshot snapshot;
}

/// 远程配置仓库: 请求接口, 读写本机快照, 读取内置默认值, 把接口数据逐项校验为 [ClientConfig].
class RemoteConfigRepository {
  RemoteConfigRepository(
    this._api,
    this._kv, {
    Future<String> Function()? loadDefaults,
  }) : _loadDefaults =
           loadDefaults ?? (() => rootBundle.loadString(defaultsAsset));

  /// 远程配置快照的存储键. 快照属于设备而非账号, 因此不放在 `cache.` 前缀下, 退出登录时保留.
  static const snapshotKey = 'config.remote';

  /// 内置默认值, 本机从未获取到配置时使用, 也是逐项校验失败时的回退值.
  static const defaultsAsset = 'assets/config/remote_defaults.json';

  final RemoteConfigApi _api;
  final KvStore _kv;
  final Future<String> Function() _loadDefaults;

  /// 读取内置默认值. 资源缺失或格式有误时返回 [ClientConfig.empty].
  Future<ClientConfig> defaults() async {
    try {
      return parseClientConfig(
        jsonDecode(await _loadDefaults()),
        ClientConfig.empty,
      );
    } on Object {
      return ClientConfig.empty;
    }
  }

  /// 读取本机快照, 没有或无法解析时返回 null. 快照中格式有误的项退回 [fallback] 中的对应项.
  Future<RemoteConfigSnapshot?> readSnapshot(ClientConfig fallback) async {
    try {
      final raw = await _kv.read(snapshotKey);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return RemoteConfigSnapshot(
        config: parseClientConfig(json['data'], fallback),
        etag: json['etag'] as String?,
      );
    } on Object {
      return null;
    }
  }

  /// 请求最新配置. 有新配置时写入本机快照, 写入失败不影响结果.
  ///
  /// 接口数据不是对象时抛出 [AppFailure], 调用方继续使用原有配置.
  Future<RemoteConfigFetch> fetch({
    required ClientConfig fallback,
    String? platform,
    int? build,
    int? campusId,
    String? etag,
  }) async {
    final result = await _api.fetch(
      platform: platform,
      build: build,
      campusId: campusId,
      etag: etag,
    );
    if (result.notModified) return const RemoteConfigUnchanged();
    final data = result.data;
    if (data is! Map<String, dynamic>) {
      throw const AppFailure(FailureKind.unknown, serverMessage: 'bad config');
    }
    final snapshot = RemoteConfigSnapshot(
      config: parseClientConfig(data, fallback),
      etag: result.etag,
    );
    try {
      await _kv.write(
        snapshotKey,
        jsonEncode({'etag': ?result.etag, 'data': data}),
      );
    } on Object {
      // 快照只用于下次启动时的初始值, 写入失败时下次启动使用旧快照或默认值.
    }
    return RemoteConfigFetched(snapshot);
  }
}

/// 把接口的 `ClientConfig` 逐项校验为 [ClientConfig].
///
/// 某一项格式有误时只有该项退回 [fallback], 其余项照常使用, 避免一处错误让整份配置作废.
/// 无法识别的公告逐条丢弃, 不认识的键忽略. [data] 不是对象时返回 [fallback].
ClientConfig parseClientConfig(Object? data, ClientConfig fallback) {
  if (data is! Map<String, dynamic>) return fallback;
  return ClientConfig(
    configVersion: switch (data['configVersion']) {
      final num v => v.toInt(),
      _ => fallback.configVersion,
    },
    flags: _flags(data['flags'], fallback),
    params: switch (data['params']) {
      final Map<String, dynamic> params => Map.unmodifiable(params),
      _ => fallback.params,
    },
    announcements: switch (data['announcements']) {
      final List<dynamic> list => [
        for (final item in list) ?_announcement(item),
      ],
      _ => fallback.announcements,
    },
    maintenance: _maintenance(data['maintenance']) ?? fallback.maintenance,
    versions: _versions(data['versions'], fallback),
  );
}

Map<RemoteFeature, FeatureFlag> _flags(Object? json, ClientConfig fallback) {
  if (json is! Map<String, dynamic>) return fallback.flags;
  return {
    for (final feature in RemoteFeature.values)
      feature: _flag(json[feature.name]) ?? fallback.flag(feature),
  };
}

FeatureFlag? _flag(Object? json) {
  if (json is! Map<String, dynamic>) return null;
  try {
    final dto = FlagDto.fromJson(json);
    final on = dto.on;
    if (on == null) return null;
    return FeatureFlag(on: on, reason: on ? null : _text(dto.reason));
  } on Object {
    return null;
  }
}

Maintenance? _maintenance(Object? json) {
  if (json is! Map<String, dynamic>) return null;
  try {
    final dto = MaintenanceDto.fromJson(json);
    final mode = switch (dto.mode) {
      'NONE' || null => MaintenanceMode.none,
      'READ_ONLY' => MaintenanceMode.readOnly,
      'DOWN' => MaintenanceMode.down,
      _ => null,
    };
    if (mode == null) return null;
    if (mode == MaintenanceMode.none) return const Maintenance();
    return Maintenance(
      mode: mode,
      message: _text(dto.message),
      until: dateFromMillis(dto.until),
    );
  } on Object {
    return null;
  }
}

Announcement? _announcement(Object? json) {
  if (json is! Map<String, dynamic>) return null;
  try {
    final dto = AnnouncementDto.fromJson(json);
    final level = switch (dto.level) {
      'NORMAL' => AnnouncementLevel.normal,
      'IMPORTANT' => AnnouncementLevel.important,
      _ => null,
    };
    final content = _text(dto.content);
    if (level == null || content == null) return null;
    return Announcement(
      id: dto.id,
      level: level,
      title: _text(dto.title),
      content: content,
      linkUrl: _text(dto.linkUrl),
      startsAt: dateFromMillis(dto.startsAt),
      endsAt: dateFromMillis(dto.endsAt),
    );
  } on Object {
    return null;
  }
}

Map<String, VersionLine> _versions(Object? json, ClientConfig fallback) {
  if (json is! Map<String, dynamic>) return fallback.versions;
  final versions = <String, VersionLine>{};
  for (final MapEntry(:key, :value) in json.entries) {
    if (_version(value) ?? fallback.versions[key] case final line?) {
      versions[key] = line;
    }
  }
  return versions;
}

VersionLine? _version(Object? json) {
  if (json is! Map<String, dynamic>) return null;
  try {
    final dto = VersionDto.fromJson(json);
    return VersionLine(
      minBuild: dto.minBuild ?? 0,
      latestBuild: dto.latestBuild ?? 0,
      latestVersionName: _text(dto.latestVersionName),
      storeUrl: _text(dto.storeUrl),
      releaseNotes: _text(dto.releaseNotes),
    );
  } on Object {
    return null;
  }
}

String? _text(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

@Riverpod(keepAlive: true)
RemoteConfigRepository remoteConfigRepository(Ref ref) =>
    RemoteConfigRepository(
      ref.watch(remoteConfigApiProvider),
      ref.watch(kvStoreProvider),
    );
