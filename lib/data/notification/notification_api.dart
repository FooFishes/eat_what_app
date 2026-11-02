import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_api.g.dart';

/// 接口分组 NotificationCards: 按分栏获取合并后的消息, 未读数, 标记已读.
class NotificationApi {
  NotificationApi(this._client);

  final ApiClient _client;

  static const endpoints = [
    'GET /notification/cards',
    'GET /notification/cards/unread/count',
    'POST /notification/cards/{id}/read',
    'POST /notification/read/all',
  ];

  /// [column] 是分栏的接口取值, 如 `ALL`, `SYSTEM`. 按最近一条的时间倒序.
  Future<Paged<NoticeCardDto>> cards(
    String column, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      '/notification/cards',
      query: {'column': column, 'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    NoticeCardDto.fromJson,
  );

  /// "全部" 分栏的未读数. `cards` 是有未读的行数, `members` 是未读的条数.
  Future<UnreadDto> unread({CancelToken? cancelToken}) async => decodeJson(
    await _client.get(
      '/notification/cards/unread/count',
      cancelToken: cancelToken,
    ),
    UnreadDto.fromJson,
  );

  /// 把一行合并的各条都标为已读. [id] 是卡片的 UUID.
  Future<void> read(String id) => _client.post('/notification/cards/$id/read');

  /// 只标记旧版通知表中的消息 (关注和旧版活动的赞), 不包括其他来源的卡片.
  Future<void> readLegacyAll() => _client.post('/notification/read/all');
}

/// 消息卡片.
///
/// - [unreadMemberCount] 为 0 表示合并的各条都已读.
/// - [latestAt] 是最近一条的 Unix 毫秒时间.
/// - [actors] 是最近的至多 3 个互动者. 系统消息为空.
@JsonSerializable(createToJson: false)
class const NoticeCardDto({
  final String? id,
  final String? column,
  final String? kind,
  final NoticeTargetDto? target,
  final int? memberCount,
  final int? unreadMemberCount,
  final int? latestAt,
  final List<NoticeActorDto>? actors,
  final NoticeDataDto? data,
}) {
  factory NoticeCardDto.fromJson(Map<String, dynamic> json) =>
      _$NoticeCardDtoFromJson(json);
}

/// 消息的对象. [domain] 如 `foods`, `users`, `topics`, `restaurant`, `feedback`.
@JsonSerializable(createToJson: false)
class const NoticeTargetDto({
  final String? domain,
  final int? id,
  final bool? unavailable,
}) {
  factory NoticeTargetDto.fromJson(Map<String, dynamic> json) =>
      _$NoticeTargetDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class const NoticeActorDto({
  final int? id,
  final String? name,
  final String? avatar,
}) {
  factory NoticeActorDto.fromJson(Map<String, dynamic> json) =>
      _$NoticeActorDtoFromJson(json);
}

/// 卡片的附加数据. [detail] 按其中的 `type` 区分结构, 由仓库逐种解析.
@JsonSerializable(createToJson: false)
class const NoticeDataDto({final Map<String, dynamic>? detail}) {
  factory NoticeDataDto.fromJson(Map<String, dynamic> json) =>
      _$NoticeDataDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class const UnreadDto({final int? cards, final int? members}) {
  factory UnreadDto.fromJson(Map<String, dynamic> json) =>
      _$UnreadDtoFromJson(json);
}

/// 消息数据. 把卡片 DTO 转换为 [Notice].
///
/// 缺少 id 的卡片无法标记已读, 转换时丢弃.
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
    );
  }

  /// 有未读消息的行数. 消息页标题旁的 "3 条未读" 按行计数, 与列表中的未读圆点一致.
  Future<int> unreadCount({CancelToken? cancelToken}) async =>
      (await _api.unread(cancelToken: cancelToken)).cards ?? 0;

  Future<void> read(String id) => _api.read(id);

  // TODO: 后端没有消息卡片的全部已读接口, 旧版接口只标记关注和旧版活动的赞. 后端提供卡片的全部已读接口后改为调用该接口, 并删除逐行标记.
  /// 全部已读: 标记旧版通知表中的全部消息, 并逐行标记 [unreadIds].
  ///
  /// [unreadIds] 只包含已加载的行. 未加载的页中, 旧版通知表以外的消息仍为未读.
  Future<void> readAll(Iterable<String> unreadIds) async {
    await _api.readLegacyAll();
    await Future.wait([for (final id in unreadIds) _api.read(id)]);
  }

  static Notice? _notice(NoticeCardDto dto) {
    final id = dto.id;
    if (id == null || id.isEmpty) return null;
    return Notice(
      id: id,
      kind: NoticeKind.fromApi(dto.kind),
      targetDomain: dto.target?.domain ?? '',
      targetId: dto.target?.id ?? 0,
      targetUnavailable: dto.target?.unavailable ?? false,
      memberCount: dto.memberCount ?? 1,
      read: (dto.unreadMemberCount ?? 0) == 0,
      latestAt: dateFromMillis(dto.latestAt) ?? DateTime.now(),
      actors: [
        for (final actor in dto.actors ?? const <NoticeActorDto>[])
          if (actor.id != null)
            NoticeActor(
              id: actor.id!,
              name: actor.name?.trim().isNotEmpty == true
                  ? actor.name!.trim()
                  : '同学',
              avatar: imageUrl(actor.avatar),
            ),
      ],
      detail: _detail(dto.data?.detail),
    );
  }

  static NoticeDetail? _detail(Map<String, dynamic>? json) {
    if (json == null) return null;
    int? id(String key) => (json[key] as num?)?.toInt();
    String text(String key) => (json[key] as String?)?.trim() ?? '';
    bool flag(String key) => json[key] as bool? ?? false;
    return switch (json['type']) {
      'topic_included' => TopicIncludedDetail(
        dishId: flag('foodUnavailable') ? null : id('foodId'),
        dishName: text('foodName'),
        topicId: flag('topicUnavailable') ? null : id('topicId'),
        topicName: text('topicName'),
      ),
      'moderation_result' => ModerationDetail(
        shop: json['targetDomain'] == 'RESTAURANT',
        approved: json['verdict'] == 'APPROVE',
      ),
      'comment' => CommentDetail(
        dishId: id('foodId'),
        commentId: id('commentId'),
        unavailable: flag('unavailable'),
      ),
      'case_result' => CaseResultDetail(
        kind: switch (json['kind']) {
          'CATALOG_ERROR' => CaseKind.catalogError,
          'REPORT' => CaseKind.report,
          _ => CaseKind.feedback,
        },
        outcome: json['outcome'] as String?,
        reasonCode: json['reasonCode'] as String?,
        reply: text('reply'),
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
