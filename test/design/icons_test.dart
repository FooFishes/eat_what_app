import 'dart:io';

import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/icons/illustrations.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_graphics/vector_graphics.dart';

const _strokeBySize = {14: '2.6', 16: '2.4', 18: '2.13'};

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

    test('assets/icons/ 和设计稿的图标一致（改了设计稿要重跑 tool/icons.dart）', () {
      expect(_svgNames('assets/icons'), _svgNames('prototype/assets/icons'));
      for (final icon in EatIcons.values) {
        final name = '${icon.file}.svg';
        expect(
          File('assets/icons/$name').readAsStringSync(),
          File('prototype/assets/icons/$name').readAsStringSync(),
          reason: name,
        );
      }
    });

    test('描边图标有三套加粗变体，填充图标没有', () {
      for (final icon in EatIcons.values) {
        final base = File('assets/icons/${icon.file}.svg').readAsStringSync();
        expect(
          base.contains('stroke-width="2"'),
          icon.stroked,
          reason: '${icon.name} 的 stroked 和文件对不上',
        );
        for (final MapEntry(key: size, value: stroke)
            in _strokeBySize.entries) {
          final variant = File('assets/icons/$size/${icon.file}.svg');
          expect(variant.existsSync(), icon.stroked, reason: variant.path);
          if (icon.stroked) {
            expect(
              variant.readAsStringSync(),
              base.replaceAll('stroke-width="2"', 'stroke-width="$stroke"'),
            );
          }
        }
      }
    });

    test('Illustration 和 assets/illustrations/ 一一对应，内容和设计稿一致', () {
      expect(
        Illustration.values.map((art) => '${art.name}.svg').toSet(),
        _svgNames('assets/illustrations'),
      );
      for (final art in Illustration.values) {
        expect(
          File(art.asset).readAsStringSync(),
          File('prototype/assets/dishes/${art.name}.svg').readAsStringSync(),
          reason: art.name,
        );
      }
    });

    test('构建时图标被预编译成二进制', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final bytes = await rootBundle.load('assets/icons/search.svg');
      final head = String.fromCharCodes(bytes.buffer.asUint8List(0, 4));
      expect(head, isNot('<svg'));
    });
  });

  test('20px 以下换成加粗变体，填充图标始终用原图', () {
    expect(EatIcons.search.assetFor(24), 'assets/icons/search.svg');
    expect(EatIcons.search.assetFor(20), 'assets/icons/search.svg');
    expect(EatIcons.search.assetFor(18), 'assets/icons/18/search.svg');
    expect(EatIcons.search.assetFor(16), 'assets/icons/16/search.svg');
    expect(EatIcons.search.assetFor(14), 'assets/icons/14/search.svg');
    expect(EatIcons.search.assetFor(12), 'assets/icons/14/search.svg');
    expect(
      EatIcons.chevronRight.assetFor(16),
      'assets/icons/16/chevron-right.svg',
    );
    expect(EatIcons.heartOn.assetFor(14), 'assets/icons/heart-on.svg');
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

    testWidgets('颜色跟着所在文字，按尺寸取资源', (tester) async {
      await pump(tester, const EatIcon(EatIcons.search, size: 16));

      final svg = picture(tester);
      expect(
        (svg.bytesLoader as AssetBytesLoader).assetName,
        'assets/icons/16/search.svg',
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
