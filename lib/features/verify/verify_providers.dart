import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/platform/browser.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/state/captcha_gate.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'verify_providers.g.dart';

/// 认证页的状态.
///
/// - [emailSentTo]: 认证邮件的收件地址.
/// - [resendAt]: 允许重发的时间.
/// - [ssoStarted]: 是否已跳转过统一认证页.
/// - [notice]: 最近一次提示.
/// - [status]: 最近一次从 `/auth/verify` 查到的认证状态, 还没查到时为 null, 页面先按账号信息显示.
class const VerifyState({
  final String? emailSentTo,
  final DateTime? resendAt,
  final bool busy = false,
  final bool ssoStarted = false,
  final String? notice,
  final VerifyStatus? status,
});

/// 认证邮件的重发间隔, 与短信验证码一致.
const emailResendInterval = Duration(seconds: 60);

/// 统一认证回跳结果, 解析自后端重定向到回跳链接时附带的 `result`, `code` 与 `ticket` 参数.
///
/// 成功回跳时认证尚未生效, 仍须由发起认证的原账号提交 [ticket] 完成确认.
/// 由于回跳链接可被任意构造, [success] 与 [code] 仅用于界面提示.
class const SsoResult({
  required final bool success,
  final int? code,

  /// 一次性的认证票据, 5 分钟内有效. 只在成功时有值.
  final String? ticket,
}) {
  /// 从回跳链接的查询参数中解析认证结果, 当 `result` 既非 success 也非 failure 时返回 null.
  static SsoResult? fromCallback(Map<String, String> query) =>
      switch (query['result']) {
        'success' => SsoResult(success: true, ticket: query['ticket']),
        'failure' => SsoResult(
          success: false,
          code: int.tryParse(query['code'] ?? ''),
        ),
        _ => null,
      };
}

/// 统一认证失败的业务码集合, 回跳链接的 `code` 参数与提交票据接口的响应均可能返回这些值.
abstract final class SsoCodes {
  /// 认证链接无效, 过期或已用过.
  static const linkExpired = 30012;

  /// 学号已认证过本站的其他账号.
  static const studentIdTaken = 30013;

  /// 学校返回的认证凭证无效或无法解析.
  static const badSchoolResponse = 50003;
}

/// 根据统一认证失败码返回用户提示文案, 不向用户暴露错误码, 未收录的业务码回落为通用提示.
String ssoFailureMessage(int? code) => switch (code) {
  SsoCodes.linkExpired => '认证链接已失效，请重新发起认证',
  SsoCodes.studentIdTaken => '该学号已认证其他账号',
  SsoCodes.badSchoolResponse => '学校返回的认证结果无效，请重新认证',
  BizCodes.opFailed => '这次认证不是当前账号发起的，请重新认证',
  BizCodes.userDisabled => '账号已被封禁',
  final int code when code ~/ 10000 == 9 => '暂时无法认证，请稍后再试',
  _ => '认证未完成，请重新认证',
};

@riverpod
class Verify extends _$Verify {
  @override
  VerifyState build() => const VerifyState();

  /// 发起山大统一认证并跳转至学校认证页, 结束后根据回跳结果更新界面提示. 由于认证链接为一次性使用, 每次发起均会重新向服务端获取.
  ///
  /// 跳转后 `ssoStarted` 即置为 true, 因此认证未完成前返回前台触发的自动刷新也会提示用户.
  Future<void> startSso() async {
    if (state.busy) return;
    final started = state.ssoStarted;
    state = _copy(busy: true, notice: null);
    final Uri url;
    try {
      url = await ref.read(authRepositoryProvider).ssoUrl();
    } on AppFailure catch (e) {
      if (!ref.mounted) return;
      state = _copy(busy: false, notice: _noticeOf(e));
      return;
    }
    if (!ref.mounted) return;
    state = _copy(busy: true, ssoStarted: true, notice: null);
    final outcome = await ref.read(browserProvider).openSso(url);
    if (!ref.mounted) return;
    switch (outcome) {
      case SsoReturned(:final link):
        state = _copy(busy: false, notice: state.notice);
        final result = SsoResult.fromCallback(link.queryParameters);
        await (result == null ? refresh() : showSsoResult(result));
      case SsoClosed():
        state = _copy(busy: false, notice: state.notice);
        await refresh();
      case SsoFailed():
        state = _copy(busy: false, ssoStarted: started, notice: '无法打开学校页面，请重试');
    }
  }

