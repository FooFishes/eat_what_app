import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/data/cancellation/cancellation_repository.dart';
import 'package:eat/data/feedback/feedback_repository.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/data/push/push_repository.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:eat/data/upload/uploader.dart';
import 'package:eat/data/sessions/sessions_repository.dart';
import 'package:eat/data/telemetry/telemetry_api.dart';
import 'package:eat/data/user/user_repository.dart';
import 'package:eat/domain/models/device_session.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/people.dart';
import 'package:eat/domain/models/push.dart';
import 'package:eat/domain/models/usage_stats.dart';
import 'package:eat/state/captcha_gate.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

/// 验证码的重发间隔.
const _resendInterval = Duration(seconds: 60);

/// 发给本账号绑定手机的验证码的用途. 不同用途的验证码不通用, 重发倒计时也分开.
enum AccountCodePurpose {
  /// 设置用户名, 设置或修改密码.
  password,

  /// 注销账号.
  deleteAccount,
}

/// 发给本账号绑定手机的验证码.
///
/// [resendAt] 之前不能重发. [failure] 是最近一次发送失败的原因.
class const AccountCodeState({
  final DateTime? resendAt,
  final bool sending = false,
  final AppFailure? failure,
});

@riverpod
class AccountCode extends _$AccountCode {
  @override
  AccountCodeState build(AccountCodePurpose purpose) =>
      const AccountCodeState();

  /// 完成人机验证后发送. 用户关闭验证时不发送, 不开始倒计时.
  Future<void> send(CaptchaPresenter present) async {
    if (state.sending) return;
    state = AccountCodeState(resendAt: state.resendAt, sending: true);
    final send = switch (purpose) {
      AccountCodePurpose.password =>
        ref.read(authRepositoryProvider).sendAccountCode,
      AccountCodePurpose.deleteAccount =>
        ref.read(cancellationRepositoryProvider).sendCode,
    };
    try {
      final sent = await ref.read(captchaGateProvider).run(present, send);
      if (!ref.mounted) return;
      state = AccountCodeState(
        resendAt: sent ? clock.now().add(_resendInterval) : state.resendAt,
      );
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = AccountCodeState(resendAt: state.resendAt, failure: e);
      }
    }
  }
}

/// 隐私设置: 是否公开关注列表和粉丝列表.
///
/// 修改时立即更新本地值, 请求失败时恢复原值.
@riverpod
class Privacy extends _$Privacy {
  @override
  Future<PrivacySettings> build() async {
    final me = ref.watch(
      sessionProvider.select((s) => s is SignedIn ? s.user?.id : null),
    );
    if (me == null) return const PrivacySettings();
    return ref
        .watch(userRepositoryProvider)
        .privacy(me, cancelToken: ref.cancelToken());
  }

  /// 成功返回 null, 失败时退回原值并返回失败原因.
  Future<AppFailure?> set(PrivacySettings next) async {
    final before = state.value;
    if (before == null) return null;
    state = AsyncData(next);
    try {
      await ref.read(userRepositoryProvider).setPrivacy(next);
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) state = AsyncData(before);
      return e;
    }
  }
}

/// 个性化推荐开关. 关闭后推荐不参考当前用户的个人记录.
@riverpod
class Personalized extends _$Personalized {
  @override
  Future<bool> build() => ref
      .watch(userRepositoryProvider)
      .personalized(cancelToken: ref.cancelToken());

  /// 成功返回 null, 失败时退回原值并返回失败原因.
  Future<AppFailure?> set({required bool personalized}) async {
    final before = state.value;
    if (before == null) return null;
    state = AsyncData(personalized);
    try {
      await ref
          .read(userRepositoryProvider)
          .setPersonalized(personalized: personalized);
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) state = AsyncData(before);
      return e;
    }
  }
}

/// 使用统计开关. 关闭时服务端删除已收集的记录.
@riverpod
class UsageStatsSetting extends _$UsageStatsSetting {
  @override
  Future<UsageStats> build() =>
      ref.watch(telemetryApiProvider).consent(cancelToken: ref.cancelToken());

  /// 成功返回 null, 并采用服务端返回的开关. 失败时退回原值并返回失败原因.
  Future<AppFailure?> set({required bool enabled}) async {
    final before = state.value;
    if (before == null) return null;
    state = AsyncData(
      UsageStats(enabled: enabled, retentionDays: before.retentionDays),
    );
    try {
      final saved = await ref.read(telemetryApiProvider).set(enabled: enabled);
      if (ref.mounted) state = AsyncData(saved);
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) state = AsyncData(before);
      return e;
    }
  }
}

