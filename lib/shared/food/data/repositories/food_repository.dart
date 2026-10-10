import 'package:eat_what_app/core/network/api_parser.dart';
import 'package:eat_what_app/core/network/models/api_response.dart';
import 'package:eat_what_app/core/network/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/shared/food/data/models/create_food_dto.dart';
import 'package:eat_what_app/shared/food/data/models/food_tag_summary_vo.dart';
import 'package:eat_what_app/shared/food/data/models/food_vo.dart';

class FoodRepository {
  final RequestClient _api;

  const new(this._api);

  Future<PaginatedData<FoodVO>> getFoodsByRestaurant(
    int restaurantId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _api.get<PaginatedData<FoodVO>>(
      Urls.foodsList,
      queryParameters: {
        'restaurantId': restaurantId,
        'page': page,
        'pageSize': pageSize,
      },
      parser: (data) => ApiParser.parsePage(data, fromJson: FoodVO.fromJson),
    );

    if (result == null) {
      throw const ParseException(message: '菜品列表为空');
    }

    return result;
  }

  Future<void> uploadFood(CreateFoodDTO dto) async {
    await _api.postVoid(Urls.foodsUpload, data: dto.toJson());
  }

  Future<List<FoodTagSummaryVO>> getSystemTags() async {
    final result = await _api.get<List<FoodTagSummaryVO>>(
      Urls.foodsSystemTags,
      parser: (data) => ApiParser.parseList(data, FoodTagSummaryVO.fromJson),
    );

    if (result == null) {
      throw const ParseException(message: '系统标签为空');
    }

    return result;
  }

  Future<void> addSystemTags(int foodId, List<int> tagIds) async {
    await _api.postVoid(
      '${Urls.foodsBase}/$foodId/tags/system',
      data: {'tagIds': tagIds},
    );
  }

  Future<void> addCustomTags(int foodId, List<String> names) async {
    await _api.postVoid(
      '${Urls.foodsBase}/$foodId/tags/custom',
      data: {'names': names},
    );
  }

  Future<void> favoriteFood(int foodId) async {
    await _api.postVoid('${Urls.foodsBase}/$foodId/favorite');
  }

  Future<void> unfavoriteFood(int foodId) async {
    await _api.postVoid('${Urls.foodsBase}/$foodId/unfavorite');
  }

  Future<PaginatedData<FoodVO>> getMyFoods({
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _api.get<PaginatedData<FoodVO>>(
      Urls.foodsMy,
      queryParameters: {'page': page, 'pageSize': pageSize},
      parser: (data) => ApiParser.parsePage(data, fromJson: FoodVO.fromJson),
    );

    if (result == null) {
      throw const ParseException(message: '我的上传菜品为空');
    }

    return result;
  }

  Future<PaginatedData<FoodVO>> getMyFavorites({
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _api.get<PaginatedData<FoodVO>>(
      Urls.foodsFavorites,
      queryParameters: {'page': page, 'pageSize': pageSize},
      parser: (data) => ApiParser.parsePage(data, fromJson: FoodVO.fromJson),
    );

    if (result == null) {
      throw const ParseException(message: '收藏菜品为空');
    }

    return result;
  }

  Future<FoodVO?> resolveCreatedFood({
    required int restaurantId,
    required String name,
    required List<String> pictureUrl,
  }) async {
    final page = await getMyFoods(page: 1, pageSize: 20);
    for (final food in page.items) {
      if (food.restaurantId != restaurantId) {
        continue;
      }
      if (food.name != name) {
        continue;
      }
      if (_samePictureList(food.pictureUrl, pictureUrl)) {
        return food;
      }
    }
    return null;
  }

  bool _samePictureList(List<String> lhs, List<String> rhs) {
    if (lhs.length != rhs.length) {
      return false;
    }
    for (var index = 0; index < lhs.length; index++) {
      if (lhs[index] != rhs[index]) {
        return false;
      }
    }
    return true;
  }
}
