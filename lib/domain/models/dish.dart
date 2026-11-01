import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/geo.dart';

/// 菜的分类（产品 4.4）。[api] 是接口里的写法，[stage] 是取色不可靠、或者菜没存舞台色时的默认色。
enum DishCategory {
  staple('staple', '主食', StageColor.broth),
  snack('snack', '小吃', StageColor.chili),
  drink('drink', '饮品', StageColor.mango),
  dessert('dessert', '甜品', StageColor.porcelain),
  soup('soup', '汤', StageColor.bamboo),
  hotPot('hot_pot', '火锅', StageColor.redoil),
  grill('grill', '烧烤', StageColor.soy),
  coldDish('cold_dish', '凉菜', StageColor.matcha),
  sideDish('side_dish', '配菜', StageColor.matcha),
  other('other', '其他', StageColor.bamboo);

  const new(this.api, this.label, this.stage);

  final String api;
  final String label;
  final StageColor stage;

  /// 发现页分类栏里单独成栏的分类，配菜和其他不单独列（产品 6.4）。
  static const shelf = [
    staple,
    snack,
    drink,
    dessert,
    soup,
    hotPot,
    grill,
    coldDish,
  ];

  static DishCategory? fromApi(String? value) {
    if (value == null) return null;
    final lower = value.toLowerCase();
    for (final category in values) {
      if (category.api == lower) return category;
    }
    return null;
  }
}

/// 饭点（产品 4.5）。时间段见 `MealTimeRules`。
enum MealTime {
  breakfast('breakfast', '早饭'),
  lunch('lunch', '午饭'),
  dinner('dinner', '晚饭'),
  night('night', '夜宵');

  const new(this.api, this.label);

  final String api;
  final String label;

  static MealTime? fromApi(String? value) {
    for (final meal in values) {
      if (meal.api == value) return meal;
    }
    return null;
  }
}

/// 封面的圆形取景：圆心在原图里的位置（0–1，按原图宽高归一）和直径占原图短边的比例。
/// 默认居中的短边内切圆（技术架构 13.4）。
class const CoverCrop({
  final double centerX = 0.5,
  final double centerY = 0.5,
  final double diameter = 1,
});

/// 一道菜上的一个口味标签：多少人打过，我打过没有。
class const TasteTag({
  required final int id,
  required final String name,
  final int count = 0,
  final bool mine = false,
});

/// 我给菜写的标签，只有自己看得见。[usage] 是用在了几道菜上，只有「我的标签」列表才有。
class const MyTag({
  required final int id,
  required final String name,
  final int? usage,
});

/// 一道菜，转盘、方块和详情都用它。
///
/// 照片 [images] 第一张是封面。舞台色接口没给时按分类默认色，分类也没有时用 `broth`；
/// [shopPoint]、[hubName]、[shopAddress] 只有推荐接口带，别的列表里是 null。
class const Dish({
  required final int id,
  required final String name,
  required final int shopId,
  final String? shopName,
  final String? shopAddress,
  final GcjPoint? shopPoint,
  final int? hubId,
  final String? hubName,
  final double? price,
  final DishCategory? category,
  final List<MealTime> mealTimes = const [],
  final List<String> images = const [],
  required final StageColor stage,
  final List<StageColor> stageAlternates = const [],
  final CoverCrop crop = const CoverCrop(),
  final List<TasteTag> tasteTags = const [],
  final List<MyTag> myTags = const [],
  final bool liked = false,
  final bool favorite = false,
  final int likes = 0,
  final int? uploaderId,
  final String? uploaderName,
  final String? description,
  final DateTime? createdAt,
}) {
  String? get cover => images.isEmpty ? null : images.first;
}

/// 发布一道菜时填好的内容（产品 9.1）。[imageKeys] 是上传后拿到的存储 key，第一张是封面；
/// [crop]、[stage]、[stageAlternates] 都是封面的。
class const NewDish({
  required final int shopId,
  required final String name,
  required final List<String> imageKeys,
  required final double price,
  required final DishCategory category,
  required final List<MealTime> mealTimes,
  required final StageColor stage,
  required final List<StageColor> stageAlternates,
  final CoverCrop crop = const CoverCrop(),
  final bool removeBackground = false,
  final List<int> tasteTagIds = const [],
  final List<String> myTagNames = const [],
  final String? description,
});
