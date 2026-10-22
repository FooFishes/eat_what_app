# EatWhat 技术架构

本文说明客户端的代码怎么组织：分层与目录、状态管理、路由与页面骨架、网络层（含弱网策略）、登录态与本地存储、设计令牌与组件、图片与取色、地图与定位、多平台差异、监控和测试。

装哪个包、为什么，见 `docs/EatWhat_依赖选型.md`；界面以 `prototype/` 为准，接口以 `docs/api.openapi.yml` 为准，本文不重复它们的内容。开发顺序见 `docs/EatWhat_开发计划.md`。

本文按 2026-10-22 的 `main` 写成：依赖选型（PR #10）、设计稿（PR #11）、接口版本 `auth-renewal-20261019`。文中关于 Riverpod 3.4.3、go_router 18.1.1 和 Flutter 3.47.7 的行为都对照过源码。

## 总原则

- 三层：数据（接口和模型）、状态（provider）、界面（页面和组件）。不另设 domain、use case 层，业务规则真的复杂起来再加。
- 界面只通过 provider 读数据、做写操作，不直接调接口类，也不碰 `dio`。
- 样式只从设计令牌来，业务代码不写裸色值和魔法数字。
- 角色、认证、同意状态以服务端返回为准，客户端只做展示层面的拦截。
- 弱网下手上有数据就先显示，没有才显示占位，失败了可以重试。
- Android、iOS、Web 一套代码，平台差异收在少数几处，见「多平台差异」。

## 目录与分层

```text
lib/
  main.dart          入口：读配置和本地 token、初始化监控，runApp
  app.dart           EatApp：MaterialApp.router、主题、本地化
  core/              和业务无关的基础设施
    config/          环境配置（接口地址、天地图 key、Sentry DSN）
    network/         Dio、ApiClient、ApiException、分页、重试策略、Ref 扩展
    session/         登录态：token 的读写和当前会话
    storage/         本地偏好
    location/        定位、坐标转换、距离
    image/           选图参数、裁切参数、舞台取色
    format/          距离、价格、时间的显示格式
  design/            设计系统
    tokens.dart      颜色、间距、圆角、阴影、尺寸，和 tokens.json 一一对应
    stage_color.dart 舞台色枚举
    text_styles.dart 文字样式
    motion.dart      动效时长和曲线
    theme.dart       ThemeData 和 ThemeExtension
    icon.dart        图标组件和用途名
    components/      Button、Chip、Tabs、ListRow、Sheet、Stage、Panel、NavBar、DishPlate……
  data/              接口和模型，按 api.openapi.yml 的分组，一组一个目录
    auth/  consent/  user/  food/  restaurant/  hub/  history/  notification/  upload/
  shared/            跨功能复用、又和业务有关的部件：当前用户、认证拦截、菜品网格……
  features/          按产品功能分目录
    auth/  discover/  nearby/  food/  restaurant/  publish/  search/  topic/  inbox/  profile/  settings/
  router/            路由表、路径常量、登录重定向、主页面外壳
```

功能目录里放页面、页面用到的 provider 和只在这里用的组件，以菜品详情为例：

```text
features/food/
  food_detail_page.dart         页面，对应 G-Dish
  food_detail_providers.dart    页面用到的 provider，生成 food_detail_providers.g.dart
  widgets/                      只在这个功能里用的组件
```

依赖只能从下往上，左边的目录不导入右边的：`core` → `design` → `data` → `shared` → `features` → `router`。

| 目录 | 放什么 | 可以导入 |
| --- | --- | --- |
| `core/` | 网络、会话、存储、定位、取色、格式化等基础设施 | 只导入第三方包 |
| `design/` | 令牌、主题、设计规范里的组件。组件只收基本类型、`ImageProvider`、`StageColor` 和回调，不认识业务模型 | `core/` |
| `data/` | 接口类、模型、由几个接口组成的流程（如上传） | `core/`，以及 `design/` 里的值类型（`StageColor`），不用组件 |
| `shared/` | 两个以上功能用到、又和业务模型有关的部件 | 以上 |
| `features/` | 页面、页面状态、本功能的组件 | 以上，外加 `router/paths.dart`。功能之间不互相导入，跳到别的功能用路径 |
| `router/` | 路由表、主页面外壳 | 以上全部 |

一个测试扫描 `lib/` 的 import，守住这个方向（见「测试」）。

命名：

- 业务实体跟接口叫：`Food`、`Restaurant`、`Hub`、`UserProfile`……接口类按分组叫 `FoodApi`、`RestaurantApi`，和 `api.openapi.yml` 对得上。
- 设计组件跟设计规范叫：`DishPlate`、`DishTile`、`Stage`、`Sheet`、`Panel`、`MapPin`……
- 页面类以 `Page` 结尾，文件名和类名对应（`food_detail_page.dart` / `FoodDetailPage`），类注释写对应的画板。
- provider 按它提供的东西命名（`foodDetailProvider`），不叫 `xxxViewModel`。
- 生成的 `*.g.dart` 入库，理由见依赖选型「JSON」。

