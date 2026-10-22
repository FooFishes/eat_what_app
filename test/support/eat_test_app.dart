import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_stage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 把组件放进挂好主题的 App 里，居中显示；传 [stage] 时放在那个舞台色上。
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

/// 设计规范的三条无障碍要求：点击区域不小于 44px、可点的东西都有说明、文字对比不低于 4.5:1。
Future<void> expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}
