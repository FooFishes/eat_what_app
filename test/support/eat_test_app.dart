import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_stage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 把组件放入挂载主题的 App 中居中显示. 传入 [stage] 时, 组件放在该舞台色上.
Future<void> pumpEat(
  WidgetTester tester,
  Widget child, {
  StageColor? stage,
  bool disableAnimations = false,
}) {
  Widget body = Center(child: child);
  if (stage != null) body = EatStage(stage: stage, child: body);
  return tester.pumpWidget(
    MaterialApp(
      theme: eatThemeData(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(body: body),
    ),
  );
}

/// 检查设计规范的两条无障碍要求:
/// - 点击区域不小于 44px.
/// - 可点击元素都有语义说明.
Future<void> expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}
