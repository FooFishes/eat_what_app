import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_palette.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/dish_tile.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_search_field.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/eat_test_app.dart';

/// 生成 [width]×[height] 的纯色 PNG, 用于测试加载和裁切.
Future<MemoryImage> _solidImage(WidgetTester tester, int width, int height) =>
    tester
        .runAsync(() async {
          final recorder = ui.PictureRecorder();
          Canvas(recorder).drawRect(
            Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
            Paint()..color = const Color(0xFFD9632B),
          );
          final image = await recorder.endRecording().toImage(width, height);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          return MemoryImage(Uint8List.view(bytes!.buffer));
        })
        .then((image) => image!);

void main() {
  group('EatListRow', () {
    testWidgets('整行可点，右边的按钮单独可点', (tester) async {
      var rowTaps = 0;
      var actionTaps = 0;
      await pumpEat(
        tester,
        SizedBox(
          width: 360,
          child: EatListRow(
            leading: const ListThumb(image: null, size: 56),
            title: const Text('红烧肉'),
            lines: const [Text('64 人收藏')],
            action: EatButton.mist(
              '回关',
              height: 36,
              onPressed: () => actionTaps++,
            ),
            onTap: () => rowTaps++,
          ),
        ),
      );

      await tester.tap(find.text('红烧肉'));
      await tester.tap(find.text('回关'));
      expect((rowTaps, actionTaps), (1, 1));
    });

    testWidgets('未读时行首有圆点，读屏读「未读」', (tester) async {
      await pumpEat(
        tester,
        SizedBox(
          width: 360,
          child: EatListRow(
            leading: const EatAvatar(name: '小林', color: StageColor.broth),
            title: const Text('小林 收藏了你上传的玉米排骨汤'),
            lines: const [Text('12 分钟前')],
            unread: true,
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(UnreadDot), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('未读')), findsOneWidget);
      expect(find.text('林'), findsNothing, reason: '头像只取第一个字');
      expect(find.text('小'), findsOneWidget);
    });
  });

  group('输入框', () {
    testWidgets('搜索框输入回调，筛选按钮有说明', (tester) async {
      final typed = <String>[];
      var filters = 0;
      await pumpEat(
        tester,
        SizedBox(
          width: 360,
          child: EatSearchField(
            hintText: '搜店名或菜名',
            onChanged: typed.add,
            onFilter: () => filters++,
            floating: true,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '螺蛳粉');
      await tester.tap(find.bySemanticsLabel('筛选'));
      expect(typed, ['螺蛳粉']);
      expect(filters, 1);
      expect(tester.getSize(find.byType(EatSearchField)).height, 48);
    });

    testWidgets('搜索框输入了内容才有清空按钮，点了清空并回调空串', (tester) async {
      final typed = <String>[];
      await pumpEat(
        tester,
        SizedBox(
          width: 360,
          child: EatSearchField(hintText: '搜菜名或店名', onChanged: typed.add),
        ),
      );

      expect(find.bySemanticsLabel('清空'), findsNothing);
      await tester.enterText(find.byType(TextField), '螺蛳粉');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('清空'));
      await tester.pump();
      expect(typed, ['螺蛳粉', '']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      expect(find.bySemanticsLabel('清空'), findsNothing);
    });

    testWidgets('价格只能输数字和小数点，前面带 ¥', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpEat(
        tester,
        SizedBox(
          width: 104,
          child: EatFormField.price(label: '价格', controller: controller),
        ),
      );

      await tester.enterText(find.byType(TextField), '1a6.5元');
      expect(controller.text, '16.5');
      expect(find.text('¥'), findsOneWidget);
    });

    testWidgets('下划线平时 handle，聚焦变 ink，出错变 warn 并写出说明', (tester) async {
      Color line() {
        final box = tester.widget<Container>(
          find.descendant(
            of: find.byType(EatFormField),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration is BoxDecoration,
            ),
          ),
        );
        return ((box.decoration! as BoxDecoration).border! as Border)
            .bottom
            .color;
      }

      await pumpEat(
        tester,
        const SizedBox(
          width: 300,
          child: EatFormField(label: '菜名', hintText: '叫什么'),
        ),
      );
      expect(line(), EatPalette.handle);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(line(), EatPalette.ink);

      await pumpEat(
        tester,
        const SizedBox(
          width: 300,
          child: EatFormField(label: '菜名', errorText: '请填写菜名'),
        ),
      );
      expect(line(), EatPalette.warn);
      expect(find.text('请填写菜名'), findsOneWidget);
    });
  });

  group('DishPlate', () {
    testWidgets('图片没加载出来时是 mist 底，加载后画出来', (tester) async {
      final image = await _solidImage(tester, 300, 200);
      await pumpEat(tester, DishPlate(image: image, size: 160));

      final plate = tester.widget<Container>(
        find.descendant(
          of: find.byType(DishPlate),
          matching: find.byType(Container),
        ),
      );
      final decoration = plate.decoration! as BoxDecoration;
      expect(decoration.color, EatPalette.mist);
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.boxShadow!.last.spreadRadius, DishPlate.rimFor(160));

      await tester.runAsync(
        () => precacheImage(image, tester.element(find.byType(DishPlate))),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(DishPlate),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
    });

    testWidgets('舞台主图是装饰，单独出现时才读替代文字', (tester) async {
      final image = await _solidImage(tester, 10, 10);
      await pumpEat(tester, DishPlate(image: image, semanticLabel: '柳州螺蛳粉'));
      expect(find.bySemanticsLabel('柳州螺蛳粉'), findsOneWidget);
    });
  });

  testWidgets('DishTile 整块可点，「我的」里显示赞数', (tester) async {
    var taps = 0;
    await pumpEat(
      tester,
      SizedBox(
        width: 170,
        child: DishTile(
          image: null,
          name: '铁锅炖大鹅',
          likes: 23,
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byType(DishTile));
    expect(taps, 1);
    expect(find.text('23'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('23 个赞')), findsOneWidget);
  });

  testWidgets('DishTile 菜名在左价格在右，店名和距离在第二行', (tester) async {
    await pumpEat(
      tester,
      SizedBox(
        width: 170,
        child: DishTile(
          image: null,
          name: '老坛酸菜牛肉手擀宽面加蛋',
          price: '¥19.5',
          shop: '鲁味面食档',
          distance: '70 m',
          onTap: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull, reason: '菜名再长也只截断菜名');
    final name = tester.getRect(find.text('老坛酸菜牛肉手擀宽面加蛋'));
    final price = tester.getRect(find.text('¥19.5'));
    expect(price.left, greaterThan(name.right - 1));
    expect(
      price.right,
      closeTo(tester.getRect(find.byType(DishTile)).right, 1),
    );
    expect(tester.getTopLeft(find.text('鲁味面食档')).dy, greaterThan(name.top));
    expect(find.text('70 m'), findsOneWidget);
  });

  testWidgets('DishTile 窄版：图片是正方形，价格挪到第二行，菜名独占一行', (tester) async {
    await pumpEat(
      tester,
      SizedBox(
        width: 108,
        child: DishTile(
          image: null,
          name: '红烧肉盖饭',
          price: '¥15',
          likes: 412,
          compact: true,
          onTap: () {},
        ),
      ),
    );

    final image = tester.getSize(find.byType(CoverImage));
    expect(image.width, image.height);
    expect(
      tester.getTopLeft(find.text('¥15')).dy,
      greaterThan(tester.getTopLeft(find.text('红烧肉盖饭')).dy),
    );
    expect(
      tester.getSize(find.text('红烧肉盖饭')).width,
      greaterThan(70),
      reason: '价格不和菜名抢一行',
    );
  });

  testWidgets('没有图片时 mist 底上有图片图标，小图只有底色', (tester) async {
    await pumpEat(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(dimension: 150, child: CoverImage(image: null)),
          SizedBox.square(dimension: 28, child: CoverImage(image: null)),
        ],
      ),
    );

    expect(find.byType(EatIcon), findsOneWidget);
    expect(tester.widget<EatIcon>(find.byType(EatIcon)).icon, EatIcons.image);
  });

  group('状态占位', () {
    testWidgets('失败时「加载失败」加「重试」', (tester) async {
      var retries = 0;
      await pumpEat(tester, FailureState(onRetry: () => retries++));

      expect(find.text('加载失败'), findsOneWidget);
      await tester.tap(find.text('重试'));
      expect(retries, 1);
      await expectAccessible(tester);
    });

    testWidgets('加载中的色块读屏只报一次「加载中」', (tester) async {
      await pumpEat(
        tester,
        const LoadingArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Skeleton.circle(size: 64),
              Skeleton.line(width: 120),
              Skeleton(width: 170, height: 150),
            ],
          ),
        ),
      );

      expect(find.bySemanticsLabel('加载中'), findsOneWidget);
    });

    testWidgets('空状态说清下一步，按钮可点', (tester) async {
      var taps = 0;
      await pumpEat(
        tester,
        EmptyState(
          icon: EatIcons.search,
          title: '没找到「螺蛳粉」',
          message: '换个词试试。要是这家店还没人建过，你来建第一个。',
          action: EatButton.outline(
            '新建一家店',
            icon: EatIcons.add,
            height: 48,
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('新建一家店'));
      expect(taps, 1);
      await expectAccessible(tester);
    });
  });
}