## 状态管理

用 Riverpod 3 + `riverpod_generator`，provider 一律用注解写（选型理由见依赖选型「状态管理」）。

| 状态 | 怎么放 | 例子 |
| --- | --- | --- |
| 会话和全局状态 | 常驻 Notifier（`@Riverpod(keepAlive: true)`） | 登录态、当前用户、地点和饭点、未读数 |
| 主页面的数据 | 常驻 provider | 发现页的推荐、附近的店、我的概览 |
| 详情页的数据 | 自动释放，看不见以后再保留 5 分钟 | 菜品详情、餐厅详情、他人主页 |
| 分页列表 | `AsyncNotifier`：`build` 拉第一页，`loadMore` 追加 | 消息、收藏、粉丝 |
| 流程状态 | 自动释放的 Notifier，流程里的几个页面都 watch 它 | 发布草稿：选的店、照片、裁切、舞台色 |
| 正在输入的表单、选中的分类、转盘角度和拖动 | 组件自己的 `State` 和 controller | 菜名输入框、分类 `Tabs` |

规则：

- 读数据用函数式 provider，返回 `Future<T>`；需要写操作或分页时用 `AsyncNotifier`。参数用 id、关键词这类基本类型。
- 写操作都是 Notifier 的方法。赞、收藏、关注这类开关先改界面，请求失败再改回来；发布、编辑资料这类提交等结果，成功后 `ref.invalidate` 受影响的 provider（比如发布后失效「我的上传」），由它们下次显示时重新拉。不在客户端做跨页面的数据同步。
- 写操作进行中的状态（按钮禁用、上传进度）由发起它的页面自己管。Riverpod 3 标为 experimental 的 `Mutation` 和离线持久化先不用，等 API 稳定再评估。
- 和用户有关的常驻 provider 都 watch 会话，退出或换账号时自动重建，不残留上一个人的数据。
- 跳转、弹面板这类副作用在组件里用 `ref.listen` 触发，provider 里不拿 `BuildContext`。
- App 回到前台（`AppLifecycleListener`）时失效未读数和当前用户：认证可能刚在邮箱里完成，消息也可能有新的。
- 分页列表加载下一页失败时不清空已有内容，只在列表底部显示失败和重试。翻页逻辑写成通用的 `Page<T>` 和辅助方法，各列表复用。

接口类本身也由常驻 provider 提供，测试时整个替换：

```dart
@Riverpod(keepAlive: true)
FoodApi foodApi(Ref ref) => FoodApi(ref.watch(apiClientProvider));

@riverpod
Future<Food> foodDetail(Ref ref, int id) async {
  ref.cacheFor(const Duration(minutes: 5));
  return ref.watch(foodApiProvider).detail(id, cancelToken: ref.cancelToken());
}
```

`cacheFor` 和 `cancelToken` 是 `core/network/` 里给 `Ref` 写的扩展，见「弱网与加载」。

## 路由与页面骨架

### 路由

- 用 `go_router`。路由表在 `router/`，由一个常驻 provider 创建 `GoRouter`，整个 App 只建一次；会话变化时通过 `refreshListenable` 让 `redirect` 重新判断。
- 路径常量和拼路径的函数放 `router/paths.dart`，页面只用它跳转，不手写路径字符串。
- Web 用路径式 URL（`usePathUrlStrategy()`），URL 和页面一一对应，分享出去的链接能直接打开。

三个主页面放在 `StatefulShellRoute.indexedStack` 里：

```dart
StatefulShellRoute.indexedStack(
  // MainShell 用 Stack 把悬浮的 NavBar 叠在 shell 上面
  builder: (context, state, shell) => MainShell(shell: shell),
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/', builder: ...)]), // 发现
    StatefulShellBranch(routes: [GoRoute(path: '/nearby', builder: ...)]), // 附近
    StatefulShellBranch(routes: [GoRoute(path: '/me', builder: ...)]), // 我的
  ],
)
```

- 三个主页面各是一个分支，切换时不销毁，滚动位置、地图视野都保留。`NavBar` 用 `shell.goBranch(index)` 切换。
- `NavBar` 只在 `MainShell` 里，悬浮在内容上方（左右 `space-16`，底部 `space-24` 再加安全区）。主页面的滚动内容底部留出约 100px。
- 其他页面都压在根 navigator 上，盖住外壳，所以不显示 `NavBar`。「我的」的子页面写成 `/me` 的子路由并把 `parentNavigatorKey` 设为根 navigator：URL 有层级（`/me/tags`），页面仍然盖在外壳上面。
- 发布按钮 `context.push('/publish')`。

主要路由：

