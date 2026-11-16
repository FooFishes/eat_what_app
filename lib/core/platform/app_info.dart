import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info.g.dart';

/// 版本名, 取自 `pubspec.yaml` 的 `version`, 如 `0.1.0`. 显示在设置页和关于页.
@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async =>
    (await PackageInfo.fromPlatform()).version;

/// 构建号, CI 中取工作流的运行序号. 更新检查基于该值比较, 而非版本名.
@Riverpod(keepAlive: true)
Future<String> appBuildNumber(Ref ref) async =>
    (await PackageInfo.fromPlatform()).buildNumber;
