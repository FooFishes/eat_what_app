// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'published.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 本次启动以来的发布次数, 包括发布菜品和新建店铺.
///
/// "我的" 的统计与上传列表, 以及餐厅详情的菜单监听该值, 变化后重新请求.
/// 功能之间不能互相导入, 因此通过该 Provider 通知.

@ProviderFor(PublishedCount)
final publishedCountProvider = PublishedCountProvider._();

/// 本次启动以来的发布次数, 包括发布菜品和新建店铺.
///
/// "我的" 的统计与上传列表, 以及餐厅详情的菜单监听该值, 变化后重新请求.
/// 功能之间不能互相导入, 因此通过该 Provider 通知.
final class PublishedCountProvider
    extends $NotifierProvider<PublishedCount, int> {
  /// 本次启动以来的发布次数, 包括发布菜品和新建店铺.
  ///
  /// "我的" 的统计与上传列表, 以及餐厅详情的菜单监听该值, 变化后重新请求.
  /// 功能之间不能互相导入, 因此通过该 Provider 通知.
  PublishedCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publishedCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$publishedCountHash();

  @$internal
  @override
  PublishedCount create() => PublishedCount();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$publishedCountHash() => r'c0e0c731fb85afbf7fcf0ce1742a717e6544648b';

/// 本次启动以来的发布次数, 包括发布菜品和新建店铺.
///
/// "我的" 的统计与上传列表, 以及餐厅详情的菜单监听该值, 变化后重新请求.
/// 功能之间不能互相导入, 因此通过该 Provider 通知.

abstract class _$PublishedCount extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