  /// 通过人机验证后发送认证邮件. 邮箱已被其他账号认证时服务端返回 [BizCodes.opFailed].
  Future<void> sendEmail(CaptchaPresenter present, String email) async {
    if (state.busy) return;
    state = _copy(busy: true, notice: null);
    final auth = ref.read(authRepositoryProvider);
    try {
      final sent = await ref
          .read(captchaGateProvider)
          .run(present, (ticket) => auth.sendVerifyEmail(email, ticket));
      if (!ref.mounted) return;
      state = sent
          ? VerifyState(
              emailSentTo: email,
              resendAt: clock.now().add(emailResendInterval),
              ssoStarted: state.ssoStarted,
              status: state.status,
            )
          : _copy(busy: false, notice: null);
    } on AppFailure catch (e) {
      if (!ref.mounted) return;
      state = _copy(
        busy: false,
        notice: e.code == BizCodes.opFailed ? '该邮箱已认证其他账号' : _noticeOf(e),
      );
    }
  }

  /// 清除已发送状态以返回邮箱输入界面.
  void editEmail() =>
      state = VerifyState(ssoStarted: state.ssoStarted, status: state.status);

  /// 重新请求账号认证状态, 在打开页面, 回到前台或点击 "已完成, 刷新状态" 时调用.
  ///
  /// 若已发起过统一认证或由用户主动刷新而账号仍未认证, 则提示重新认证. 自动刷新不会覆盖已有提示, 以保留回跳链接携带的具体失败原因.
  Future<void> refresh({bool userAsked = false}) async {
    await _reload();
    if (!ref.mounted) return;
    if (_verified) {
      state = _copy(notice: null);
    } else if (userAsked || (state.ssoStarted && state.notice == null)) {
      state = _copy(notice: '认证未完成，请重新认证');
    }
  }

  /// 处理统一认证回跳结果: 成功时提交票据完成认证并刷新账号状态.
  ///
  /// 票据仅允许发起认证的原账号提交, 若期间切换过账号, 服务端会拒绝提交以避免错绑到新账号.
  /// 若票据提交成功但刷新后账号仍显示未认证, 可能是用户信息刷新失败, 此时提示稍后刷新而非要求重新认证.
  Future<void> showSsoResult(SsoResult result) async {
    String? failure;
    if (result case SsoResult(success: true, :final ticket?)) {
      try {
        await ref.read(authRepositoryProvider).confirmSso(ticket);
      } on AppFailure catch (e) {
        failure = switch (e.kind) {
          FailureKind.cancelled => null,
          FailureKind.business || FailureKind.unknown => ssoFailureMessage(
            e.code is int ? e.code! as int : null,
          ),
          _ => e.message,
        };
      }
      if (!ref.mounted) return;
    }
    await _reload();
    if (!ref.mounted) return;
    if (_verified) {
      state = _copy(notice: null);
    } else if (failure != null) {
      state = _copy(notice: failure);
    } else if (result.success && result.ticket != null) {
      state = _copy(ssoStarted: true, notice: '认证结果尚未生效，请稍后刷新状态');
    } else {
      state = _copy(notice: ssoFailureMessage(result.code));
    }
  }

  /// 同时刷新账号信息和 `/auth/verify` 的认证状态. 认证状态查询失败时保留上一次的结果.
  Future<void> _reload() async {
    final user = ref.read(sessionProvider.notifier).refreshUser();
    VerifyStatus? status;
    try {
      status = await ref.read(authRepositoryProvider).verifyStatus();
    } on AppFailure {
      // 查询失败 (如网络不可达) 时沿用上一次的结果, 等下次刷新.
    }
    await user;
    if (ref.mounted && status != null) {
      state = _copy(notice: state.notice, status: status);
    }
  }

  /// 认证状态以 `/auth/verify` 为准, 还没查到时看账号信息.
  bool get _verified =>
      state.status?.verified ??
      switch (ref.read(sessionProvider)) {
        SignedIn(:final user) => user?.verified ?? false,
        SignedOut() || Guest() => false,
      };

  VerifyState _copy({
    bool? busy,
    bool? ssoStarted,
    required String? notice,
    VerifyStatus? status,
  }) => VerifyState(
    emailSentTo: state.emailSentTo,
    resendAt: state.resendAt,
    busy: busy ?? state.busy,
    ssoStarted: ssoStarted ?? state.ssoStarted,
    notice: notice,
    status: status ?? state.status,
  );

  static String? _noticeOf(AppFailure failure) =>
      failure.kind == FailureKind.cancelled ? null : failure.message;
}

/// 邮箱认证落地页的提交状态, null 表示尚未开始提交.
@riverpod
class EmailVerification extends _$EmailVerification {
  @override
  AsyncValue<void>? build() => null;

  /// 提交邮件链接中的 [token] 完成邮箱认证, 成功后刷新账号状态, 失败详情保存在 [AsyncError.error] 中.
  ///
  /// 由于 [token] 仅能使用一次, 状态非空时忽略后续调用, 避免页面重建引发重复提交.
  Future<void> submit(String token) async {
    if (state != null) return;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).verifyEmail(token);
      await ref.read(sessionProvider.notifier).refreshUser();
      if (ref.mounted) state = const AsyncData(null);
    } on AppFailure catch (e, stack) {
      if (ref.mounted) state = AsyncError(e, stack);
    }
  }
}
