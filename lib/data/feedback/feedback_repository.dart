import 'package:eat/data/feedback/feedback_api.dart';
import 'package:eat/domain/models/report.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feedback_repository.g.dart';

/// 意见反馈, 店铺 "信息有误" 和举报.
///
/// [idempotencyKey] 由调用方保存: 同一份内容重试时沿用, 内容变化后换新值.
/// 补充说明去掉首尾空白, 为空时不发送.
class FeedbackRepository {
  FeedbackRepository(this._api);

  final FeedbackApi _api;

  Future<void> reportShopError({
    required int shopId,
    required ShopErrorType type,
    String note = '',
    required String idempotencyKey,
  }) => _api.submitCatalogError(
    CatalogErrorDto(
      restaurantId: shopId,
      errorType: type.api,
      note: _note(note),
    ),
    idempotencyKey: idempotencyKey,
  );

  Future<void> report(
    ReportTarget target, {
    required ReportReason reason,
    String note = '',
    required String idempotencyKey,
  }) => _api.submitReport(
    ReportDto(
      targetType: target.kind.api,
      targetId: target.id,
      reason: reason.api,
      note: _note(note),
    ),
    idempotencyKey: idempotencyKey,
  );

  /// 提交意见反馈. [screenshotKeys] 是已上传的截图. 从菜或店进入时传入 [dishId] 或 [shopId].
  Future<void> sendFeedback({
    required String text,
    List<String> screenshotKeys = const [],
    int? dishId,
    int? shopId,
    required String idempotencyKey,
  }) => _api.submitFeedback(
    FeedbackMessageDto(
      text: text.trim(),
      screenshotKeys: screenshotKeys.isEmpty ? null : screenshotKeys,
      context: switch ((dishId, shopId)) {
        (final id?, _) => FeedbackContextDto(type: 'FOOD', id: id),
        (null, final id?) => FeedbackContextDto(type: 'RESTAURANT', id: id),
        _ => null,
      },
    ),
    idempotencyKey: idempotencyKey,
  );

  static String? _note(String note) {
    final trimmed = note.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

@Riverpod(keepAlive: true)
FeedbackRepository feedbackRepository(Ref ref) =>
    FeedbackRepository(ref.watch(feedbackApiProvider));
