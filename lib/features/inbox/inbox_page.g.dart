// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 一个分栏的消息列表, 滚动到底部时加载下一页. 切换分栏时重新请求.
///
/// 点击一行和全部已读时, 先修改本地状态, 再通知服务端.

@ProviderFor(Inbox)
final inboxProvider = InboxFamily._();

/// 一个分栏的消息列表, 滚动到底部时加载下一页. 切换分栏时重新请求.
///
/// 点击一行和全部已读时, 先修改本地状态, 再通知服务端.
final class InboxProvider extends $AsyncNotifierProvider<Inbox, InboxPages> {
  /// 一个分栏的消息列表, 滚动到底部时加载下一页. 切换分栏时重新请求.
  ///
  /// 点击一行和全部已读时, 先修改本地状态, 再通知服务端.
  InboxProvider._({
    required InboxFamily super.from,
    required NoticeColumn super.argument,
  }) : super(
         retry: null,
         name: r'inboxProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inboxHash();

  @override
  String toString() {
    return r'inboxProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Inbox create() => Inbox();

  @override
  bool operator ==(Object other) {
    return other is InboxProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inboxHash() => r'fa0555ba21da8a8d8c0f7eaf785962df66dadca5';

/// 一个分栏的消息列表, 滚动到底部时加载下一页. 切换分栏时重新请求.
///
/// 点击一行和全部已读时, 先修改本地状态, 再通知服务端.

final class InboxFamily extends $Family
    with
        $ClassFamilyOverride<
          Inbox,
          AsyncValue<InboxPages>,
          InboxPages,
          FutureOr<InboxPages>,
          NoticeColumn
        > {
  InboxFamily._()
    : super(
        retry: null,
        name: r'inboxProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 一个分栏的消息列表, 滚动到底部时加载下一页. 切换分栏时重新请求.
  ///
  /// 点击一行和全部已读时, 先修改本地状态, 再通知服务端.

  InboxProvider call(NoticeColumn column) =>
      InboxProvider._(argument: column, from: this);

  @override
  String toString() => r'inboxProvider';
}

/// 一个分栏的消息列表, 滚动到底部时加载下一页. 切换分栏时重新请求.
///
/// 点击一行和全部已读时, 先修改本地状态, 再通知服务端.

abstract class _$Inbox extends $AsyncNotifier<InboxPages> {
  late final _$args = ref.$arg as NoticeColumn;
  NoticeColumn get column => _$args;

  FutureOr<InboxPages> build(NoticeColumn column);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<InboxPages>, InboxPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<InboxPages>, InboxPages>,
              AsyncValue<InboxPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
