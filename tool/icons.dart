/// 按 `EatIcons` 从 MingCute 官方的 `@mingcute/svg` 取图标, 生成 `assets/icons/`.
///
/// 用法: `fvm dart run tool/icons.dart`.
/// 增删图标或升级版本后重新运行. `test/design/icons_test.dart` 检查枚举和文件是否一一对应.
///
/// 从 npm 下载锁定版本的包, 用系统的 `tar` 解开, 文件原样复制, 只按用途改名.
/// npm 上已发布的版本不能修改, 锁定版本号即可保证每次生成的结果相同.
/// 官方许可证 (Apache-2.0) 一起复制, 启动时登记到系统的许可证页.
library;

import 'dart:io';

import 'package:eat/design/icons/eat_icons.dart';

const _version = '3.1.0';
const _tarball = 'https://registry.npmjs.org/@mingcute/svg/-/svg-$_version.tgz';
const _target = 'assets/icons';
const _license = 'assets/LICENSE-MingCute.txt';

Future<void> main() async {
  final temp = Directory.systemTemp.createTempSync('mingcute_svg_');
  try {
    final archive = File('${temp.path}/svg.tgz');
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(Uri.parse(_tarball))).close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          '下载失败: ${response.statusCode}',
          uri: Uri.parse(_tarball),
        );
      }
      await response.pipe(archive.openWrite());
    } finally {
      client.close();
    }
    final tar = Process.runSync('tar', [
      '-xzf',
      'svg.tgz',
    ], workingDirectory: temp.path);
    if (tar.exitCode != 0) throw ProcessException('tar', [], '${tar.stderr}');
    final package = '${temp.path}/package';

    final target = Directory(_target);
    if (target.existsSync()) target.deleteSync(recursive: true);
    target.createSync(recursive: true);
    for (final icon in EatIcons.values) {
      final style = icon.filled ? 'core-filled' : 'core-regular';
      final source = File('$package/$style/${icon.mingcute}.svg');
      if (!source.existsSync()) {
        throw StateError('${icon.name}: 官方包里没有 $style/${icon.mingcute}.svg');
      }
      source.copySync('$_target/${icon.file}.svg');
    }
    File('$package/LICENSE').copySync(_license);
    stdout.writeln(
      '从 @mingcute/svg $_version 生成了 ${EatIcons.values.length} 个图标。',
    );
  } finally {
    temp.deleteSync(recursive: true);
  }
}
