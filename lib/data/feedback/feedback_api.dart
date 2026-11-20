import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feedback_api.g.dart';

/// FeedbackApi 调用的接口路径, 相对于业务接口地址.
abstract final class FeedbackEndpoints {
  static const catalogErrors = '/feedback/catalog-errors';
  static const reports = '/feedback/reports';
  static const messages = '/feedback/messages';
  static const mineList = '/feedback/mine';
  static String mine(int id) => '/feedback/mine/$id';
}

/// 封装 Feedback 接口分组, 提供意见反馈, 店铺 "信息有误" 纠错, 举报及个人提交记录查询等接口.
///
/// 若同一对象已存在本人未处理的同类纠错或举报记录, 服务端会直接返回已有记录, 客户端按提交成功处理;
/// 意见反馈不参与该去重合并, 网络失败后重试可能会产生多条记录.
class FeedbackApi {
  FeedbackApi(this._client);

  final ApiClient _client;

  Future<void> submitCatalogError(CatalogErrorDto body) =>
      _client.post(FeedbackEndpoints.catalogErrors, body: body.toJson());

  Future<void> submitReport(ReportDto body) =>
      _client.post(FeedbackEndpoints.reports, body: body.toJson());

  Future<void> submitFeedback(FeedbackMessageDto body) =>
      _client.post(FeedbackEndpoints.messages, body: body.toJson());

  /// 分页查询本人提交过的记录, 新提交的在前. [kind] 为 `FEEDBACK`, `CATALOG_ERROR` 或 `REPORT`, 为 null 时不筛选.
  Future<Paged<FeedbackCaseDto>> mineList({
    String? kind,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      FeedbackEndpoints.mineList,
      query: {'kind': ?kind, 'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    FeedbackCaseDto.fromJson,
  );

  /// 查询本人提交过的一条记录. 若记录不存在或非本人提交, 服务端返回业务码 10001.
  Future<FeedbackCaseDto> mine(int id, {CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(FeedbackEndpoints.mine(id), cancelToken: cancelToken),
        FeedbackCaseDto.fromJson,
      );
}

/// 本人提交过的反馈, 纠错或举报记录 (`FeedbackDtos.CaseView`). 时间为毫秒时间戳.
@JsonSerializable(createToJson: false)
class const FeedbackCaseDto({
  final int? id,

  /// `FEEDBACK`, `CATALOG_ERROR` 或 `REPORT`.
  final String? kind,

  /// 意见反馈的分类: `PROBLEM`, `SUGGESTION` 或 `OTHER`. 没分类的旧记录返回 `OTHER`, 信息有误和举报为 null.
  final String? category,

  /// `OPEN` 或 `CLOSED`.
  final String? status,

  /// 记录关联的目标对象, 无关联对象的意见反馈为 null.
  final FeedbackTargetDto? target,

  /// 信息有误的错误类型或举报原因, 意见反馈为 null.
  final String? reason,

  /// 意见反馈的正文, 或信息有误和举报的补充说明.
  final String? text,
  final List<FeedbackScreenshotDto>? screenshots,

  /// `ACCEPTED`, `REJECTED` 或 `RESOLVED` (仅意见反馈), 未处理时为 null.
  final String? outcome,

  /// 管理员的公开回复, 没有回复时为空字符串.
  final String? reply,
  final int? createdAt,
  final int? closedAt,
}) {
  factory FeedbackCaseDto.fromJson(Map<String, dynamic> json) =>
      _$FeedbackCaseDtoFromJson(json);
}

/// 反馈记录关联的目标对象 (`FeedbackDtos.Target`), [type] 取值为 `FOOD`, `RESTAURANT`, `COMMENT` 或 `USER`.
@JsonSerializable(createToJson: false)
class const FeedbackTargetDto({final String? type, final int? id}) {
  factory FeedbackTargetDto.fromJson(Map<String, dynamic> json) =>
      _$FeedbackTargetDtoFromJson(json);
}

/// 反馈记录中的一张截图 (`FeedbackDtos.Screenshot`), [url] 为可直接展示的地址.
@JsonSerializable(createToJson: false)
class const FeedbackScreenshotDto({final int? slot, final String? url}) {
  factory FeedbackScreenshotDto.fromJson(Map<String, dynamic> json) =>
      _$FeedbackScreenshotDtoFromJson(json);
}

/// 店铺 "信息有误" 的请求体 (`CatalogErrorInput`). [note] 最多 200 字.
@JsonSerializable(createFactory: false, includeIfNull: false)
class const CatalogErrorDto({
  required final int restaurantId,
  required final String errorType,
  final String? note,
}) {
  Map<String, dynamic> toJson() => _$CatalogErrorDtoToJson(this);
}

/// 举报的请求体 (`ReportInput`). [note] 最多 200 字.
@JsonSerializable(createFactory: false, includeIfNull: false)
class const ReportDto({
  required final String targetType,
  required final int targetId,
  required final String reason,
  final String? note,
}) {
  Map<String, dynamic> toJson() => _$ReportDtoToJson(this);
}

/// 意见反馈的请求体 (`FeedbackDtos.MessageRequest`). [text] 最多 500 字.
///
/// - [category] 为 `PROBLEM`, `SUGGESTION` 或 `OTHER`, 服务端允许省略 (归入 `OTHER`), 客户端要求必选.
/// - [screenshotKeys] 为用途 `feedback` 的上传存储 key, 最多 3 个; 从菜品或店铺页进入时, [context] 指向对应对象.
/// - 设备型号, 系统和 App 版本不在请求里: 服务端按登录会话的安装 ID 取设备登记时上报的档案.
@JsonSerializable(
  createFactory: false,
  includeIfNull: false,
  explicitToJson: true,
)
class const FeedbackMessageDto({
  required final String text,
  required final String category,
  final List<String>? screenshotKeys,
  final FeedbackContextDto? context,
}) {
  Map<String, dynamic> toJson() => _$FeedbackMessageDtoToJson(this);
}

/// 意见反馈关联的上下文对象, [type] 取值为 `FOOD` 或 `RESTAURANT`.
@JsonSerializable(createFactory: false)
class const FeedbackContextDto({
  required final String type,
  required final int id,
}) {
  Map<String, dynamic> toJson() => _$FeedbackContextDtoToJson(this);
}

@Riverpod(keepAlive: true)
FeedbackApi feedbackApi(Ref ref) => FeedbackApi(ref.watch(apiClientProvider));
