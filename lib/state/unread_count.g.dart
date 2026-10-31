// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unread_count.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 未读消息数，发现页铃铛上的圆点和消息页的「3 条未读」用它。
///
/// 回到前台、回到发现页时由页面调 [refresh]（产品 10.3）；读了消息直接减。

@ProviderFor(UnreadCount)
final unreadCountProvider = UnreadCountProvider._();

/// 未读消息数，发现页铃铛上的圆点和消息页的「3 条未读」用它。
///
/// 回到前台、回到发现页时由页面调 [refresh]（产品 10.3）；读了消息直接减。
final class UnreadCountProvider
    extends $AsyncNotifierProvider<UnreadCount, int> {
  /// 未读消息数，发现页铃铛上的圆点和消息页的「3 条未读」用它。
  ///
  /// 回到前台、回到发现页时由页面调 [refresh]（产品 10.3）；读了消息直接减。
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

/// 未读消息数，发现页铃铛上的圆点和消息页的「3 条未读」用它。
///
/// 回到前台、回到发现页时由页面调 [refresh]（产品 10.3）；读了消息直接减。

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
