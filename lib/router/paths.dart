/// 全局页面路径常量, 页面跳转一律使用此处定义 (如 `context.go(Paths.nearby)`), 不在页面中手写路径字符串.
///
/// 这些地址同时是 Web URL 和分享链接的路径, 改名会使已发出的链接失效.
/// 功能目录只能从 `router/` 导入本文件.
abstract final class Paths {
  static const discover = '/discover';
  static const nearby = '/nearby';
  static const me = '/me';

  /// 登录页路径, 可带 `from` (登录后回跳的地址) 和 `expired=1` (因登录过期进入的标识).
  static const login = '/login';

  /// 构造登录后回跳至 [from] 的登录页路径. 若 [from] 为发现页则省略该参数, 因为登录后默认进入发现页.
  static String loginFrom(String from) => from == discover
      ? login
      : Uri(path: login, queryParameters: {'from': from}).toString();

  static const loginPhone = '/login/phone';
  static const loginPassword = '/login/password';

  /// 学生认证. `onboarding=1` 表示新号码注册后的认证引导, 左上角显示 "先逛逛" 而不是返回.
  ///
  /// `sso=success|failure`, `code` 和 `ticket` 是 Web 统一认证的结果, 由 `router/deep_links.dart` 从 [ssoCallback] 转入.
  static const verify = '/verify';

  /// Web 统一认证结束后后端重定向到的地址, 带 `result=success|failure`.
  /// 成功时带一次性的 `ticket`, 由认证页提交后认证才生效. 失败时带业务码 `code`.
  ///
  /// 该地址不是页面, 路由表把它重定向到 [verify]. 改动需同步后端的 `app.oauth-success-redirect`.
  /// App 的回跳地址是自定义 scheme, 见 `core/platform/browser.dart` 的 `ssoCallbackScheme`.
  static const ssoCallback = '/app/auth/callback';

  /// 学校邮箱验证页路径. 邮件链接中携带 `token`, 登录后由发起认证的账号提交验证.
  ///
  /// 改动需同步后端的 `APP_EMAIL_VERIFY_URL`.
  static const verifyEmail = '/verify/email';

  static const meEdit = '/me/edit';
  static const myTags = '/me/tags';

  /// 个人标签下的菜品列表页路径. 将标签名 [name] 写入查询参数, 以保证页面刷新后仍能显示标题.
  static const myTagPattern = '/me/tags/:tagId';
  static String myTag(int id, String name) =>
      Uri(path: '/me/tags/$id', queryParameters: {'name': name}).toString();

  /// 浏览足迹页路径.
  static const history = '/me/history';

  /// 当前用户的等级与经验明细页路径.
  static const growth = '/me/growth';

  /// 他人主页路径, 可从菜品上传者, 消息, 粉丝或关注列表进入.
  static const userPattern = '/users/:userId';
  static String user(int id) => '/users/$id';

  /// 粉丝与关注列表页路径. [fans] 为 true 时打开 "粉丝" 分栏, 否则打开 "关注".
  static const followsPattern = '/users/:userId/follows';
  static String follows(int userId, {required bool fans}) =>
      '/users/$userId/follows?tab=${fans ? 'fans' : 'followings'}';

  static const settings = '/settings';
  static const settingsAccount = '/settings/account';
  static const settingsUsername = '/settings/account/username';
  static const settingsPassword = '/settings/account/password';
  static const settingsPhone = '/settings/account/phone';
  static const settingsDevices = '/settings/account/devices';
  static const settingsDelete = '/settings/account/delete';
  static const settingsPrivacy = '/settings/privacy';
  static const settingsBlocked = '/settings/privacy/blocked';

  /// 推荐偏好页路径, 入口在隐私页 "个性化推荐" 开关下方.
  static const settingsPreferences = '/settings/privacy/preferences';
  static const settingsNotify = '/settings/notify';
  static const settingsPersonalize = '/settings/personalize';
  static const settingsAbout = '/settings/about';

