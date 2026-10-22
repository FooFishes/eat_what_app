/// 把 `prototype/assets/icons/` 的图标复制到 `assets/icons/`，并为描边图标生成小尺寸的加粗变体。
///
/// 用法：`fvm dart run tool/icons.dart`。设计稿增删图标后重跑，再同步 `EatIcons`；
/// `test/design/icons_test.dart` 会检查两边对得上。
///
/// 图标在 24 网格里是 2px 描边，缩到 20px 以下实际线宽不到 1.5px，看起来发虚。资源在构建时
/// 预编译成二进制，运行时改不了描边，所以预先生成 14、16、18 三套，分别用 2.6、2.4、2.13 的描边，
/// 让实际线宽保持在 1.5–1.6px。没有 `stroke-width="2"` 的图标（实心或本身就是填充轮廓）不生成变体。
library;

import 'dart:io';

const _source = 'prototype/assets/icons';
const _target = 'assets/icons';

const _strokeBySize = {14: '2.6', 16: '2.4', 18: '2.13'};

void main() {
  final source = Directory(_source);
  final target = Directory(_target);
  if (target.existsSync()) target.deleteSync(recursive: true);
  for (final size in _strokeBySize.keys) {
    Directory('$_target/$size').createSync(recursive: true);
  }

  final files =
      source
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.svg'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  var variants = 0;
  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final svg = file.readAsStringSync();
    File('$_target/$name').writeAsStringSync(svg);
    if (!svg.contains('stroke-width="2"')) continue;
    for (final MapEntry(key: size, value: stroke) in _strokeBySize.entries) {
      File('$_target/$size/$name').writeAsStringSync(
        svg.replaceAll('stroke-width="2"', 'stroke-width="$stroke"'),
      );
    }
    variants++;
  }
  stdout.writeln('复制了 ${files.length} 个图标，其中 $variants 个生成了 14、16、18 的加粗变体。');
}