/// 屏蔽的人. [moreError] 是加载下一页失败的原因.
class const BlockedPages({
  required final Paged<UserBrief> pages,
  final AppFailure? moreError,
});

@riverpod
class BlockedUsers extends _$BlockedUsers {
  @override
  Future<BlockedPages> build() async => BlockedPages(
    pages: await ref
        .watch(userRepositoryProvider)
        .blocked(cancelToken: ref.cancelToken()),
  );

  var _loading = false;

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.pages.hasNext || _loading) return;
    _loading = true;
    try {
      final next = await ref
          .read(userRepositoryProvider)
          .blocked(page: current.pages.page + 1);
      if (ref.mounted) {
        state = AsyncData(BlockedPages(pages: current.pages.append(next)));
      }
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = AsyncData(BlockedPages(pages: current.pages, moreError: e));
      }
    } finally {
      _loading = false;
    }
  }

  /// 解除屏蔽. 成功后从列表中移除. 失败时抛出 [AppFailure].
  Future<void> unblock(UserBrief user) async {
    await ref.read(userRepositoryProvider).setBlocked(user.id, blocked: false);
    final current = state.value;
    if (!ref.mounted || current == null) return;
    state = AsyncData(
      BlockedPages(
        pages: Paged(
          items: [
            for (final u in current.pages.items)
              if (u.id != user.id) u,
          ],
          page: current.pages.page,
          hasNext: current.pages.hasNext,
        ),
      ),
    );
  }
}

/// 反馈所关于的菜或店的名称. 两者都没有时为 null.
@riverpod
Future<String?> feedbackSubject(Ref ref, {int? dishId, int? shopId}) async {
  final token = ref.cancelToken();
  if (dishId != null) {
    return (await ref
            .watch(foodRepositoryProvider)
            .detail(dishId, cancelToken: token))
        .name;
  }
  if (shopId != null) {
    return (await ref
            .watch(placeRepositoryProvider)
            .shop(shopId, cancelToken: token))
        .name;
  }
  return null;
}

/// 已登录的设备. 本机排在最前.
@riverpod
class DeviceSessions extends _$DeviceSessions {
  @override
  Future<List<DeviceSession>> build() => ref
      .watch(sessionsRepositoryProvider)
      .list(cancelToken: ref.cancelToken());

  /// 使一台设备下线. 成功后从列表中移除. 失败时抛出 [AppFailure].
  Future<void> revoke(DeviceSession device) async {
    try {
      await ref.read(sessionsRepositoryProvider).revoke(device.id);
    } on AppFailure catch (e) {
      // 服务端找不到该设备, 说明它已经下线, 例如在其他设备上被下线. 结果与下线成功相同.
      if (e.code != BizCodes.opFailed) rethrow;
    }
    final devices = state.value;
    if (!ref.mounted || devices == null) return;
    state = AsyncData([
      for (final d in devices)
        if (d.id != device.id) d,
    ]);
  }

  /// 使本机以外的所有设备下线, 成功后重新读取列表. 本机的会话不变. 失败时抛出 [AppFailure].
  Future<void> revokeOthers() async {
    await ref.read(sessionsRepositoryProvider).revokeOthers();
    if (ref.mounted) ref.invalidateSelf();
  }
}

/// 各推送栏目的开关. 修改时立即更新本地值, 保存失败时恢复原值.
@riverpod
class PushSettings extends _$PushSettings {
  @override
  Future<List<PushSetting>> build() => ref
      .watch(pushRepositoryProvider)
      .settings(cancelToken: ref.cancelToken());

  /// 成功返回 null, 并采用服务端返回的全部开关. 失败时退回原值并返回失败原因.
  Future<AppFailure?> set(
    PushCategory category, {
    required bool enabled,
  }) async {
    final before = state.value;
    if (before == null) return null;
    state = AsyncData([
      for (final s in before)
        s.category == category
            ? PushSetting(category: s.category, enabled: enabled)
            : s,
    ]);
    try {
      final saved = await ref
          .read(pushRepositoryProvider)
          .set(category, enabled: enabled);
      if (ref.mounted) state = AsyncData(saved);
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) state = AsyncData(before);
      return e;
    }
  }
}

/// 换绑手机的进度.
///
/// 换绑分三步: 验证当前号码, 验证新号码, 提交. 服务端在给新号码发码时校验当前号码的验证码,
/// 通过后 10 分钟内给新号码发码和提交都不再需要它.
class const PhoneChangeState({
  /// 用户填的当前号码验证码, 等待服务端校验.
  final String? oldCode,

  /// 当前号码已通过服务端校验.
  final bool oldVerified = false,
}) {
  /// 已离开第一步, 正在验证新号码.
  bool get verifyingNew => oldCode != null || oldVerified;
}

