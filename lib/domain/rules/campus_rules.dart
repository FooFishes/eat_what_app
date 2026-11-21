import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';

/// 自动选校区的规则.
abstract final class CampusRules {
  /// 按定位自动选的校区: 有定位 [me] 时取离得最近的一个, 没有时取默认校区, 也没有默认校区时取第一个.
  /// [campuses] 为空时返回 null.
  static Campus? nearest(List<Campus> campuses, GcjPoint? me) {
    if (campuses.isEmpty) return null;
    if (me == null) {
      return campuses.firstWhere(
        (c) => c.isDefault,
        orElse: () => campuses.first,
      );
    }
    var best = campuses.first;
    var bestDistance = GeoRules.distance(me, best.center);
    for (final c in campuses.skip(1)) {
      final d = GeoRules.distance(me, c.center);
      if (d < bestDistance) {
        best = c;
        bestDistance = d;
      }
    }
    return best;
  }
}
