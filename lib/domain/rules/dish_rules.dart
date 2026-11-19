import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';

/// 菜品在舞台, 转盘和餐厅详情上的显示规则.
abstract final class DishRules {
  /// 舞台菜名每行的最大字数.
  static const lineLength = 4;

  /// 断行时不拆开的常见结尾词.
  static const _tails = [
    '煎饼果子',
    '螺蛳粉',
    '酸辣粉',
    '麻辣烫',
    '肉夹馍',
    '排骨汤',
    '云吞',
    '馄饨',
    '米线',
    '拉面',
    '盖饭',
    '炒饭',
    '套餐',
  ];

  // TODO: 客户端缺少中文分词能力无法按词断行, 目前按字数均分. 后端在发布接口返回断行位置后改用该结果, 并删除 [_tails].
  /// 把菜名断成每行不超过 [lineLength] 个字的若干行.
  ///
  /// 各行字数尽量相等. 菜名以 [_tails] 中的词结尾时, 该词不拆到两行.
  static List<String> stageLines(String name) {
    final chars = name.trim().runes.map(String.fromCharCode).toList();
    if (chars.length <= lineLength) return [chars.join()];
    final lines = (chars.length / lineLength).ceil();
    final base = chars.length ~/ lines;
    var extra = chars.length % lines;
    final sizes = [
      for (var i = 0; i < lines; i++) base + (extra-- > 0 ? 1 : 0),
    ];
    // 结尾词被拆到两行时, 把整个结尾词移到最后一行: 最后一行增加相应字数, 倒数第二行减少相应字数.
    final text = chars.join();
    for (final tail in _tails) {
      if (!text.endsWith(tail) || tail.length > lineLength) continue;
      final last = sizes.last;
      if (last >= tail.length) break;
      final need = tail.length - last;
      if (sizes[sizes.length - 2] - need < 1) break;
      sizes[sizes.length - 2] -= need;
      sizes[sizes.length - 1] += need;
      break;
    }
    final result = <String>[];
    var start = 0;
    for (final size in sizes) {
      result.add(chars.sublist(start, start + size).join());
      start += size;
    }
    return result;
  }

  /// 评分的可选分值, 从低到高.
  static const scores = [1, 2, 3, 4, 5];

  /// 1 到 5 分各自的说法, 打分时写在星星下面.
  static const scoreWords = ['不好吃', '一般', '还行', '好吃', '必吃'];

  /// 平均分的文字, 如 "4.3 分". 有人评过就写, 没人评过 (没有平均分) 时返回 null.
  static String? scoreText(DishRating rating) {
    final score = rating.score;
    if (score == null || rating.count == 0) return null;
    return '${score.toStringAsFixed(1)} 分';
  }

  /// 菜品评分统计的说明, 如 "4.3 分，12 人评过"; 没人评过时写 "还没人评分".
  static String ratingSummary(DishRating rating) => switch (scoreText(rating)) {
    final score? => '$score，${rating.count} 人评过',
    null when rating.count == 0 => '还没人评分',
    null => '${rating.count} 人评过',
  };

  /// 菜品未保存舞台色时的兜底颜色, 优先取分类默认色, 无分类时使用 `broth`.
  static StageColor defaultStage(DishCategory? category) =>
      category?.stage ?? StageColor.broth;

  /// 转盘上每道菜实际使用的舞台色.
  ///
  /// 与前一道菜撞色时依次尝试该菜的备选色, 全部撞色则保持原色.
  /// 替换只影响转盘显示, 不修改菜品保存的舞台色.
  static List<StageColor> turntableColors(List<Dish> dishes) {
    final colors = <StageColor>[];
    for (final dish in dishes) {
      final previous = colors.isEmpty ? null : colors.last;
      final candidates = [dish.stage, ...dish.stageAlternates];
      colors.add(
        candidates.firstWhere(
          (color) => color != previous,
          orElse: () => dish.stage,
        ),
      );
    }
    return colors;
  }

  /// 价格的显示文字, 如 "¥ 18" "¥ 18.5", 符号和数字之间隔一个空格. 没有价格时返回 null.
  static String? priceText(double? price) {
    if (price == null) return null;
    final fixed = price.toStringAsFixed(1);
    return '¥ ${fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed}';
  }

  /// 获赞最多的 [count] 道菜, 用于个人主页的舞台.
  ///
  /// 与招牌菜无关: 招牌菜由编辑者标记, 见 [Dish.signature].
  static List<Dish> mostLiked(List<Dish> dishes, {int count = 3}) {
    final sorted = [...dishes]..sort((a, b) => b.likes.compareTo(a.likes));
    return sorted.take(count).toList();
  }
}
