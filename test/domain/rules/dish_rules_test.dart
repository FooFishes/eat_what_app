import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:flutter_test/flutter_test.dart';

Dish _dish(
  int id, {
  StageColor stage = StageColor.broth,
  List<StageColor> alternates = const [],
  int likes = 0,
  List<TasteTag> tags = const [],
}) => Dish(
  id: id,
  name: '菜$id',
  shopId: 1,
  stage: stage,
  stageAlternates: alternates,
  likes: likes,
  tasteTags: tags,
);

void main() {
  group('舞台菜名断行', () {
    test('四个字以内一行', () {
      expect(DishRules.stageLines('铁锅炖'), ['铁锅炖']);
      expect(DishRules.stageLines('红烧排骨'), ['红烧排骨']);
    });

    test('每行不超过四个字，尽量一样长', () {
      expect(DishRules.stageLines('黄焖鸡米饭'), ['黄焖鸡', '米饭']);
      final lines = DishRules.stageLines('秘制酱香鸡腿饭加蛋套餐');
      expect(lines, hasLength(3));
      expect(lines.every((l) => l.length <= 4), isTrue);
    });

    test('常见结尾词不拆开', () {
      expect(DishRules.stageLines('柳州螺蛳粉'), ['柳州', '螺蛳粉']);
      expect(DishRules.stageLines('玉米排骨汤'), ['玉米', '排骨汤']);
      expect(DishRules.stageLines('鲜虾蟹籽云吞'), ['鲜虾蟹', '籽云吞']);
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
    expect(DishRules.priceText(18), '¥18');
    expect(DishRules.priceText(18.5), '¥18.5');
    expect(DishRules.priceText(null), isNull);
  });

  test('招牌是获赞最多的三道', () {
    final dishes = [
      _dish(1, likes: 3),
      _dish(2, likes: 40),
      _dish(3, likes: 12),
      _dish(4, likes: 1),
    ];
    expect(DishRules.signatures(dishes).map((d) => d.id), [2, 3, 1]);
  });

  test('一家店的口味标签按人数汇总，最多 6 个', () {
    final dishes = [
      _dish(
        1,
        tags: const [
          TasteTag(id: 1, name: '皮薄', count: 3),
          TasteTag(id: 2, name: '量大', count: 1),
        ],
      ),
      _dish(
        2,
        tags: const [
          TasteTag(id: 2, name: '量大', count: 5),
          TasteTag(id: 3, name: '排队久'),
        ],
      ),
    ];
    final summary = DishRules.tasteSummary(dishes);
    expect(summary.map((t) => (t.name, t.count)), [('量大', 6), ('皮薄', 3)]);
  });
}
