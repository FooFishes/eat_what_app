// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AccountCode)
final accountCodeProvider = AccountCodeProvider._();

final class AccountCodeProvider
    extends $NotifierProvider<AccountCode, AccountCodeState> {
  AccountCodeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountCodeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountCodeHash();

  @$internal
  @override
  AccountCode create() => AccountCode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountCodeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountCodeState>(value),
    );
  }
}

String _$accountCodeHash() => r'c764e2677d54f502f44d88b14fc53141b8e8c46f';

abstract class _$AccountCode extends $Notifier<AccountCodeState> {
  AccountCodeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AccountCodeState, AccountCodeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AccountCodeState, AccountCodeState>,
              AccountCodeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 隐私设置: 是否公开关注列表和粉丝列表.
///
/// 修改时立即更新本地值, 请求失败时恢复原值.

@ProviderFor(Privacy)
final privacyProvider = PrivacyProvider._();

/// 隐私设置: 是否公开关注列表和粉丝列表.
///
/// 修改时立即更新本地值, 请求失败时恢复原值.
final class PrivacyProvider
    extends $AsyncNotifierProvider<Privacy, PrivacySettings> {
  /// 隐私设置: 是否公开关注列表和粉丝列表.
  ///
  /// 修改时立即更新本地值, 请求失败时恢复原值.
  PrivacyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privacyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privacyHash();

  @$internal
  @override
  Privacy create() => Privacy();
}

String _$privacyHash() => r'9a2cee4f15e05327e3678d1fd594951c8547d4d8';

/// 隐私设置: 是否公开关注列表和粉丝列表.
///
/// 修改时立即更新本地值, 请求失败时恢复原值.

abstract class _$Privacy extends $AsyncNotifier<PrivacySettings> {
  FutureOr<PrivacySettings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PrivacySettings>, PrivacySettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PrivacySettings>, PrivacySettings>,
              AsyncValue<PrivacySettings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 个性化推荐开关. 关闭后推荐不参考当前用户的个人记录.

@ProviderFor(Personalized)
final personalizedProvider = PersonalizedProvider._();

/// 个性化推荐开关. 关闭后推荐不参考当前用户的个人记录.
final class PersonalizedProvider
    extends $AsyncNotifierProvider<Personalized, bool> {
  /// 个性化推荐开关. 关闭后推荐不参考当前用户的个人记录.
  PersonalizedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personalizedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personalizedHash();

  @$internal
  @override
  Personalized create() => Personalized();
}

String _$personalizedHash() => r'c9ef78eb2a326f0d92ddca12a5086469ba9648bc';

/// 个性化推荐开关. 关闭后推荐不参考当前用户的个人记录.

abstract class _$Personalized extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(BlockedUsers)
final blockedUsersProvider = BlockedUsersProvider._();

final class BlockedUsersProvider
    extends $AsyncNotifierProvider<BlockedUsers, BlockedPages> {
  BlockedUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blockedUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blockedUsersHash();

  @$internal
  @override
  BlockedUsers create() => BlockedUsers();
}

String _$blockedUsersHash() => r'2882f6ad771a33b3d0213fa9097c5c1e47afa3a7';

abstract class _$BlockedUsers extends $AsyncNotifier<BlockedPages> {
  FutureOr<BlockedPages> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BlockedPages>, BlockedPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BlockedPages>, BlockedPages>,
              AsyncValue<BlockedPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 反馈所关于的菜或店的名称. 两者都没有时为 null.

@ProviderFor(feedbackSubject)
final feedbackSubjectProvider = FeedbackSubjectFamily._();

/// 反馈所关于的菜或店的名称. 两者都没有时为 null.

final class FeedbackSubjectProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// 反馈所关于的菜或店的名称. 两者都没有时为 null.
  FeedbackSubjectProvider._({
    required FeedbackSubjectFamily super.from,
    required ({int? dishId, int? shopId}) super.argument,
  }) : super(
         retry: null,
         name: r'feedbackSubjectProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$feedbackSubjectHash();

  @override
  String toString() {
    return r'feedbackSubjectProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as ({int? dishId, int? shopId});
    return feedbackSubject(
      ref,
      dishId: argument.dishId,
      shopId: argument.shopId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FeedbackSubjectProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedbackSubjectHash() => r'd9ec8b4646baba16661e61fcb6033ace7bbd3e2b';

/// 反馈所关于的菜或店的名称. 两者都没有时为 null.

final class FeedbackSubjectFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<String?>,
          ({int? dishId, int? shopId})
        > {
  FeedbackSubjectFamily._()
    : super(
        retry: null,
        name: r'feedbackSubjectProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 反馈所关于的菜或店的名称. 两者都没有时为 null.

  FeedbackSubjectProvider call({int? dishId, int? shopId}) =>
      FeedbackSubjectProvider._(
        argument: (dishId: dishId, shopId: shopId),
        from: this,
      );

  @override
  String toString() => r'feedbackSubjectProvider';
}

/// 已登录的设备. 本机排在最前.

@ProviderFor(DeviceSessions)
final deviceSessionsProvider = DeviceSessionsProvider._();

/// 已登录的设备. 本机排在最前.
final class DeviceSessionsProvider
    extends $AsyncNotifierProvider<DeviceSessions, List<DeviceSession>> {
  /// 已登录的设备. 本机排在最前.
  DeviceSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceSessionsHash();

  @$internal
  @override
  DeviceSessions create() => DeviceSessions();
}

String _$deviceSessionsHash() => r'3315e821dafaa075396c5d27844737c0e3506235';

/// 已登录的设备. 本机排在最前.

abstract class _$DeviceSessions extends $AsyncNotifier<List<DeviceSession>> {
  FutureOr<List<DeviceSession>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<DeviceSession>>, List<DeviceSession>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<DeviceSession>>, List<DeviceSession>>,
              AsyncValue<List<DeviceSession>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 各推送栏目的开关. 修改时立即更新本地值, 保存失败时恢复原值.

@ProviderFor(PushSettings)
final pushSettingsProvider = PushSettingsProvider._();

/// 各推送栏目的开关. 修改时立即更新本地值, 保存失败时恢复原值.
final class PushSettingsProvider
    extends $AsyncNotifierProvider<PushSettings, List<PushSetting>> {
  /// 各推送栏目的开关. 修改时立即更新本地值, 保存失败时恢复原值.
  PushSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushSettingsHash();

  @$internal
  @override
  PushSettings create() => PushSettings();
}

String _$pushSettingsHash() => r'dfab0da9260c1f82ff8af0d1ad7a139675f9d136';

/// 各推送栏目的开关. 修改时立即更新本地值, 保存失败时恢复原值.

abstract class _$PushSettings extends $AsyncNotifier<List<PushSetting>> {
  FutureOr<List<PushSetting>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PushSetting>>, List<PushSetting>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PushSetting>>, List<PushSetting>>,
              AsyncValue<List<PushSetting>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 换绑手机的进度. 给新号码发送验证码时开始一次换绑, 新号码变化时重新开始.

@ProviderFor(PhoneChange)
final phoneChangeProvider = PhoneChangeProvider._();

/// 换绑手机的进度. 给新号码发送验证码时开始一次换绑, 新号码变化时重新开始.
final class PhoneChangeProvider
    extends $NotifierProvider<PhoneChange, MobileChange?> {
  /// 换绑手机的进度. 给新号码发送验证码时开始一次换绑, 新号码变化时重新开始.
  PhoneChangeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phoneChangeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phoneChangeHash();

  @$internal
  @override
  PhoneChange create() => PhoneChange();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MobileChange? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MobileChange?>(value),
    );
  }
}

String _$phoneChangeHash() => r'd9136d801ca617484904ef4e11fc2754e5c6de72';

/// 换绑手机的进度. 给新号码发送验证码时开始一次换绑, 新号码变化时重新开始.

abstract class _$PhoneChange extends $Notifier<MobileChange?> {
  MobileChange? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MobileChange?, MobileChange?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MobileChange?, MobileChange?>,
              MobileChange?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 提交意见反馈. 截图逐张上传, 已上传的截图不重复上传.

@ProviderFor(FeedbackSender)
final feedbackSenderProvider = FeedbackSenderProvider._();

/// 提交意见反馈. 截图逐张上传, 已上传的截图不重复上传.
final class FeedbackSenderProvider
    extends $NotifierProvider<FeedbackSender, bool> {
  /// 提交意见反馈. 截图逐张上传, 已上传的截图不重复上传.
  FeedbackSenderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedbackSenderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedbackSenderHash();

  @$internal
  @override
  FeedbackSender create() => FeedbackSender();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$feedbackSenderHash() => r'8a5405e7cfe86dd65ab711f9d0526ad8c2b1c9ea';

/// 提交意见反馈. 截图逐张上传, 已上传的截图不重复上传.

abstract class _$FeedbackSender extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
