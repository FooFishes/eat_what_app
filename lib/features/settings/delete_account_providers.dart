import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/data/cancellation/cancellation_repository.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_account_providers.g.dart';

/// 注销账号页面的表单状态, 记录是否同步删除评论与回复, 提交状态及最近一次失败信息.
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

  /// 提交注销申请; 已绑定手机号的账号需传入 [code], 未绑定手机号的账号需传入 [password].
  ///
  /// 提交成功返回 true 并交由页面调用 [leave] 退出登录; 失败时记录错误原因并返回 false.
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

  /// 提交申请成功后清除本机登录态; 服务端已将全部设备置为下线状态.
  Future<void> leave() => ref.read(sessionProvider.notifier).logout();
}
