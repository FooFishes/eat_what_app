import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/dish_rules.dart';

/// 舞台和店铺行显示的推荐率. [percent] 是整数百分比, [count] 是该场景的评价条数.
typedef ShopRateView = ({RatingScene scene, int percent, int count});

/// 店铺的展示和填写规则: 舞台色, 推荐率, 品类和口味的上限, 同名查重半径.
///
/// 店名和地址描述的字数上限见 `PublishRules`.
abstract final class ShopRules {
  static const categoriesMax = 2;
  static const tastesMax = 3;

  /// 舞台上店名的最大显示行数. 因店名最长可达 20 字, 相比菜名 (最多 3 行) 额外增加一行.
  static const nameMaxLines = 4;

  /// 计算店名在舞台上的断行结果, 最多 [nameMaxLines] 行.
  ///
  /// 若按菜名规则 (`DishRules.stageLines`) 断行不超过 [nameMaxLines] 行则直接沿用; 更长的店名均分为 [nameMaxLines] 行 (每行最多 5 字), 超出 4 字时由页面缩小字号.
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

  // TODO: 后端暂不保存店铺的舞台色, 目前客户端按类型和品类映射. 后端恢复该字段且响应中返回舞台色后, 优先使用服务端取值.
  /// 店铺的舞台色, 按类型和第一个品类映射. 甜点饮品店用 `porcelain`, 美食店和自助店按品类, 没有品类时用 `broth`.
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
      ShopCategory.japaneseKorean || null => StageColor.broth,
    };
  }

  static ShopStat statOf(Shop shop, RatingScene scene) => switch (scene) {
    RatingScene.dineIn => shop.dineIn,
    RatingScene.delivery => shop.delivery,
  };

  /// 计算舞台和店铺行展示的推荐率, 两个场景评价均不足 [rateMinCount] 条时返回 null.
  ///
  /// 堂食评价达到门槛时优先展示堂食; 若堂食不足而外卖达标, 则降级展示外卖推荐率.
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
