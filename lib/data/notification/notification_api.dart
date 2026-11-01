import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_api.g.dart';

/// 接口分组 Notification: 消息列表, 未读数, 标记已读.
class NotificationApi {
  NotificationApi(this._client);

  final ApiClient _client;

  static const endpoints = [
    'GET /notification/list',
    'GET /notification/unread/count',
    'POST /notification/read/{id}',
    'POST /notification/read/all',
  ];

  Future<Paged<NotificationDto>> list({
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      '/notification/list',
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    NotificationDto.fromJson,
  );

  Future<int> unreadCount({CancelToken? cancelToken}) async {
    final data = await _client.get(
      '/notification/unread/count',
      cancelToken: cancelToken,
    );
    return data is num ? data.toInt() : 0;
  }

  Future<void> read(int id) => _client.post('/notification/read/$id');

  Future<void> readAll() => _client.post('/notification/read/all');
}

@JsonSerializable(createToJson: false)
class const NotificationDto({
  final int? id,
  final int? actorId,
  final String? actorName,
  final String? actorAvatar,
  final String? type,
  final String? targetType,
  final int? targetId,
  final String? data,
  final bool? read,
  final int? createdAt,
}) {
  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);
}

/// 消息数据. 把 DTO 转换为 [Notice], 并把 JSON 字符串形式的 `data` 解析为 Map.
class NotificationRepository {
  NotificationRepository(this._api, this._assetBaseUrl);

  final NotificationApi _api;
  final String _assetBaseUrl;

  Future<Paged<Notice>> list({int page = 1, CancelToken? cancelToken}) async {
    final result = await _api.list(page: page, cancelToken: cancelToken);
    return Paged(
      items: [for (final dto in result.items) ?_notice(dto)],
      page: result.page,
      hasNext: result.hasNext,
    );
  }

  Future<int> unreadCount({CancelToken? cancelToken}) =>
      _api.unreadCount(cancelToken: cancelToken);

  Future<void> read(int id) => _api.read(id);

  Future<void> readAll() => _api.readAll();

  Notice? _notice(NotificationDto dto) {
    if (dto.id == null) return null;
    return Notice(
      id: dto.id!,
      actorId: dto.actorId ?? 0,
      actorName: dto.actorName?.trim().isNotEmpty == true
          ? dto.actorName!.trim()
          : '同学',
      actorAvatar: resolveImageUrl(dto.actorAvatar, _assetBaseUrl),
      type: dto.type ?? '',
      targetType: dto.targetType ?? '',
      targetId: dto.targetId ?? 0,
      data: _data(dto.data),
      read: dto.read ?? false,
      createdAt: dateFromMillis(dto.createdAt) ?? DateTime.now(),
    );
  }

  static Map<String, Object?> _data(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}

@Riverpod(keepAlive: true)
NotificationApi notificationApi(Ref ref) =>
    NotificationApi(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) =>
    NotificationRepository(
      ref.watch(notificationApiProvider),
      ref.watch(appConfigProvider).assetBaseUrl,
    );
