// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AccountCode)
final accountCodeProvider = AccountCodeFamily._();

final class AccountCodeProvider
    extends $NotifierProvider<AccountCode, AccountCodeState> {
  AccountCodeProvider._({
    required AccountCodeFamily super.from,
    required AccountCodePurpose super.argument,
  }) : super(
         retry: null,
         name: r'accountCodeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$accountCodeHash();

  @override
  String toString() {
    return r'accountCodeProvider'
        ''
        '($argument)';
  }

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

  @override
  bool operator ==(Object other) {
    return other is AccountCodeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$accountCodeHash() => r'6467167d188a34ff7df72d62baaa197e6895f543';

final class AccountCodeFamily extends $Family
    with
        $ClassFamilyOverride<
          AccountCode,
          AccountCodeState,
          AccountCodeState,
          AccountCodeState,
          AccountCodePurpose
        > {
  AccountCodeFamily._()
    : super(
        retry: null,
        name: r'accountCodeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AccountCodeProvider call(AccountCodePurpose purpose) =>
      AccountCodeProvider._(argument: purpose, from: this);

  @override
  String toString() => r'accountCodeProvider';
}

abstract class _$AccountCode extends $Notifier<AccountCodeState> {
  late final _$args = ref.$arg as AccountCodePurpose;
  AccountCodePurpose get purpose => _$args;

  AccountCodeState build(AccountCodePurpose purpose);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 用户的隐私设置状态, 控制是否公开关注列表和粉丝列表.
///
/// 修改时先乐观更新本地状态, 若请求失败则恢复原值.

@ProviderFor(Privacy)
final privacyProvider = PrivacyProvider._();

/// 用户的隐私设置状态, 控制是否公开关注列表和粉丝列表.
///
/// 修改时先乐观更新本地状态, 若请求失败则恢复原值.
final class PrivacyProvider
    extends $AsyncNotifierProvider<Privacy, PrivacySettings> {
  /// 用户的隐私设置状态, 控制是否公开关注列表和粉丝列表.
  ///
  /// 修改时先乐观更新本地状态, 若请求失败则恢复原值.
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

/// 用户的隐私设置状态, 控制是否公开关注列表和粉丝列表.
///
/// 修改时先乐观更新本地状态, 若请求失败则恢复原值.

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

/// 个性化推荐开关状态. 关闭后推荐结果不再参考当前用户的个人记录.

@ProviderFor(Personalized)
final personalizedProvider = PersonalizedProvider._();

/// 个性化推荐开关状态. 关闭后推荐结果不再参考当前用户的个人记录.
final class PersonalizedProvider
    extends $AsyncNotifierProvider<Personalized, bool> {
  /// 个性化推荐开关状态. 关闭后推荐结果不再参考当前用户的个人记录.
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

/// 个性化推荐开关状态. 关闭后推荐结果不再参考当前用户的个人记录.

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

/// 使用统计开关状态. 关闭后停止采集, 服务端会删除已收集的记录.

@ProviderFor(UsageStatsSetting)
final usageStatsSettingProvider = UsageStatsSettingProvider._();

/// 使用统计开关状态. 关闭后停止采集, 服务端会删除已收集的记录.
final class UsageStatsSettingProvider
    extends $AsyncNotifierProvider<UsageStatsSetting, UsageStats> {
  /// 使用统计开关状态. 关闭后停止采集, 服务端会删除已收集的记录.
  UsageStatsSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usageStatsSettingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usageStatsSettingHash();

  @$internal
  @override
  UsageStatsSetting create() => UsageStatsSetting();
}

String _$usageStatsSettingHash() => r'a5a61a1513c375c0b0b1af6531a8a2003a3e866e';

/// 使用统计开关状态. 关闭后停止采集, 服务端会删除已收集的记录.

abstract class _$UsageStatsSetting extends $AsyncNotifier<UsageStats> {
  FutureOr<UsageStats> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UsageStats>, UsageStats>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UsageStats>, UsageStats>,
              AsyncValue<UsageStats>,
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

/// 查询反馈关联的菜品或店铺名称. 若两者均未指定则返回 null.

@ProviderFor(feedbackSubject)
final feedbackSubjectProvider = FeedbackSubjectFamily._();

/// 查询反馈关联的菜品或店铺名称. 若两者均未指定则返回 null.

final class FeedbackSubjectProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// 查询反馈关联的菜品或店铺名称. 若两者均未指定则返回 null.
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

/// 查询反馈关联的菜品或店铺名称. 若两者均未指定则返回 null.

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

  /// 查询反馈关联的菜品或店铺名称. 若两者均未指定则返回 null.

  FeedbackSubjectProvider call({int? dishId, int? shopId}) =>
      FeedbackSubjectProvider._(
        argument: (dishId: dishId, shopId: shopId),
        from: this,
      );

  @override
  String toString() => r'feedbackSubjectProvider';
}

/// 当前账号已登录的设备列表, 本机设备排在最前.

@ProviderFor(DeviceSessions)
final deviceSessionsProvider = DeviceSessionsProvider._();

/// 当前账号已登录的设备列表, 本机设备排在最前.
final class DeviceSessionsProvider
    extends $AsyncNotifierProvider<DeviceSessions, List<DeviceSession>> {
  /// 当前账号已登录的设备列表, 本机设备排在最前.
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

String _$deviceSessionsHash() => r'1dc3c596a5775e24d689ee3fbfae6a9f6caa59ec';

/// 当前账号已登录的设备列表, 本机设备排在最前.

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

/// 各推送栏目的开关状态. 修改时先乐观更新本地值, 若保存失败则恢复原值.

@ProviderFor(PushSettings)
final pushSettingsProvider = PushSettingsProvider._();

/// 各推送栏目的开关状态. 修改时先乐观更新本地值, 若保存失败则恢复原值.
final class PushSettingsProvider
    extends $AsyncNotifierProvider<PushSettings, List<PushSetting>> {
  /// 各推送栏目的开关状态. 修改时先乐观更新本地值, 若保存失败则恢复原值.
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

String _$pushSettingsHash() => r'666de3623ecf3cd3438a1db3e9131efbc64c4d31';

/// 各推送栏目的开关状态. 修改时先乐观更新本地值, 若保存失败则恢复原值.

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

/// 换绑和补绑手机号的业务控制器. 补绑仅用于尚未绑定手机的账号, 无需验证当前号码.

@ProviderFor(PhoneChange)
final phoneChangeProvider = PhoneChangeProvider._();

/// 换绑和补绑手机号的业务控制器. 补绑仅用于尚未绑定手机的账号, 无需验证当前号码.
final class PhoneChangeProvider
    extends $NotifierProvider<PhoneChange, PhoneChangeState> {
  /// 换绑和补绑手机号的业务控制器. 补绑仅用于尚未绑定手机的账号, 无需验证当前号码.
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
  Override overrideWithValue(PhoneChangeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhoneChangeState>(value),
    );
  }
}

String _$phoneChangeHash() => r'7e2b2c3a46c2377b9c0a18b4fa4d936ff6ea386e';

/// 换绑和补绑手机号的业务控制器. 补绑仅用于尚未绑定手机的账号, 无需验证当前号码.

abstract class _$PhoneChange extends $Notifier<PhoneChangeState> {
  PhoneChangeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PhoneChangeState, PhoneChangeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PhoneChangeState, PhoneChangeState>,
              PhoneChangeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 意见反馈提交控制器, 逐张上传未上传过的截图并提交反馈内容.

@ProviderFor(FeedbackSender)
final feedbackSenderProvider = FeedbackSenderProvider._();

/// 意见反馈提交控制器, 逐张上传未上传过的截图并提交反馈内容.
final class FeedbackSenderProvider
    extends $NotifierProvider<FeedbackSender, bool> {
  /// 意见反馈提交控制器, 逐张上传未上传过的截图并提交反馈内容.
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

String _$feedbackSenderHash() => r'77b7a869fcd8973521b613a67fcf670f1165b433';

/// 意见反馈提交控制器, 逐张上传未上传过的截图并提交反馈内容.

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
