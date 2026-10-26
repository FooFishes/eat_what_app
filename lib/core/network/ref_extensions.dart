import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// 页面数据 Provider 共用的两件事：离开页面后再缓存一会儿，以及释放时取消请求（技术架构 10.5）。
extension RefCache on Ref {
  /// 没人看以后再保留 [duration]，这段时间里回来不重新请求。
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() => timer = Timer(duration, link.close));
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }

  /// Provider 释放时取消请求。
  CancelToken cancelToken() {
    final token = CancelToken();
    onDispose(token.cancel);
    return token;
  }
}
