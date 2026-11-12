import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WGS-84 转 GCJ-02 和公开算法的结果一致', () {
    // 对照点为天安门, 是公开算法常用的示例坐标.
    final gcj = GeoRules.toGcj(const WgsPoint(39.908692, 116.397477));
    expect(gcj.lat, closeTo(39.910093, 0.00002));
    expect(gcj.lng, closeTo(116.403714, 0.00002));
  });

  test('境外不加偏移', () {
    final gcj = GeoRules.toGcj(const WgsPoint(35.6812, 139.7671));
    expect(gcj, const GcjPoint(35.6812, 139.7671));
  });

  test('球面距离：纬度差 0.01° 约 1.11 km', () {
    final d = GeoRules.distance(
      const GcjPoint(36.66, 117.14),
      const GcjPoint(36.67, 117.14),
    );
    expect(d, closeTo(1112, 2));
  });

  test('距离的写法：320 m、1.2 km、12 km', () {
    expect(GeoRules.formatDistance(4), '10 m');
    expect(GeoRules.formatDistance(318), '320 m');
    expect(GeoRules.formatDistance(996), '1 km');
    expect(GeoRules.formatDistance(1000), '1 km');
    expect(GeoRules.formatDistance(1240), '1.2 km');
    expect(GeoRules.formatDistance(12400), '12 km');
  });

  test('没有定位、或者人离校区超过 5 km 时不显示距离', () {
    const campus = GcjPoint(36.667, 117.140);
    const shop = GcjPoint(36.668, 117.141);
    expect(
      GeoRules.distanceLabel(me: null, target: shop, campusCenter: campus),
      isNull,
    );
    expect(
      GeoRules.distanceLabel(
        me: const GcjPoint(36.80, 117.14),
        target: shop,
        campusCenter: campus,
      ),
      isNull,
    );
    expect(
      GeoRules.distanceLabel(
        me: const GcjPoint(36.666, 117.140),
        target: shop,
        campusCenter: campus,
      ),
      '240 m',
    );
  });
}
