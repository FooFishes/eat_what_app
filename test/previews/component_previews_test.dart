import 'package:eat_what_app/app/shell/widgets/custom_bottom_navigation_bar.dart';
import 'package:eat_what_app/features/upload/presentation/widgets/editable_image_grid.dart';
import 'package:eat_what_app/previews/component_previews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpPreview(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 380),
  double textScale = 1,
}) async {
  tester.view.reset();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, textScaler: .linear(textScale)),
      child: componentPreviewWrapper(child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 390.0, 600.0]) {
    testWidgets('底部导航在宽度 $width 下可切换选中项且无布局异常', (tester) async {
      await pumpPreview(
        tester,
        bottomNavigationPreview(),
        size: Size(width, 130),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<CustomBottomNavigationBar>(
              find.byType(CustomBottomNavigationBar),
            )
            .currentIndex,
        0,
      );
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CustomBottomNavigationBar>(
              find.byType(CustomBottomNavigationBar),
            )
            .currentIndex,
        4,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('较大字体的导航预览无溢出', (tester) async {
    await pumpPreview(
      tester,
      largeTextBottomNavigationPreview(),
      size: const Size(390, 150),
      textScale: 1.5,
    );
    expect(tester.takeException(), isNull);
  });

  for (final (preview, count) in [
    (emptyImageGridPreview, 0),
    (partialImageGridPreview, 2),
    (fullImageGridPreview, 9),
  ]) {
    testWidgets('图片网格初始 $count 张时可添加、删除并遵守九张上限', (tester) async {
      await pumpPreview(tester, preview());
      expect(tester.takeException(), isNull);
      EditableImageGrid grid() => tester.widget(find.byType(EditableImageGrid));
      expect(grid().images, hasLength(count));
      if (count < 9) {
        await tester.tap(find.text('添加照片'));
        await tester.pumpAndSettle();
        expect(grid().images, hasLength(count + 1));
      } else {
        expect(find.text('添加照片'), findsNothing);
      }
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();
      expect(grid().images, hasLength(count < 9 ? count : count - 1));
      expect(find.text('添加照片'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('窄屏图片网格在 1.5 倍字体下无溢出', (tester) async {
    await pumpPreview(
      tester,
      partialImageGridPreview(),
      size: const Size(320, 380),
      textScale: 1.5,
    );
    expect(tester.takeException(), isNull);
  });
}
