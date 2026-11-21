/// 用 `flutter_launcher_icons` 生成两套 App 图标: 默认的猪猪和备选的饭饭 (技术架构 16.4).
///
/// 用法: `fvm dart run tool/launcher_icons.dart`. 输入图由 `tool/app_icons.py` 生成, 换图后重新运行.
///
/// 插件只认一套图标, 第二套要脚本补位:
/// - 安卓自适应图标的前景图不管图标叫什么都写成 `ic_launcher_foreground`, 饭饭要改名, 否则会被猪猪覆盖.
/// - iOS 按名字新建图标时, 图片和 `Contents.json` 写进不同的目录, 还会把工程的主图标改成新名字.
///   所以饭饭先按默认图标生成, 再整个复制成 `AppIcon-Bun.appiconset`.
/// - 插件会改写 `project.pbxproj` 里所有 `ASSETCATALOG` 开头的设置, 运行后还原.
library;

import 'dart:io';

const _res = 'android/app/src/main/res';
const _iosAssets = 'ios/Runner/Assets.xcassets';
const _pbxproj = 'ios/Runner.xcodeproj/project.pbxproj';
const _manifest = 'web/manifest.json';
const _densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];

void main() {
  final pbxproj = File(_pbxproj).readAsStringSync();
  try {
    _generate('tool/app_icons/bun.yaml');
    for (final density in _densities) {
      File('$_res/drawable-$density/ic_launcher_foreground.png')
          .renameSync('$_res/drawable-$density/ic_launcher_bun_foreground.png');
    }
    final xml = File('$_res/mipmap-anydpi-v26/ic_launcher_bun.xml');
    xml.writeAsStringSync(
      xml.readAsStringSync().replaceAll(
        '@drawable/ic_launcher_foreground',
        '@drawable/ic_launcher_bun_foreground',
      ),
    );
    final bun = Directory('$_iosAssets/AppIcon-Bun.appiconset');
    if (bun.existsSync()) bun.deleteSync(recursive: true);
    bun.createSync();
    for (final file in Directory(
      '$_iosAssets/AppIcon.appiconset',
    ).listSync().whereType<File>()) {
      file.copySync('${bun.path}/${file.uri.pathSegments.last}');
    }

    _generate('tool/app_icons/pig.yaml');
    final manifest = File(_manifest);
    final text = manifest.readAsStringSync();
    if (!text.endsWith('\n')) manifest.writeAsStringSync('$text\n');
  } finally {
    File(_pbxproj).writeAsStringSync(pbxproj);
  }
}

void _generate(String config) {
  final result = Process.runSync(Platform.resolvedExecutable, [
    'run',
    'flutter_launcher_icons',
    '-f',
    config,
  ]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    throw ProcessException(
      'flutter_launcher_icons',
      ['-f', config],
      '',
      result.exitCode,
    );
  }
}
