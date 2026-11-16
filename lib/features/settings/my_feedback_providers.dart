import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/feedback/feedback_repository.dart';
import 'package:eat/domain/models/feedback_case.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_feedback_providers.g.dart';

/// 我的反馈列表的分页状态. [moreError] 记录加载下一页失败的原因.
class const FeedbackCasePages({
  required final Paged<FeedbackCase> pages,
  final AppFailure? moreError,
});

/// 本人提交过的意见反馈, 信息有误和举报, 新提交的在前.
@riverpod
class MyFeedbackCases extends _$MyFeedbackCases {
  @override
  Future<FeedbackCasePages> build() async => FeedbackCasePages(
    pages: await ref
        .watch(feedbackRepositoryProvider)
        .mine(cancelToken: ref.cancelToken()),
  );

  var _loading = false;

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.pages.hasNext || _loading) return;
    _loading = true;
    try {
      final next = await ref
          .read(feedbackRepositoryProvider)
          .mine(page: current.pages.page + 1);
      if (ref.mounted) {
        state = AsyncData(FeedbackCasePages(pages: current.pages.append(next)));
      }
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = AsyncData(
          FeedbackCasePages(pages: current.pages, moreError: e),
        );
      }
    } finally {
      _loading = false;
    }
  }
}

/// 本人提交过的一条记录及其处理结果.
@riverpod
Future<FeedbackCase> feedbackCase(Ref ref, int id) => ref
    .watch(feedbackRepositoryProvider)
    .mineDetail(id, cancelToken: ref.cancelToken());
