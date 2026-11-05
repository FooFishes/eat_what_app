import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/geo.dart';

/// 菜品分类.
///
/// [api] 是接口中的取值. [stage] 是默认舞台色, 在取色不可靠或菜品未保存舞台色时使用.
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

  /// 发现页分类栏中单独成栏的分类. 配菜和其他不单独成栏.
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

/// 饭点. 各饭点的时间段见 `MealTimeRules`.
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

/// 封面的圆形取景.
///
/// [centerX] 和 [centerY] 是圆心在原图中的位置, 按原图宽高归一化到 0–1.
/// [diameter] 是直径占原图短边的比例. 默认值表示居中的短边内切圆.
class const CoverCrop({
  final double centerX = 0.5,
  final double centerY = 0.5,
  final double diameter = 1,
});

/// 菜品上的一个口味标签. [count] 是打过该标签的人数, [mine] 表示当前用户是否打过.
class const TasteTag({
  required final int id,
  required final String name,
  final int count = 0,
  final bool mine = false,
});

/// 当前用户给菜品写的标签, 只有本人可见.
///
/// [usage] 是该标签用于多少道菜, 只有 "我的标签" 列表返回该值.
class const MyTag({
  required final int id,
  required final String name,
  final int? usage,
});

/// 菜品. 转盘, 菜品方块和详情页共用.
///
/// - [images] 的第一张是封面.
/// - 接口未返回舞台色时使用分类默认色, 分类也缺失时使用 `broth`.
/// - [shopPoint], [hubName], [shopAddress] 只有推荐接口返回, 其他列表中为 null.
class const Dish({
  required final int id,
  required final String name,
  required final int shopId,
  final String? shopName,
  final String? shopAddress,
  final GcjPoint? shopPoint,
  final int? hubId,
  final String? hubName,

  /// 店铺与查询坐标的距离, 单位米. 只有带坐标查询菜品时有值.
  final double? distance,
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

/// 发布菜品时填写的内容.
///
/// [imageKeys] 是上传后获得的存储 key, 第一张是封面.
/// [crop], [stage], [stageAlternates] 都针对封面.
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
  final List<int> tasteTagIds = const [],
  final List<String> myTagNames = const [],
  final String? description,
});
