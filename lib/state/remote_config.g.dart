// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 远程配置快照 (技术架构第 17 节).
///
/// - 启动时由 `bootstrap` 调用 [restore], 读取本机快照, 没有快照时使用内置默认值, 不等待网络.
/// - 同意隐私政策后调用 [refresh] 获取最新配置, 回到前台时调用 [resume].
/// - 获取失败不提示用户, 继续使用当前配置 (产品 12.2).

@ProviderFor(RemoteConfig)
final remoteConfigProvider = RemoteConfigProvider._();

/// 远程配置快照 (技术架构第 17 节).
///
/// - 启动时由 `bootstrap` 调用 [restore], 读取本机快照, 没有快照时使用内置默认值, 不等待网络.
/// - 同意隐私政策后调用 [refresh] 获取最新配置, 回到前台时调用 [resume].
/// - 获取失败不提示用户, 继续使用当前配置 (产品 12.2).
final class RemoteConfigProvider
    extends $NotifierProvider<RemoteConfig, ClientConfig> {
  /// 远程配置快照 (技术架构第 17 节).
  ///
  /// - 启动时由 `bootstrap` 调用 [restore], 读取本机快照, 没有快照时使用内置默认值, 不等待网络.
  /// - 同意隐私政策后调用 [refresh] 获取最新配置, 回到前台时调用 [resume].
  /// - 获取失败不提示用户, 继续使用当前配置 (产品 12.2).
  RemoteConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteConfigHash();

  @$internal
  @override
  RemoteConfig create() => RemoteConfig();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClientConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClientConfig>(value),
    );
  }
}

String _$remoteConfigHash() => r'25939971e22cc34371cac988959c03ff9da1d48d';

/// 远程配置快照 (技术架构第 17 节).
///
/// - 启动时由 `bootstrap` 调用 [restore], 读取本机快照, 没有快照时使用内置默认值, 不等待网络.
/// - 同意隐私政策后调用 [refresh] 获取最新配置, 回到前台时调用 [resume].
/// - 获取失败不提示用户, 继续使用当前配置 (产品 12.2).

abstract class _$RemoteConfig extends $Notifier<ClientConfig> {
  ClientConfig build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ClientConfig, ClientConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClientConfig, ClientConfig>,
              ClientConfig,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 当前平台的版本线, 没有时为 null.

@ProviderFor(currentVersionLine)
final currentVersionLineProvider = CurrentVersionLineProvider._();

/// 当前平台的版本线, 没有时为 null.

final class CurrentVersionLineProvider
    extends $FunctionalProvider<VersionLine?, VersionLine?, VersionLine?>
    with $Provider<VersionLine?> {
  /// 当前平台的版本线, 没有时为 null.
  CurrentVersionLineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentVersionLineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentVersionLineHash();

  @$internal
  @override
  $ProviderElement<VersionLine?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VersionLine? create(Ref ref) {
    return currentVersionLine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VersionLine? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VersionLine?>(value),
    );
  }
}

String _$currentVersionLineHash() =>
    r'd2efa9f43d699b3cf88749e7e9430be31734c836';

/// 本机构建号与当前平台版本线比较的结果. 构建号读出之前为 [UpdateDecision.none].

@ProviderFor(appUpdate)
final appUpdateProvider = AppUpdateProvider._();

/// 本机构建号与当前平台版本线比较的结果. 构建号读出之前为 [UpdateDecision.none].

final class AppUpdateProvider
    extends $FunctionalProvider<UpdateDecision, UpdateDecision, UpdateDecision>
    with $Provider<UpdateDecision> {
  /// 本机构建号与当前平台版本线比较的结果. 构建号读出之前为 [UpdateDecision.none].
  AppUpdateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateHash();

  @$internal
  @override
  $ProviderElement<UpdateDecision> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdateDecision create(Ref ref) {
    return appUpdate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateDecision value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateDecision>(value),
    );
  }
}

String _$appUpdateHash() => r'5d40d00bb1ae5bd4b89196c3c3dc5eccd16ccf4a';

