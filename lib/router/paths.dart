/// 页面的地址。跳页面一律用这里的常量（`context.go(Paths.nearby)`），不在页面里手写字符串。
///
/// 这些地址也是 Web 的 URL 和分享链接的路径，改名会让已经发出去的链接失效。
/// 功能目录只能从 `router/` 导入这个文件。
abstract final class Paths {
  static const discover = '/discover';
  static const nearby = '/nearby';
  static const me = '/me';

  /// 登录。可带 `from`（登录后回到哪）和 `expired=1`（因为登录过期来的）。
  static const login = '/login';
  static const loginPhone = '/login/phone';
  static const loginPassword = '/login/password';

  /// 学生认证。`onboarding=1` 是新号码注册后的认证引导，左上角是「先逛逛」而不是返回。
  static const verify = '/verify';

  static const settings = '/settings';
  static const settingsAccount = '/settings/account';
  static const settingsAbout = '/settings/about';

  /// 发布第 1 步：选店。
  static const publish = '/publish';

  /// 菜品详情。从列表进来时把手上的那道菜放在 `extra` 里，舞台不用等接口（技术架构 10.5）。
  static const dishPattern = '/dishes/:dishId';
  static String dish(int id) => '/dishes/$id';

  /// 餐厅详情。
  static const shopPattern = '/shops/:shopId';
  static String shop(int id) => '/shops/$id';

  /// 搜索，从发现页右上角进。
  static const search = '/search';

  /// 消息，从发现页右上角的铃铛进。
  static const inbox = '/inbox';

  /// 组件页，只在 debug 构建里有。
  static const kit = '/kit';
}
