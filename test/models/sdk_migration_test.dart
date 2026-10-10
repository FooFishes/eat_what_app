import 'package:eat_what_app/core/constant/biz_code.dart';
import 'package:eat_what_app/core/network/models/api_response.dart';
import 'package:eat_what_app/features/auth/data/models/auth_request.dart';
import 'package:eat_what_app/features/auth/data/models/token_response.dart';
import 'package:eat_what_app/features/foodie_map/data/models/activity_food_page_response.dart';
import 'package:eat_what_app/features/foodie_map/data/models/activity_food_response.dart';
import 'package:eat_what_app/features/foodie_map/data/models/regional_food.dart';
import 'package:eat_what_app/features/profile/data/models/update_user_info_request.dart';
import 'package:eat_what_app/features/restaurant/data/models/restaurant.dart';
import 'package:eat_what_app/shared/food/data/models/food_system_tag_vo.dart';
import 'package:eat_what_app/shared/food/data/models/food_tag_summary_vo.dart';
import 'package:eat_what_app/shared/food/data/models/food_vo.dart';
import 'package:eat_what_app/shared/location/data/models/city_response.dart';
import 'package:eat_what_app/shared/location/data/models/province.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('更新资料区分未传、显式 null 和正常值，命名参数保持兼容', () {
    expect(const UpdateUserInfoRequest().toJson(), isEmpty);
    expect(
      const UpdateUserInfoRequest(
        userName: null,
        avatar: null,
        gender: null,
        birthday: null,
        signature: null,
        hometownProvinceId: null,
        hometownCityId: null,
      ).toJson(),
      {
        'userName': null,
        'avatar': null,
        'gender': null,
        'birthday': null,
        'signature': null,
        'hometownProvinceId': null,
        'hometownCityId': null,
      },
    );
    expect(
      const UpdateUserInfoRequest(
        userName: '小明',
        hometownProvinceId: 15,
        hometownCityId: 1501,
      ).toJson(),
      {'userName': '小明', 'hometownProvinceId': 15, 'hometownCityId': 1501},
    );
  });

  test('const 主构造函数和泛型 JSON 工厂保持原有字段与转换', () {
    const city = CityResponse(id: 1501, provinceId: 15, name: '济南市');
    expect(
      CityResponse.fromJson({'id': 1501.0, 'provinceId': 15.0, 'name': '济南市'})
          .toJson(),
      city.toJson(),
    );
    final response = ApiResponse<CityResponse>.fromJson({
      'code': 0,
      'msg': ' 成功 ',
      'data': city.toJson(),
      'timestamp': 123,
    }, (data) => CityResponse.fromJson(data as Map<String, dynamic>));
    expect(response.code, 0);
    expect(response.msg, '成功');
    expect(response.timestamp, 123);
    expect(response.data!.toJson(), city.toJson());
    const page = PaginatedData<CityResponse>(
      currentPage: 1,
      items: [city],
      totalPages: 1,
      totalItems: 1,
      hasNext: false,
    );
    expect(page.items.single.name, '济南市');
  });

  test('认证请求保留字段映射和默认设备，令牌兼容数字与字符串账号', () {
    expect(AuthRequest(account: 'test', password: 'secret').toJson(), {
      'username': 'test',
      'password': 'secret',
      'device': 'APP',
    });
    for (final (input, expected) in [
      (42, 42),
      ('42', 42),
      ('invalid', 0),
      (null, 0),
    ]) {
      final token = TokenResponse.fromJson({
        'isLogin': true,
        'loginDeviceType': 'APP',
        'loginId': input,
        'loginType': 'account',
        'tag': 'ignored',
        'tokenActiveTimeout': 10,
        'tokenName': 'Authorization',
        'tokenSessionTimeout': 20,
        'tokenTimeout': 30,
        'tokenValue': 'test-token',
      });
      expect(token.loginId, expected);
      expect(token.tag, isEmpty);
    }
  });

  test('美食模型对图片和两类标签保持只读副本', () {
    final pictures = ['photo.png'];
    final systemTags = <FoodSystemTagVO>[];
    final customTags = <FoodTagSummaryVO>[];
    final food = FoodVO(
      id: 1,
      accountId: 2,
      uploaderName: '上传者',
      restaurantId: 3,
      name: '面条',
      description: '',
      price: 12,
      category: null,
      pictureUrl: pictures,
      systemTags: systemTags,
      myCustomTags: customTags,
      isFavorite: false,
      likesCount: 0,
      createdAt: null,
      updatedAt: null,
    );
    pictures.clear();
    systemTags.add(
      const FoodSystemTagVO(id: 1, name: '好吃', count: 1, taggedByMe: true),
    );
    customTags.add(const FoodTagSummaryVO(id: 1, name: '午餐'));
    expect(food.pictureUrl, ['photo.png']);
    expect(food.systemTags, isEmpty);
    expect(food.myCustomTags, isEmpty);
    expect(() => food.pictureUrl.clear(), throwsUnsupportedError);
    expect(() => food.systemTags.clear(), throwsUnsupportedError);
    expect(() => food.myCustomTags.clear(), throwsUnsupportedError);
    expect(FoodVO.fromJson(food.toJson()).toJson(), food.toJson());
  });

  test('餐厅模型保留只读图片副本和 POI 字段映射', () {
    final pictures = ['restaurant.png'];
    final restaurant = Restaurant(
      id: 1,
      name: '餐厅',
      address: '济南',
      cityId: 1501,
      gcjLng: 117,
      gcjLat: 36,
      hubId: null,
      poi: 'poi-id',
      pictureUrl: pictures,
      createdAt: null,
      updatedAt: null,
    );
    pictures.clear();
    expect(restaurant.pictureUrl, ['restaurant.png']);
    expect(() => restaurant.pictureUrl.clear(), throwsUnsupportedError);
    expect(restaurant.toJson()['POI'], 'poi-id');
    expect(
      Restaurant.fromJson(restaurant.toJson()).toJson(),
      restaurant.toJson(),
    );
  });

  test('活动模型和分页保留只读副本、JSON 和重定向构造行为', () {
    final pictures = ['activity.png'];
    final activity = ActivityFoodResponse(
      id: 1,
      accountId: 2,
      foodName: '面条',
      description: '活动美食',
      provinceId: 15,
      cityId: 1501,
      pictureUrl: pictures,
      likesCount: 3,
      isLiked: true,
      createdAt: 100,
      updatedAt: 200,
      uploaderName: '上传者',
    );
    pictures.clear();
    expect(activity.pictureUrl, ['activity.png']);
    expect(() => activity.pictureUrl.clear(), throwsUnsupportedError);
    final items = [activity];
    final page = ActivityFoodPageResponse(
      currentPage: 1,
      items: items,
      totalPages: 1,
      totalItems: 1,
      hasNext: false,
    );
    items.clear();
    expect(page.items, hasLength(1));
    expect(() => page.items.clear(), throwsUnsupportedError);
    expect(
      ActivityFoodPageResponse.fromJson(page.toJson()).toJson(),
      page.toJson(),
    );
    final regional = RegionalFood.fromActivityFoodResponse(activity);
    expect(regional.url, 'activity.png');
    expect(regional.accountName, '上传者');
    final changed = regional.copyWith(isLiked: false);
    expect(changed.isLiked, false);
    expect(changed.id, regional.id);
    expect(changed.url, regional.url);
    expect(regional.isLiked, true);
  });

  test('枚举主构造函数保留业务值和省份查找', () {
    expect(Province.fromId(15), Province.shandong);
    expect(Province.fromName('山东省济南市'), Province.shandong);
    expect(Province.fromId(-1), isNull);
    expect(Province.hongKong.isMHT, isTrue);
    expect(Province.foreign.isForeign, isTrue);
    expect(Province.shandong.code, 'SD');
    expect(
      BizCode.values.map((value) => value.code).toSet().length,
      BizCode.values.length,
    );
  });
}
