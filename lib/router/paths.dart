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

  /// 加菜页点「换一家」打开的选店：选好后带着店返回加菜页，不再往下走。
  static const publishChangeShop = '/publish?change=1';

  /// 新建店。[name] 是带过来的店名（搜索没找到时的关键词）；[returnShop] 为 true 时建好后带着店
  /// 返回上一页，否则直接换成加菜页。
  static const publishShopPattern = '/publish/shop';
  static String publishShop({String? name, bool returnShop = false}) {
    final query = {
      if (name != null && name.isNotEmpty) 'name': name,
      if (returnShop) 'return': '1',
    };
    return Uri(
      path: publishShopPattern,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  /// 发布第 2 步：给这家店加菜。
  static const publishDishPattern = '/publish/dish';
  static String publishDish(int shopId) => '/publish/dish?shopId=$shopId';

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
