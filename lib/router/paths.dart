/// 页面的地址。跳页面一律用这里的常量（`context.go(Paths.nearby)`），不在页面里手写字符串。
///
/// 这些地址也是 Web 的 URL 和分享链接的路径，改名会让已经发出去的链接失效。
/// 功能目录只能从 `router/` 导入这个文件。
abstract final class Paths {
  static const discover = '/discover';
  static const nearby = '/nearby';
  static const me = '/me';

  /// 发布第 1 步：选店。
  static const publish = '/publish';

  /// 组件页，只在 debug 构建里有。
  static const kit = '/kit';
}
