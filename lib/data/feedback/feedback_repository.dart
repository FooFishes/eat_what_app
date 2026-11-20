import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/feedback/feedback_api.dart';
import 'package:eat/domain/models/feedback_case.dart';
import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/report.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feedback_repository.g.dart';

/// 负责提交意见反馈, 店铺 "信息有误" 纠错和内容举报, 并查询本人的提交记录.
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
    required FeedbackCategory category,
    List<String> screenshotKeys = const [],
    int? dishId,
    int? shopId,
  }) => _api.submitFeedback(
    FeedbackMessageDto(
      text: text.trim(),
      category: category.api,
      screenshotKeys: screenshotKeys.isEmpty ? null : screenshotKeys,
      context: switch ((dishId, shopId)) {
        (final id?, _) => FeedbackContextDto(type: 'FOOD', id: id),
        (null, final id?) => FeedbackContextDto(type: 'RESTAURANT', id: id),
        _ => null,
      },
    ),
  );

  /// 分页获取本人提交过的记录, 新提交的在前. 类型无法识别的记录将被过滤.
  Future<Paged<FeedbackCase>> mine({
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final result = await _api.mineList(page: page, cancelToken: cancelToken);
    return Paged(
      items: [for (final dto in result.items) ?_toCase(dto)],
      page: result.page,
      hasNext: result.hasNext,
      total: result.total,
    );
  }

  /// 获取本人提交过的一条记录及其处理结果. 若记录不存在或非本人提交, 服务端返回业务码 10001.
  Future<FeedbackCase> mineDetail(int id, {CancelToken? cancelToken}) async {
    final c = _toCase(await _api.mine(id, cancelToken: cancelToken));
    if (c == null) {
      throw const AppFailure(FailureKind.unknown, serverMessage: 'bad case');
    }
    return c;
  }

  static FeedbackCase? _toCase(FeedbackCaseDto dto) {
    final id = dto.id;
    final kind = switch (dto.kind) {
      'FEEDBACK' => CaseKind.feedback,
      'CATALOG_ERROR' => CaseKind.catalogError,
      'REPORT' => CaseKind.report,
      _ => null,
    };
    final createdAt = dateFromMillis(dto.createdAt);
    if (id == null || kind == null || createdAt == null) return null;
    return FeedbackCase(
      id: id,
      kind: kind,
      category: kind == CaseKind.feedback
          ? FeedbackCategory.fromApi(dto.category)
          : null,
      closed: dto.status == 'CLOSED',
      subject: _subject(dto.target),
      reasonCode: dto.reason,
      text: dto.text?.trim() ?? '',
      screenshots: [
        for (final shot in dto.screenshots ?? const <FeedbackScreenshotDto>[])
          ?imageUrl(shot.url),
      ],
      outcome: CaseOutcome.fromApi(dto.outcome),
      reply: dto.reply?.trim() ?? '',
      createdAt: createdAt,
      closedAt: dateFromMillis(dto.closedAt),
    );
  }

  static CaseSubject? _subject(FeedbackTargetDto? target) {
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
