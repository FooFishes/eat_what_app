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

/// 接口分组 Feedback: 意见反馈, 店铺 "信息有误", 举报, 以及我提交过的记录.
///
/// 同一个对象已有本人未处理的同类记录时, 服务端返回已有记录, 客户端按提交成功处理.
/// 意见反馈没有这一合并, 网络失败后重试可能产生两条记录.
class FeedbackApi {
  FeedbackApi(this._client);

  final ApiClient _client;

  Future<void> submitCatalogError(CatalogErrorDto body) =>
      _client.post(FeedbackEndpoints.catalogErrors, body: body.toJson());

  Future<void> submitReport(ReportDto body) =>
      _client.post(FeedbackEndpoints.reports, body: body.toJson());

  Future<void> submitFeedback(FeedbackMessageDto body) =>
      _client.post(FeedbackEndpoints.messages, body: body.toJson());

  /// 我提交过的一条记录. 记录不存在或不是本人提交的, 返回 10001.
  Future<FeedbackCaseDto> mine(int id, {CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(FeedbackEndpoints.mine(id), cancelToken: cancelToken),
        FeedbackCaseDto.fromJson,
      );
}

/// 我提交过的一条反馈, 信息有误或举报 (`FeedbackDtos.CaseView`). 只读取消息页跳转需要的字段.
@JsonSerializable(createToJson: false)
class const FeedbackCaseDto({
  final int? id,

  /// `FEEDBACK`, `CATALOG_ERROR` 或 `REPORT`.
  final String? kind,

  /// 记录关于的对象. 意见反馈没有关联对象时为 null.
  final FeedbackTargetDto? target,
}) {
  factory FeedbackCaseDto.fromJson(Map<String, dynamic> json) =>
      _$FeedbackCaseDtoFromJson(json);
}

/// 记录关于的对象 (`FeedbackDtos.Target`). [type] 为 `FOOD`, `RESTAURANT`, `COMMENT` 或 `USER`.
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
/// [screenshotKeys] 是用途为 `feedback` 的上传 key, 最多 3 个. 从菜或店进入时 [context] 指向该菜或店.
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

/// 反馈关于的对象. [type] 为 `FOOD` 或 `RESTAURANT`.
@JsonSerializable(createFactory: false)
class const FeedbackContextDto({
  required final String type,
  required final int id,
}) {
  Map<String, dynamic> toJson() => _$FeedbackContextDtoToJson(this);
}

@Riverpod(keepAlive: true)
FeedbackApi feedbackApi(Ref ref) => FeedbackApi(ref.watch(apiClientProvider));
