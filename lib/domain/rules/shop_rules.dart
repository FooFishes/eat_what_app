import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/geo_rules.dart';

/// 舞台和店铺行显示的推荐率. [percent] 是整数百分比, [count] 是该场景的评价条数.
typedef ShopRateView = ({RatingScene scene, int percent, int count});

/// 店铺的展示和填写规则: 舞台色, 推荐率, 品类和口味的上限, 同名查重半径.
///
/// 店名和地址描述的字数上限见 `PublishRules`.
abstract final class ShopRules {
  static const categoriesMax = 2;
  static const tastesMax = 3;

  /// 舞台上店名的最多行数. 菜名最多三行, 店名最长 20 字, 多给一行.
  static const nameMaxLines = 4;

  /// 店名在舞台上的断行. 最多 [nameMaxLines] 行.
  ///
  /// 断成不超过 [nameMaxLines] 行时沿用菜名的规则 (`DishRules.stageLines`).
  /// 更长的店名平分成 [nameMaxLines] 行, 每行超过四个字, 由页面缩小字号. 店名最长 20 字, 每行至多五个字.
  static List<String> stageLines(String name) {
    final lines = DishRules.stageLines(name);
    if (lines.length <= nameMaxLines) return lines;
    final chars = name.trim().runes.map(String.fromCharCode).toList();
    final base = chars.length ~/ nameMaxLines;
    final extra = chars.length % nameMaxLines;
    final result = <String>[];
    var start = 0;
    for (var i = 0; i < nameMaxLines; i++) {
      final size = base + (i < extra ? 1 : 0);
      result.add(chars.sublist(start, start + size).join());
      start += size;
    }
    return result;
  }

  /// 推荐率的显示门槛: 一个场景的评价满该条数才显示推荐率.
  ///
  /// 与搜店接口 `recommendedOnly` 的门槛相同, 附近页 "只看口碑好的" 筛出的店都能显示推荐率.
  static const rateMinCount = 3;

  /// 同名查重的半径, 单位米.
  ///
  /// 与后端相同: 该范围内已有同名的店时, 新建和改名都返回 40004.
  static const sameNameRadius = 100;

  /// 新建店时提示同名店的半径, 单位米. 该范围内有同名 (忽略空白) 的店时提示用户.
  static const sameNameHintRadius = 200;

  /// 新建店时, 附近的同名店 [same] 是否阻止提交. 阻止时用户只能选已有的店或改名.
  ///
  /// 与后端查重一致: 与新店位置 [point] 相距不超过 [sameNameRadius], 且店名去掉首尾空白后完全相同.
  /// 更远, 或店名只差中间的空白时只提示, 用户可以继续新建.
  static bool blocksNewShop(
    Shop same, {
    required String name,
    required GcjPoint point,
  }) =>
      same.name.trim() == name.trim() &&
      GeoRules.distance(point, same.point) <= sameNameRadius;

  // TODO: 后端不保存店铺的舞台色. 后端恢复舞台色后, 响应中有舞台色时优先使用.
  /// 店铺的舞台色, 按类型和第一个品类映射. 甜点饮品店用 `porcelain`, 没有品类时用 `broth`.
  ///
  /// 映射是纯函数, 同一家店在店铺页, 推荐卡片和各端的颜色一致.
  static StageColor stageOf(Shop shop) {
    if (shop.kind == ShopKind.drink) return StageColor.porcelain;
    return switch (shop.categories.firstOrNull) {
      ShopCategory.rice => StageColor.soy,
      ShopCategory.noodles => StageColor.mango,
      ShopCategory.hotPot => StageColor.redoil,
      ShopCategory.grill => StageColor.chili,
      ShopCategory.soup => StageColor.broth,
      ShopCategory.fastFood => StageColor.bamboo,
      null => StageColor.broth,
    };
  }

  static ShopStat statOf(Shop shop, RatingScene scene) => switch (scene) {
    RatingScene.dineIn => shop.dineIn,
    RatingScene.delivery => shop.delivery,
  };

  /// 舞台和店铺行显示的推荐率. 都不满 [rateMinCount] 条时为 null.
  ///
  /// 堂食满门槛时取堂食. 堂食不满而外卖满时取外卖, 外卖的推荐率比没有推荐率更有参考价值.
  static ShopRateView? rateOf(Shop shop) {
    for (final scene in RatingScene.values) {
      final stat = statOf(shop, scene);
      if (stat.count >= rateMinCount && stat.rate != null) {
        return (
          scene: scene,
          percent: (stat.rate! * 100).round(),
          count: stat.count,
        );
      }
    }
    return null;
  }

  /// 推荐率的文字, 如 "86% 推荐", 外卖的写作 "外卖 86% 推荐".
  static String rateText(ShopRateView rate) => switch (rate.scene) {
    RatingScene.dineIn => '${rate.percent}% 推荐',
    RatingScene.delivery => '外卖 ${rate.percent}% 推荐',
  };
}
