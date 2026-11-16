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

  /// 登录后回到 [from]. [from] 是发现页时不带, 因为登录后默认进入发现页.
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

  /// 学校邮箱验证. 邮件里的链接带 `token`, 登录后由发起认证的账号提交.
  ///
  /// 改动需同步后端的 `APP_EMAIL_VERIFY_URL`.
  static const verifyEmail = '/verify/email';

  static const meEdit = '/me/edit';
  static const myTags = '/me/tags';

  /// 标签下的菜. [name] 是标签名, 放在地址中, 刷新页面后标题仍能显示.
  static const myTagPattern = '/me/tags/:tagId';
  static String myTag(int id, String name) =>
      Uri(path: '/me/tags/$id', queryParameters: {'name': name}).toString();

  /// 足迹.
  static const history = '/me/history';

  /// 本人的等级和经验明细.
  static const growth = '/me/growth';

  /// 他人主页. 从菜品详情的上传者, 消息, 粉丝和关注列表进入.
  static const userPattern = '/users/:userId';
  static String user(int id) => '/users/$id';

  /// 粉丝和关注列表. [fans] 为 true 时打开 "粉丝" 分栏, 否则打开 "关注".
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
  static const settingsNotify = '/settings/notify';
  static const settingsPersonalize = '/settings/personalize';
  static const settingsAbout = '/settings/about';

  /// 反馈. 从菜品或店铺进入时传入 [dishId] 或 [shopId], 页面显示 "关于 某某".
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
  ///
  /// [comment] 是要滚动到的评论 id, 来自消息和 "我的评论".
  static const dishPattern = '/dishes/:dishId';
  static String dish(int id, {int? comment}) =>
      comment == null ? '/dishes/$id' : '/dishes/$id?comment=$comment';

  /// 编辑菜品. 认证用户都能编辑, 不能换店.
  static const dishEditPattern = '/dishes/:dishId/edit';
  static String dishEdit(int id) => '/dishes/$id/edit';

  /// 菜品的修改记录, 可以恢复到某个版本.
  static const dishHistoryPattern = '/dishes/:dishId/history';
  static String dishHistory(int id) => '/dishes/$id/history';

  /// 一道菜的全部评论.
  static const commentsPattern = '/dishes/:dishId/comments';
  static String comments(int dishId) => '/dishes/$dishId/comments';

  /// 写评论或回复.
  ///
  /// - 回复时 [reply] 是所属评论的 id, [to] 是被回复的那条回复的 id, [name] 是被回复人的昵称.
  ///   昵称放在地址中, 刷新页面后 "回复 小林" 仍能显示.
  /// - [photo] 为 true 时打开页面后立即选择照片, 入口是全部评论底部的相机按钮.
  static const writeCommentPattern = '/dishes/:dishId/comments/new';
  static String writeComment(
    int dishId, {
    int? reply,
    int? to,
    String? name,
    bool photo = false,
  }) {
    final query = {
      'reply': ?reply?.toString(),
      'to': ?to?.toString(),
      if (reply != null) 'name': ?name,
      if (photo) 'photo': '1',
    };
    return Uri(
      path: '/dishes/$dishId/comments/new',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  /// 餐厅详情.
  static const shopPattern = '/shops/:shopId';
  static String shop(int id) => '/shops/$id';

  /// 编辑店铺. 认证用户都能编辑.
  static const shopEditPattern = '/shops/:shopId/edit';
  static String shopEdit(int id) => '/shops/$id/edit';

  /// 店铺的修改记录, 可以恢复到某个版本.
  static const shopHistoryPattern = '/shops/:shopId/history';
  static String shopHistory(int id) => '/shops/$id/history';

  /// 搜索, 入口在发现页右上角.
  static const search = '/search';

  /// 往期专题, 入口在发现页选中专题时的列表底部.
  static const topics = '/topics';

  /// 专题. 从发现页, 往期专题, 菜品详情的专题提示和消息进入.
  static const topicPattern = '/topics/:topicId';
  static String topic(int id) => '/topics/$id';

  /// 消息, 入口是发现页右上角的铃铛.
  static const inbox = '/inbox';

  /// 组件页, 只在 debug 构建中存在.
  static const kit = '/kit';
}
