import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/shop_rules.dart';
import 'package:eat/features/discover/discover_providers.dart';
import 'package:flutter_test/flutter_test.dart';

Shop _shop(
  int id, {
  ShopKind kind = ShopKind.food,
  List<ShopCategory> categories = const [],
}) => Shop(
  id: id,
  name: '店$id',
  point: const GcjPoint(36.6681, 117.1412),
  kind: kind,
  categories: categories,
);

void main() {
  group('不想去这家后的转盘队列', () {
    final feed = TurntableFeed(
      shops: [for (var i = 1; i <= 10; i++) _shop(i)],
      index: 3,
      batchStarts: const [0, 8],
      page: 2,
    );

    test('去掉当前这家，停在下一家；批次起点前移', () {
      final next = feed.without(4);

      expect(next.shops.map((s) => s.id), [1, 2, 3, 5, 6, 7, 8, 9, 10]);
      expect(next.current?.id, 5);
      expect(next.batchStarts, [0, 7]);
      expect(next.batch, (start: 0, length: 7));
      expect(next.page, 2);
    });

    test('去掉前面的店，当前这家不变', () {
      final next = feed.without(1);

      expect(next.current?.id, 4);
      expect(next.index, 2);
    });

    test('去掉最后一家且正停在它上面，回到第一家；变空的批次不再算圆点', () {
      final last = TurntableFeed(
        shops: [for (var i = 1; i <= 9; i++) _shop(i)],
        index: 8,
        batchStarts: const [0, 8],
      );

      final next = last.without(9);

      expect(next.current?.id, 1);
      expect(next.batchStarts, [0]);
    });

    test('队列里没有这家时不变', () {
      expect(identical(feed.without(42), feed), isTrue);
    });
  });

  group('转盘的舞台色', () {
    test('按店铺品类映射；甜点饮品店用 porcelain，没有品类用 broth', () {
      final colors = turntableColors([
        _shop(1, categories: [ShopCategory.rice]),
        _shop(2, kind: ShopKind.drink),
        _shop(3),
      ]);

      expect(colors, [StageColor.soy, StageColor.porcelain, StageColor.broth]);
    });

    test('和前一家撞色时换用第二个品类的颜色，没有可换的保持原色', () {
      final colors = turntableColors([
        _shop(1, categories: [ShopCategory.rice]),
        _shop(2, categories: [ShopCategory.rice, ShopCategory.noodles]),
        _shop(3, categories: [ShopCategory.noodles]),
      ]);

      expect(colors, [StageColor.soy, StageColor.mango, StageColor.mango]);
    });
  });

  group('舞台上的店名断行', () {
    test('不超过四行时和菜名一样每行至多四个字', () {
      expect(ShopRules.stageLines('袁记云饺'), ['袁记云饺']);
      expect(ShopRules.stageLines('杨国福麻辣烫'), ['杨国福', '麻辣烫']);
      expect(ShopRules.stageLines('沙县小吃软件园万达金街店'), ['沙县小吃', '软件园万', '达金街店']);
    });

    test('更长的店名平分成四行', () {
      expect(ShopRules.stageLines('老北京炸酱面馆软件园万达金街二店').map((l) => l.length), [
        4,
        4,
        4,
        4,
      ]);
      final lines = ShopRules.stageLines('老北京炸酱面馆软件园万达金街第二店');
      expect(lines.join(), '老北京炸酱面馆软件园万达金街第二店');
      expect(lines.map((l) => l.length), [5, 4, 4, 4]);
      final longest = ShopRules.stageLines('一二三四五六七八九十一二三四五六七八九十');
      expect(longest.map((l) => l.length), [5, 5, 5, 5]);
    });

    test('标点不在行首或行尾', () {
      expect(ShopRules.stageLines('山东大学(软件园校区)食堂'), [
        '山东大学',
        '(软件',
        '园校区)',
        '食堂',
      ]);
      expect(ShopRules.stageLines('山东大学（软件园校区）食堂'), [
        '山东大学',
        '（软件',
        '园校区）',
        '食堂',
      ]);
    });

    test('更长的店名挪动标点时不超过均分后的最长行', () {
      expect(ShopRules.stageLines('沙县小吃(山东大学软件园校区二店)'), [
        '沙县小吃',
        '(山东大学',
        '软件园校',
        '区二店)',
      ]);
      expect(ShopRules.stageLines('沙县小吃(山东大学软件园校区金街第二店)'), [
        '沙县小吃(',
        '山东大学软',
        '件园校区金',
        '街第二店)',
      ]);
    });

    test('更长的店名在后一个分界移动后，前一个分界再移动', () {
      expect(ShopRules.stageLines('山东大学(软件园校区)学生在线办公室'), [
        '山东大学',
        '(软件园校',
        '区)学生在',
        '线办公室',
      ]);
    });
  });
}
