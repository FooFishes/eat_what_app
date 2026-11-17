/// 推荐卡片 (`RecommendDtos.Card`) 的响应样例: 店铺的子集, 带招牌菜和距离.
///
/// [signature] 为 null 时没有招牌菜, [moreFoods] 是排在它后面的其他代表菜. [distance] 只在请求带坐标时返回.
/// 默认是游客视角, 没有收藏和我的评价.
Map<String, Object?> cardJson({
  int id = 7,
  String name = '袁记云饺',
  String kind = 'food',
  List<String> categories = const ['粉面'],
  String? hubName = '万达金街',
  double? distance,
  ({String name, double? price, String? photo})? signature = (
    name: '鲜虾蟹籽云吞',
    price: 18,
    photo: 'https://img.test/foods/1.jpg',
  ),
  ({double rate, int count}) dineIn = (rate: 0.86, count: 12),
  ({double rate, int count})? delivery,
  List<Map<String, Object?>> moreFoods = const [],
}) => {
  'id': id,
  'name': name,
  'address': '万达金街 1 层',
  'gcjLng': 117.1412,
  'gcjLat': 36.6681,
  'pictureUrl': 'https://img.test/restaurants/$id.jpg',
  'hubId': hubName == null ? null : 3,
  'hubName': hubName,
  'distanceMeters': distance,
  'kind': kind,
  'mealTimes': ['lunch', 'dinner'],
  'priceBand': null,
  'categories': categories,
  'tags': <String>[],
  'deliveryEnabled': false,
  'dineIn': {'rate': dineIn.rate, 'count': dineIn.count},
  'delivery': {'rate': delivery?.rate, 'count': delivery?.count ?? 0},
  'myRatings': null,
  'isFavorite': null,
  'signatureFoods': [
    if (signature != null)
      {
        'id': 100 + id,
        'name': signature.name,
        'price': signature.price,
        'pictureUrl': signature.photo,
      },
    ...moreFoods,
  ],
};

/// 推荐列表 (`RecommendDtos.Feed`) 的响应样例.
Map<String, Object?> feedJson(
  List<Object?> items, {
  int page = 1,
  bool hasNext = false,
  String mealTime = 'lunch',
}) => {
  'mealTime': mealTime,
  'currentPage': page,
  'items': items,
  'totalPages': hasNext ? page + 1 : page,
  'totalItems': items.length,
  'hasNext': hasNext,
};
