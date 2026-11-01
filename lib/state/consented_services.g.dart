// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consented_services.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 必须在同意隐私政策后才能启动的服务: 崩溃上报和热更新检查.
///
/// 启动时本机已有同意记录, 由 `bootstrap` 在首帧前启动.
/// 首次登录时由登录流程在写入同意记录后启动.
/// 状态表示是否已启动.

@ProviderFor(ConsentedServices)
final consentedServicesProvider = ConsentedServicesProvider._();

/// 必须在同意隐私政策后才能启动的服务: 崩溃上报和热更新检查.
///
/// 启动时本机已有同意记录, 由 `bootstrap` 在首帧前启动.
/// 首次登录时由登录流程在写入同意记录后启动.
/// 状态表示是否已启动.
final class ConsentedServicesProvider
    extends $NotifierProvider<ConsentedServices, bool> {
  /// 必须在同意隐私政策后才能启动的服务: 崩溃上报和热更新检查.
  ///
  /// 启动时本机已有同意记录, 由 `bootstrap` 在首帧前启动.
  /// 首次登录时由登录流程在写入同意记录后启动.
  /// 状态表示是否已启动.
  ConsentedServicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consentedServicesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consentedServicesHash();

  @$internal
  @override
  ConsentedServices create() => ConsentedServices();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$consentedServicesHash() => r'4f252e177deee02571679da3c2f02a350fd8dfbe';

/// 必须在同意隐私政策后才能启动的服务: 崩溃上报和热更新检查.
///
/// 启动时本机已有同意记录, 由 `bootstrap` 在首帧前启动.
/// 首次登录时由登录流程在写入同意记录后启动.
/// 状态表示是否已启动.

abstract class _$ConsentedServices extends $Notifier<bool> {
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
