// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'published.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 这次打开 App 以来发布了几道菜、建了几家店。「我的」的统计和上传、餐厅详情的菜单都监听它，
/// 发布成功后重新拉（技术架构 13.3）。功能之间不互相导入，靠它通知。

@ProviderFor(PublishedCount)
final publishedCountProvider = PublishedCountProvider._();

/// 这次打开 App 以来发布了几道菜、建了几家店。「我的」的统计和上传、餐厅详情的菜单都监听它，
/// 发布成功后重新拉（技术架构 13.3）。功能之间不互相导入，靠它通知。
final class PublishedCountProvider
    extends $NotifierProvider<PublishedCount, int> {
  /// 这次打开 App 以来发布了几道菜、建了几家店。「我的」的统计和上传、餐厅详情的菜单都监听它，
  /// 发布成功后重新拉（技术架构 13.3）。功能之间不互相导入，靠它通知。
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

/// 这次打开 App 以来发布了几道菜、建了几家店。「我的」的统计和上传、餐厅详情的菜单都监听它，
/// 发布成功后重新拉（技术架构 13.3）。功能之间不互相导入，靠它通知。

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
