import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feedback_api.g.dart';

/// 接口分组 Feedback: 意见反馈, 店铺 "信息有误" 和举报.
///
/// 提交都要求携带 `Idempotency-Key`. 同一个键重放时, 服务端返回第一次的结果.
/// 同一个键对应不同内容时, 服务端拒绝请求.
///
/// 同一个对象已有未处理的记录时, 服务端返回已有记录, 客户端按提交成功处理.
class FeedbackApi {
  FeedbackApi(this._client);

  final ApiClient _client;

  static const endpoints = [
    'POST /feedback/catalog-errors',
    'POST /feedback/reports',
    'POST /feedback/messages',
  ];

  Future<void> submitCatalogError(
    CatalogErrorDto body, {
    required String idempotencyKey,
  }) => _client.post(
    '/feedback/catalog-errors',
    body: body.toJson(),
    headers: {'Idempotency-Key': idempotencyKey},
  );

  Future<void> submitReport(ReportDto body, {required String idempotencyKey}) =>
      _client.post(
        '/feedback/reports',
        body: body.toJson(),
        headers: {'Idempotency-Key': idempotencyKey},
      );

  Future<void> submitFeedback(
    FeedbackMessageDto body, {
    required String idempotencyKey,
  }) => _client.post(
    '/feedback/messages',
    body: body.toJson(),
    headers: {'Idempotency-Key': idempotencyKey},
  );
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
