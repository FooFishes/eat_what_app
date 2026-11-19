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

/// 界面深浅色的选择. 在设置 → 个性化中切换.
enum Appearance { system, light, dark }

/// 界面深浅色: 跟随系统, 或固定浅色, 深色. 默认跟随系统.
///
/// 和 [NavGlassTransparency] 一样是设备级偏好, 游客也能切换, 退出登录时不清除.
/// 启动时在首帧前调用 [restore] 读出, 避免先按系统深浅画一帧再跳.
@Riverpod(keepAlive: true)
class AppearancePreference extends _$AppearancePreference {
  static const key = 'prefs.appearance.theme';

  @override
  Appearance build() => Appearance.system;

  /// 读出本机保存的选择. 没存过或值认不出时保持跟随系统.
  Future<void> restore() async {
    final saved = await ref.read(kvStoreProvider).read(key);
    if (!ref.mounted) return;
    state = Appearance.values.asNameMap()[saved] ?? state;
  }

  Future<void> select(Appearance value) async {
    state = value;
    await ref.read(kvStoreProvider).write(key, value.name);
  }
}
