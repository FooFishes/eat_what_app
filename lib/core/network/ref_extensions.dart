import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// 页面数据 Provider 的公共行为: 离开页面后保留缓存一段时间, 释放时取消请求.
extension RefCache on Ref {
  /// 最后一个监听者离开后缓存仍保留 [duration], 期间重新监听不会发起请求.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() => timer = Timer(duration, link.close));
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }

  /// 先给本地缓存, 再在后台请求新的.
  ///
  /// 只在第一次构建时读 [cached]: 有缓存就先返回它, 等它成为当前状态后让 Provider 重新构建, 这次直接走 [fetch].
  /// 之后的重新构建 (下拉刷新, 失效) 也直接走 [fetch]. 后台请求失败时 Provider 是带着缓存值的错误状态.
  Future<T> cacheFirst<T>(
    Future<T?> Function() cached,
    Future<T> Function() fetch,
  ) async {
    if (isFirstBuild) {
      final value = await cached();
      if (value != null && mounted) {
        // 放进事件队列而不是微任务, 因为缓存要先落到状态上, 过早失效会连同缓存一起丢掉.
        Future(() {
          if (mounted) invalidateSelf();
        });
        return value;
      }
    }
    return fetch();
  }

  /// 返回一个在 Provider 释放时取消的 [CancelToken].
  CancelToken cancelToken() {
    final token = CancelToken();
    onDispose(token.cancel);
    return token;
  }
}
