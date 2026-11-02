import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/data/feedback/feedback_repository.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/data/push/push_repository.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:eat/data/upload/uploader.dart';
import 'package:eat/data/sessions/sessions_repository.dart';
import 'package:eat/data/user/user_repository.dart';
import 'package:eat/domain/models/device_session.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/people.dart';
import 'package:eat/domain/models/push.dart';
import 'package:eat/state/captcha_gate.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

/// 验证码的重发间隔.
const _resendInterval = Duration(seconds: 60);

/// 发给本账号绑定手机的验证码: 设置用户名和设置或修改密码共用.
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
  AccountCodeState build() => const AccountCodeState();

  /// 完成人机验证后发送. 用户关闭验证时不发送, 不开始倒计时.
  Future<void> send(CaptchaPresenter present) async {
    if (state.sending) return;
    state = AccountCodeState(resendAt: state.resendAt, sending: true);
    final auth = ref.read(authRepositoryProvider);
    try {
      final sent = await ref
          .read(captchaGateProvider)
          .run(present, auth.sendAccountCode);
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
    await ref.read(sessionsRepositoryProvider).revoke(device.id);
    final devices = state.value;
    if (!ref.mounted || devices == null) return;
    state = AsyncData([
      for (final d in devices)
        if (d.id != device.id) d,
    ]);
  }

  /// 使其他所有设备下线. 本机的会话随之换发.
  ///
  /// 返回 false 表示未能获取本机的新会话, 已回到登录页. 失败时抛出 [AppFailure].
  Future<bool> revokeOthers() async {
    final session = ref.read(sessionProvider.notifier);
    final rotation = await ref.read(sessionsRepositoryProvider).revokeOthers();
    final kept = await session.adoptRotation(rotation);
    if (kept && ref.mounted) ref.invalidateSelf();
    return kept;
  }
}

/// 各推送栏目的开关. 修改时立即更新本地值, 保存失败时恢复原值.
@riverpod
class PushSettings extends _$PushSettings {
  @override
  Future<List<PushSetting>> build() => ref
      .watch(pushRepositoryProvider)
      .settings(cancelToken: ref.cancelToken());

  /// 成功返回 null, 失败时退回原值并返回失败原因.
  ///
  /// 成功后重新读取, 以获取下一次修改开关时需回传的版本信息.
  Future<AppFailure?> set(
    PushCategory category, {
    required bool enabled,
  }) async {
    final before = state.value;
    final current = before?.where((s) => s.category == category).firstOrNull;
    if (before == null || current == null) return null;
    state = AsyncData([
      for (final s in before)
        s.category == category
            ? PushSetting(
                category: s.category,
                enabled: enabled,
                revision: s.revision,
                closeFrontier: s.closeFrontier,
              )
            : s,
    ]);
    try {
      await ref.read(pushRepositoryProvider).set(current, enabled: enabled);
      if (ref.mounted) ref.invalidateSelf();
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) state = AsyncData(before);
      return e;
    }
  }
}

/// 换绑手机的进度. 给新号码发送验证码时开始一次换绑, 新号码变化时重新开始.
@riverpod
class PhoneChange extends _$PhoneChange {
  @override
  MobileChange? build() => null;

  /// 给新号码发送验证码. 返回 false 表示用户关闭了人机验证. 失败时抛出 [AppFailure].
  Future<bool> sendNewCode(CaptchaPresenter present, String mobile) async {
    final users = ref.read(userRepositoryProvider);
    var change = state;
    if (change == null || change.mobile != mobile) {
      change = await users.startMobileChange(mobile);
      if (!ref.mounted) return false;
      state = change;
    }
    final started = change;
    return ref
        .read(captchaGateProvider)
        .run(
          present,
          (ticket) => users.sendMobileChangeCode(
            started,
            oldPhone: false,
            ticket: ticket,
          ),
        );
  }

  /// 给旧号码发送验证码. 调用前须已给新号码发送验证码. 失败时抛出 [AppFailure].
  Future<bool> sendOldCode(CaptchaPresenter present) async {
    final change = state;
    if (change == null) return false;
    final users = ref.read(userRepositoryProvider);
    return ref
        .read(captchaGateProvider)
        .run(
          present,
          (ticket) => users.sendMobileChangeCode(
            change,
            oldPhone: true,
            ticket: ticket,
          ),
        );
  }

  /// 提交换绑, 采用换发的会话. 返回 false 表示未能获取本机的新会话, 已回到登录页.
  ///
  /// 失败时抛出 [AppFailure].
  Future<bool> commit({
    required String newCode,
    String? oldCode,
    String? password,
  }) async {
    final change = state;
    if (change == null) return false;
    final session = ref.read(sessionProvider.notifier);
    final rotation = await ref
        .read(userRepositoryProvider)
        .commitMobileChange(
          change,
          newCode: newCode,
          oldCode: oldCode,
          password: password,
        );
    return session.adoptRotation(rotation);
  }
}

/// 提交意见反馈. 截图逐张上传, 已上传的截图不重复上传.
@riverpod
class FeedbackSender extends _$FeedbackSender {
  @override
  bool build() => false;

  /// [uploaded] 记录每张截图上传后的 key, 以截图的字节为键. 重试时复用这些 key, 提交内容不变, 因此幂等键仍然有效.
  ///
  /// 失败时抛出 [AppFailure].
  Future<void> send({
    required String text,
    required List<Uint8List> screenshots,
    required Map<Uint8List, String> uploaded,
    int? dishId,
    int? shopId,
    required String idempotencyKey,
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
            idempotencyKey: idempotencyKey,
          );
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
