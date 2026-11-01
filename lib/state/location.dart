import 'dart:async';

import 'package:eat/core/platform/location.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location.g.dart';

/// 定位权限和最近一次位置 (GCJ-02).
///
/// 位置只保存在内存中, 不写入本地存储. 产品按最少够用原则处理个人信息, 位置不需要跨启动保留.
class const LocationState({
  final LocationAccess access = LocationAccess.notAsked,
  final GcjPoint? point,

  /// 首次申请权限前的说明是否已展示. 从本地存储读出之前为 null.
  final bool? explained,
});

/// 当前位置. 进入发现页和附近页时各定位一次.
///
/// 尚未申请过权限时不主动弹出系统权限框, 先由页面展示说明.
@Riverpod(keepAlive: true)
class CurrentLocation extends _$CurrentLocation {
  static const explainedKey = 'prefs.location.explained';

  @override
  LocationState build() {
    unawaited(_init());
    return const LocationState();
  }

  LocationService get _service => ref.read(locationServiceProvider);

  Future<void> _init() async {
    final explained =
        await ref.read(kvStoreProvider).read(explainedKey) != null;
    final access = await _service.access();
    if (!ref.mounted) return;
    state = LocationState(
      access: access,
      point: state.point,
      explained: explained,
    );
    if (access == LocationAccess.granted) await refresh();
  }

  /// 已有权限时重新定位一次.
  Future<void> refresh() async {
    if (state.access != LocationAccess.granted) return;
    final raw = await _service.current();
    if (!ref.mounted || raw == null) return;
    state = LocationState(
      access: state.access,
      point: GeoRules.toGcj(WgsPoint(raw.lat, raw.lng)),
      explained: state.explained,
    );
  }

  /// 用户在说明面板点击允许后调用: 记录说明已展示, 再弹出系统权限框.
  Future<LocationAccess> request() async {
    await ref.read(kvStoreProvider).write(explainedKey, '1');
    final access = await _service.request();
    if (!ref.mounted) return access;
    state = LocationState(access: access, point: state.point, explained: true);
    if (access == LocationAccess.granted) await refresh();
    return access;
  }

  /// 用户在说明面板点击 "先不用" 后调用: 记录说明已展示, 之后不再弹出说明.
  Future<void> dismissExplanation() async {
    await ref.read(kvStoreProvider).write(explainedKey, '1');
    if (!ref.mounted) return;
    state = LocationState(
      access: state.access,
      point: state.point,
      explained: true,
    );
  }
}
