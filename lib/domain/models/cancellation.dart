/// 注销申请所处的阶段, 对应接口的 `phase`.
enum CancellationPhase {
  /// 没有进行中的注销, 或注销已撤销.
  active,

  /// 已申请, 正在冷静期. 可以撤销.
  preparing,

  /// 冷静期内等待各站确认. 可以撤销.
  pending,

  /// 已彻底删除.
  finalized,

  unknown;

  static CancellationPhase parse(String? value) => switch (value) {
    'ACTIVE' => active,
    'PREPARING' => preparing,
    'PENDING' => pending,
    'FINALIZED' => finalized,
    _ => unknown,
  };

  /// 冷静期内, 可以撤销.
  bool get revocable => this == preparing || this == pending;
}

/// 一次注销申请的状态.
class const CancellationStatus({
  required final CancellationPhase phase,

  /// 冷静期结束, 账号彻底删除的时间. 接口未给出时为 null.
  final DateTime? deadline,
  final bool complete = false,
});

/// 登录时发现账号正在注销: 登录接口给出的注销申请.
///
/// 撤销还需要申请时保存在本机的恢复凭据, 见 `CancellationRepository`.
class const PendingCancellation({
  required final String subjectId,
  required final String requestId,
  required final CancellationPhase phase,
});
