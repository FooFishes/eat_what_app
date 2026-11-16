import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feedback_api.g.dart';

/// FeedbackApi 调用的接口路径, 相对于业务接口地址.
abstract final class FeedbackEndpoints {
  static const catalogErrors = '/feedback/catalog-errors';
  static const reports = '/feedback/reports';
  static const messages = '/feedback/messages';
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

  /// 查询本人提交过的一条记录. 若记录不存在或非本人提交, 服务端返回业务码 10001.
  Future<FeedbackCaseDto> mine(int id, {CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(FeedbackEndpoints.mine(id), cancelToken: cancelToken),
        FeedbackCaseDto.fromJson,
      );
}

/// 本人提交过的反馈, 纠错或举报记录 (`FeedbackDtos.CaseView`), 仅读取消息页跳转所需的字段.
@JsonSerializable(createToJson: false)
class const FeedbackCaseDto({
  final int? id,

  /// `FEEDBACK`, `CATALOG_ERROR` 或 `REPORT`.
  final String? kind,

  /// 记录关联的目标对象, 无关联对象的意见反馈为 null.
  final FeedbackTargetDto? target,
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

/// 意见反馈的请求体 (`FeedbackInput`). [text] 最多 500 字.
///
/// [screenshotKeys] 为用途 `feedback` 的上传存储 key, 最多 3 个; 从菜品或店铺页进入时, [context] 指向对应对象.
@JsonSerializable(
  createFactory: false,
  includeIfNull: false,
  explicitToJson: true,
)
class const FeedbackMessageDto({
  required final String text,
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
