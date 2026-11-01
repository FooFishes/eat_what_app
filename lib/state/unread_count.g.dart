// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unread_count.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 未读消息数, 用于发现页铃铛上的圆点和消息页的未读条数.
///
/// 回到前台和回到发现页时由页面调用 [refresh]. 阅读消息后直接递减.

@ProviderFor(UnreadCount)
final unreadCountProvider = UnreadCountProvider._();

/// 未读消息数, 用于发现页铃铛上的圆点和消息页的未读条数.
///
/// 回到前台和回到发现页时由页面调用 [refresh]. 阅读消息后直接递减.
final class UnreadCountProvider
    extends $AsyncNotifierProvider<UnreadCount, int> {
  /// 未读消息数, 用于发现页铃铛上的圆点和消息页的未读条数.
  ///
  /// 回到前台和回到发现页时由页面调用 [refresh]. 阅读消息后直接递减.
  UnreadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadCountHash();

  @$internal
  @override
  UnreadCount create() => UnreadCount();
}

String _$unreadCountHash() => r'6f923fedcb3c0aa49e10306ee7cd48750592cf2e';

/// 未读消息数, 用于发现页铃铛上的圆点和消息页的未读条数.
///
/// 回到前台和回到发现页时由页面调用 [refresh]. 阅读消息后直接递减.

abstract class _$UnreadCount extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
