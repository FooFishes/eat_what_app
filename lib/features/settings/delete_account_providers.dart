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
  @override
  DeleteAccountState build() => const DeleteAccountState();

  void setDeleteComments({required bool value}) {
    if (state.submitting) return;
    state = DeleteAccountState(deleteComments: value);
  }

  /// 申请注销. 有手机号的账号带 [code], 没有手机号的带 [password].
  ///
  /// 成功返回 true, 之后由页面调用 [leave]; 失败时记录原因, 返回 false.
  Future<bool> submit({String? code, String? password}) async {
    final session = ref.read(sessionProvider);
    if (state.submitting || session is! SignedIn) return false;
    final userId = session.user?.id;
    if (userId == null) return false;
    final deleteComments = state.deleteComments;
    state = DeleteAccountState(
      deleteComments: deleteComments,
      submitting: true,
    );
    try {
      await ref
          .read(cancellationRepositoryProvider)
          .request(
            userId: userId,
            code: code,
            password: password,
            deleteComments: deleteComments,
          );
      return true;
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = DeleteAccountState(deleteComments: deleteComments, failure: e);
      }
      return false;
    }
  }

  /// 申请成功后退出登录. 服务端已让全部设备下线, 这里清除本机的登录态.
  Future<void> leave() => ref.read(sessionProvider.notifier).logout();
}