| 路径 | 页面 | 画板 |
| --- | --- | --- |
| `/`、`/nearby`、`/me` | 发现、附近、我的 | `G2-Home`、`G-Nearby`、`G-Me` |
| `/food/:id`、`/food/:id/comments` | 菜品详情、全部评论 | `G-Dish`、`G-Comments` |
| `/restaurant/:id`、`/restaurant/:id/wrong-info` | 餐厅详情、信息有误 | `G-Detail`、`G-WrongInfo` |
| `/publish`、`/publish/new-restaurant`、`/publish/:restaurantId` | 发布 1/2 选店、新建店、发布 2/2 加菜 | `G-PickShop`、`G-NewShop`、`G-AddDish` |
| `/search`、`/inbox` | 搜索、消息 | `G-Search`、`G-Inbox` |
| `/topics`、`/topic/:id` | 往期专题、专题 | `G-TopicArchive`、`G-Topic` |
| `/user/:id`、`/user/:id/follows` | 他人主页、粉丝与关注 | `G-UserProfile`、`G-Follows` |
| `/me/edit`、`/me/tags`、`/me/tags/:id`、`/me/history`、`/me/follows` | 编辑资料、我的标签、标签下的菜、足迹、我的粉丝与关注 | `G-EditProfile`、`G-MyTags`、`G-TagDishes`、`G-History`、`G-Follows` |
| `/settings` 及其子路径 | 设置、账号与安全、登录设备、注销、隐私、屏蔽、通知、关于、反馈 | `G-Settings` 等 |
| `/login` 及其子路径、`/verify`、`/reconsent`、`/data-notice` | 登录、注册、认证、同意 | `G-Login` 等 |

- 不进路由表的：底部面板用 `showModalBottomSheet` 弹出，不改 URL；调整照片是发布流程里拿着内存中图片的一步，用 `Navigator.push` 打开、返回裁切结果。
- 返回按钮：`context.canPop()` 时 `pop`，否则（Web 直接打开链接或刷新后）`go('/')`。
- 从列表进详情时，把列表里那一条通过 `extra` 作为预览传过去。详情页先用它画舞台（图、菜名、舞台色），抽屉里的内容等接口；直接打开链接没有预览时，舞台也走占位。

登录重定向：

- `main()` 在 `runApp` 之前读出本地 token（这时原生启动图还在），交给会话作初始值。路由第一帧就知道该去哪，不需要启动页。
- 没登录时访问任何页面都跳 `/login?from=<原地址>`，登录后回到 `from`。分享链接在 Web 上因此能用：先登录再看。
- 已登录时访问登录相关页面跳回 `/`。
- 会话要求重新同意时跳 `/reconsent`，见「登录、注册和同意」。
- 认证不做重定向，见「当前用户与认证拦截」。

### 页面骨架

| 骨架 | 用在哪 | 要点 |
| --- | --- | --- |
| `StageScaffold` | 发现、菜品详情、餐厅详情、我的、他人主页、发布 2/2 | 舞台色、左栏文字、主盘子、按钮行、抽屉内容。舞台高度由页面传（发现 520，我的和他人主页 400，餐厅详情 372，加菜 332）；抽屉压上舞台 32px，跟页面一起滚；舞台色变化时背景和文字 500ms 一起过渡 |
| `PlainScaffold` | 消息、选店、搜索、评论、设置等白底页 | 44×44 的返回、`page-title` 大标题；分组靠小标题和留白，不加卡片 |
| 地图页 | 附近、新建店 | 地图当舞台；附近的抽屉用 `DraggableScrollableSheet`，加 `shadow-sheet` |
| 调整照片 | 发布流程里的调整照片 | `crop-*` 深色底，独立布局 |
| `showPanel` | 地点和饭点、筛选、加标签、举报、退出确认、认证拦截 | 包一层 `showModalBottomSheet`：`scrim` 遮罩、顶部圆角和把手、标题加关闭按钮、最高 85% 屏高、超出时内部滚动；减少动态效果时直接出现 |

- 状态栏图标的深浅跟着骨架走（`AnnotatedRegion<SystemUiOverlayStyle>`）：舞台页按舞台色深浅，白底页用深色图标，调整照片页用浅色图标。
- 画板是 390×844。舞台里的盘子按右侧出血排，360 宽的安卓机上要检查左栏文字不被盘子压住。
- 宽屏（Web 桌面浏览器、平板）先把整个 App 放在居中的手机宽度里（最宽 480 左右），两侧留白；真正的宽屏布局等有设计再做。

## 网络层

### 配置

- 环境配置用 `--dart-define-from-file=config/<env>.json` 注入，`core/config/` 的 `AppConfig` 用 `String.fromEnvironment` 读取：接口地址 `API_BASE_URL`、天地图 key `TIANDITU_KEY`、Sentry DSN `SENTRY_DSN`。
- `config/example.json` 入库，只有字段名和说明；真实的 `config/dev.json`、`config/prod.json` 不入库，CI 从 Secrets 生成。
- Web 部署在和接口同域的地址上，接口地址写相对路径 `/api`（接口文档 `servers` 第一项就是这个反代前缀），不用处理跨域。App 写完整地址。

