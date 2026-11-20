import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:flutter_test/flutter_test.dart';

Dish _dish(
  int id, {
  StageColor stage = StageColor.broth,
  List<StageColor> alternates = const [],
  int likes = 0,
}) => Dish(
  id: id,
  name: '菜$id',
  shopId: 1,
  stage: stage,
  stageAlternates: alternates,
  likes: likes,
);

void main() {
  group('舞台菜名断行', () {
    test('四个字以内一行', () {
      expect(DishRules.stageLines('铁锅炖'), ['铁锅炖']);
      expect(DishRules.stageLines('红烧排骨'), ['红烧排骨']);
    });

    test('按字数均分，每行不超过四个字，多出的字放在前面', () {
      expect(DishRules.stageLines('黄焖鸡米饭'), ['黄焖鸡', '米饭']);
      expect(DishRules.stageLines('柳州螺蛳粉'), ['柳州螺', '蛳粉']);
      expect(DishRules.stageLines('鲜虾蟹籽云吞'), ['鲜虾蟹', '籽云吞']);
      expect(DishRules.stageLines('番茄牛腩焖面条'), ['番茄牛腩', '焖面条']);
      expect(DishRules.stageLines('秘制酱香鸡腿饭加蛋'), ['秘制酱', '香鸡腿', '饭加蛋']);
      expect(DishRules.stageLines('秘制酱香鸡腿饭加蛋套餐'), ['秘制酱香', '鸡腿饭加', '蛋套餐']);
      expect(DishRules.stageLines('老坛酸菜牛肉面加蛋加肠粉'), ['老坛酸菜', '牛肉面加', '蛋加肠粉']);
    });

    test('首尾空白不算字数', () {
      expect(DishRules.stageLines('  红烧排骨  '), ['红烧排骨']);
    });

    test('闭合标点不在行首，并到上一行', () {
      expect(DishRules.stageLines('山东大学(软件园校区)食堂'), [
        '山东大学',
        '(软件',
        '园校区)',
        '食堂',
      ]);
      expect(DishRules.stageLines('山东大学（软件园校区）食堂'), [
        '山东大学',
        '（软件',
        '园校区）',
        '食堂',
      ]);
      expect(DishRules.stageLines('酸辣粉，加蛋'), ['酸辣粉，', '加蛋']);
    });

    test('开启标点不在行尾，推到下一行', () {
      expect(DishRules.stageLines('黄焖鸡(大份)'), ['黄焖鸡', '(大份)']);
      expect(DishRules.stageLines('黄焖鸡（大份）'), ['黄焖鸡', '（大份）']);
      expect(DishRules.stageLines('香辣鸡「微辣」'), ['香辣鸡', '「微辣」']);
    });

    test('后一个分界移动腾出字数后，前一个分界再移动', () {
      expect(DishRules.stageLines('鸡腿饭(加蛋加肠)套餐'), ['鸡腿饭', '(加蛋加', '肠)套餐']);
    });

    test('挪动标点会超过每行字数上限时保持均分', () {
      expect(DishRules.stageLines('鸡腿饭(大)加蛋'), ['鸡腿饭(', '大)加蛋']);
      expect(DishRules.stageLines('红烧排骨)加蛋饭'), ['红烧排骨', ')加蛋饭']);
    });

    test('splitEvenly 按传入的上限挪动标点', () {
      final chars = '鸡腿饭(大)加蛋'.split('');
      expect(DishRules.splitEvenly(chars, 2, maxLength: 5), ['鸡腿饭', '(大)加蛋']);
    });
  });

  test('转盘上相邻撞色时后一道换成备选色，不改保存的值', () {
    final dishes = [
      _dish(1, stage: StageColor.soy),
      _dish(2, stage: StageColor.soy, alternates: [StageColor.redoil]),
      _dish(
        3,
        stage: StageColor.redoil,
        alternates: [StageColor.redoil, StageColor.chili],
      ),
      _dish(4, stage: StageColor.broth),
    ];
    expect(DishRules.turntableColors(dishes), [
      StageColor.soy,
      StageColor.redoil,
      StageColor.chili,
      StageColor.broth,
    ]);
    expect(dishes[1].stage, StageColor.soy);
  });

  test('价格：整数不写小数，最多一位小数', () {
    expect(DishRules.priceText(18), '¥ 18');
    expect(DishRules.priceText(18.5), '¥ 18.5');
    expect(DishRules.priceText(null), isNull);
  });

  test('获赞最多的三道', () {
    final dishes = [
      _dish(1, likes: 3),
      _dish(2, likes: 40),
      _dish(3, likes: 12),
      _dish(4, likes: 1),
    ];
    expect(DishRules.mostLiked(dishes).map((d) => d.id), [2, 3, 1]);
  });

  test('没保存舞台色时用分类的默认色，没有分类时用 broth', () {
    expect(DishRules.defaultStage(DishCategory.staple), StageColor.broth);
    expect(DishRules.defaultStage(DishCategory.dish), StageColor.soy);
    expect(DishRules.defaultStage(DishCategory.snack), StageColor.chili);
    expect(DishRules.defaultStage(DishCategory.soup), StageColor.bamboo);
    expect(DishRules.defaultStage(DishCategory.drinkDessert), StageColor.mango);
    expect(DishRules.defaultStage(DishCategory.special), StageColor.matcha);
    expect(DishRules.defaultStage(null), StageColor.broth);
  });

  test('分类按中文原值解析，不认识的值为 null', () {
    expect(DishCategory.fromApi('饮品甜品'), DishCategory.drinkDessert);
    expect(DishCategory.fromApi(' 菜 '), DishCategory.dish);
    expect(DishCategory.fromApi('staple'), isNull);
    expect(DishCategory.fromApi(null), isNull);
  });
  group('评分', () {
    test('有人评过就显示平均分，保留一位小数', () {
      expect(
        DishRules.scoreText(const DishRating(score: 4.25, count: 3)),
        '4.3 分',
      );
      expect(
        DishRules.scoreText(const DishRating(score: 5, count: 3)),
        '5.0 分',
      );
      expect(
        DishRules.scoreText(const DishRating(score: 5, count: 1)),
        '5.0 分',
      );
      expect(DishRules.scoreText(const DishRating()), isNull);
    });

    test('统计说明：写平均分和人数，没人评过单独说', () {
      expect(
        DishRules.ratingSummary(const DishRating(score: 4.3, count: 12)),
        '4.3 分，12 人评过',
      );
      expect(
        DishRules.ratingSummary(const DishRating(score: 4, count: 2)),
        '4.0 分，2 人评过',
      );
      expect(DishRules.ratingSummary(const DishRating()), '还没人评分');
    });
  });
}
