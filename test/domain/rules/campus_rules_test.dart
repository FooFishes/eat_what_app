import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/campus_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const park = Campus(
    id: 1,
    name: '软件园',
    center: GcjPoint(36.667, 117.140),
    isDefault: true,
  );
  const center = Campus(id: 2, name: '中心校区', center: GcjPoint(36.672, 117.025));

  test('有定位时选最近的校区', () {
    expect(
      CampusRules.nearest([park, center], const GcjPoint(36.67, 117.02)),
      center,
    );
    expect(
      CampusRules.nearest([park, center], const GcjPoint(36.66, 117.14)),
      park,
    );
  });

  test('没有定位时选默认校区，没有默认校区时选第一个，没有校区时为 null', () {
    expect(CampusRules.nearest([center, park], null), park);
    expect(CampusRules.nearest([center], null), center);
    expect(CampusRules.nearest(const [], null), isNull);
  });
}
