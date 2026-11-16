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

/// 发送至当前账号绑定手机的验证码用途. 不同用途的验证码互不通用, 重发倒计时也相互独立.
enum AccountCodePurpose {
  /// 设置用户名, 设置或修改密码.
  password,

  /// 注销账号.
  deleteAccount,
}

/// 发送至账号绑定手机的验证码状态.
///
/// 在 [resendAt] 之前不可重发. [failure] 记录最近一次发送失败的原因.
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

  /// 完成人机验证后发送验证码. 若用户关闭验证则放弃发送, 也不启动倒计时.
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

/// 用户的隐私设置状态, 控制是否公开关注列表和粉丝列表.
///
/// 修改时先乐观更新本地状态, 若请求失败则恢复原值.
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

  /// 成功时返回 null, 失败时恢复原值并返回失败原因.
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

/// 个性化推荐开关状态. 关闭后推荐结果不再参考当前用户的个人记录.
@riverpod
class Personalized extends _$Personalized {
  @override
  Future<bool> build() => ref
      .watch(userRepositoryProvider)
      .personalized(cancelToken: ref.cancelToken());

  /// 成功时返回 null, 失败时恢复原值并返回失败原因.
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

/// 使用统计开关状态. 关闭后服务端会删除已收集的记录.
@riverpod
class UsageStatsSetting extends _$UsageStatsSetting {
  @override
  Future<UsageStats> build() =>
      ref.watch(telemetryApiProvider).consent(cancelToken: ref.cancelToken());

  /// 成功时返回 null 并采用服务端返回的开关状态, 失败时恢复原值并返回失败原因.
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

/// 已屏蔽用户列表的分页状态. [moreError] 记录加载下一页失败的原因.
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

  /// 解除对 [user] 的屏蔽, 成功后将其从列表中移除, 失败时抛出 [AppFailure].
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

/// 查询反馈关联的菜品或店铺名称. 若两者均未指定则返回 null.
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

/// 当前账号已登录的设备列表, 本机设备排在最前.
@riverpod
class DeviceSessions extends _$DeviceSessions {
  @override
  Future<List<DeviceSession>> build() => ref
      .watch(sessionsRepositoryProvider)
      .list(cancelToken: ref.cancelToken());

  /// 使指定设备下线并在成功后将其从列表中移除, 失败时抛出 [AppFailure].
  Future<void> revoke(DeviceSession device) async {
    try {
      await ref.read(sessionsRepositoryProvider).revoke(device.id);
    } on AppFailure catch (e) {
      // 服务端找不到该设备时说明其已处于下线状态 (例如已在其他端踢下线), 视为操作成功.
      if (e.code != BizCodes.opFailed) rethrow;
    }
    final devices = state.value;
    if (!ref.mounted || devices == null) return;
    state = AsyncData([
      for (final d in devices)
        if (d.id != device.id) d,
    ]);
  }

  /// 使本机以外的所有设备下线并刷新列表, 本机会话保持不变, 失败时抛出 [AppFailure].
  Future<void> revokeOthers() async {
    await ref.read(sessionsRepositoryProvider).revokeOthers();
    if (ref.mounted) ref.invalidateSelf();
  }
}

/// 各推送栏目的开关状态. 修改时先乐观更新本地值, 若保存失败则恢复原值.
@riverpod
class PushSettings extends _$PushSettings {
  @override
  Future<List<PushSetting>> build() => ref
      .watch(pushRepositoryProvider)
      .settings(cancelToken: ref.cancelToken());

  /// 成功时返回 null 并采用服务端返回的全部开关状态, 失败时恢复原值并返回失败原因.
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

/// 换绑手机号的流程状态.
///
/// 换绑分为验证当前号码, 验证新号码, 提交三步. 服务端会在给新号码发码时校验当前号码的验证码,
/// 通过后 10 分钟内重发新号码验证码或提交换绑均不再需要该验证码.
class const PhoneChangeState({
  /// 用户输入的当前号码验证码, 等待随新号码发码请求一并校验.
  final String? oldCode,

  /// 当前号码是否已通过服务端校验.
  final bool oldVerified = false,
}) {
  /// 是否已进入验证新号码阶段.
  bool get verifyingNew => oldCode != null || oldVerified;
}

/// 换绑和补绑手机号的业务控制器. 补绑仅用于尚未绑定手机的账号, 无需验证当前号码.
@riverpod
class PhoneChange extends _$PhoneChange {
  @override
  PhoneChangeState build() => const PhoneChangeState();

  UserRepository get _users => ref.read(userRepositoryProvider);

  /// 向当前绑定的手机号发送验证码. 返回 false 表示用户取消了人机验证, 失败时抛出 [AppFailure].
  Future<bool> sendOldCode(CaptchaPresenter present) =>
      ref.read(captchaGateProvider).run(present, _users.sendOldMobileCode);

  /// 记录用户输入的当前号码验证码并进入下一步, 该验证码将在给新号码发码时由服务端校验.
  void enterOldCode(String code) => state = PhoneChangeState(oldCode: code);

  /// 重置状态, 回到第一步重新验证当前号码.
  void restart() => state = const PhoneChangeState();

  /// 向新手机号发送验证码, 若当前号码尚未通过校验则一并提交其验证码.
  ///
  /// 若当前号码验证码错误 ([BizCodes.wrongCode]) 或校验已过期 ([BizCodes.paramMissing]), 则自动重置回第一步.
  /// 返回 false 表示用户取消了人机验证, 失败时抛出 [AppFailure].
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

  /// 提交新手机号与验证码完成换绑, 成功后刷新当前账号信息 (本机保持登录, 其他设备需重新登录).
  ///
  /// 若当前号码的校验已过期 ([BizCodes.stateNotAllowed]), 则重置回第一步. 失败时抛出 [AppFailure].
  Future<void> commit(String mobile, String code) async {
    try {
      await _users.commitMobileChange(mobile, code);
    } on AppFailure catch (e) {
      if (ref.mounted && e.code == BizCodes.stateNotAllowed) restart();
      rethrow;
    }
    await ref.read(sessionProvider.notifier).refreshUser();
  }

  /// 为未绑定手机的账号向 [mobile] 发送补绑验证码. 返回 false 表示用户取消了人机验证, 失败时抛出 [AppFailure].
  Future<bool> sendBindCode(CaptchaPresenter present, String mobile) => ref
      .read(captchaGateProvider)
      .run(present, (ticket) => _users.sendBindCode(mobile, ticket));

  /// 提交 [mobile] 与验证码完成补绑, 成功后刷新账号信息, 失败时抛出 [AppFailure].
  Future<void> bind(String mobile, String code) async {
    await _users.bindMobile(mobile, code);
    await ref.read(sessionProvider.notifier).refreshUser();
  }
}

/// 意见反馈提交控制器, 逐张上传未上传过的截图并提交反馈内容.
@riverpod
class FeedbackSender extends _$FeedbackSender {
  @override
  bool build() => false;

  /// 提交反馈文本与截图, 失败时抛出 [AppFailure].
  ///
  /// [uploaded] 以截图字节为键缓存已上传的存储 key, 重试时复用该 key 而不再重复上传.
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
