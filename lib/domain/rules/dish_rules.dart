import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';

/// 菜在舞台、转盘和餐厅详情上的显示规则。
abstract final class DishRules {
  /// 舞台菜名每行最多几个字（产品 6.4）。
  static const lineLength = 4;

  /// 一行里不拆开的常见结尾词（技术架构待确认 A15）。
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

  /// 把菜名断成每行不超过四个字的几行，尽量排得一样长，不把常见结尾词拆到两行。
  ///
  /// 「按词断行」要分词，客户端没有分词能力，先按字数平分兜底（技术架构待确认 A15）。
  static List<String> stageLines(String name) {
    final chars = name.trim().runes.map(String.fromCharCode).toList();
    if (chars.length <= lineLength) return [chars.join()];
    final lines = (chars.length / lineLength).ceil();
    final base = chars.length ~/ lines;
    var extra = chars.length % lines;
    final sizes = [
      for (var i = 0; i < lines; i++) base + (extra-- > 0 ? 1 : 0),
    ];
    // 结尾词被拆开时，把它整个挪到最后一行：最后一行补上、前一行让出。
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

  /// 转盘上每道菜实际用的舞台色：和前一道撞色时临时用自己的第一个备选色，不改保存的值（产品 4.7）。
  /// 备选色也撞了就再往后找；都撞了就保持原色。
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

  /// 价格写成「¥18」「¥18.5」，没有价格返回 null。
  static String? priceText(double? price) {
    if (price == null) return null;
    final fixed = price.toStringAsFixed(1);
    return '¥${fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed}';
  }

  /// 招牌菜：获赞最多的 [count] 道（产品 4.2）。
  static List<Dish> signatures(List<Dish> dishes, {int count = 3}) {
    final sorted = [...dishes]..sort((a, b) => b.likes.compareTo(a.likes));
    return sorted.take(count).toList();
  }

  /// 一家店所有菜的口味标签按人数汇总，最多 [count] 个（产品 6.6）。
  static List<TasteTag> tasteSummary(List<Dish> dishes, {int count = 6}) {
    final totals = <int, TasteTag>{};
    for (final dish in dishes) {
      for (final tag in dish.tasteTags) {
        final sum = totals[tag.id];
        totals[tag.id] = TasteTag(
          id: tag.id,
          name: tag.name,
          count: (sum?.count ?? 0) + tag.count,
        );
      }
    }
    final sorted = totals.values.where((tag) => tag.count > 0).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return sorted.take(count).toList();
  }
}
