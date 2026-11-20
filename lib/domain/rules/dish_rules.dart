import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';

/// 菜品在舞台, 转盘和餐厅详情上的显示规则.
abstract final class DishRules {
  /// 舞台菜名每行的最大字数.
  static const lineLength = 4;

  /// 把菜名断成每行不超过 [lineLength] 个字的若干行.
  ///
  /// 按字数均分, 不分词: 各行字数尽量相等, 除不尽时多出的字放在前面几行. 标点的处理见 [splitEvenly].
  static List<String> stageLines(String name) {
    final chars = name.trim().runes.map(String.fromCharCode).toList();
    if (chars.length <= lineLength) return [chars.join()];
    return splitEvenly(
      chars,
      (chars.length / lineLength).ceil(),
      maxLength: lineLength,
    );
  }

  /// 把 [chars] 均分成 [count] 行, 再让闭合标点不在行首, 开启标点不在行尾.
  ///
  /// 均分后检查行与行的分界, 落在标点上的分界只向前或向后移动一个字. 闭合标点优先并到上一行,
  /// 开启标点优先移到下一行, 若不满足则向另一边移动. 移动后有一行超过 [maxLength] 字,
  /// 或新分界仍落在标点上, 这个分界保持均分的位置.
  ///
  /// 只移动一个字是为了不引入分词, 断行仍接近均分. 一个分界移动后, 相邻分界可能因此腾出字数,
  /// 所以重复检查直到没有分界变化. 移动过的分界已不落在标点上, 之后不再移动, 循环一定结束.
  ///
  /// 行数不变. 店名超长时调用方传入均分后的最长行作 [maxLength], 页面的字号不变.
  static List<String> splitEvenly(
    List<String> chars,
    int count, {
    required int maxLength,
  }) {
    final base = chars.length ~/ count;
    final extra = chars.length % count;
    final ends = <int>[];
    var end = 0;
    for (var i = 0; i < count - 1; i++) {
      end += base + (i < extra ? 1 : 0);
      ends.add(end);
    }
    var changed = true;
    while (changed) {
      changed = false;
      for (var i = 0; i < ends.length; i++) {
        final at = ends[i];
        if (_canBreakAt(chars, at)) continue;
        final previous = i == 0 ? 0 : ends[i - 1];
        final next = i == ends.length - 1 ? chars.length : ends[i + 1];
        final shifts = _closing.contains(chars[at])
            ? const [1, -1]
            : const [-1, 1];
        for (final shift in shifts) {
          final moved = at + shift;
          final before = moved - previous;
          final after = next - moved;
          if (before < 1 || before > maxLength) continue;
          if (after < 1 || after > maxLength) continue;
          if (!_canBreakAt(chars, moved)) continue;
          ends[i] = moved;
          changed = true;
          break;
        }
      }
    }
    final result = <String>[];
    var start = 0;
    for (final end in [...ends, chars.length]) {
      result.add(chars.sublist(start, end).join());
      start = end;
    }
    return result;
  }

  /// 在第 [at] 个字之前断行时, 下一行不以闭合标点开头, 上一行不以开启标点结尾.
  static bool _canBreakAt(List<String> chars, int at) =>
      !_closing.contains(chars[at]) && !_opening.contains(chars[at - 1]);

  /// 不放在行首的闭合标点, 中英文都算. 每个字符是一个标点.
  ///
  /// 直引号 `"` `'` 分不出开闭, 不收录.
  static const _closing = ')]}）］｝】」』》〉〕〗”’、，。．！？：；％…,.!?:;%';

  /// 不放在行尾的开启标点, 中英文都算. 每个字符是一个标点.
  static const _opening = '([{（［｛【「『《〈〔〖“‘';

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