### 请求怎么发

- 两个 `Dio`：业务接口一个，带鉴权和拦截器；上传到对象存储一个，`putUrl` 是预签名地址，不带鉴权头、不加前缀。
- 超时：连接 10 秒、接收 15 秒。上传不用固定超时卡，界面显示进度、可以取消。
- 鉴权头：拦截器从会话取 `tokenName` 和 `tokenValue`，加上 `<tokenName>: Bearer <tokenValue>`。头名用登录返回的 `tokenName`，不写死 `satoken`。登录、注册、读同意政策这几个开放接口不带头。
- `ApiClient` 负责发请求、解开 `{code, msg, data}`、检查业务 `code`，把各种失败统一成 `ApiException`。接口类只写路径、参数和 `data` 的解析。
- 接口类按 `api.openapi.yml` 的分组，一组一个：`AuthApi`、`ConsentApi`、`UserApi`、`FoodApi`、`RestaurantApi`、`HubApi`、`HistoryApi`、`NotificationApi`、`UploadApi`。只写客户端真正调用的接口。`Activity`、`Location` 目前没有页面用到，管理和运维接口客户端不接。

### 失败的分类

`ApiException` 是 sealed class，页面和重试策略都按类型判断：

| 类型 | 什么时候 | 自动重试 | 界面 |
| --- | --- | --- | --- |
| `NetworkException` | 连不上、超时 | 读请求重试 | 没有数据时显示没网状态和「重试」 |
| `ServerException` | HTTP 5xx | 读请求重试 | 同上 |
| `ServerException` | 其他 HTTP 错误 | 不重试 | 显示失败说明 |
| `BusinessException` | HTTP 200 但 `code` 不是 0，或错误响应里带 `code`（可能是字符串） | 不重试 | 显示 `msg` |
| `NotVerifiedException` | 接口因为没认证拒绝 | 不重试 | 认证拦截 |
| `AuthExpiredException` | 登录失效 | 不重试 | 清掉 token，回登录页 |
| `ConsentRequiredException` | 需要（重新）同意数据存放 | 不重试 | 进同意页 |
| `ParseException` | 响应和模型对不上 | 不重试 | 显示通用失败，上报 Sentry |

- 业务码表先按 `legacy` 分支的 `lib/core/constant/biz_code.dart` 整理（20001–20003 登录失效、20004 权限不足），加上接口文档写到的 20005 / 20006（需要同意），做登录时和后端核对一遍。
- 离开页面导致的取消不算失败，不提示、不上报。

### 模型和 JSON

- 主构造函数加 `json_serializable`，见依赖选型「JSON」。接口文档几乎把所有字段都写成可空，模型按实际返回决定：id、名字这类一定有的字段不可空，缺了就是 `ParseException`。
- 时间字段有毫秒数也有 ISO 字符串（接口文档的说明里写了两种都会出现），用一个 `JsonConverter` 统一转成 `DateTime`。
- 图片字段可能是完整地址，也可能是上传返回的 `key`，模型解析时统一转成完整地址。
- 菜品分类等枚举在模型里是 Dart 枚举，和接口的取值对应；分类自带中文名和默认舞台色。
- 坐标保持接口原样的 GCJ-02，字段名带 `gcj`，见「地图与定位」。
- 分页统一成 `Page<T>`（`items`、`hasNext`、`currentPage`）。

### 弱网与加载

手上有数据就先显示，没有才显示占位，失败了可以重试（2026-10-22 确定）。这部分用已经选好的包就能做，不新增依赖。

**切换页面**

- 三个主页面放在 `StatefulShellRoute.indexedStack` 里，切走时不销毁，数据只拉一次；它们的 provider 标 `keepAlive`。
- 看不见的页面不会偷偷发请求。go_router 给不在当前分支的页面包了 `TickerMode(enabled: false)`，被别的页面盖住的路由 Flutter 也这样处理；Riverpod 3 会暂停这些页面上的监听，只被暂停的监听者用到的 provider 也跟着暂停。常驻 provider 在暂停期间被失效时，等回到页面再带着旧数据刷新。
- 详情页的 provider 自动释放，但看不见以后再保留 5 分钟（`ref.cacheFor`），回到刚看过的页面不用重新拉。
- 从列表点进详情，先用列表里已有的图、名字和舞台色把舞台画出来，只有抽屉里的内容要等。

**自动重试**

