import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_api.g.dart';

/// NotificationApi 调用的接口路径, 相对于业务接口地址.
abstract final class NotificationEndpoints {
  static const unreadCount = '/notification/cards/unread/count';
  static String readCard(int id) => '/notification/cards/$id/read';
  static const readAll = '/notification/cards/read-all';
  static const cards = '/notification/cards';
}

/// 通知消息接口 (`NotificationCards` 分组), 提供按分栏获取合并消息, 查询未读数和标记已读.
class NotificationApi {
  NotificationApi(this._client);

  final ApiClient _client;

  /// 按最近一条消息的时间倒序获取通知卡片列表; [column] 为分栏接口取值, 如 `ALL`, `SYSTEM`.
  Future<Paged<NoticeCardDto>> cards(
    String column, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      NotificationEndpoints.cards,
      query: {'column': column, 'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    NoticeCardDto.fromJson,
  );

  /// 查询 "全部" 分栏的未读数, 返回的 `cards` 为含未读消息的行数, `members` 为未读消息条数.
  Future<UnreadDto> unread({CancelToken? cancelToken}) async => decodeJson(
    await _client.get(
      NotificationEndpoints.unreadCount,
      cancelToken: cancelToken,
    ),
    UnreadDto.fromJson,
  );

  /// 将指定消息卡片内合并的多条消息全部标记为已读.
  Future<void> read(int id) => _client.post(NotificationEndpoints.readCard(id));

  /// 将分栏 [column] 下的全部消息 (含未加载页) 标记为已读; 传入 `ALL` 表示全部分栏.
  Future<void> readAll(String column) =>
      _client.post(NotificationEndpoints.readAll, query: {'column': column});
}

/// 消息卡片 (`NotificationDtos.Card`).
///
/// - [unreadMemberCount] 为 0 时表示该卡片合并的消息已全部阅读.
/// - [latestAt] 为最近一条消息的 Unix 毫秒时间戳.
/// - [actors] 为最近至多 3 位互动者, 系统消息时为空.
/// - [data] 仅系统消息携带, 按其中的 `type` 字段区分结构并由仓库逐类解析.
@JsonSerializable(createToJson: false)
class const NoticeCardDto({
  final int? id,
  final String? column,
  final String? kind,
  final NoticeTargetDto? target,
  final int? memberCount,
  final int? unreadMemberCount,
  final int? latestAt,
  final List<NoticeActorDto>? actors,
  final Map<String, dynamic>? data,
}) {
  factory NoticeCardDto.fromJson(Map<String, dynamic> json) =>
      _$NoticeCardDtoFromJson(json);
}

/// 消息指向的目标对象, [domain] 取值如 `foods`, `comments`, `users`, `feedback`, `announcements`.
@JsonSerializable(createToJson: false)
class const NoticeTargetDto({final String? domain, final int? id}) {
  factory NoticeTargetDto.fromJson(Map<String, dynamic> json) =>
      _$NoticeTargetDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class const NoticeActorDto({
  final int? id,
  final String? displayName,
  final String? avatar,
}) {
  factory NoticeActorDto.fromJson(Map<String, dynamic> json) =>
      _$NoticeActorDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class const UnreadDto({final int? cards, final int? members}) {
  factory UnreadDto.fromJson(Map<String, dynamic> json) =>
      _$UnreadDtoFromJson(json);
}

/// 通知消息仓库, 负责将接口卡片 DTO 转换为领域模型 [Notice].
///
/// 缺少 `id` 的卡片无法执行已读标记, 因此在转换时直接丢弃.
class NotificationRepository {
  NotificationRepository(this._api);

  final NotificationApi _api;

  Future<Paged<Notice>> list(
    NoticeColumn column, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final result = await _api.cards(
      column.api,
      page: page,
      cancelToken: cancelToken,
    );
    return Paged(
      items: [for (final dto in result.items) ?_notice(dto)],
      page: result.page,
      hasNext: result.hasNext,
      total: result.total,
    );
  }

  /// 返回含未读消息的行数; 消息页标题旁的 "3 条未读" 按行计数, 与列表中的未读圆点保持一致.
  Future<int> unreadCount({CancelToken? cancelToken}) async =>
      (await _api.unread(cancelToken: cancelToken)).cards ?? 0;

  Future<void> read(int id) => _api.read(id);

  /// 将分栏 [column] 下的全部消息 (含未加载页) 标记为已读.
  Future<void> readAll(NoticeColumn column) => _api.readAll(column.api);

  static Notice? _notice(NoticeCardDto dto) {
    final id = dto.id;
    if (id == null) return null;
    return Notice(
      id: id,
      kind: NoticeKind.fromApi(dto.kind),
      targetDomain: dto.target?.domain ?? '',
      targetId: dto.target?.id ?? 0,
      memberCount: dto.memberCount ?? 1,
      read: (dto.unreadMemberCount ?? 0) == 0,
      latestAt: dateFromMillis(dto.latestAt) ?? DateTime.now(),
      actors: [
        for (final actor in dto.actors ?? const <NoticeActorDto>[])
          if (actor.id != null)
            NoticeActor(
              id: actor.id!,
              name: actor.displayName?.trim().isNotEmpty == true
                  ? actor.displayName!.trim()
                  : '同学',
              avatar: imageUrl(actor.avatar),
            ),
      ],
      detail: _detail(dto.data),
      dishId: (dto.data?['foodId'] as num?)?.toInt(),
    );
  }

  static NoticeDetail? _detail(Map<String, dynamic>? json) {
    if (json == null) return null;
    String text(String key) => (json[key] as String?)?.trim() ?? '';
    return switch (json['type']) {
      'case_result' => CaseResultDetail(
        caseId: (json['caseId'] as num?)?.toInt(),
        kind: switch (json['kind']) {
          'CATALOG_ERROR' => CaseKind.catalogError,
          'REPORT' => CaseKind.report,
          _ => CaseKind.feedback,
        },
        outcome: json['outcome'] as String?,
        reasonCode: json['reasonCode'] as String?,
        reply: text('reply'),
      ),
      'announcement' => AnnouncementDetail(
        title: text('title'),
        content: text('content'),
      ),
      'account_banned' => BanDetail(
        reason: text('reason').isEmpty ? null : text('reason'),
        until: dateFromMillis((json['banUntil'] as num?)?.toInt()),
      ),
      'new_device_login' => NewDeviceDetail(
        deviceName: deviceNameOf(json['deviceName'] as String?),
        platform: json['device'] as String?,
      ),
      'content_removed' => ContentRemovedDetail(
        comment: json['contentType'] == 'comment',
        title: text('title'),
        reason: text('reason').isEmpty ? null : text('reason'),
      ),
      _ => null,
    };
  }
}

@Riverpod(keepAlive: true)
NotificationApi notificationApi(Ref ref) =>
    NotificationApi(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) =>
    NotificationRepository(ref.watch(notificationApiProvider));
