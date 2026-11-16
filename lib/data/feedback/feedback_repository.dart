import 'package:dio/dio.dart';
import 'package:eat/data/feedback/feedback_api.dart';
import 'package:eat/domain/models/report.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feedback_repository.g.dart';

/// 负责提交意见反馈, 店铺 "信息有误" 纠错和内容举报, 并查询反馈关联对象.
///
/// 补充说明会自动去除首尾空白, 为空时不随请求发送.
class FeedbackRepository {
  FeedbackRepository(this._api);

  final FeedbackApi _api;

  Future<void> reportShopError({
    required int shopId,
    required ShopErrorType type,
    String note = '',
  }) => _api.submitCatalogError(
    CatalogErrorDto(
      restaurantId: shopId,
      errorType: type.api,
      note: _note(note),
    ),
  );

  Future<void> report(
    ReportTarget target, {
    required ReportReason reason,
    String note = '',
  }) => _api.submitReport(
    ReportDto(
      targetType: target.kind.api,
      targetId: target.id,
      reason: reason.api,
      note: _note(note),
    ),
  );

  /// 提交意见反馈. [screenshotKeys] 为已上传截图的存储 key; 从菜品或店铺页进入时传入 [dishId] 或 [shopId].
  Future<void> sendFeedback({
    required String text,
    List<String> screenshotKeys = const [],
    int? dishId,
    int? shopId,
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
  );

  /// 查询本人提交记录 [caseId] 关联的目标对象. 若该意见反馈无关联对象或类型无法识别, 则返回 null.
  Future<CaseSubject?> caseSubject(
    int caseId, {
    CancelToken? cancelToken,
  }) async {
    final target = (await _api.mine(caseId, cancelToken: cancelToken)).target;
    final id = target?.id;
    if (id == null) return null;
    final kind = switch (target?.type) {
      'FOOD' => CaseSubjectKind.dish,
      'RESTAURANT' => CaseSubjectKind.shop,
      'COMMENT' => CaseSubjectKind.comment,
      'USER' => CaseSubjectKind.user,
      _ => null,
    };
    return kind == null ? null : CaseSubject(kind: kind, id: id);
  }

  static String? _note(String note) {
    final trimmed = note.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

@Riverpod(keepAlive: true)
FeedbackRepository feedbackRepository(Ref ref) =>
    FeedbackRepository(ref.watch(feedbackApiProvider));