- 用 Riverpod 3 自带的自动重试，沿用它的默认节奏：间隔从 200 ms 开始翻倍，最长 6.4 秒，最多 10 次。
- 在 `ProviderScope(retry: ...)` 里限定只重试超时、连不上和 5xx；业务 `code` 报错、登录失效、解析失败都不重试。
- 写操作（发布、评论、赞、关注……）不在 provider 的 `build` 里，本来就不会被自动重试，`dio` 也不加重试拦截器。失败时保留用户已经输入的内容，由用户再点一次。

```dart
Duration? retryPolicy(int retryCount, Object error) {
  final retryable = switch (error) {
    NetworkException() => true,
    ServerException(:final statusCode) => statusCode >= 500,
    _ => false,
  };
  return retryable ? ProviderContainer.defaultRetry(retryCount, error) : null;
}
```

**加载、失败、没网的样子**

设计稿只给了图片底色 `mist` 和 `wifi-off` 图标，下面的做法已经确定（2026-10-22）：

- 加载中：用 `mist` 色块按内容的形状占位（舞台、盘子、方块、列表行），不用转圈。
- 失败且没有旧数据：`wifi-off` 图标、一句说明、「重试」按钮。Riverpod 在后台重试时，状态是「加载中但带着上一次的错误」，这时也显示失败状态；后台某次重试成功，就自动换成内容。
- 有旧数据时刷新：保留旧内容；刷新失败也不清空，只给一句不打断操作的提示，样式做时和设计对。
- 这几种状态做成 `design/` 里的通用组件，页面按同一条规则选：有数据显示数据，没数据但有错误显示失败，都没有显示占位。

**取消、防抖和图片**

- 每个发请求的 provider 拿一个 `CancelToken`，provider 释放时取消。离开页面，页面的请求就停了。
- 搜索输入防抖：provider 先等 300 ms，期间关键词变了（旧的 provider 被释放）就不发请求。
- 网络图片用 `cached_network_image`：移动端存磁盘，没网时看过的图照样能显示；Web 靠浏览器缓存。图片没出来时底色用 `mist`。

**冷启动**

- 第一版不做离线快照：冷启动时没网，发现页显示失败状态和「重试」。等实际在食堂用过，再决定要不要把上一次的推荐存在本地（`shared_preferences` 就够）。

```dart
extension RefCache on Ref {
  /// 没人看以后再保留 [duration]，这段时间里回来不重新请求。
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() => timer = Timer(duration, link.close));
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }

  /// provider 释放时取消请求。
  CancelToken cancelToken() {
    final token = CancelToken();
    onDispose(token.cancel);
    return token;
  }
}
```

### 上传

预签名三步，见接口文档 Upload 分组：

1. 调 `/upload/presign`（多张用 `/upload/presign/batch`），带上文件名、类型、大小和用途（`foods`、`restaurants`、`avatar`、`activity`）。
2. 用上传专用的 `Dio` 向 `putUrl` PUT 原始字节，`Content-Type` 和第 1 步声明的一致；`onSendProgress` 出进度，`CancelToken` 取消。
3. 调 `/upload/complete` 确认，再把 `key` 写进菜品、餐厅或头像的请求。

- 封装成 `data/upload/` 里的 `Uploader`，发布、新建店、换头像，以后的评论照片、反馈截图都用它。
- 发布时选好照片就在后台开始传，用户填菜名、价格的同时图在上传；点「发布」只等还没传完的。已经传好的不重复传，失败的单独重传。
- `foods`、`restaurants` 用途要求已认证，头像只要求登录。

## 登录态与本地存储

### 会话

- `core/session/` 的常驻 Notifier 管当前会话：没登录，或已登录（`tokenName`、`tokenValue`）。token 存在 `flutter_secure_storage`。
- 启动时有 token 就当作已登录，不额外请求校验；token 是否还有效由第一次请求的结果决定，失效了再回登录页。
- `ApiClient` 遇到登录失效、需要重新同意时，通过构造时传入的回调通知会话，这样 `core/network` 不用导入上层。

### 登录、注册和同意

登录和注册接口的返回不只成功、失败两种，客户端按返回进入不同的页面：

| 接口返回 | 客户端怎么做 |
| --- | --- |
| `code` 为 0，`data` 带 `tokenName`、`tokenValue` | 存 token，进入已登录 |
| 带 `consentProof`，或 `code` 为 20005 / 20006 | 进数据存放说明和同意。同意后用 proof 调 `/auth/consent/grant`，再登录一次；这次用的账号密码只留在内存里 |
| 已登录时任何接口返回 20005 / 20006 | 进「重新同意」（`G-Reconsent`）：同意后照常使用，也可以退出登录或注销 |
| 登录失效 | 清掉 token，回登录页，登录后回到原地址 |

- 注册前先读 `/auth/consent/policy` 拿到政策版本，`G-RegisterConfirm` 勾选后把 `crossBorderConsent` 和 `consentPolicyVersion` 和注册信息一起提交。
- 20005 和 20006 各指什么、proof 多久过期，以后端为准，做登录时核对。

### 统一认证与邮箱认证