@ProviderFor(appGate)
final appGateProvider = AppGateProvider._();

final class AppGateProvider
    extends $FunctionalProvider<AppGate, AppGate, AppGate>
    with $Provider<AppGate> {
  AppGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appGateHash();

  @$internal
  @override
  $ProviderElement<AppGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppGate create(Ref ref) {
    return appGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppGate>(value),
    );
  }
}

String _$appGateHash() => r'82182ee9acce6ef6b6a3416f265be14d65f3fbe0';

/// 管理本机的公告与建议更新记录. 记录属于设备, 退出登录时保留.

@ProviderFor(Notices)
final noticesProvider = NoticesProvider._();

/// 管理本机的公告与建议更新记录. 记录属于设备, 退出登录时保留.
final class NoticesProvider extends $NotifierProvider<Notices, NoticeRecords> {
  /// 管理本机的公告与建议更新记录. 记录属于设备, 退出登录时保留.
  NoticesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noticesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noticesHash();

  @$internal
  @override
  Notices create() => Notices();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoticeRecords value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoticeRecords>(value),
    );
  }
}

String _$noticesHash() => r'c124edc9e9e39ed1e666c2b6c0d92bc4cebc5a0b';

/// 管理本机的公告与建议更新记录. 记录属于设备, 退出登录时保留.

abstract class _$Notices extends $Notifier<NoticeRecords> {
  NoticeRecords build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NoticeRecords, NoticeRecords>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NoticeRecords, NoticeRecords>,
              NoticeRecords,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 发现页抽屉顶部要显示的普通公告, 没有时为 null.

@ProviderFor(bannerNotice)
final bannerNoticeProvider = BannerNoticeProvider._();

/// 发现页抽屉顶部要显示的普通公告, 没有时为 null.

final class BannerNoticeProvider
    extends $FunctionalProvider<Announcement?, Announcement?, Announcement?>
    with $Provider<Announcement?> {
  /// 发现页抽屉顶部要显示的普通公告, 没有时为 null.
  BannerNoticeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bannerNoticeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bannerNoticeHash();

  @$internal
  @override
  $ProviderElement<Announcement?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Announcement? create(Ref ref) {
    return bannerNotice(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Announcement? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Announcement?>(value),
    );
  }
}

String _$bannerNoticeHash() => r'40112da642187665b416a205f8c82a67c41c3a15';

/// 待弹出的重要公告, 没有时为 null.

@ProviderFor(importantNotice)
final importantNoticeProvider = ImportantNoticeProvider._();

/// 待弹出的重要公告, 没有时为 null.

final class ImportantNoticeProvider
    extends $FunctionalProvider<Announcement?, Announcement?, Announcement?>
    with $Provider<Announcement?> {
  /// 待弹出的重要公告, 没有时为 null.
  ImportantNoticeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importantNoticeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importantNoticeHash();

  @$internal
  @override
  $ProviderElement<Announcement?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Announcement? create(Ref ref) {
    return importantNotice(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Announcement? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Announcement?>(value),
    );
  }
}

String _$importantNoticeHash() => r'dc6d7494ca21138bc28eabad729a65ce4e1faa9a';

/// 需要提示建议更新时为当前平台的版本线, 否则为 null.

@ProviderFor(updatePrompt)
final updatePromptProvider = UpdatePromptProvider._();

/// 需要提示建议更新时为当前平台的版本线, 否则为 null.

final class UpdatePromptProvider
    extends $FunctionalProvider<VersionLine?, VersionLine?, VersionLine?>
    with $Provider<VersionLine?> {
  /// 需要提示建议更新时为当前平台的版本线, 否则为 null.
  UpdatePromptProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updatePromptProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updatePromptHash();

  @$internal
  @override
  $ProviderElement<VersionLine?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VersionLine? create(Ref ref) {
    return updatePrompt(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VersionLine? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VersionLine?>(value),
    );
  }
}

String _$updatePromptHash() => r'd1ed90124caf7710468dbdcef5d7abc1b375bcb3';
