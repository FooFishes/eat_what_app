import 'dart:ui' show Tristate;

import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/widgets/like_heart.dart';
import 'package:eat/design/widgets/morph_card.dart';
import 'package:eat/design/widgets/star_rating.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/eat_test_app.dart';

void main() {
  group('StarRating', () {
    Future<List<int>> pump(WidgetTester tester, {int? value}) async {
      final picked = <int>[];
      await pumpEat(
        tester,
        StatefulBuilder(
          builder: (context, setState) => StarRating(
            value: value,
            labels: const ['不好吃', '一般', '还行', '好吃', '必吃'],
            onChanged: (score) {
              picked.add(score);
              setState(() => value = score);
            },
          ),
        ),
      );
      return picked;
    }

    testWidgets('每颗星是一个按钮，点第 n 颗选 n 分，下面写这个分数的说法', (tester) async {
      final picked = await pump(tester);
      expect(find.bySemanticsLabel(RegExp(r'^\d 分$')), findsNWidgets(5));
      await expectAccessible(tester);

      await tester.tap(find.bySemanticsLabel('4 分'));
      await tester.pumpAndSettle();
      expect(picked, [4]);
      expect(find.text('好吃'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('4 分'))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
    });

    testWidgets('按住左右滑，松手时选中手指所在的那颗', (tester) async {
      final picked = await pump(tester);
      final first = tester.getCenter(find.bySemanticsLabel('1 分'));
      final last = tester.getCenter(find.bySemanticsLabel('5 分'));

      final gesture = await tester.startGesture(first);
      await gesture.moveTo(Offset.lerp(first, last, 0.3)!);
      await gesture.moveTo(last);
      await tester.pump();
      expect(find.text('必吃'), findsOneWidget, reason: '滑动时说法跟着变');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(picked, [5]);
    });

    testWidgets('只展示时一排小星，不接点击，读屏不读', (tester) async {
      await pumpEat(tester, const StarRating(value: 3, size: 14));
      expect(find.bySemanticsLabel(RegExp('分')), findsNothing);
    });
  });

  group('LikeHeart', () {
    testWidgets('赞上换成实心并播放弹跳，取消换回空心', (tester) async {
      var liked = false;
      late StateSetter set;
      await pumpEat(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return LikeHeart(liked: liked);
          },
        ),
      );
      EatIcons icon() => tester.widget<EatIcon>(find.byType(EatIcon)).icon;
      expect(icon(), EatIcons.heart);

      set(() => liked = true);
      // 第一帧起表, 再过 200ms 正在放大.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(icon(), EatIcons.heartOn);
      final mid = tester.widget<Transform>(
        find.ancestor(
          of: find.byType(EatIcon),
          matching: find.byType(Transform),
        ),
      );
      expect(mid.transform.getMaxScaleOnAxis(), greaterThan(1), reason: '弹起来');
      await tester.pumpAndSettle();

      set(() => liked = false);
      await tester.pumpAndSettle();
      expect(icon(), EatIcons.heart);
    });
  });

  group('showMorphCard', () {
    testWidgets('从那一格展开成卡片，点卡片外面收回', (tester) async {
      final origin = GlobalKey();
      await pumpEat(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showMorphCard<void>(
              context,
              origin: origin,
              from: const Color(0xFFEEEEEE),
              height: 200,
              face: (_) => const Text('格子'),
              builder: (_) => const Text('卡片内容'),
            ),
            child: SizedBox(key: origin, width: 100, height: 60),
          ),
        ),
      );

      await tester.tap(find.byKey(origin));
      // 新路由的第一帧在台下布局, 第二帧起才看得见.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('格子'), findsOneWidget, reason: '开头画的是那一格原来的样子');
      await tester.pumpAndSettle();
      expect(find.text('格子'), findsNothing);
      expect(find.text('卡片内容'), findsOneWidget);
      final card = tester.getRect(find.text('卡片内容'));
      expect(card.width, greaterThan(100));

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('卡片内容'), findsNothing);
    });
  });
}