  /// 我的反馈列表页路径, 列出本人提交的意见反馈, 信息有误和举报.
  static const myFeedback = '/settings/about/feedback';

  /// 我的反馈中单条记录的详情页路径, 展示提交内容和处理结果.
  static const myFeedbackCasePattern = '/settings/about/feedback/:caseId';
  static String myFeedbackCase(int id) => '/settings/about/feedback/$id';

  /// 反馈页路径. 从菜品或店铺入口进入时传入 [dishId] 或 [shopId], 页面显示 "关于 某某".
  static const feedbackPattern = '/feedback';
  static String feedback({int? dishId, int? shopId}) {
    final query = {
      'dishId': ?dishId?.toString(),
      'shopId': ?shopId?.toString(),
    };
    return Uri(
      path: feedbackPattern,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  /// 发布流程第 1 步: 选择店铺页路径.
  static const publish = '/publish';

  /// 在加菜页点击 "换一家" 进入的重选店铺路径, 选定后携带店铺返回加菜页, 不进入下一步.
  static const publishChangeShop = '/publish?change=1';

  /// 新建店铺页路径, [name] 为搜索无结果时预填的店名关键词.
  ///
  /// [returnShop] 为 true 时在创建完成后携带店铺返回上一页, 否则替换为加菜页.
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

  /// 发布流程第 2 步: 为选定店铺加菜页路径.
  static const publishDishPattern = '/publish/dish';
  static String publishDish(int shopId) => '/publish/dish?shopId=$shopId';

  /// 菜品详情页路径. 从列表进入时可通过 `extra` 传入已有菜品数据, 使舞台无需等待接口即可先行渲染.
  ///
  /// [comment] 为需要自动滚动定位的目标评论 id, 通常来自消息通知和 "我的评论".
  static const dishPattern = '/dishes/:dishId';
  static String dish(int id, {int? comment}) =>
      comment == null ? '/dishes/$id' : '/dishes/$id?comment=$comment';

  /// 编辑菜品页路径, 已认证用户均可编辑, 但不能更换所属店铺.
  static const dishEditPattern = '/dishes/:dishId/edit';
  static String dishEdit(int id) => '/dishes/$id/edit';

  /// 菜品修改记录页路径, 支持恢复到某个历史版本.
  static const dishHistoryPattern = '/dishes/:dishId/history';
  static String dishHistory(int id) => '/dishes/$id/history';

  /// 菜品全部评论页路径.
  static const commentsPattern = '/dishes/:dishId/comments';
  static String comments(int dishId) => '/dishes/$dishId/comments';

  /// 店铺详情页路径.
  static const shopPattern = '/shops/:shopId';
  static String shop(int id) => '/shops/$id';

  /// 编辑店铺页路径, 已认证用户均可编辑.
  static const shopEditPattern = '/shops/:shopId/edit';
  static String shopEdit(int id) => '/shops/$id/edit';

  /// 店铺修改记录页路径, 支持恢复到某个历史版本.
  static const shopHistoryPattern = '/shops/:shopId/history';
  static String shopHistory(int id) => '/shops/$id/history';

  /// 搜索页路径, 入口位于发现页右上角.
  static const search = '/search';

  /// 往期专题页路径, 入口位于发现页选中专题时的列表底部.
  static const topics = '/topics';

  /// 专题详情页路径, 可从发现页, 往期专题, 菜品详情的专题提示和消息进入.
  static const topicPattern = '/topics/:topicId';
  static String topic(int id) => '/topics/$id';

  /// 消息中心页路径, 入口位于发现页右上角的铃铛.
  static const inbox = '/inbox';

  /// 强制更新页路径. 只由路由守卫导向, 不需要更新时访问会被导回发现页.
  static const update = '/update';

  /// 停服维护页路径. 只由路由守卫导向, 不在维护时访问会被导回发现页.
  static const maintenance = '/maintenance';

  /// 组件预览页路径, 仅在 debug 构建中存在.
  static const kit = '/kit';
}
