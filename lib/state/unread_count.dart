import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/notification/notification_api.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unread_count.g.dart';

/// 未读消息行数计数, 用于发现页铃铛上的圆点和消息页的未读条数.
///
/// 回到前台和回到发现页时由页面调用 [refresh] 刷新; 点击一行后由页面调用 [markRead] 在本地扣减, 避免重复请求.
@Riverpod(keepAlive: true)
class UnreadCount extends _$UnreadCount {
  @override
  Future<int> build() async {
    if (ref.watch(sessionProvider.select((s) => s is! SignedIn))) return 0;
    return ref
        .watch(notificationRepositoryProvider)
        .unreadCount(cancelToken: ref.cancelToken());
  }

  void refresh() => ref.invalidateSelf();

  void markRead(int count) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData((current - count).clamp(0, current));
  }
}
