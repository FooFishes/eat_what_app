/// 页面地址. 页面跳转一律使用这里的常量, 如 `context.go(Paths.nearby)`, 不在页面中手写字符串.
///
/// 这些地址同时是 Web URL 和分享链接的路径, 改名会使已发出的链接失效.
/// 功能目录只能从 `router/` 导入本文件.
abstract final class Paths {
  static const discover = '/discover';
  static const nearby = '/nearby';
  static const me = '/me';

  /// 登录. 可带 `from` (登录后返回的地址) 和 `expired=1` (因登录过期而进入).
  static const login = '/login';
  static const loginPhone = '/login/phone';
  static const loginPassword = '/login/password';

  /// 学生认证. `onboarding=1` 表示新号码注册后的认证引导, 左上角显示 "先逛逛" 而不是返回.
  static const verify = '/verify';

  static const settings = '/settings';
  static const settingsAccount = '/settings/account';
  static const settingsAbout = '/settings/about';

  /// 发布第 1 步: 选店.
  static const publish = '/publish';

  /// 加菜页点击 "换一家" 打开的选店. 选定后带着店铺返回加菜页, 不进入下一步.
  static const publishChangeShop = '/publish?change=1';

  /// 新建店铺. [name] 是预填的店名, 来自搜索无结果时的关键词.
  ///
  /// [returnShop] 为 true 时, 建好后带着店铺返回上一页; 否则替换为加菜页.
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

  /// 发布第 2 步: 为选定的店铺加菜.
  static const publishDishPattern = '/publish/dish';
  static String publishDish(int shopId) => '/publish/dish?shopId=$shopId';

  /// 菜品详情. 从列表进入时把已有的菜品数据放在 `extra` 中, 舞台无需等待接口即可显示.
  static const dishPattern = '/dishes/:dishId';
  static String dish(int id) => '/dishes/$id';

  /// 餐厅详情.
  static const shopPattern = '/shops/:shopId';
  static String shop(int id) => '/shops/$id';

  /// 搜索, 入口在发现页右上角.
  static const search = '/search';

  /// 消息, 入口是发现页右上角的铃铛.
  static const inbox = '/inbox';

  /// 组件页, 只在 debug 构建中存在.
  static const kit = '/kit';
}
