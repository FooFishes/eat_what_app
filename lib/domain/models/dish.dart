import 'package:eat/design/tokens/stage_color.dart';
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

  /// 不认识的值返回 null, 调用方按没有分类处理. 后端只在末尾追加新分类.
  static DishCategory? fromApi(String? value) {
    final trimmed = value?.trim();
    for (final category in values) {
      if (category.api == trimmed) return category;
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

/// 菜品上的一个投票口味标签. [count] 是打过该标签的人数, [mine] 表示当前用户是否打过.
///
/// 后端 v2 没有口味投票接口, 只有保留的加标签面板使用.
class const TasteTag({
  required final int id,
  required final String name,
  final int count = 0,
  final bool mine = false,
});

/// 当前用户给菜品写的标签, 只有本人可见.
///
/// [usage] 是该标签用于多少道菜, 只有 "我的标签" 列表返回该值.
/// 后端 v2 没有我的标签接口, 只有保留的我的标签页使用.
class const MyTag({
  required final int id,
  required final String name,
  final int? usage,
});

/// 菜品. 菜品方块, 店铺菜单和详情页共用.
///
/// - [images] 的第一张是封面.
/// - [stage], [stageAlternates], [crop] 优先使用服务端保存的值.
///   服务端没有返回时, [stage] 取分类默认色, [crop] 取居中的短边内切圆.
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

  /// 口味, 最多 3 个, 由编辑者设置.
  final List<Taste> tags = const [],

  /// 是否招牌菜. 由编辑者标记, 每家店最多 3 道.
  final bool signature = false,
  final bool liked = false,
  final bool favorite = false,
  final int likes = 0,

  /// 首次发布者的账号. 用于判断是不是自己的菜和获取上传者资料, 账号已删除时为 null.
  final int? uploaderId,
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
  required final StageColor stage,
  required final List<StageColor> stageAlternates,
  final CoverCrop crop = const CoverCrop(),
  final List<Taste> tags = const [],
  final bool signature = false,
  final String? description,
});

/// 编辑菜品时提交的改动. 值为 null 的字段不修改.
///
/// - [description] 为空字符串表示清除.
/// - [imageKeys] 和 [tags] 为空列表表示清除.
/// - 菜品不能换店, 因此没有店铺字段.
///
/// [imageKeys] 是完整的新图片列表, 保留的原图也要传原来的存储 key, 第一张是封面.
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
});

/// 按菜名, 说明和照片识别出的分类和口味, 只是建议, 由用户确认后再提交.
///
/// 识别结果是不认识的分类时 [category] 为 null.
class const DishSuggestion({
  final DishCategory? category,
  final List<Taste> tags = const [],
});
