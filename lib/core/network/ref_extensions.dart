import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// 页面数据 Provider 的公共行为: 离开页面后保留缓存一段时间, 释放时取消请求.
extension RefCache on Ref {
  /// 最后一个监听者离开后保留 [duration]. 期间重新监听不会发起请求.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() => timer = Timer(duration, link.close));
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }

  /// 返回一个在 Provider 释放时取消的 [CancelToken].
  CancelToken cancelToken() {
    final token = CancelToken();
    onDispose(token.cancel);
    return token;
  }
}