- 山大统一认证：移动端用 `webview_flutter` 打开 `/auth/sdu`，在 `NavigationDelegate` 里拦截跳到回调地址（带 `token` 参数）的那次导航，再调 `/auth/callback` 换取结果；Web 整页跳转，回跳后由对应的路由处理。登录页的「用山大统一认证登录」和认证页的统一认证走同一套流程，结果交给会话统一处理：拿到 token 就进入已登录，只是完成认证就刷新当前用户。
- 邮箱认证：调 `/auth/sendEmail` 后用户去邮箱点链接；回到前台时刷新认证状态（「回到这里会自动刷新」）。

### 当前用户与认证拦截

- `shared/` 里的常驻 provider 拉 `/user/info`，提供昵称、头像、是否已认证。认证完成、改资料后失效它。
- 设计规定发布、点赞、评论、关注要先认证。这些按钮先看当前用户是否已认证，没认证就弹认证拦截面板，引到 `/verify`；认证完回来，用户再点一次（「刚才被拦下的操作现在可以直接做了」）。
- 客户端的判断只是展示层面的。接口以没认证为由拒绝时（读接口也可能），同样走拦截：写操作弹面板，读接口在页面上显示需要认证的状态和去认证的按钮。

### 退出登录

- 调 `/auth/logout`，失败也继续；清掉 token 和这台设备上的个人偏好，会话变成没登录。和用户有关的常驻 provider 跟着重建，路由回到登录页（「这台设备上的登录信息和个人数据会清掉」）。

### 本地偏好

- 用 `shared_preferences` 的 `SharedPreferencesAsync`，统一从 `core/storage/` 的一个类读写，键名集中定义。
- 存的是最近搜过的词、地点和饭点的手动选择这类偏好。和个人有关的在退出登录时清掉。
- 没有需要本地数据库的功能，不加数据库（见依赖选型「本地存储」）。

## 设计令牌与组件

### 令牌

- `tokens.json` 里的颜色、间距、圆角、阴影、尺寸写成 `design/tokens.dart` 里的常量，名字和 `tokens.json` 一一对应，再挂到 `ThemeData` 的一个 `ThemeExtension` 上，组件和页面通过 `context.tokens` 读取。
- 一个单元测试读 `prototype/design-system/tokens.json`，逐项比对 Dart 里的值。设计稿重新导出后，测试会指出哪里没跟上。
- `tokens.json` 只有日间一套颜色，不做深色模式。
- 文字样式按 `tokens.json` 的 `type` 一一写成 `TextStyle`（`stageDish`、`pageTitle`、`priceHero`……）：数字类用 Bricolage Grotesque，其他用 Noto Sans SC。两种字体打包和子集化的做法见依赖选型「字体」，子集脚本放 `tool/fonts/`。
- `ThemeData` 的默认字体设成 Noto Sans SC，Material 组件内部的文字也不会去网上拉字体；iOS 上缺字回落苹方。
- 系统字体放大时正文跟着放大；舞台上的大字（菜名、价格）限制最大倍数，避免挤出舞台，具体倍数做页面时和设计对。

### 舞台色

```dart
enum StageColor(final Color color, final bool isDark, final String label) {
  broth(Color(0xFFF3C46E), false, '汤色'),
  mango(Color(0xFFFFCB45), false, '芒果黄'),
  bamboo(Color(0xFFD8B27A), false, '竹屉'),
  chili(Color(0xFFD9632B), false, '辣橙'),
  tomato(Color(0xFFC9442B), true, '番茄红'),
  redoil(Color(0xFFA8321C), true, '红油'),
  soy(Color(0xFF8F5B24), true, '酱色'),
  porcelain(Color(0xFF9DB8D9), false, '青花蓝'),
  matcha(Color(0xFF9DBF7A), false, '抹茶绿');

  // 文字色、次级文字色、次按钮底、转盘桌面和细边、实心按钮的底和字，都写成由 isDark 推出的 getter
}
```

- 深浅写死在枚举里，页面不自己判断。次级文字色有一个例外：`chili` 上用 `ink`，不用 `ink-soft`（`tokens.json` 的说明里写了对比度）。
- 舞台换色时在两个 `StageColor` 之间插值，背景和文字 500ms `ease` 一起过渡。
- 分类默认色写在菜品分类枚举上：主食 `broth`、小吃 `chili`、饮品 `mango`、甜品 `porcelain`、汤 `bamboo`、火锅 `redoil`、烧烤 `soy`、凉菜和配菜 `matcha`、其他 `bamboo`。

### 动效

`tokens.json` 里没有动效，按设计规范 README 写成 `motion.dart` 里的常量：转盘吸附 680ms `Cubic(0.2, 0.9, 0.25, 1.1)`、舞台换色 500ms `ease`、选中态 160–200ms、按钮按下 90ms、面板出现和收起 240ms。

