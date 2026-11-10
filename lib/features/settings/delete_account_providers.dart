import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/data/cancellation/cancellation_repository.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_account_providers.g.dart';

/// 注销页的状态: 是否同时删除评论和回复, 提交状态, 最近一次失败.
class const DeleteAccountState({
  final bool deleteComments = false,
  final bool submitting = false,
  final AppFailure? failure,
});

@riverpod
class DeleteAccount extends _$DeleteAccount {
  /// 上次提交的申请. 失败重试时沿用, 服务端据此识别同一次申请.
  CancellationDraft? _draft;

  @override
  DeleteAccountState build() => const DeleteAccountState();

  void setDeleteComments({required bool value}) {
    if (state.submitting) return;
    state = DeleteAccountState(deleteComments: value);
  }

  /// 申请注销. 成功返回 true, 之后由页面调用 [leave]; 失败时记录原因, 返回 false.
  ///
  /// 同一次申请不能改变是否删除评论, 因此改了选择后换一份新的申请.
  Future<bool> submit() async {
    if (state.submitting) return false;
    final deleteComments = state.deleteComments;
    state = DeleteAccountState(
      deleteComments: deleteComments,
      submitting: true,
    );
    final repository = ref.read(cancellationRepositoryProvider);
    final draft = switch (_draft) {
      final draft? when draft.deleteComments == deleteComments => draft,
      _ => repository.draft(deleteComments: deleteComments),
    };
    _draft = draft;
    try {
      await repository.request(draft);
      return true;
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = DeleteAccountState(deleteComments: deleteComments, failure: e);
      }
      return false;
    }
  }

  /// 申请成功后退出登录. 冷静期内账号不能用, 本机的会话也随之失效.
  Future<void> leave() => ref.read(sessionProvider.notifier).logout();
}
