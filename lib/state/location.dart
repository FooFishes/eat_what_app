import 'dart:async';

import 'package:eat/core/platform/location.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location.g.dart';

/// 定位权限状态与最近一次获取的坐标 (GCJ-02).
///
/// 遵循个人信息最小化原则, 位置坐标仅保存在内存中而不写入本地存储, 无需跨启动保留.
class const LocationState({
  final LocationAccess access = LocationAccess.notAsked,
  final GcjPoint? point,

  /// 首次申请权限前的说明是否已展示. 从本地存储读出之前为 null.
  final bool? explained,
});

/// 维护当前设备位置, 在进入发现页与附近页时触发定位更新.
///
/// 若尚未申请过系统定位权限, 不会主动弹出系统授权框, 而是交由页面先行展示权限说明.
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

  /// 在已获得定位权限的前提下重新获取一次当前位置.
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

  /// 在用户于说明面板点击允许后记录已展示状态, 并唤起系统定位权限请求.
  Future<LocationAccess> request() async {
    await ref.read(kvStoreProvider).write(explainedKey, '1');
    final access = await _service.request();
    if (!ref.mounted) return access;
    state = LocationState(access: access, point: state.point, explained: true);
    if (access == LocationAccess.granted) await refresh();
    return access;
  }

  /// 在用户于说明面板点击 "先不用" 后记录已展示状态, 后续不再重复弹出权限说明.
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