系统开了「减少动态效果」（`MediaQuery.disableAnimationsOf`）时，登录页的转盘停住，面板直接出现，不做滑入。

### 组件

- `design/components/` 里一个设计规范组件对应一个文件，名字和 `prototype/design-system/components/<Name>/` 一致，组件注释写明对应的 README。
- 组件只收基本类型、`ImageProvider`、`StageColor` 和回调，不认识 `Food`、`Restaurant`。把业务模型摆成组件的部件放在 `shared/` 或功能目录里，比如 `FoodGrid` 把一组 `Food` 摆成 `DishTile` 网格。
- 按钮的厚度：设计用了内高光和内阴影（CSS 的 `inset`），Flutter 的 `BoxShadow` 不支持 `inset`，用 `CustomPainter` 或渐变叠加来画。按下时下沉 1px、换成 `-pressed` 阴影，90ms。
- 可点组件共用一套按下和键盘焦点的处理：焦点是 2px `paper` 内圈加 2px `ink` 外圈的双环，Web 和外接键盘都看得到。
- 点击区域不小于 44px，36px 高的标签向外扩到 44px。只有图标的按钮写语义标签，图标旁边有文字时把图标排除出语义树。
- 图标组件按依赖选型「图标」的做法用 `flutter_svg` 渲染 MingCute 的 SVG。
- 「待接入」标记、加载占位、失败重试、空状态也是 `design/` 里的组件。
- 写组件时用 Widget Preview 对照设计稿；另做一个只在 debug 构建里出现的组件页（对照 `G-Kit`），方便在真机上和设计一起看。

### 待接入的功能

- 设计要求没有接口的功能照样画出来，旁边放「待接入」。做法：页面照常写，数据也走 provider，只是 provider 先返回放在功能目录里的示例数据（插画和示例文字），不发请求；写操作的按钮点了也不发请求。
- 接口上线后只换 provider 的实现、补接口类，页面不用改，同时去掉「待接入」。

## 图片：选择、调整、上传与取色

- 选图、拍照用 `image_picker`，由平台缩放压缩，先用长边 1600、质量 85，按实际体积和清晰度再调。拿到的是 `XFile`，用 `readAsBytes()` 读字节。业务代码不用 `dart:io` 的 `File`，否则 Web 编译不过。
- 裁切参数 `PlateCrop`：圆心用相对原图的坐标（0–1），缩放以「圆刚好装下原图短边」为 1。原图照常上传，`DishPlate` 按参数显示，`DishTile` 直接用原图。
- 调整照片页（`G-Crop`）的拖动、双指缩放和缩放滑条用 `GestureDetector` 加 `Transform` 手写，完成时返回 `PlateCrop` 和选好的舞台色。
- 头像用同一套手势，完成时用 `PictureRecorder` 按圆圈画到 512×512 导出 PNG 再上传，因为头像只存一个地址。

### 舞台取色

- 取色是纯函数，放 `core/image/`：输入圆圈里的像素，输出按推荐顺序排好的三个 `StageColor`，以及「太灰、不可靠」的标记。
- 取像素：用 `dart:ui` 把原图按小尺寸解码（比如 64×64），只看圆圈里面的像素。三端都能跑，计算量很小，不用开 isolate。
- 算法照设计规范：按饱和度加权求主色调，在 OKLab 里找最近的舞台色，取前三个；圈内饱和度太低时，把分类默认色放在第一位。
- 单元测试用 `prototype/assets/photos/` 的实拍图，结果要和 `G-PhotoPipeline` 一致：螺蛳粉、铁锅炖、红烧肉吸附为 `soy`，粘豆包为 `broth`，玉米排骨汤为 `bamboo`。
- 转盘上相邻两道菜撞色时，后一道换成它的第二候选。接口只存一个舞台色，第二候选就取色板里离它最近的另一个颜色。
- 接口现在还没有舞台色和裁切字段：模型里先留可空字段，显示时回落到分类默认色和居中裁切；发布时照样让用户调整、选色，接口有了字段再一起提交。

## 地图与定位

- 底图：`flutter_map` 的 `TileLayer` 加载天地图栅格瓦片（球面墨卡托的 `_w` 系列，底图和注记两层），key 来自配置。整体调色向 `map-ground` 靠，参数做附近页时和设计一起定。
- 坐标：接口和模型用 GCJ-02，设备定位和天地图是 WGS-84。转换只在两处做：调接口前 WGS-84 转 GCJ-02，画到地图上前 GCJ-02 转 WGS-84。转换和距离计算是 `core/location/` 里的纯函数，配单元测试。
- 距离（「320 m」）由客户端按当前位置和店的坐标算，接口不返回距离。
- 定位权限用到时才申请（进附近、选店、新建店），不在启动时要。没有权限或定位失败时页面也要能用，比如退回校区中心点并说明，具体做法做附近页时和产品确认。
- 国内安卓机多数没有 Google 服务，要确认 `geolocator` 用的是系统定位，必要时强制用 `LocationManager`。
- 标记：`MapPin` 是普通组件，放在 `MarkerLayer` 里，选中态、店名胶囊、无障碍标签都直接写；商圈范围用 `PolygonLayer` 的虚线描边。
- 新建店：拖动地图让中间的针对准店门口，停下后（防抖）调 `/hub/locate` 判断属于哪个商圈。
- 「导航去店里」用 `url_launcher` 打开高德地图的 URI，直接传 GCJ-02 坐标。

