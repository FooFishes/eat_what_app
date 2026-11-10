import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/data/cancellation/cancellation_repository.dart';
import 'package:eat/domain/models/cancellation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'restore_providers.g.dart';

/// 撤销注销时验证身份的方式.
enum RestoreMethod { code, password }

/// 撤销注销页的状态.
class const RestoreState({
  /// 登录接口给出的注销申请. 为 null 时没有要撤销的申请, 页面回到登录页.
  final PendingCancellation? pending,

  /// 登录时填的账号, 用密码验证时预先填好.
  final String account = '',
  final RestoreMethod method = RestoreMethod.code,

  /// 正在读取本机保存的恢复凭据.
  final bool loading = false,

  /// 本机没有这次申请的恢复凭据, 说明申请是在其他设备上提交的.
  final bool missing = false,

  /// 冷静期结束, 账号彻底删除的时间.
  final DateTime? deadline,
  final DateTime? resendAt,
  final bool sending = false,
  final bool submitting = false,

  /// 已撤销. 页面提示重新登录并返回.
  final bool restored = false,
  final AppFailure? failure,
}) {
  /// 复制并修改部分字段. [failure] 不沿用, 不传时清除.
  RestoreState copyWith({
    RestoreMethod? method,
    bool? loading,
    bool? missing,
    DateTime? deadline,
    DateTime? resendAt,
    bool? sending,
    bool? submitting,
    bool? restored,
    AppFailure? failure,
  }) => RestoreState(
    pending: pending,
    account: account,
    method: method ?? this.method,
    loading: loading ?? this.loading,
    missing: missing ?? this.missing,
    deadline: deadline ?? this.deadline,
    resendAt: resendAt ?? this.resendAt,
    sending: sending ?? this.sending,
    submitting: submitting ?? this.submitting,
    restored: restored ?? this.restored,
    failure: failure,
  );
}

/// 验证码的重发间隔.
const _resendInterval = Duration(seconds: 60);

/// 撤销注销: 登录页发现账号正在注销时开始, 撤销注销页验证身份后撤销.
///
/// 跨越登录页和撤销注销页, 因此一直保留. 恢复凭据只放在内存和安全存储里, 不进入地址.
@Riverpod(keepAlive: true)
class AccountRestore extends _$AccountRestore {
  CancellationTicket? _ticket;
  RestoreCode? _code;

  @override
  RestoreState build() => const RestoreState();

  CancellationRepository get _repository =>
      ref.read(cancellationRepositoryProvider);

  /// 登录时发现账号正在注销. 读取本机保存的恢复凭据, 再查询冷静期的截止时间.
  ///
  /// [account] 是登录时填的账号. [method] 是默认的验证方式, 与登录方式一致.
  Future<void> begin(
    PendingCancellation pending, {
    required String account,
    required RestoreMethod method,
  }) async {
    _ticket = null;
    _code = null;
    state = RestoreState(
      pending: pending,
      account: account,
      method: method,
      loading: true,
    );
    final ticket = await _repository.ticketFor(pending);
    if (!identical(state.pending, pending)) return;
    if (ticket == null) {
      state = state.copyWith(loading: false, missing: true);
      return;
    }
    _ticket = ticket;
    state = state.copyWith(loading: false);
    try {
      final status = await _repository.status(ticket);
      if (identical(state.pending, pending)) {
        state = state.copyWith(deadline: status.deadline);
      }
    } on AppFailure {
      // 截止时间只用于说明, 查不到时页面写 "冷静期结束后".
    }
  }

  void useMethod(RestoreMethod method) {
    if (state.submitting) return;
    state = state.copyWith(method: method);
  }

  /// 给绑定的手机发验证码. 成功后开始重发倒计时.
  Future<void> sendCode() async {
    final ticket = _ticket;
    if (ticket == null || state.sending) return;
    state = state.copyWith(sending: true);
    try {
      _code = await _repository.sendRestoreCode(ticket);
      state = state.copyWith(
        sending: false,
        resendAt: clock.now().add(_resendInterval),
      );
    } on AppFailure catch (e) {
      state = state.copyWith(sending: false, failure: e);
    }
  }

  /// 用验证码验证身份后撤销. 还没发过验证码时不提交.
  Future<void> submitCode(String code) async {
    final ticket = _ticket;
    final sent = _code;
    if (ticket == null || sent == null) return;
    await _submit(() => _repository.restoreWithCode(ticket, sent, code));
  }

  /// 用账号密码验证身份后撤销.
  Future<void> submitPassword(String account, String password) async {
    final ticket = _ticket;
    if (ticket == null) return;
    await _submit(
      () => _repository.restoreWithPassword(
        ticket,
        identifier: account,
        password: password,
      ),
    );
  }

  Future<void> _submit(Future<CancellationStatus> Function() restore) async {
    if (state.submitting) return;
    state = state.copyWith(submitting: true);
    try {
      await restore();
      state = state.copyWith(submitting: false, restored: true);
    } on AppFailure catch (e) {
      state = state.copyWith(submitting: false, failure: e);
    }
  }

  /// 离开撤销注销页时清除申请和内存中的凭据.
  void clear() {
    _ticket = null;
    _code = null;
    if (ref.mounted) state = const RestoreState();
  }
}
