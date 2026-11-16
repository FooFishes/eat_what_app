import 'dart:async';

import 'package:eat/core/storage/kv_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appearance.g.dart';

/// 底部导航液态玻璃的透明度, 0 为不透明, 1 为完全透明. 在设置 → 个性化中调整.
///
/// 属于设备级偏好, 游客也能调整, 退出登录时不清除.
@Riverpod(keepAlive: true)
class NavGlassTransparency extends _$NavGlassTransparency {
  static const key = 'prefs.appearance.navGlass';
  static const fallback = 0.7;

  /// 下限保证调到最不透明时仍看得出是玻璃. 上限是完全透明, 只剩边缘的折射和高光.
  static const min = 0.2;
  static const max = 1.0;

  /// 标记用户是否已在本地偏好读出前调整过透明度, 若已调整则忽略随后读出的旧值.
  bool _changed = false;

  @override
  double build() {
    unawaited(_restore());
    return fallback;
  }

  Future<void> _restore() async {
    final saved = double.tryParse(
      await ref.read(kvStoreProvider).read(key) ?? '',
    );
    if (!ref.mounted || _changed || saved == null) return;
    state = saved.clamp(min, max);
  }

  /// 拖动滑条时连续调用以实时更新内存中的值, 松手后再调用 [save] 写入本机.
  void set(double value) {
    _changed = true;
    state = value.clamp(min, max);
  }

  Future<void> save() => ref.read(kvStoreProvider).write(key, '$state');
}
