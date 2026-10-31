// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 消息列表，滑到底接着加载；点一条、全部已读时先改本地再告诉服务端。

@ProviderFor(Inbox)
final inboxProvider = InboxProvider._();

/// 消息列表，滑到底接着加载；点一条、全部已读时先改本地再告诉服务端。
final class InboxProvider extends $AsyncNotifierProvider<Inbox, InboxPages> {
  /// 消息列表，滑到底接着加载；点一条、全部已读时先改本地再告诉服务端。
  InboxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxHash();

  @$internal
  @override
  Inbox create() => Inbox();
}

String _$inboxHash() => r'8b055980f0f2260d11c95b805b9e43633f65c22a';

/// 消息列表，滑到底接着加载；点一条、全部已读时先改本地再告诉服务端。

abstract class _$Inbox extends $AsyncNotifier<InboxPages> {
  FutureOr<InboxPages> build();
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
    return element.handleCreate(ref, build);
  }
}