## 多平台差异

| 方面 | Android | iOS | Web |
| --- | --- | --- | --- |
| token 存储 | Keystore 加密 | Keychain | WebCrypto 加密后放 localStorage |
| 统一认证 | WebView | WebView | 整页跳转 |
| 选图 | 系统照片选择器 | PHPicker | 浏览器选文件 |
| 推送（待接入） | 厂商通道 | APNs | 不做 |
| 热更新 | Shorebird | Shorebird | 部署即更新 |
| 分享 | 系统分享面板 | 系统分享面板 | Web Share，不支持时复制链接 |
| 返回 | 返回键、返回手势 | 右滑返回 | 浏览器后退 |
| 状态栏 | 跟舞台深浅 | 跟舞台深浅 | 没有 |

Web 另外要注意：

- 构建加 `--no-web-resources-cdn`，CanvasKit 随站点一起发布，不从 Google 的 CDN 下载，国内不稳定。字体已经打包，同理。
- 路径式 URL 需要服务器把所有路径回落到 `index.html`。
- 接口走同域的 `/api`，见「配置」。
- 平台相关的代码用条件导入隔离，业务代码不直接用 `dart:io` 和浏览器 API。
- 浏览器定位要求 HTTPS。

Android、iOS 另外要注意：

- 权限说明（定位、相机、相册）用中文写清楚用途：Android 在 `AndroidManifest.xml`，iOS 在 `Info.plist`。
- 国内安卓商店会检查隐私合规：同意隐私政策之前不采集个人信息，权限用到时再申请。上架前按商店的检测要求自查一遍。

## 监控与日志

- Sentry 在第一次分发测试包之前接入，见依赖选型「监控与崩溃上报」。DSN 来自配置，没有 DSN（本地开发）时不启用。
- 上报未捕获的异常、`ParseException` 和其他意料之外的错误。网络失败、业务 `code`、取消只记面包屑，不单独上报，避免噪音。
- release 名带版本号、构建号和 Shorebird 补丁号，崩溃能对到具体补丁。
- 调试构建打开 `dio` 的请求日志，release 不打。

## 测试

| 测什么 | 怎么测 |
| --- | --- |
| 取色、坐标转换和距离、格式化（距离、价格、时间）、重试策略、业务码分类 | 单元测试 |
| `ApiClient` 解包、`code` 检查、各种失败分别变成哪种 `ApiException`、鉴权头 | 单元测试，用假的 `HttpClientAdapter` |
| 会话（登录、需要同意、失效、退出）、分页、乐观更新失败后改回 | `ProviderContainer.test()`，override 接口类 |
| 设计组件的各种状态；页面的占位、失败、内容三种状态；`NavBar` 只在主页面出现；登录重定向 | Widget 测试，override provider |
| 点击区域、文字对比度、可点元素有标签 | Widget 测试里用 `iOSTapTargetGuideline`（44px）、`textContrastGuideline`、`labeledTapTargetGuideline` |
| 令牌和 `tokens.json` 一致；`lib/` 的 import 不违反分层方向 | 单元测试 |

- 替身用 `mocktail` 或手写的假实现，测试不连真接口。
- 测试目录和 `lib/` 一一对应，文件名以 `_test.dart` 结尾。
- 不做 golden 测试：字体渲染在 macOS 和 CI 的 Linux 上不一样，维护成本高。视觉对照靠 Widget Preview 和组件页。
- 端到端测试（`integration_test`）等登录、发布流程稳定后再加。
- CI 的检查步骤在现有的格式检查、`flutter analyze`、`flutter test` 之外，加上 `dart analyze`（`riverpod_lint` 的规则只在它里面报，见依赖选型）和「重新生成代码后 `git diff --exit-code`」。

## 以后再定

| 事情 | 什么时候再看 |
| --- | --- |
| 冷启动离线快照 | 实际在食堂、宿舍的弱网下用过之后 |
| golden 测试 | 设计稳定、需要防样式回退时 |
| 端到端测试 | 登录、发布流程稳定后 |
| Web 宽屏布局、首屏按功能拆包（deferred import） | 有宽屏设计，或测出 Web 首屏太慢时 |
| 本地数据库（优先 `drift`） | 出现草稿箱、离线浏览这类需求时 |
| 推送 | 接口提供推送设备登记后，见依赖选型「推送」 |
