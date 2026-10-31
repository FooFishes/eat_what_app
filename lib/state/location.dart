import 'dart:async';

import 'package:eat/core/platform/location.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location.g.dart';

/// 定位权限和最近一次位置（GCJ-02）。位置只在内存里，不落盘（产品 7.6）。
class const LocationState({
  final LocationAccess access = LocationAccess.notAsked,
  final GcjPoint? point,

  /// 第一次申请权限前的说明展示过没有（产品 6.13）。读出来之前是 null。
  final bool? explained,
});

/// 当前位置：进发现页、附近页时定位一次。还没问过系统时不主动弹权限框，先由页面给说明。
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

  /// 有权限时重新定位一次。
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

  /// 用户看过说明、点了允许：记下说明展示过，再弹系统的权限框。
  Future<LocationAccess> request() async {
    await ref.read(kvStoreProvider).write(explainedKey, '1');
    final access = await _service.request();
    if (!ref.mounted) return access;
    state = LocationState(access: access, point: state.point, explained: true);
    if (access == LocationAccess.granted) await refresh();
    return access;
  }

  /// 说明面板点了「先不用」：记下来，不再反复弹（技术架构 14.2）。
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
