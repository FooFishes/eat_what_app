import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/taste.dart';

/// 菜品分类, 声明顺序即菜单顺序.
///
/// [api] 是接口中的取值, 与界面文字相同. [stage] 是默认舞台色, 在菜品没有保存舞台色时使用.
enum DishCategory {
  staple('主食', StageColor.broth),
  dish('菜', StageColor.soy),
  snack('小吃', StageColor.chili),
  soup('汤', StageColor.bamboo),
  drinkDessert('饮品甜品', StageColor.mango),
  special('特色', StageColor.matcha);

  const new(this.api, this.stage);

  final String api;
  final StageColor stage;

  String get label => api;

  /// 未知值返回 null, 由调用方按无分类处理. 后端仅在末尾追加新分类.
  static DishCategory? fromApi(String? value) {
    final trimmed = value?.trim();
    for (final category in values) {
      if (category.api == trimmed) return category;
    }
    return null;
  }
}

/// 菜品封面的圆形取景区域.
///
/// [centerX] 和 [centerY] 是圆心在原图中的位置, 按原图宽高归一化到 0–1.
/// [diameter] 是直径占原图短边的比例. 默认值表示居中的短边内切圆.
class const CoverCrop({
  final double centerX = 0.5,
  final double centerY = 0.5,
  final double diameter = 1,
});

/// 菜品的评分统计.
///
/// [score] 是 1–5 分的平均分, 保留一位小数, 没有人评分时为 null. [count] 是评分人数.
class const DishRating({final double? score, final int count = 0});

/// 菜品上的投票口味标签. [count] 为标注该标签的人数, [mine] 表示当前用户是否已标注.
///
/// 后端 v2 暂未提供口味投票接口, 仅由保留的加标签面板使用.
class const TasteTag({
  required final int id,
  required final String name,
  final int count = 0,
  final bool mine = false,
});

/// 当前用户为菜品添加的私有标签, 仅本人可见.
///
/// [usage] 为该标签关联的菜品数量, 仅在 "我的标签" 列表中返回.
/// 后端 v2 暂未提供我的标签接口, 仅由保留的我的标签页使用.
class const MyTag({
  required final int id,
  required final String name,
  final int? usage,
});

/// 菜品信息, 供菜品方块, 店铺菜单与详情页共用.
///
/// - [images] 的第一张是封面.
/// - [stage], [stageAlternates], [crop] 优先使用服务端保存的值.
///   服务端未返回时, [stage] 取分类默认色, [crop] 取居中的短边内切圆.
class const Dish({
  required final int id,
  required final String name,
  required final int shopId,
  final String? shopName,
  final double? price,
  final DishCategory? category,
  final List<String> images = const [],
  required final StageColor stage,
  final List<StageColor> stageAlternates = const [],
  final CoverCrop crop = const CoverCrop(),

  /// 口味标签列表, 最多 3 个, 由编辑者设置.
  final List<Taste> tags = const [],

  /// 是否为招牌菜, 由编辑者标记, 每家店最多 3 道.
  final bool signature = false,
  final bool liked = false,
  final bool favorite = false,
  final int likes = 0,

  /// 首次发布者的账号 id, 用于判断菜品归属及获取上传者资料, 账号已删除时为 null.
  final int? uploaderId,
  final String? description,
  final DateTime? createdAt,

  /// 这道菜自己设置的饭点. 为空表示沿用店铺的饭点.
  final List<MealTime> mealTimes = const [],

  /// 实际供应的饭点: 设置了 [mealTimes] 时就是它, 否则是店铺的饭点.
  final List<MealTime> effectiveMealTimes = const [],

  /// 这道菜能不能点外卖.
  final bool deliveryEnabled = false,
  final DishRating rating = const DishRating(),

  /// 当前用户打的分 (1–5). 游客或没打过分时为 null.
  final int? myRating,
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
  required final StageColor stage,
  required final List<StageColor> stageAlternates,
  final CoverCrop crop = const CoverCrop(),
  final List<Taste> tags = const [],
  final bool signature = false,
  final String? description,

  /// 这道菜自己的饭点. 为空表示沿用店铺的饭点.
  final List<MealTime> mealTimes = const [],
  final bool deliveryEnabled = false,
});

/// 编辑菜品时提交的改动. 值为 null 的字段不修改.
///
/// - [description] 为空字符串表示清除.
/// - [imageKeys] 和 [tags] 为空列表表示清除.
/// - [mealTimes] 为空列表表示改回沿用店铺的饭点.
/// - 菜品不能换店, 因此没有店铺字段.
///
/// [imageKeys] 为完整的新图片列表, 保留的原图仍需传入其原有的存储 key, 第一张将作为封面.
class const DishChange({
  final String? name,
  final DishCategory? category,
  final double? price,
  final String? description,
  final List<String>? imageKeys,
  final List<Taste>? tags,
  final bool? signature,
  final StageColor? stage,
  final List<StageColor>? stageAlternates,
  final CoverCrop? crop,
  final List<MealTime>? mealTimes,
  final bool? deliveryEnabled,
});

/// 发布前查重得到的已有菜品, 是这家店里菜名包含输入的菜.
///
/// [sameName] 为 true 表示与输入的菜名相同 (忽略空白和大小写), 这时不能发布. [photo] 是封面.
class const DishDuplicate({
  required final int id,
  required final String name,
  final DishCategory? category,
  final double? price,
  final String? photo,
  final bool sameName = false,
});

/// 发布和编辑菜品时可选的分类, 口味, 饭点和数量上限, 由服务端下发.
///
/// 各列表只包含客户端认识的取值, 顺序按服务端返回. 默认值是服务端不可用时使用的内置值.
class const DishOptions({
  final List<DishCategory> categories = DishCategory.values,
  final List<Taste> tastes = Taste.values,
  final List<MealTime> mealTimes = MealTime.values,

  /// 一道菜最多几张照片.
  final int photosMax = 6,

  /// 一道菜最多几个口味.
  final int tagsMax = 3,

  /// 一家店最多几道招牌菜.
  final int signaturesMax = 3,
});

/// 根据菜名, 说明与照片识别出的分类及口味建议, 需经用户确认后再提交.
///
/// 若识别出未知分类, 则 [category] 为 null.
class const DishSuggestion({
  final DishCategory? category,
  final List<Taste> tags = const [],
});
