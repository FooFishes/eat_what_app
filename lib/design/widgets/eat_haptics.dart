import 'dart:async';

import 'package:flutter/services.dart';

/// 触感反馈工具, 仅在用户操作引起界面变化时触发, 数据加载和自动动画不触发.
///
/// 在不支持震动的平台 (Web, 部分 Android 设备) 上调用没有效果.
abstract final class EatHaptics {
  /// 选中变化时触发: 转盘转到另一道菜, 切换分栏, 单选, 开关.
  static void selection() => unawaited(HapticFeedback.selectionClick());

  /// 轻触时触发: 赞, 收藏和触发下拉刷新.
  static void light() => unawaited(HapticFeedback.lightImpact());
}