/// 换绑和补绑手机. 补绑只用于还没有手机号的账号, 不需要验证当前号码.
@riverpod
class PhoneChange extends _$PhoneChange {
  @override
  PhoneChangeState build() => const PhoneChangeState();

  UserRepository get _users => ref.read(userRepositoryProvider);

  /// 第一步: 给当前绑定的号码发验证码. 返回 false 表示用户关闭了人机验证. 失败时抛出 [AppFailure].
  Future<bool> sendOldCode(CaptchaPresenter present) =>
      ref.read(captchaGateProvider).run(present, _users.sendOldMobileCode);

  /// 填好当前号码的验证码, 进入第二步. 验证码由服务端在给新号码发码时校验.
  void enterOldCode(String code) => state = PhoneChangeState(oldCode: code);

  /// 回到第一步, 重新验证当前号码.
  void restart() => state = const PhoneChangeState();

  /// 第二步: 给新号码发验证码. 当前号码还没通过校验时一并提交它的验证码.
  ///
  /// 当前号码的验证码错误 ([BizCodes.wrongCode]) 或校验已过期 ([BizCodes.paramMissing]) 时回到第一步.
  /// 返回 false 表示用户关闭了人机验证. 失败时抛出 [AppFailure].
  Future<bool> sendNewCode(CaptchaPresenter present, String mobile) async {
    final oldCode = state.oldVerified ? null : state.oldCode;
    try {
      final sent = await ref
          .read(captchaGateProvider)
          .run(
            present,
            (ticket) => _users.sendNewMobileCode(
              mobile,
              oldCode: oldCode,
              ticket: ticket,
            ),
          );
      if (sent && ref.mounted) {
        state = const PhoneChangeState(oldVerified: true);
      }
      return sent;
    } on AppFailure catch (e) {
      if (ref.mounted &&
          (e.code == BizCodes.wrongCode || e.code == BizCodes.paramMissing)) {
        restart();
      }
      rethrow;
    }
  }

  /// 第三步: 提交新号码和它的验证码, 成功后刷新账号信息. 其他设备要重新登录, 本机不受影响.
  ///
  /// 当前号码的校验已过期 ([BizCodes.stateNotAllowed]) 时回到第一步. 失败时抛出 [AppFailure].
  Future<void> commit(String mobile, String code) async {
    try {
      await _users.commitMobileChange(mobile, code);
    } on AppFailure catch (e) {
      if (ref.mounted && e.code == BizCodes.stateNotAllowed) restart();
      rethrow;
    }
    await ref.read(sessionProvider.notifier).refreshUser();
  }

  /// 补绑: 给 [mobile] 发验证码. 返回 false 表示用户关闭了人机验证. 失败时抛出 [AppFailure].
  Future<bool> sendBindCode(CaptchaPresenter present, String mobile) => ref
      .read(captchaGateProvider)
      .run(present, (ticket) => _users.sendBindCode(mobile, ticket));

  /// 补绑: 提交 [mobile] 和它的验证码, 成功后刷新账号信息. 失败时抛出 [AppFailure].
  Future<void> bind(String mobile, String code) async {
    await _users.bindMobile(mobile, code);
    await ref.read(sessionProvider.notifier).refreshUser();
  }
}

/// 提交意见反馈. 截图逐张上传, 已上传的截图不重复上传.
@riverpod
class FeedbackSender extends _$FeedbackSender {
  @override
  bool build() => false;

  /// [uploaded] 记录每张截图上传后的 key, 以截图的字节为键. 重试时复用这些 key, 不重复上传.
  ///
  /// 失败时抛出 [AppFailure].
  Future<void> send({
    required String text,
    required List<Uint8List> screenshots,
    required Map<Uint8List, String> uploaded,
    int? dishId,
    int? shopId,
  }) async {
    if (state) return;
    state = true;
    try {
      final uploader = ref.read(uploaderProvider);
      final keys = <String>[];
      for (final shot in screenshots) {
        keys.add(
          uploaded[shot] ??= await uploader.upload(
            shot,
            biz: UploadBiz.feedback,
          ),
        );
      }
      await ref
          .read(feedbackRepositoryProvider)
          .sendFeedback(
            text: text,
            screenshotKeys: keys,
            dishId: dishId,
            shopId: shopId,
          );
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
