import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/morph_popover.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/eat_test_app.dart';

/// 一条两项的分类栏, 再点选中项开关浮层; 浮层开着时点另一项, 浮层跟过去.
class _Harness extends StatefulWidget {
  const new({required this.dismissed});

  final List<String> dismissed;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final _anchors = [GlobalKey(), GlobalKey()];
  var _tab = 0;
  var _open = false;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 360,
    height: 400,
    child: Column(
      children: [
        MorphPopover(
          anchor: _open ? [_anchors[_tab]] : null,
          onDismiss: () {
            widget.dismissed.add('dismiss');
            setState(() => _open = false);
          },
          builder: (_) => Text(_tab == 0 ? '左边的选项' : '右边的选项'),
          child: EatTabs(
            tabs: const [
              EatTabItem('左', indicator: '已筛选'),
              EatTabItem('右'),
            ],
            selected: _tab,
            onSelected: (i) => setState(() => _tab = i),
            onReselect: (_) => setState(() => _open = !_open),
            reselectHint: '筛选',
            expanded: _open,
            anchors: _anchors,
          ),
        ),
        const Expanded(child: Center(child: Text('外面'))),
      ],
    ),
  );
}

void main() {
  testWidgets('分类栏：点选中项回调再点一次，只有选中项带箭头，小圆点读出说明', (tester) async {
    final semantics = tester.ensureSemantics();
    final selected = <int>[];
    final reselected = <int>[];
    await pumpEat(
      tester,
      SizedBox(
        width: 360,
        child: EatTabs(
          tabs: const [
            EatTabItem('菜', indicator: '午饭'),
            EatTabItem('店'),
          ],
          selected: 0,
          onSelected: selected.add,
          onReselect: reselected.add,
          reselectHint: '筛选',
        ),
      ),
    );

    expect(find.byType(EatIcon), findsOneWidget);
    expect(
      tester.widget<EatIcon>(find.byType(EatIcon)).icon,
      EatIcons.chevronDown,
    );
    expect(find.bySemanticsLabel(RegExp('午饭')), findsOneWidget);
    await tester.tap(find.text('菜'));
    await tester.tap(find.text('店'));
    expect(reselected, [0]);
    expect(selected, [1]);
    semantics.dispose();
  });

  testWidgets('发现页的三个分类带箭头和小圆点时，390 宽的手机上仍三格等宽、字在格里居中', (tester) async {
    await pumpEat(
      tester,
      SizedBox(
        width: 390,
        child: EatTabs(
          tabs: const [
            EatTabItem('美食', icon: EatIcons.bowl, indicator: '推荐率'),
            EatTabItem('甜点饮品', icon: EatIcons.drink),
            EatTabItem('自助', icon: EatIcons.buffet),
          ],
          selected: 0,
          onSelected: (_) {},
          onReselect: (_) {},
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (w) => w is EatIcon && w.icon == EatIcons.chevronDown,
      ),
      findsOneWidget,
    );
    final left = tester.getTopLeft(find.byType(EatTabs)).dx + 20;
    const column = (390 - 40) / 3;
    for (final (i, label) in ['甜点饮品', '自助'].indexed) {
      // 没选中的项里只有图标和字, 两者一起在格里居中.
      final icon = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is EatIcon && w.icon == [EatIcons.drink, EatIcons.buffet][i],
        ),
      );
      final text = tester.getRect(find.text(label));
      final center = (icon.left + text.right) / 2;
      expect(center, closeTo(left + column * (i + 1.5), 1));
    }
  });
  testWidgets('浮层从选中项长出来，停在它下面；点分类栏不收，点外面收起', (tester) async {
    final dismissed = <String>[];
    await pumpEat(tester, _Harness(dismissed: dismissed));
    expect(find.text('左边的选项'), findsNothing);

    await tester.tap(find.text('左'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final early = tester.getTopLeft(find.text('左边的选项'));
    await tester.pumpAndSettle();
    final settled = tester.getTopLeft(find.text('左边的选项'));
    final tab = tester.getRect(find.text('左'));
    expect(early, isNot(settled), reason: '浮层从分类那一项的位置过渡过来');
    expect(settled.dy, greaterThan(tab.bottom));
    expect(tester.getTopLeft(find.byType(EatTabs)).dx, lessThan(settled.dx));

    // 分类栏和浮层算一个整体, 点分类栏不算点外面.
    await tester.tap(find.text('右'));
    await tester.pumpAndSettle();
    expect(dismissed, isEmpty);
    expect(find.text('右边的选项'), findsOneWidget);
    expect(find.text('左边的选项'), findsNothing);
    final moved = tester.getRect(find.text('右边的选项'));
    expect(moved.left, greaterThan(settled.dx), reason: '浮层跟到右边那一项下面');

    await tester.tap(find.text('外面'));
    await tester.pumpAndSettle();
    expect(dismissed, ['dismiss']);
    expect(find.text('右边的选项'), findsNothing);
  });

  testWidgets('浮层外面能点到页面上的东西，再点选中项收起', (tester) async {
    final dismissed = <String>[];
    var tapped = 0;
    await pumpEat(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Harness(dismissed: dismissed),
          TextButton(onPressed: () => tapped++, child: const Text('按钮')),
        ],
      ),
    );
    await tester.tap(find.text('左'));
    await tester.pumpAndSettle();
    expect(find.text('左边的选项'), findsOneWidget);

    await tester.tap(find.text('按钮'));
    await tester.pumpAndSettle();
    expect(tapped, 1, reason: '浮层不挡住页面');
    expect(dismissed, ['dismiss']);

    await tester.tap(find.text('左'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('左'));
    await tester.pumpAndSettle();
    expect(find.text('左边的选项'), findsNothing);
  });

  testWidgets('系统返回先收起浮层', (tester) async {
    final dismissed = <String>[];
    await pumpEat(tester, _Harness(dismissed: dismissed));
    await tester.tap(find.text('左'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(dismissed, ['dismiss']);
    expect(find.text('左边的选项'), findsNothing);
    expect(find.text('左'), findsOneWidget);
  });

  testWidgets('减少动态效果时直接出现', (tester) async {
    await pumpEat(tester, _Harness(dismissed: []), disableAnimations: true);
    await tester.tap(find.text('左'));
    await tester.pump();
    await tester.pump();
    expect(find.text('左边的选项').hitTestable(), findsOneWidget);
  });
}
