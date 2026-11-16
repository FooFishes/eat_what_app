import 'dart:io';

import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/icons/emoji.dart';
import 'package:eat/design/icons/illustrations.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_graphics/vector_graphics.dart';

Set<String> _svgNames(String dir) =>
    Directory(dir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.svg'))
        .toSet();

void main() {
  group('资源', () {
    test('EatIcons 和 assets/icons/ 的文件一一对应', () {
      expect(
        EatIcons.values.map((icon) => '${icon.file}.svg').toSet(),
        _svgNames('assets/icons'),
      );
    });

    test('图标都跟随文字颜色，没有别的子目录', () {
      for (final icon in EatIcons.values) {
        expect(
          File(icon.asset).readAsStringSync(),
          contains('currentColor'),
          reason: icon.name,
        );
      }
      expect(
        Directory('assets/icons').listSync().whereType<Directory>(),
        isEmpty,
      );
    });

    test('Illustration 和 assets/illustrations/ 一一对应', () {
      expect(
        Illustration.values.map((art) => '${art.name}.svg').toSet(),
        _svgNames('assets/illustrations'),
      );
    });

    test('Emoji 和 assets/emoji/ 里的图片一一对应，每个都有动图和静态图', () {
      final images = Directory('assets/emoji')
          .listSync()
          .whereType<File>()
          .map((f) => 'assets/emoji/${f.uri.pathSegments.last}')
          .where((path) => path.endsWith('.webp'))
          .toSet();
      expect({
        for (final emoji in Emoji.values) ...[emoji.asset, emoji.still],
      }, images);
    });
  });

  group('EatIcon', () {
    SvgPicture picture(WidgetTester tester) =>
        tester.widget<SvgPicture>(find.byType(SvgPicture));

    Future<void> pump(WidgetTester tester, Widget icon) => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF123456)),
          child: Center(child: icon),
        ),
      ),
    );

    testWidgets('颜色跟着所在文字，任何尺寸都用同一个资源', (tester) async {
      await pump(tester, const EatIcon(EatIcons.search, size: 16));

      final svg = picture(tester);
      expect(
        (svg.bytesLoader as AssetBytesLoader).assetName,
        'assets/icons/search.svg',
      );
      expect(
        svg.colorFilter,
        const ColorFilter.mode(Color(0xFF123456), BlendMode.srcIn),
      );
      expect(tester.getSize(find.byType(EatIcon)), const Size(16, 16));
    });

    testWidgets('赞过的心形默认是 stage-tomato', (tester) async {
      await pump(tester, const EatIcon(EatIcons.heartOn));

      expect(
        picture(tester).colorFilter,
        ColorFilter.mode(StageColor.tomato.color, BlendMode.srcIn),
      );
    });

    testWidgets('写了说明才进读屏，否则是装饰', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const EatIcon(EatIcons.back, semanticLabel: '返回'));
      expect(find.bySemanticsLabel('返回'), findsOneWidget);

      await pump(tester, const EatIcon(EatIcons.back));
      expect(picture(tester).excludeFromSemantics, isTrue);
      semantics.dispose();
    });
  });
}
