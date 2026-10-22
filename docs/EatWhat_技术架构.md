# EatWhat 技术架构

> 2026-10-22 初稿。依据产品文档（2026-10-22）、现状差距（2026-10-22）、接口 `auth-renewal-20261019`、设计规范与画板「G 定稿」（2026-10-22）。

本文说明客户端怎么搭：分层、目录、状态、路由、网络、存储，以及产品第 11、12 节那些运行保障在代码里落在哪。用到的包和版本见 `EatWhat_依赖选型.md`。行为以产品文档为准，接口没跟上的地方按现状差距过渡。标「待确认」的条目汇总在文末。

## 1. 总体约定

- **一套代码，三端运行**。平台差异只出现在 `lib/core/platform/` 和少数明确标注的地方，页面里不写 `Platform.isIOS`。
- **Provider 和 JSON 用代码生成，路由手写**。Provider 用 `riverpod_generator` 的 `@riverpod`（第 4 节），接口 DTO 用 `json_serializable`（第 7.6 节），都经 `build_runner` 生成 `*.g.dart`。生成文件入库，CI 重新生成一遍并检查没有差异（第 21.3 节）。不用 `freezed`、`retrofit`、`go_router_builder`。选型理由见依赖选型第 3、5 节。
- **不写裸值**。颜色、间距、圆角、阴影、尺寸、动效都来自设计令牌（第 11 节）。
- **业务规则写成纯函数**。权限表、饭点、取色、撞色、坐标转换、跳转规则都放在不依赖 Flutter 组件的文件里，配单元测试。
- **过渡期的做法有统一出口**。「待接入」、按产品规则在客户端拦截、校区和商圈做成配置，都走第 8、17 节的机制，接口上线后改一处即可。
- **文案集中**。动作叫法（「换一个」「就它了」「导航去店里」……）和错误提示放在 `lib/core/copy/`，页面专属文案写在页面里。

## 2. 目录结构与分层

### 2.1 目录

```text
lib/
  main.dart                 入口，只调用 bootstrap()
  bootstrap.dart            启动顺序（第 3 节）
  app.dart                  EatApp：MaterialApp.router、主题、本地化、字号上限
  core/                     基础设施，不含产品规则
    config/                 AppConfig：编译期传入的环境配置
    network/                ApiClient、拦截器、响应外壳解析、ApiException、分页
    storage/                SecureStore、KvStore（shared_preferences）、CacheStore
    failure/                AppFailure 分类；失败 → 「说人话」的提示
    copy/                   通用文案：动作叫法、错误提示
    geo/                    GCJ-02 / WGS-84 转换、距离、「320 m」格式化
    format/                 价格「¥18」、时间「12 分钟前」、计数
    platform/               平台能力的接口和各端实现：定位、选图压缩、分享、外部地图、
                            推送、设备与安装 ID、版本、热更新、浏览器（仅 Web）
    telemetry/              埋点 Analytics、崩溃上报 CrashReporter
  design/                   设计系统，不认识业务数据
    tokens/                 tokens.json 的转写：颜色、字体、间距、圆角、阴影、尺寸、动效、StageColor
    theme/                  EatTheme（ThemeExtension）、StageTheme（舞台色过渡）
    layout/                 断点、宽屏左右布局和居中一栏、舞台高度、字号上限
    stage/                  舞台取色算法、撞色规则（纯函数）
    icons/                  图标名表、EatIcon
    widgets/                Button、Chip、DishPlate、DishTile、ListRow、Panel、Sheet、Stage、
                            StageScaffold、PlainScaffold、NavBar、Tabs、TasteCloud、Turntable、
                            StageColorPicker、MapPin、SearchField、FormField、Switch、RadioRow、
                            PendingTag（待接入）、状态占位（加载、失败、空、没网）
  domain/                   领域模型和产品规则，纯 Dart，不做 IO
    models/                 Dish、Shop、Campus、Hub、MealTime、DishCategory、TasteTag、Comment、
                            Notice、CurrentUser、AccountStatus、CoverCrop、Paged<T> …
    rules/                  权限表、饭点、价格与名称校验、推荐率、消息 → 跳转、菜名断行
  data/                     数据层：按后端资源分组，做 IO
    auth/ consent/ user/ food/ restaurant/ hub/ notification/ upload/ history/ config/ analytics/ …
                            每组：xxx_api.dart（请求与 JSON 解析）、xxx_repository.dart（缓存、合并、转领域模型）
  state/                    跨页面共享的状态：登录态、账号状态、同意记录、远程配置、功能状态、
                            当前位置、地点和饭点、菜的赞和收藏、未读数、网络状态
  features/                 按页面分组：页面、页面私有组件、页面的 Provider
    auth/                   登录、手机号登录、密码登录
    verify/                 认证
    discover/               发现、转盘、地点和饭点面板
    search/                 搜索
    topic/                  专题、往期专题
    dish/                   菜品详情、大图、全部评论、写评论、加标签面板、举报面板
    shop/                   餐厅详情、信息有误
    nearby/                 附近、地图、筛选面板
    publish/                选店、新建店、加菜、调整照片、上传队列、编辑菜品
    profile/                我的、他人主页、编辑资料、我的标签、标签下的菜、足迹、粉丝和关注
    inbox/                  消息
    settings/               设置、账号与安全、登录设备、注销、隐私、屏蔽的人、通知、关于、反馈
    system/                 强制更新、维护、公告、建议更新、拦截面板、人机验证、轻提示
  router/                   路由表、路径常量（paths.dart）、守卫、深链处理、MainShell（NavBar 外壳）
assets/
  fonts/  icons/  illustrations/  config/remote_defaults.json
config/
  example.json              环境配置样例（真实的 dev.json、staging.json、prod.json 不入库）
tool/                       一次性脚本：字体子集化、图标描边变体
test/                       与 lib/ 同构；另有 support/（假实现）、fixtures/（样例 JSON、取色样图）
```

一个功能目录内部先平铺：`dish_page.dart`、`dish_providers.dart`、`widgets/`。文件多了再分子目录，不预先建空层。

### 2.2 依赖方向

| 层 | 可以依赖 | 不能依赖 |
| --- | --- | --- |
| `core` | Flutter SDK、第三方包 | 其他所有层 |
| `design/tokens` | `dart:ui` | 其他所有层（它是叶子，谁都能引用） |
| `design`（其余） | `core`、`design/tokens` | `domain`、`data`、`state`、`features` |
| `domain` | `design/tokens`（只为 `StageColor`） | Flutter 组件、`core/network`、`data` 及以上 |
| `data` | `domain`、`core` | `design/widgets`、`state`、`features` |
| `state` | `data`、`domain`、`core` | `features`、`design/widgets` |
| `features` | 以上全部；`router/paths.dart`（只为路径常量） | 别的功能目录的内部文件、`router` 的其余文件 |
| `router` | `features`（页面构造）、`state` | — |

- 功能之间不互相 import。跳到别的页面用 `router/paths.dart` 里的路径常量；共享的状态放 `state/`；两个功能都要用的组件，没有业务数据的放 `design/widgets/`，有业务数据的放进被依赖较多的那个功能，并在本文登记。
- `design/widgets` 的组件只收基本类型和令牌（图片地址、裁切参数、`StageColor`、文字），不收 `Dish`。
- 用一个测试守住依赖方向：`test/architecture_test.dart` 扫描 `lib/` 下每个文件的 import，按上表报错。同一个测试还检查：`lib/` 和 `test/` 里没有直接导入 `package:flutter/material.dart` 和 `package:flutter_localizations`（用 `material_ui`，见依赖选型第 2 节）；包内跨目录的导入都用 `package:eat/...`。

## 3. 启动流程

`bootstrap.dart` 按下面的顺序走。原则：首帧不等网络；同意隐私政策之前不初始化任何会联网或收集设备信息的 SDK。

| 步骤 | 做什么 | 等不等 |
| --- | --- | --- |
| 1 | `WidgetsFlutterBinding.ensureInitialized()`；Web 上 `usePathUrlStrategy()` | 等 |
| 2 | 读 `AppConfig`（编译期常量） | 立即 |
| 3 | 读本地存储（`shared_preferences`）里的偏好；读安全存储里的 token | 等，几十毫秒 |
| 4 | iOS 卸载重装检测：本地存储里没有「已安装」标记而 Keychain 里有 token，就清掉 Keychain（Keychain 卸载后会残留，`shared_preferences` 不会） | 等 |
| 5 | 读本地同意记录、缓存的远程配置（没有就用内置默认值）、缓存的当前用户 | 等 |
| 6 | 已同意隐私政策：先初始化 Sentry，再 `runApp`；没同意：直接 `runApp` | — |
| 7 | 首帧：有登录态进 `/discover`（先显示缓存），没有进 `/login`；舞台先用上一次的舞台色 | — |
| 8 | 首帧后、已同意：拉远程配置 → 版本检查 → 热更新检查 → `GET /user/info` 校验登录态 → 初始化推送（已登录时） | 后台 |

用户在登录页勾选同意并登录成功后，补做第 6、8 步里还没做的初始化。

## 4. 状态管理

用 Riverpod 3，Provider 用 `riverpod_generator` 生成：写带 `@riverpod` 注解的函数或类，`build_runner` 生成 `xxxProvider`。

### 4.1 Provider 的种类

| 用途 | 写法 | 例子 |
| --- | --- | --- |
| 单例服务 | `@Riverpod(keepAlive: true)` 函数 | `apiClientProvider`、`kvStoreProvider`、`appConfigProvider`、`clockProvider` |
| 跨页面状态 | `@Riverpod(keepAlive: true)` 类（`extends _$Xxx`） | `sessionProvider`、`remoteConfigProvider`、`placeAndMealProvider` |
| 页面数据 | `@riverpod` 类，`build` 带参数（默认自动释放，参数即 family） | `dishDetailProvider(dishId)`、`shopDetailProvider(shopId)` |
| 派生值 | `@riverpod` 函数 | `accountStatusProvider`、`featureStateProvider(feature)` |
| 一次性异步 | 返回 `Future` 的 `@riverpod` 函数 | 往期专题列表 |

`StateProvider`、`StateNotifierProvider` 在 3.x 已移到 `legacy.dart`，不用。实验性的 `Mutation` 和离线持久化也不用。

**生成文件**

- 有 `@riverpod` 的文件写 `part 'xxx.g.dart';`，改完跑 `fvm dart run build_runner build`（开发时可以用 `watch`）。
- `*.g.dart` 入库，不手改。生成结果已经按 `dart format` 排好版，`analysis_options.yaml` 把它们排除在分析之外。CI 用 `build_runner build --only-check` 比对，源文件改了没重新生成、或生成了没提交都会失败。
- `riverpod_lint` 作为分析器插件写在 `analysis_options.yaml` 的 `plugins` 下（不进 `pubspec.yaml`，由分析器自己拉取），检查 Provider 的写法（`runApp` 外面没有 `ProviderScope`、family 参数不合规则等）。它的结果只有 `dart analyze` 报告，`flutter analyze` 看不到。

### 4.2 共享状态（`lib/state/`）

| Provider | 内容 | 谁改 |
| --- | --- | --- |
| `sessionProvider` | 未登录 / 已登录（token、当前用户）；过期时带上原因和原地址 | 登录、退出、过期、刷新用户信息 |
| `accountStatusProvider` | 未登录、未认证、已认证、封禁中（原因、解封时间） | 由 `sessionProvider` 派生 |
| `consentProvider` | 隐私政策同意版本和时间（跨站同步同意由客户端自动发送，不进这里，见 9.5） | 登录页 |
| `remoteConfigProvider` | 远程配置快照（第 17 节） | 启动、回到前台 |
| `featureStateProvider(feature)` | 某个功能当前是：可用、待接入、已关闭、只读维护 | 派生 |
| `locationProvider` | 定位权限状态、最近一次位置（GCJ-02，只在内存） | 发现页、附近页 |
| `placeAndMealProvider` | 当前校区；饭点是自动还是手动，手动的到哪个时间段结束 | 地点和饭点面板 |
| `dishInteractionsProvider` | 菜的赞、收藏、赞数的本地覆盖值，按菜 id | 赞、收藏按钮 |
| `unreadCountProvider` | 未读消息数 | 回到前台、回到发现页、读消息 |
| `networkStatusProvider` | 最近一次请求是否连不上网 | 网络层 |

### 4.3 约定

- 组件里不写业务逻辑：组件只读 Provider、调 Notifier 的方法。页面内的临时 UI 状态（输入框控制器、展开收起）可以用 `StatefulWidget`。
- **乐观更新**：赞、收藏、打标签、关注先改 `dishInteractionsProvider` 等本地覆盖值，所有显示这道菜的地方（转盘、方块、详情）一起变；请求失败就退回原值，并给一句轻提示「没赞上，再试一次」。下次拉到服务端数据时清掉覆盖值。
- **重试**：`ProviderScope(retry: ...)` 统一策略：只对网络错误自动重试，最多 2 次；业务错误、登录过期不重试。页面上的「再试一次」调用 `ref.invalidate`。
- **请求取消**：页面数据的 Provider 在 `ref.onDispose` 里取消自己的 `CancelToken`。
- **暂停**：Riverpod 3 按 `TickerMode` 暂停不可见组件的监听，`StatefulShellRoute` 切走的分支自动暂停，不需要额外处理。
- 测试用 `ProviderContainer.test()` 加 `overrides` 换掉仓库和接口。

## 5. 路由与页面骨架

用 `go_router`。设计规范预设的结构**确认采用**：三个主页面放进 `StatefulShellRoute.indexedStack` 的三个分支；外壳 `MainShell` 是一个 `Stack`，下面是分支内容，上面悬浮 `NavBar`。

### 5.1 路由表

「栈」一列：分支表示在主页面的分支导航器里（显示 `NavBar`）；根表示压在根导航器上（盖住 `NavBar`，产品 6.1 要求详情和流程页不显示导航）。所有登录后的子页面都设 `parentNavigatorKey` 为根导航器。

| 页面 | 路径 | 栈 | 未登录可进 | 画板 |
| --- | --- | --- | --- | --- |
| 发现 | `/discover` | 分支 0 | 否 | `G-HomePhoto` |
| 附近 | `/nearby` | 分支 1 | 否 | `G-Nearby` |
| 我的 | `/me` | 分支 2 | 否 | `G-Me` |
| 登录 | `/login` | 根 | 是 | `G-Login` |
| 手机号登录 | `/login/phone` | 根 | 是 | `G-PhoneLogin` |
| 密码登录 | `/login/password` | 根 | 是 | `G-PasswordLogin` |
| 认证 | `/verify` | 根 | 否 | `G-Verify` |
| 菜品详情 | `/dishes/:dishId` | 根 | 否 | `G-Dish` |
| 全部评论 | `/dishes/:dishId/comments` | 根 | 否 | `G-Comments` |
| 写评论、回复 | `/dishes/:dishId/comments/new` | 根 | 否 | `G-WriteComment` |
| 编辑菜品 | `/dishes/:dishId/edit` | 根 | 否 | `G-AddDish` |
| 餐厅详情 | `/shops/:shopId` | 根 | 否 | `G-Detail` |
| 信息有误 | `/shops/:shopId/report` | 根 | 否 | `G-WrongInfo` |
| 往期专题 | `/topics` | 根 | 否 | `G-TopicArchive` |
| 专题 | `/topics/:topicId` | 根 | 否 | `G-Topic` |
| 搜索 | `/search` | 根 | 否 | `G-Search` |
| 消息 | `/inbox` | 根 | 否 | `G-Inbox` |
| 他人主页 | `/users/:userId` | 根 | 否 | `G-UserProfile` |
| 粉丝、关注 | `/users/:userId/follows` | 根 | 否 | `G-Follows` |
| 编辑资料 | `/me/edit` | 根 | 否 | `G-EditProfile` |
| 我的标签 | `/me/tags` | 根 | 否 | `G-MyTags` |
| 标签下的菜 | `/me/tags/:tagId` | 根 | 否 | `G-TagDishes` |
| 足迹 | `/me/history` | 根 | 否 | `G-History` |
| 设置 | `/settings` | 根 | 否 | `G-Settings` |
| 账号与安全 | `/settings/account` | 根 | 否 | `G-SettingsAccount` |
| 换绑手机、设置或修改密码 | `/settings/account/phone`、`/settings/account/password` | 根 | 否 | 无画板，按白底页规则 |
| 登录设备 | `/settings/account/devices` | 根 | 否 | `G-Devices` |
| 注销账号 | `/settings/account/delete` | 根 | 否 | `G-DeleteAccount` |
| 隐私 | `/settings/privacy` | 根 | 否 | `G-SettingsPrivacy` |
| 屏蔽的人 | `/settings/privacy/blocked` | 根 | 否 | `G-Blocked` |
| 通知 | `/settings/notify` | 根 | 否 | `G-SettingsNotify` |
| 关于 | `/settings/about` | 根 | 否 | `G-SettingsAbout` |
| 反馈 | `/feedback`（可带 `dishId`、`shopId`） | 根 | 否 | `G-Feedback` |
| 发布 1/2 选店 | `/publish` | 根 | 否 | `G-PickShop` |
| 新建店 | `/publish/shop` | 根 | 否 | `G-NewShop` |
| 发布 2/2 加菜 | `/publish/dish?shopId=` | 根 | 否 | `G-AddDish` |
| 强制更新 | `/update` | 根 | 是 | `G-ForceUpdate` |
| 停服维护 | `/maintenance` | 根 | 是 | `G-Maintenance` |

**不进路由表的**：

- 底部面板（地点和饭点、筛选、加标签、举报、拦截、分享、退出确认、建议更新、定位说明、推送询问）：用统一的 `showPanel()` 弹出，不改地址。
- 调整照片（`G-Crop`）、看大图：发布流程或详情页内用 `Navigator.push` 打开的全屏页。它们依赖内存里的照片，刷新页面后无法恢复，所以不给地址。
- 重要公告弹窗、人机验证：弹窗。

过渡期：手机号登录上线前，`/login/password` 先承担「用户名 + 密码」登录，注册沿用用户名方式（现状差距 2.1），页面结构不变。

### 5.2 MainShell 与 NavBar

- `MainShell` = `Stack`：底层是 `navigationShell`，上层是定位好的 `NavBar`（距左右 `space-16`、距底部 `space-24` 加系统底部安全区）。宽屏时 `NavBar` 放进左侧面板底部（第 12 节）。
- 页面通过 `NavBarInset.of(context)` 拿到导航占用的高度，滚动列表底部留出这段空白（约 100px，含安全区）。
- 点当前所在的标签：回到该分支的根并滚到顶部（`goBranch(index, initialLocation: true)`）。
- 发布按钮：`context.push('/publish')`，压在根导航器上。
- 安卓返回键：在附近或我的，先回发现；在发现，退出 App。

### 5.3 守卫

GoRouter 的顶层 `redirect` 调用一个纯函数 `resolveRedirect(输入) → 目标地址或 null`，输入是当前地址、登录态、远程配置里的版本线和维护状态。`refreshListenable` 接一个桥接对象，`sessionProvider`、`remoteConfigProvider` 变化时让路由重新判断。

按顺序判断，命中一条就返回：

| 顺序 | 条件 | 去哪 |
| --- | --- | --- |
| 1 | 当前版本低于强制更新线 | `/update` |
| 2 | 停服维护中 | `/maintenance` |
| 3 | 未登录，且目标不是「未登录可进」的页面 | `/login?from=<原地址>`；过期时再带 `expired=1` |
| 4 | 已登录还去 `/login*` | `/discover` |

`resolveRedirect` 有完整的单元测试，覆盖上面每一条和它们的组合。路由的 `metadata` 标记「未登录可进」，不在守卫里写死路径列表。

### 5.4 登录后回到原页面

- 守卫把原地址放进 `from` 参数（URL 编码）。
- 登录成功后：`from` 是站内路径、能匹配路由表、不是 `/login` 开头，就 `go(from)`；否则 `go('/discover')`。校验是为了防止拼出来的链接把人带到外站。
- 新号码注册后进认证引导（`/verify?onboarding=1`），「先逛逛」再去 `from`。
- 登录过期：网络层发现过期 → `sessionProvider.expire()` 清登录态并记下当前地址 → 守卫跳到 `/login?from=...&expired=1` → 登录页显示「登录过期了，重新登录一下」。同时有多个请求过期时只处理一次。

### 5.5 发布流程的导航

- 入口：`NavBar` 的「＋」、餐厅详情的「加一道菜」（直接 `/publish/dish?shopId=`）、发现页空状态、搜索没结果的「新建一家店」（`/publish/shop`，建好后替换成 `/publish/dish`）。
- 流程状态（选的店、照片、上传队列、表单）在一个随流程释放的 Provider 里；Web 上刷新 `/publish/dish` 时状态没了，守卫让它回到 `/publish`。
- 中途关闭：页面用 `PopScope` 拦住返回，填过内容时弹「这道菜还没发布，确定不要了？」。
- 发布成功：退出发布流程的所有页面，再压入 `/dishes/:id`，提示「发布好了」。这样从详情返回就回到发起发布的页面（产品 6.9）。
- 发布入口的权限拦截在进入流程之前做（第 8 节），不进入流程。

### 5.6 Web 的 URL 策略

- 用 path 策略（`usePathUrlStrategy()`），地址形如 `https://<域名>/dishes/123`，和分享链接、App Links 共用一套路径。
- 服务器把所有非静态文件的路径回落到 `index.html`；`/.well-known/` 下的文件和 `/api` 不回落。
- 浏览器后退等于路由后退。直接打开详情页时没有上一页，详情页左上角的返回改为 `go('/discover')`。

## 6. 分享链接与深链

### 6.1 链接格式

- 分享链接就是 Web 地址：`https://<Web 域名>/dishes/<id>`、`/shops/<id>`、`/topics/<id>`。域名待确认 A1。
- 自定义 Scheme `you.v50to.eat://` 只用于站内回跳（如认证完成后回 App），不对外分享。

### 6.2 装了 App 打开 App，否则打开 Web

| 平台 | 做法 |
| --- | --- |
| Android | App Links：`AndroidManifest.xml` 里给分享路径加 `autoVerify` 的 intent-filter；Web 域名下放 `/.well-known/assetlinks.json`，写正式签名证书的 SHA-256（商店重签名时把商店的证书也写上） |
| iOS | Universal Links：开启 Associated Domains（`applinks:<域名>`）；Web 域名下放 `/.well-known/apple-app-site-association`，限定分享路径 |
| 没装 App | 系统直接在浏览器打开同一个地址，就是 Web 版 |

需要正式签名密钥和 Apple 开发者账号，见待确认 A1。

### 6.3 统一入口：DeepLinkHandler

- 关闭 Flutter 自带的深链处理（安卓 `flutter_deeplinking_enabled=false`、iOS `FlutterDeepLinkingEnabled=false`），所有外部来的链接由 `app_links` 收下，交给 `router/deep_links.dart` 的 `DeepLinkHandler`。原因：统一入口方便做白名单和埋点；以后接远程推送时，安卓厂商通道的离线推送点开会被 Flutter 当成深链而白屏，现在关掉可以提前避开（依赖选型第 10 节）。
- 来源：App Links / Universal Links、自定义 Scheme、通知点击、消息页点击（站内调用同一个函数）。
- 处理：
  1. 只接受 `https://<Web 域名>/...` 和 `you.v50to.eat://...`，取出路径和参数。
  2. 按白名单匹配：`/dishes/:id`（可带 `comment`）、`/shops/:id`、`/topics/:id`、`/users/:id`、`/inbox`、`/verify`、`/me`、`/settings/account/devices`。匹配不上就去 `/discover`。
  3. App 在运行：`push` 到目标，返回回到原来的页面。冷启动：目标就是初始地址，返回去 `/discover`。
  4. 没登录：守卫先去登录页，登录后回到目标（5.4）。
- 消息、推送的「点了去哪」由 `domain/rules/notice_target.dart` 把消息的 `type`、`targetType`、`targetId`、`data` 转成站内路径（产品 10.2 那张表），单元测试覆盖每种类型。

### 6.4 微信内置浏览器

- Web 启动时用 `navigator.userAgent` 判断是否包含 `MicroMessenger`。
- 是微信：顶部常驻一条「在 App 里打开」。点了盖一层引导，箭头指向右上角，写「点右上角，选在浏览器打开」（产品 11.1）。微信里不尝试唤起 App。
- 微信里分享：`navigator.share` 不可用，分享面板只有「复制链接」，复制后提示一句。
- 微信里打开分享链接时显示的标题和缩略图，见待确认 A9。

## 7. 网络层

### 7.1 环境配置

用 `--dart-define-from-file=config/<环境>.json` 在编译期传入，代码里用 `String.fromEnvironment` 读成 `AppConfig`（`core/config/`，`appConfigProvider` 提供）。不写死 IP 和端口。不传文件时每一项都是空串、`ENV_NAME` 是 `dev`，`fvm flutter run -d chrome` 照样能跑，只是调不了接口。

| 键 | 说明 | 例 |
| --- | --- | --- |
| `ENV_NAME` | `dev` / `staging` / `prod` | `prod` |
| `API_BASE_URL` | 业务接口前缀，对应接口文档 `servers` 第一项的反代 `/api` | `https://<域名>/api` |
| `WEB_BASE_URL` | Web 版和分享链接的地址 | `https://<域名>` |
| `ASSET_BASE_URL` | 图片字段是 key 时拼接用的前缀（待确认 A3） | — |
| `SENTRY_DSN` | 为空就不启用崩溃上报 | — |
| `TIANDITU_KEY` | 地图瓦片 Key | — |
| `CAPTCHA_APP_ID` | 人机验证 | — |

- 仓库只放 `config/example.json`；`config/` 下其余的 `*.json` 加进 `.gitignore`。本地复制一份改名为 `dev.json` 再填值；CI 从 Secrets 写出文件再构建。
- 这些值会编进安装包，只放公开的值。
- 推荐 Web 和接口同源（`https://<域名>/` 放 Web，`/api` 反代到业务网关）：Web 不用处理 CORS，以后改用 Cookie 也方便。待确认 A1。

### 7.2 两个客户端

| 客户端 | 用途 | 基础地址 | 鉴权头 | 超时 |
| --- | --- | --- | --- | --- |
| `ApiClient` | 业务接口 | `API_BASE_URL` | 加 | 连接 10 s，收发 15 s |
| `UploadClient` | 向预签名地址 `PUT` 图片 | 无（用完整的 `putUrl`） | **不加**（加了会把 token 发给存储服务，还会破坏签名） | 发送 120 s |

### 7.3 拦截器（按顺序）

1. **鉴权**：有登录态就加头。头名用登录返回的 `tokenName`（当前部署是 `satoken`），值是 `Bearer <tokenValue>`，两者都存在安全存储里，不写死头名。
2. **响应外壳**：所有业务响应都是 `{code, msg, data, timestamp}`。`code == 0` 取 `data` 往下传；否则抛 `ApiException(code, msg)`。HTTP 200 也要判断 `code`。`ErrorResponse` 的 `code` 可能是字符串（集群或授权拦截），按字符串保留。
3. **错误转换**：把 `DioException`、`ApiException` 转成 `AppFailure`（7.5），顺带更新 `networkStatusProvider`、记 Sentry 面包屑（方法、路径模板、业务码，不记参数和响应体）。
4. **日志**：只在调试构建打开，鉴权头和手机号打码。

### 7.4 业务码

接口文档只写了「0 为成功」，没有列错误码。下面是 legacy 分支 `biz_code.dart` 里的定义加上接口文档提到的码，**都要向后端确认是否仍然有效**（待确认 A2）。

| 码 | legacy 含义 | 客户端怎么处理 |
| --- | --- | --- |
| 0 | 成功 | — |
| 10001、10002 | 参数非法、缺失 | 表单就地提示；上报 |
| 10003 | 请求频率过高 | 「操作太快了，慢一点」；验证码场景「验证码发得太频繁了，明天再试」 |
| 20001、20002、20003 | 未登录、token 无效、token 过期 | 登录过期流程（5.4） |
| 20004 | 权限不足 | 重新拉用户信息，按新的账号状态弹拦截面板（第 8 节） |
| 20005、20006 | 接口文档：海外未同意、授权过期或未同步 | `ApiClient` 自动同意后重发原请求，用户看不到（9.5） |
| 30xxx | 用户模块（密码错、验证码错、邮箱不对……） | 每个码一句话，表在 `core/failure/messages.dart` |
| 9xxxx、HTTP 5xx | 系统错误 | 「服务器开小差了，等会儿再试」；上报 |

还缺的码：需要人机验证、功能已关闭、只读维护、操作受限（24 小时不能评论）、内容违规。要后端定义（A2）。

### 7.5 错误转成「说人话」的提示

`AppFailure` 分类和默认提示：

| 类型 | 判断 | 提示 | 附带动作 |
| --- | --- | --- | --- |
| 没网 | 连接错误、DNS 失败、超时 | 网络不太好，再试一次 | 顶部「网络不太好」条，下一次请求成功后消失 |
| 服务器出错 | HTTP 5xx、9xxxx | 服务器开小差了，等会儿再试 | 上报 |
| 登录过期 | 见 7.4 | 登录过期了，重新登录一下 | 清登录态 |
| 没权限 | 20004 或服务端判定 | 不弹提示，弹拦截面板 | 刷新账号状态 |
| 太频繁 | 10003 | 操作太快了，慢一点 | — |
| 已知业务错误 | 在表里的码 | 表里那句 | — |
| 未知 | 其他 | 没办成，再试一次 | 上报，带码和 `msg` |

- 不把服务端的 `msg` 和错误码直接给用户看（产品 6.13、9.11）。例外是封禁原因、操作受限原因这类本来就写给用户的内容。
- 展示位置：页面加载失败就地显示「没加载出来」和「再试一次」；动作失败用轻提示（样式待确认 A6）；面板里提交失败，结果留在面板里。
- 首次加载用占位色块，不用全屏转圈（产品 6.13）。

### 7.6 模型与 JSON

- 不从 `docs/api.openapi.yml` 生成接口客户端（理由见依赖选型第 5 节）。每个接口分组手写一个 `XxxApi`：方法名对应接口，返回 DTO。
- DTO 用 `json_serializable`：类上标 `@JsonSerializable(createToJson: false)`（只发请求体的 DTO 才要 `toJson`），`fromJson` 转给生成的 `_$XxxFromJson`。字段名和接口一致，不一致的用 `@JsonKey(name: ...)`。
- DTO 只在 `data/` 内部用；`XxxRepository` 把 DTO 转成 `domain/models` 里的领域模型。接口字段几乎全是可空的，DTO 照实写成可空，在 repository 里补默认值，UI 拿到的模型尽量不为空。领域模型不做 JSON，不标注解。
- 时间字段是 Unix 毫秒，统一转 `DateTime`。
- 坐标字段用带 GCJ 的那组（`gcjLng`、`gcjLat`），见第 14 节。
- **契约测试**：`test/contract/openapi_paths_test.dart` 用 `yaml` 包读 `docs/api.openapi.yml`，检查每个 `XxxApi` 里登记的「方法 + 路径」都在文档里。后端更新接口文件后先跑它。

### 7.7 分页、防重复

- 分页统一成 `Paged<T>`（`items`、`page`、`hasNext`），对应接口的 `PageResult_*`。列表滚到底自动加载下一页，加载中不重复发。
- 提交类按钮在请求期间不可再点；发布、评论这类在服务端也要防重（后端事项，记入 A2）。

## 8. 账号状态、权限与拦截

### 8.1 建模

- `AccountStatus`：`signedOut`、`unverified`、`verified`、`banned(原因, 解封时间)`。由 `GET /user/info` 的 `verified`、`banned`、`banReason`、`bannedAt` 等字段算出（`AccountStatusVO` 还有 `banExpireAt`）。
- `Capability`：需要拦截的动作，按产品 7.2 的表列：赞、收藏、打口味标签、写我的标签、评论、回复、评价店、关注、发布菜、新建店、编辑删除自己的菜、编辑资料。浏览类、消息、设置、反馈、信息有误、举报、屏蔽、退出、注销对所有已登录状态都开放，不进这张表。
- `domain/rules/permission_policy.dart` 一个纯函数：`check(账号状态, 能力) → 允许 | 需要认证(动作词) | 封禁中(原因, 解封时间)`。产品 7.2 的表一格一格写成单元测试。

### 8.2 功能状态

一个入口能不能用，先看功能状态，再看账号：

| 顺序 | 状态 | 来源 | 表现 |
| --- | --- | --- | --- |
| 1 | 待接入 | 编译期常量表 `core/env/pending_features.dart`，和现状差距一一对应 | 入口照常显示，旁边 `PendingTag`「待接入」；点了不发请求 |
| 2 | 停服维护 | 远程配置 | 整个 App 进 `/maintenance` |
| 3 | 全站只读 | 远程配置 | 写操作点了提示「维护中，暂时不能发布，预计 23:30 恢复」 |
| 4 | 功能关闭 | 远程配置的功能开关 | 点了提示「这个功能暂时关了」，有原因写原因 |
| 5 | 账号拦截 | 8.1 的权限函数 | 弹拦截面板 |
| 6 | 操作受限 | 服务端返回（码待定，A2） | 提示里写原因和恢复时间 |

- 「待接入」是编译期常量而不是远程开关：接口没好时客户端代码也没写，只能随新版本上线。接口上线后改常量、删掉现状差距里对应的一行。
- 远程开关只能把已经做好的功能关掉，不能打开新功能（产品 12.2）。

### 8.3 统一拦截入口

- 所有受限的按钮都调同一个函数 `guardedAction(ref, context, Capability.like, () { ... })`：依次判断 8.2 的状态，被拦就弹对应的面板或提示并返回，否则执行动作。
- 按钮永远照常显示，不隐藏、不置灰（产品 7.3）。
- 拦截面板文案按动作换词：未认证「认证后才能点赞」，主按钮「去认证」（到 `/verify`），次按钮「先逛逛」；封禁中「账号封禁中，暂时不能点赞」，加原因和解封时间，没有「去认证」。动作词表放在 `core/copy/`。
- 服务端和客户端判断不一致时（客户端以为能做，服务端返回没权限）：重新拉用户信息，按新状态弹面板。回到前台时也刷新一次用户信息（产品 7.3「账号状态在别处变了，下一次操作时按新状态处理」）。
- 认证成功后 `sessionProvider` 更新，之前被拦的操作立即可用，不用重新登录（产品 6.3）。

### 8.4 过渡期

- 现状差距 P0：推荐、菜品详情、餐厅详情、菜单、标签、足迹现在要求已认证。`pending_features.dart` 里有一个「浏览需要认证」的开关，打开时这些页面对未认证账号显示认证引导；后端放开后关掉。
- 关注现在只要求登录，产品要求已认证：客户端按产品规则拦（`Capability.follow`）。

### 8.5 待接入的功能

- 设计要求没有接口的功能照样画出来，旁边放「待接入」（8.2 第 1 行）。页面照常写，数据也走 Provider，只是 Provider 先返回放在功能目录里的示例数据（插画和示例文字），不发请求；写操作的按钮点了也不发请求。
- 示例数据只用于演示，插画不能冒充用户上传的照片。
- 接口上线后只换 Provider 的实现、补 `data/` 里的接口类，页面不用改；同时改 `pending_features.dart`、去掉「待接入」，删掉现状差距里对应的一行。

## 9. 本地存储与登录态

### 9.1 存什么、存哪

| 数据 | 存储（没写安全存储的都在 `shared_preferences`，用键的前缀分组） | 作用域 | 退出登录时 |
| --- | --- | --- | --- |
| `tokenName`、`tokenValue` | 安全存储 | 账号 | 删 |
| 安装 ID（首次启动随机生成，用于风控识别设备、埋点） | 安全存储 | 设备 | 留 |
| 隐私政策同意版本和时间 | `prefs.*` | 设备 | 留 |
| 当前校区 | `prefs.*` | 设备 | 留 |
| 手动选的饭点和到期时间 | `prefs.*` | 设备 | 留 |
| 上一次的舞台色 | `prefs.*` | 设备 | 留 |
| 定位说明是否展示过、推送是否问过 | `prefs.*` | 设备 | 留 |
| 关掉的普通公告、看过的重要公告、提示过的建议更新版本 | `prefs.*` | 设备 | 留 |
| 热更新分组号（1–100） | `prefs.*` | 设备 | 留 |
| 最近搜过的词（最多 10 个） | `prefs.*`，键带用户 id | 账号 | 删 |
| 接口缓存（第 10 节） | `cache.*`，键带用户 id | 账号 | `cache.*` 全部删掉 |
| 远程配置快照 | `config.remote`（不在 `cache.*` 下） | 设备 | 留 |
| 埋点队列 | `analytics.queue` | 设备 | 先尝试上报，再清空 |
| 图片磁盘缓存 | `cached_network_image` | 设备 | 留（都是公开内容） |

- 设备级的数据不算「个人数据」：校区选择、问过权限没有、公告看过没有。
- 定位结果只在内存里，不落盘（产品 7.6「不记录轨迹」）。

### 9.2 登录态生命周期

- 登录、注册成功：存 token 和头名 → `GET /user/info` → `sessionProvider` 变成已登录 → 初始化依赖登录的服务（推送绑定、Sentry 用户 id、埋点用户 id）。
- 启动：有 token 就先按已登录进发现页（用缓存的用户信息），后台再校验；校验返回过期就走过期流程。
- 登录一直保持，直到退出、长时间没用、改密码、换绑手机（产品 7.4），失效由服务端判断，客户端不做 token 续期。
- 同一账号可以同时在手机和 Web 上登录，客户端不做互斥。

### 9.3 退出登录

退出确认后按顺序：

1. `POST /auth/logout`（失败也继续）。
2. 解绑推送（设备登记接口上线后），清 Sentry、埋点的用户 id。
3. 删 token；删掉 `cache.*` 的键；删账号作用域的偏好。
4. 清内存：`ProviderContainer` 里依赖账号的 Provider 全部 `invalidate`，`dishInteractionsProvider` 等清空。
5. `go('/login')`。

注销账号走同一套清理。

### 9.4 同意记录与 SDK 初始化

- 登录页的勾选在登录成功后写进本地同意记录（版本 + 时间）。远程配置里有当前隐私政策版本，本地版本更旧时的处理见待确认 A7。
- 跨站同步同意由客户端替用户自动发送，不进本地同意记录，见 9.5。
- 只有本地同意记录存在时才初始化 Sentry、Shorebird 检查、推送、埋点上报、读取设备信息（第 3 节）。

### 9.5 跨站同步同意

默认所有用户都同意，客户端替每个用户发送同意，不做任何同意相关的页面：设计稿里的 `G-RegisterConfirm`、`G-DataNotice`、`G-Reconsent` 不做，账号与安全里的「数据存放」和关于里的《数据存放说明》也不放。产品规则见产品文档 7.5。

- 只接同意接口 `/auth/consent/grant`。同意和注册都要带当前的政策版本，用 `/auth/consent/policy` 读出来。查询状态、撤回不接。
- 代码放在 `data/consent/` 的 `ConsentApi`，以后要接别的同意接口也放这里。
- 注册：新号码验证后直接注册，请求里带 `crossBorderConsent: true` 和 `consentPolicyVersion`，没有「完成注册」这一步。
- 登录或注册返回 `consentProof`：不算登录成功。带上 proof 调同意，成功后用同一组账号密码自动再登录一次；账号密码只为这一次留在内存里。
- 已登录时接口返回 20005 / 20006：`ApiClient` 通过构造时传入的回调（和登录过期一样，`core/network` 不导入 `data/`）不带 proof 调一次同意，用的是当前会话，成功后把原请求重发一次。几个请求同时遇到时只同意一次；同意失败，或重发后还是这两个码，就按 7.5 的「未知」处理。
- 页面不用管这些。20005 和 20006 各指什么、proof 多久过期、不带 proof 的同意在哪些部署下可用，做登录时和后端核对（A2）。

## 10. 离线与缓存

### 10.1 缓存哪些

| 内容 | 键 | 上限 | 过期 | 用途 |
| --- | --- | --- | --- | --- |
| 上一批推荐 | 校区 + 饭点 | 每个组合 1 批 | 不过期，拿到新的就覆盖 | 推荐拿不到时先看上一批 |
| 「今日推荐」第一页 | 校区 + 饭点 | 1 页 | 1 天 | 发现页离线可看 |
| 菜品详情 | 菜 id | 最近 50 道 | 7 天 | 离线可看 |
| 我的：资料、统计、上传第一页 | 用户 id | 1 份 | 不过期 | 离线可看 |
| 当前用户信息 | — | 1 份 | 不过期 | 启动时先用 |
| 取色结果（过渡期，见 13.6） | 图片地址 + 裁切参数 | 500 条 | 不过期 | 避免重复计算 |

`CacheStore` 包在 `KvStore` 外面，每条记录是 `cache.*` 下的一个 JSON 字符串，带写入时间和最近访问时间，超上限按最近访问淘汰。`shared_preferences` 在安卓、iOS 上会把整份数据读进内存，所以缓存总量控制在 1 MB 左右，超了也按最近访问淘汰。

### 10.2 读的流程

- 先显示缓存，同时请求新数据，回来后替换（先旧后新）。缓存标为「旧数据」时不显示特殊样式，只在请求失败时给提示。
- 推荐请求失败、有上一批：转盘用上一批，提示「网络不太好，先看看上次的」（产品 12.6）。
- 请求失败、没有缓存：就地「没加载出来」+「再试一次」。
- 没网：顶部「网络不太好」，已经加载的内容继续能看（产品 6.13）。

### 10.3 写操作

- 发布、评论、赞这些要联网的操作不排队、不离线提交。点了提示没网，表单内容留在页面状态里不丢（产品 12.6）。
- 发布页的照片上传失败可以单张重试（13.3）。

### 10.4 图片

- 安卓、iOS：`cached_network_image` 的磁盘缓存，看过的图离线能看。
- Web：靠浏览器 HTTP 缓存，图片服务器要返回合适的缓存头（A3）。
- 列表和方块按显示尺寸解码（`memCacheWidth`），不把 2048 像素的原图整张解码。图片服务能出缩略图的话按尺寸请求缩略图（A3）。

### 10.5 弱网与加载

手上有数据就先显示，没有才显示占位，失败了可以重试。这里把散在各节的做法汇总成每个页面都要落实的清单，不新增依赖。

**切换页面**

- 三个主页面放在 `StatefulShellRoute.indexedStack` 里（5.2），切走时不销毁，数据只拉一次；它们的 Provider 标 `keepAlive`。
- 看不见的页面不偷偷发请求：Riverpod 3 按 `TickerMode` 暂停不可见页面的监听（4.3）。常驻 Provider 在暂停期间被失效时，回到页面再带着旧数据刷新。
- 详情页的 Provider 自动释放，但看不见以后在内存里再保留 5 分钟（`ref.cacheFor`），回到刚看过的页面不用重新拉；更久的离线可看靠 10.1 的磁盘缓存。
- 从列表点进详情，先用列表里已有的图、名字和舞台色把舞台画出来，只有抽屉里的内容要等。

**重试**

- 读请求的自动重试按 4.3：只对网络错误重试，最多 2 次；业务 `code` 报错、登录过期、解析失败不重试。
- 写操作（发布、评论、赞、关注……）不在 Provider 的 `build` 里，不会被自动重试，`dio` 也不加重试拦截器。失败时保留用户已经输入的内容，由用户再点一次（10.3）。

**加载、失败、没网的样子**

- 加载中：用 `mist` 色块按内容的形状占位（舞台、盘子、方块、列表行），不用转圈（7.5）。
- 失败且没有旧数据：`wifi-off` 图标、「没加载出来」、「再试一次」按钮。后台重试期间状态是「加载中但带着上一次的错误」，这时也显示失败；某次重试成功就自动换成内容。
- 有旧数据时刷新：保留旧内容；刷新失败也不清空，只给一句不打断操作的提示（10.2）。
- 这几种状态是 `design/widgets/` 里的通用状态占位组件，页面按同一条规则选：有数据显示数据，没数据但有错误显示失败，都没有显示占位。

**取消和防抖**

- 每个发请求的 Provider 拿一个 `CancelToken`，Provider 释放时取消（4.3）。离开页面，页面的请求就停了。
- 搜索输入防抖：Provider 先等 300 ms，期间关键词变了（旧的 Provider 被释放）就不发请求。

`cacheFor` 和 `cancelToken` 是 `core/network/` 里给 `Ref` 写的扩展：

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

  /// Provider 释放时取消请求。
  CancelToken cancelToken() {
    final token = CancelToken();
    onDispose(token.cancel);
    return token;
  }
}
```

## 11. 设计令牌落地

### 11.1 转写与校验

- `lib/design/tokens/` 手写转写 `prototype/design-system/tokens.json`：颜色、字体、间距、圆角、阴影、尺寸。动效写在规范 README 里，没有进 `tokens.json`，一起转写。
- `test/design/tokens_test.dart` 读 `tokens.json`，逐项比对 Dart 常量（颜色值、间距、圆角、尺寸、字号、行高、字重）。设计更新导出后跑测试，就知道哪里没同步。
- CSS 到 Flutter 的换算：
  - 行高：`height = lineHeight / fontSize`，并设 `leadingDistribution: TextLeadingDistribution.even`，和 CSS 的上下平分行距一致。
  - 字距：直接用 px 值。
  - 阴影：外阴影转 `BoxShadow`；`inset` 内阴影 Flutter 不支持，按钮的「顶部 1px 高光、底部 2px 内阴影」在 `Button` 里用自定义绘制实现；`shadow-plate` 的 `0 0 0 8px #fff` 是盘沿，用白色外圈实现，不当阴影处理。

### 11.2 ThemeExtension 和常量的分工

| 令牌 | 形式 | 读法 | 理由 |
| --- | --- | --- | --- |
| 颜色、文字样式、阴影 | `EatTheme extends ThemeExtension<EatTheme>` | `context.eat.colors.ink` | 按设计规范做成主题扩展，组件从上下文取，测试时可替换 |
| 间距、圆角、尺寸 | 编译期常量 | `EatSpace.s20`、`EatRadius.pill` | 只有一套浅色主题，这些值不随主题变；常量才能写进 `const EdgeInsets` |
| 动效 | 编译期常量 | `EatMotion.snap`（680 ms，`Cubic(0.2, 0.9, 0.25, 1.1)`） | 同上 |

设计规范写「tokens 做成 ThemeExtension（颜色、间距、圆角、阴影）」。间距和圆角改成常量是实现上的取舍，值和名字不变。

### 11.3 舞台色枚举

`StageColor` 是 9 个值的枚举，每个值带着自己的配色，深浅写死，不在运行时去猜：

| 值 | 颜色 | 深浅 | 文字 | 次级文字 | 次按钮底 | 转盘桌面 / 细边 | 实心按钮 | 分类默认 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `broth` | `#f3c46e` | 浅 | `ink` | `ink-soft` | `stage-ghost-light` | `table-light` / `table-ring-light` | `ink` 底，舞台色字 | 主食 |
| `mango` | `#ffcb45` | 浅 | `ink` | `ink-soft` | 同上 | 同上 | 同上 | 饮品；「我的」默认 |
| `bamboo` | `#d8b27a` | 浅 | `ink` | `ink-soft` | 同上 | 同上 | 同上 | 汤、其他 |
| `chili` | `#d9632b` | 浅 | `ink` | `ink`（不用 `ink-soft`） | 同上 | 同上 | 同上 | 小吃 |
| `porcelain` | `#9db8d9` | 浅 | `ink` | `ink-soft` | 同上 | 同上 | 同上 | 甜品 |
| `matcha` | `#9dbf7a` | 浅 | `ink` | `ink-soft` | 同上 | 同上 | 同上 | 凉菜、配菜 |
| `tomato` | `#c9442b` | 深 | `paper` | `paper` 85% | `stage-ghost-dark` | `table-dark` / `table-ring-dark` | `paper` 到 `paper-bottom` 渐变，舞台色字 | — |
| `redoil` | `#a8321c` | 深 | `paper` | `paper` 85% | 同上 | 同上 | 同上 | 火锅 |
| `soy` | `#8f5b24` | 深 | `paper` | `paper` 85% | 同上 | 同上 | 同上 | 烧烤 |

- 分类到默认色的对应（产品 4.4）写在 `domain/models/dish_category.dart`，分类和后端枚举（`staple`、`drink`……）一一对应。
- 状态栏图标跟着舞台深浅切换（`AnnotatedRegion<SystemUiOverlayStyle>`）。

### 11.4 舞台换色

- `StageTheme` 是一个 `InheritedWidget`，提供当前舞台色的整套配色。外面包一层 `TweenAnimationBuilder`，舞台色变化时背景和文字 500 ms `ease` 一起过渡（规范「动效」）。
- 系统开启减少动态效果（`MediaQuery.disableAnimationsOf`）时直接切换，转盘不自动转，登录页转盘停住。

### 11.5 字体与字号

- 字体文件、子集化见依赖选型第 9 节。文字样式里同时设 `fontWeight` 和 `fontVariations`（可变字体的 `wght` 轴）。
- 中文样式用 `NotoSansSC`；数字样式（`price-hero`、`price-inline`、`stat`、`distance`、`count`）用 `BricolageGrotesque`，回落到 `NotoSansSC`。
- 选中态靠字重，不靠颜色：`tab-active` 900，`tab` 400。

### 11.6 图标

- `EatIcons` 是按用途命名的常量表（`search`、`chevron-right`、`heart-on`……），和 `assets/icons/` 的文件名一致。
- `EatIcon(EatIcons.search, size: 22)`：颜色默认取 `DefaultTextStyle` 的颜色，用 `ColorFilter` 上色；尺寸是 14、16、18 时自动换成加粗描边的变体文件。
- 只有图标的按钮至少 44×44，并带 `Semantics(label: '返回')` 这类说明。

### 11.7 Material 的使用范围

- 用 `material_ui` 的 `MaterialApp.router`、本地化、文本选择菜单、输入框。`ThemeData` 只做最少设置：浅色、关掉水波纹（`NoSplash`）、背景 `paper`、挂上 `EatTheme`。
- 按钮、标签、开关、面板、列表行全部用 `design/widgets/` 里自己的组件，不用 Material 的视觉组件，避免 M3 默认样式混进来。
- 不跟随系统深色模式：`themeMode` 固定浅色（产品 11.2、5.2）。
- 键盘焦点：自定义组件的焦点样式统一画「2px `paper` 内圈 + 2px `ink` 外圈」（规范「状态」）。

## 12. 屏幕适配

### 12.1 断点

| 宽度 | 类型 | 规则 |
| --- | --- | --- |
| < 360 | 窄手机 | 铺满；舞台菜名、价格字号按 `宽度 / 360` 缩小，菜名最小 36px，每行仍不超过四个字 |
| 360–599 | 手机 | 铺满，左右边距 `space-20`，两列方块等分 |
| ≥ 600 | 宽屏 | 有舞台的页面和附近页：舞台铺满，抽屉变成左侧悬浮面板；白底页面居中一栏，最宽 480 |

`design/layout/` 提供 `EatLayout.of(context)`：宽度类型、舞台高度、内容最大宽度、舞台字号系数，页面不自己算。

### 12.2 宽屏的舞台页面

画板 `G-WideHome`。

- 舞台铺满整个屏幕，不随内容滚动，舞台高度就是屏幕高度（不用 12.4 的公式）。
- 抽屉变成左侧悬浮面板：宽 400，离屏幕边 `space-16`，四角 `radius-sheet`，压在舞台色上不加阴影（规范 `Sheet`）。面板里的内容用自己的 `CustomScrollView` 单独滚动，底部留出 `NavBar` 的高度。
- 舞台内容排在面板右边那块区域：菜名、价格、按钮靠左，盘子靠右，盘子按这块区域的高度缩放（800 高时主盘子 440）。
- 发现页的转盘中心放在屏幕右侧外面，菜沿着右边缘上下转：下一道从右上角露出来，上一道在右下角，再远的隐藏。换菜的动画、吸附曲线和手机一样。
- 发现页的地点、搜索、通知从舞台顶栏挪到面板顶部，用 `ink`。
- `NavBar` 放在面板底部，距面板左右和底部 `space-20`；发现、附近、我的三个页面位置一致，切换时不动。
- `StageScaffold` 在宽屏时换成这种左右布局，页面传进来的舞台内容和抽屉 sliver 不变。
- 白底页面放在居中一栏，最宽 480，内容用横向留白挤到中间（`max(0, (宽 - 480) / 2)`）。

### 12.3 附近页宽屏

画板 `G-WideNearby`。

- 地图铺满整个屏幕；抽屉变成和 12.2 一样的左侧悬浮面板，列表和地图同时看。
- 面板压在地图上，加 `shadow-float`。
- 商圈标签从面板里挪到地图上方，做成浮层（`shadow-float`），从面板右边 `space-24` 开始排。
- `NavBar` 放在面板底部，和发现页一致。

### 12.4 舞台高度

- 舞台高度 `H = clamp(屏幕高度 × 520 / 844, 420, 560)`；844 高时正好 520。
- 盘子和转盘按 `H / 520` 等比缩放。
- 舞台内容（菜名、价格、按钮）贴着舞台底部排，底部留出被抽屉压住的 32px 加间距，保证不被盖住。
- 高屏多出来的高度自然给了抽屉。

### 12.5 StageScaffold

有舞台的页面（发现、菜品详情、餐厅详情、我的、他人主页、发布第 2 步）都用 `StageScaffold`：

- 参数：舞台色、舞台内容（盘子、文字、按钮）、抽屉内容（一组 sliver）、可选的顶栏。
- 结构：一个 `CustomScrollView`。第一个 sliver 是舞台，它的布局高度是 `H - 32`、绘制高度是 `H`（自定义一个很小的 `RenderSliver`，`layoutExtent < paintExtent`），后面的抽屉 sliver 从 `H - 32` 开始画，正好压住舞台底部 32px；抽屉用 `DecoratedSliver` 画白底和顶部 `radius-sheet` 圆角，压在舞台色上不加阴影。
- 抽屉跟着页面一起滚（规范 `Sheet`）。附近页例外，用自己的可拖动面板。
- 有 Widget 测试保证：舞台高度按 12.4 计算；抽屉顶部在 `H - 32`；舞台按钮不被抽屉盖住。
- 白底页面用 `PlainScaffold`：44×44 返回、`page-title` 大标题、`space-20` 边距。

### 12.6 安全区、方向、键盘

- 顶部栏在状态栏下面；舞台色延伸到状态栏后面。`NavBar` 底部是 24px 加系统底部安全区。
- 方向：手机（最短边 < 600）启动时锁竖屏；平板和 Web 不锁，按宽屏规则排。iOS 的 `Info.plist` 允许 iPad 横屏。
- 键盘：输入框获得焦点时滚到可见；底部主按钮（下一步、发布、发送）跟着 `viewInsets.bottom` 浮在键盘上方。

### 12.7 系统字号

| 文字 | 跟随上限 | 做法 |
| --- | --- | --- |
| 正文、列表、按钮 | 2 倍 | 根部 `MediaQuery.withClampedTextScaling(maxScaleFactor: 2.0)` |
| 底部导航、胶囊标签等固定尺寸控件 | 1.3 倍 | 组件内部再夹一次 `maxScaleFactor: 1.3` |
| 舞台菜名、价格、页面大标题 | 不跟随 | `TextScaler.noScaling` |

字号放大后文字换行，按钮跟着变高，不截断。用 Widget 测试在 2 倍字号下检查主要页面没有溢出。

## 13. 图片上传与舞台取色

### 13.1 流程

```text
选图（拍照 / 相册多选）
  → 压缩（长边 ≤ 2048，JPEG 质量 85，去 EXIF）
  → 加进上传队列，立刻在后台上传
  → 第一张自动进「调整照片」：得到裁切参数 + 实时算三个推荐色
  → 填表
  → 发布：等所有照片传完，提交 key 列表、裁切参数、舞台色和备选色
```

### 13.2 选图与压缩

- `image_picker`：拍照或相册多选（最多补到 9 张）；Web 上是文件选择框。
- `flutter_image_compress` 的 `compressWithList`：长边不超过 2048，JPEG 质量 85；头像长边 640。默认去掉 EXIF，照片里的 GPS 位置不会传上去，方向统一校正。
- 一张一张顺序压缩，避免同时解码多张大图占内存。
- HEIC：iOS 上原生能解；Web 上取决于浏览器（iOS Safari 选图时通常会转成 JPEG），解不了就提示「这张照片格式不支持，换一张」。

### 13.3 上传队列

- 每张照片一个条目，状态：等待 → 上传中（进度）→ 完成（得到 key）/ 失败。
- 单张上传三步（接口 Upload 分组）：`POST /upload/presign`（`biz` 为 `foods`、`avatar` 或 `restaurants`，带 `contentType`、`fileSize`）→ 用 `UploadClient` 向 `putUrl` `PUT` 原始字节 → `POST /upload/complete`。拿到的 `key` 发布时写进 `pictureUrl`。
- 同时最多传 2 张。失败的单张显示「重试」，重试从申请签名开始（签名可能已过 `expireAt`）。
- 「后台上传」指在发布页填表时并行上传。App 切到后台时 iOS 可能挂起请求，回到前台后失败的条目自动重试一次。范围待确认 A13。
- 发布按钮在照片没传完时显示进度（产品 6.9），全部完成才真正提交。
- 队列随发布流程的 Provider 释放；不存草稿（产品 6.9）。
- Web 直传要求对象存储允许本站域名跨域 `PUT`（A3）。

### 13.4 圆形裁切参数

- 「调整照片」只产出参数，不生成裁好的图：`CoverCrop(centerX, centerY, diameter)`。`centerX`、`centerY` 是圆心在原图里的位置（0–1，按原图宽高归一），`diameter` 是圆的直径占原图短边的比例（默认 1，即短边内切圆，居中）。
- 和分辨率无关：缩略图、原图、不同尺寸的盘子都按同一组参数裁。`DishPlate` 收图片地址和这组参数。
- 手势：拖动、双指缩放，缩放滑条是替代操作（规范「无障碍」）。参数限制在圆不超出原图的范围内。
- 接口字段还没有（现状差距 P0），格式要和后端约定（A3）。没有之前裁切默认居中，改选存不下来。
- 头像需要真的裁：把圆形区域画到 `PictureRecorder`，导出 PNG，再压成 JPEG 上传。

### 13.5 舞台取色算法

放在 `lib/design/stage/stage_palette.dart`，纯函数：输入像素和裁切参数，输出三个 `StageColor` 和「是否可靠」。

1. 把封面按长边 ≤ 256 解码（`ui.instantiateImageCodec` 的目标尺寸），拿 RGBA。
2. 只取圆内的像素（裁切参数映射到缩小后的坐标），跳过透明像素。
3. 转到 OKLab / OKLCh。权重 = 彩度 × 亮度系数（太黑、太白的像素降权）。
4. 色相分 36 个区间按权重累计，取权重最大的区间（连同两侧相邻区间），这部分像素的加权平均就是代表色。
5. 可靠性：圆内「有颜色」的像素（彩度超过阈值）权重占比太低，判为太灰。
6. 吸附：按 OKLab 距离给 9 个舞台色排序，取前三。太灰时：第一个换成分类默认色（还没选分类就用 `broth`，选了分类后自动换成分类色；用户手动选过就不再动，产品 6.9），后两个取排序里的前两个。
7. 阈值写成常量，用样图调。

**验收**：`prototype/assets/photos/` 的 5 张样图复制到 `test/fixtures/photos/`，按设计资源说明的实测结果写测试：螺蛳粉、铁锅炖、红烧肉 → `soy`；粘豆包 → `broth`；玉米排骨汤 → `bamboo`。

**撞色**：`resolveTurntableColors(菜列表)`：相邻两道的舞台色相同，后一道临时用第一个备选色，不改保存的值（产品 4.7）。纯函数，单元测试。

**在哪算**：发布时在「调整照片」页实时算（裁切变化后防抖 100 ms）。256 像素的图在三端主线程上都够快，不开 isolate。结果随菜品保存，所有人看到同一个颜色（产品 4.7）。

### 13.6 过渡期：从封面现算

接口还没有舞台色字段时（现状差距 P0），显示一道菜之前从封面现算：

- 转盘一批 8 道，预取下一批时顺便算。
- 结果按「图片地址 + 裁切参数」缓存（10.1）。
- Web 上读像素要求图片服务器允许跨域（A3）；读不到就用分类默认色。
- 字段上线后去掉现算，直接用保存的值。

### 13.7 显示

- 舞台和转盘：`DishPlate`，按裁切参数显示，加盘沿。加载前盘子里是 `mist` 底，不用插画顶替。
- 方块（`DishTile`）：原图 `cover`，不套盘沿。
- 大图：先上传者的照片，再评论里的照片，每张标出是谁拍的。

### 13.8 自动去掉背景

推荐由后端在上传完成后生成去背景版本（依赖选型 D8）。客户端：「调整照片」里的开关受远程配置的功能开关控制；开关状态随菜品保存；显示时开关为开且有去背景图就用去背景图，否则退回圆形裁切。后端没做之前，开关显示「待接入」。

## 14. 定位、地图与导航去店里

### 14.1 坐标系

| 来源或去处 | 坐标系 | 处理 |
| --- | --- | --- |
| 设备定位（安卓、iOS、浏览器） | WGS-84 | 拿到后立刻转 GCJ-02 |
| 接口参数和返回（`gcjLng`、`gcjLat`） | GCJ-02 | 原样用 |
| 接口里的 GeoJSON（餐厅 `location`、商圈 `boundary`、`center`） | 未说明（目录导入同时有 `centerWgs`、`centerGcj`，推测 GeoJSON 是 WGS-84） | 待后端确认（A3） |
| 天地图瓦片 | CGCS2000（与 WGS-84 差厘米级） | 画到地图上之前，GCJ-02 转 WGS-84 |
| 高德、腾讯、百度的导航 URL | GCJ-02（百度用 `coord_type=gcj02` 指定） | 原样用 |
| Apple 地图 URL | 大陆境内的处理方式没查到资料 | 真机验证后定 |

- 转换在 `core/geo/`：WGS-84 → GCJ-02 是公开算法；GCJ-02 → WGS-84 用迭代反算，误差在米级。单元测试用几组已知点验证。
- 距离：两点都用 GCJ-02 算球面距离。显示「320 m」「1.2 km」。混用坐标系会差几百米，所以所有距离计算只接受 GCJ-02 的类型（用两个不同的类型 `GcjPoint`、`WgsPoint` 防止混用）。

### 14.2 定位

- `LocationService`（`core/platform/location/`）包住 `geolocator`，对外只给 GCJ-02 的位置和权限状态。
- 第一次进发现页：先弹说明「允许定位后，能看到离你多远」，用户点了再申请系统权限（产品 6.13）。拒绝后记下来，不再反复弹。
- 只在需要时定位（进发现页、附近页、发布选店、新建店），不后台定位、不记录轨迹，位置不落盘（产品 7.6）。
- 没有权限，或离校区中心超过 5 km（阈值来自远程配置）：不显示距离，改显示商圈名；附近以校区中心为准。
- Web 只在 HTTPS 下能定位；微信内置浏览器走同样的浏览器定位。

### 14.3 校区和商圈

- 校区列表（名称、中心点、包含哪些商圈）先放在远程配置里，内置默认值只有软件园（现状差距 P1：先做成配置，不写死在业务代码里）。软件园中心点坐标和商圈对应关系要运营提供。
- 商圈的范围和名称用接口 `/hub/list`、`/hub/detail`；按位置判断商圈用 `/hub/locate`。
- 第一次打开：有定位就选最近的已开放校区，没有就选软件园；之后记住（产品 4.1）。

### 14.4 地图（附近页、新建店）

方案待确认 D1（依赖选型第 7 节），下面按推荐的 `flutter_map` + 天地图写：

- 图层从下到上：天地图底图（`vec_w`）→ 注记（`cva_w`）→ 商圈范围（虚线框，填充 24% 当前舞台色，规范 `MapPin`）→ 店铺标记 → 我的位置。
- 标记是 Flutter 组件：普通 44px、选中 72px 加舞台色外圈和店名胶囊。同时只放大一个。每个标记带店名的语义标签。
- 交互：禁止旋转；拖动结束后防抖 400 ms，用新的地图中心（转 GCJ-02）调 `/restaurant/search` 重新加载；点标记选中并让列表滚到它，再点进餐厅详情；点商圈胶囊把地图缩放到商圈范围，并带 `hubId` 过滤列表。
- 底图颜色：整体加一个色彩矩阵滤镜，往 `map-ground` 的暖色靠。做不到严格按 `map-*` 令牌（D1）。
- 地图左下角按天地图要求显示标识和审图号。
- 出问题退回列表（产品 12.6）：瓦片连续加载失败超过阈值，或 Key 无效，附近页切成只有列表，提示「地图没加载出来，先看列表」。
- 新建店选点：地图中心固定一个图钉，拖动地图对准店门口；停下后用中心点调 `/hub/locate` 显示所属商圈。默认中心是当前位置。

### 14.5 导航去店里

`ExternalMapLauncher`（`core/platform/external_maps/`）：

| 平台 | 地图 App | 链接 | 检测是否安装 |
| --- | --- | --- | --- |
| iOS | Apple 地图 | `maps://?daddr=<纬度>,<经度>&dirflg=w` | 系统自带，总是列出 |
| iOS | 高德 | `iosamap://path?sourceApplication=<应用名>&dlat=&dlon=&dname=&dev=0&t=2` | `canLaunchUrl`，`Info.plist` 声明 `iosamap` |
| iOS / 安卓 | 百度 | `baidumap://map/direction?destination=latlng:<纬度>,<经度>\|name:<店名>&coord_type=gcj02&mode=walking&src=<应用标识>` | 声明 `baidumap` |
| iOS / 安卓 | 腾讯 | `qqmap://map/routeplan?type=walk&to=<店名>&tocoord=<纬度>,<经度>&referer=<Key>` | 声明 `qqmap` |
| 安卓 | 高德 | `androidamap://route?sourceApplication=<应用名>&dlat=&dlon=&dname=&dev=0&t=2` | `<queries>` 声明 |
| Web | 高德网页版 | `https://uri.amap.com/navigation?to=<经度>,<纬度>,<店名>&mode=walk&coordinate=gaode&callnative=1` | — |

- 步行方式（`t=2`、`mode=walk`）：校区周边的店基本走着去。
- 装了几个列几个，让用户选（产品 6.6）；只有一个就直接打开；一个都没有就打开高德网页版。
- iOS 的 Apple 地图在大陆用的是高德数据，传入的坐标按哪个坐标系解释没查到资料，真机验证后决定传 GCJ-02 还是 WGS-84。
- 已关门的店「导航去店里」不可用（产品 6.6）。
- 链接参数里的店名做 URL 编码。

## 15. 推送

现在不接远程推送（安卓厂商通道、iOS APNs 都先不做），用本地通知顶上（依赖选型第 11 节）。推送能力全部收在 `PushService` 接口后面，以后接远程推送只加一个实现，设置页、消息页、深链这些调用方不改。

### 15.1 接口

```dart
// core/platform/push/push_service.dart
abstract interface class PushService {
  /// 同意隐私政策并登录后调用一次。
  Future<void> init();

  /// 系统通知权限的当前状态，以及申请权限。
  Future<PushPermission> permission();
  Future<PushPermission> requestPermission();

  /// 把一条站内通知交给系统显示。远程实现由服务端下发，这里可以什么都不做。
  Future<void> show(PushNotice notice);

  /// 点通知后要去的站内路径。冷启动由 initialLink 给出，运行中从 taps 来。
  Future<String?> initialLink();
  Stream<String> get taps;

  /// 设备登记用的标识。本地实现返回 null；远程实现返回推送注册 ID。
  Future<String?> deviceToken();

  /// 退出登录时调用：清掉已显示的通知，远程实现还要解绑设备。
  Future<void> unbind();
}

enum PushPermission { notAsked, granted, denied }

enum PushKind { comment, likeAndFavorite, follow, system }

class PushNotice({
  required final String id,          // 消息 id，用来去重
  required final PushKind kind,      // 评论和回复、赞和收藏、关注、系统消息
  required final String title,
  required final String body,
  required final String link,        // 站内路径，如 /dishes/12?comment=34
}) {}
```

| 实现 | 平台 | 说明 |
| --- | --- | --- |
| `LocalPushService` | Android、iOS | `flutter_local_notifications`。`show` 弹系统通知，`deviceToken` 返回 null |
| `NoopPushService` | Web；未同意隐私政策 | 全部空操作，`permission` 返回 `denied` |
| 远程实现（以后） | Android、iOS | 接厂商通道、APNs 时新增，见依赖选型待确认 D2 |

用哪个实现由 `pushServiceProvider` 按平台和同意状态决定，测试里用假实现覆盖。

### 15.2 本地通知从哪来

本地通知没有服务端下发，要客户端自己发现新消息，由 `features/inbox/` 里的 `NoticeWatcher` 负责：

- **前台**：按产品 10.3，回到前台、回到发现页时刷新未读数，不弹系统通知（和产品「前台收到推送只刷新未读数」一致）。
- **退到后台**：每 5 分钟拉一次新消息，最多持续 30 分钟，间隔和时长放在远程配置里。拉到比上次通知过的更新的消息，按 15.3 的规则交给 `PushService.show`。
- **限制**：只有进程还活着时才有效。安卓退到后台后进程通常还能活一段时间；iOS 挂起后计时器停止，基本只有刚退到后台的几十秒；App 被杀后都收不到。消息页不受影响（产品 12.6）。
- 上次通知到哪一条记在 `prefs.*`，同一条消息不重复弹。

### 15.3 规则

产品 10.4 原本由服务端做的规则，本地通知期间都在客户端做；接远程推送后改回服务端，客户端只读写开关。

- **按类型开关**：设置 → 通知里的四个开关（评论和回复、赞和收藏、关注、系统消息），默认都开。接口上线前存在本地 `prefs.*`，按账号区分。
- **合并**：赞和收藏，同一道菜 1 小时内合成一条「Momo 等 5 人赞了你上传的番茄牛腩饭」；评论、回复、关注、系统消息一条一弹。
- **免打扰**：23:00–08:00 不弹，这段时间的消息只进消息页。
- **权限时机**：不在第一次打开时要（产品 10.4）。第一次发布成功后，先弹面板「有人赞你的菜、评论你的菜时告诉你？」，用户同意再调 `requestPermission`（安卓 13 起 `POST_NOTIFICATIONS`，iOS 通知授权）。拒绝后在设置 → 通知里显示状态和「去系统设置打开」（用 `geolocator` 的 `openAppSettings`，Web 不显示）。
- **点通知跳转**：通知带上 `link`，点了交给 `DeepLinkHandler`（6.3），和点消息一样。冷启动时用 `initialLink`。

### 15.4 其他

- **初始化时机**：同意隐私政策并且已登录之后（第 3 节第 8 步）。
- **推送出问题不影响消息页**（产品 12.6）：消息页只依赖接口。
- **Web**：没有推送。设置 → 通知里写「网页版没有推送，消息在消息页看」。

## 16. 版本与更新

### 16.1 建议更新、强制更新

- 版本线在远程配置里，按平台给：最新构建号（建议更新）、最低可用构建号（强制更新）、商店地址。
- 比较用构建号（`package_info_plus` 的 `buildNumber`，CI 用 `github.run_number`），不比较版本名。
- 强制更新：守卫第 1 条，所有页面都进 `/update`，只能去更新。尽量少用（产品 12.1）。
- 建议更新：在发现页弹一次面板「有新版本」，按钮「去更新」「下次再说」。同一个构建号只提示一次，记在 `prefs`。
- 「去更新」：iOS 打开 App Store 页面；安卓去哪取决于分发渠道（待确认 A12）。
- 版本检查从第一个上架版本起就要带上，否则以后没法让旧版本更新（现状差距 2.1）。

### 16.2 热更新

方案待确认 D3（依赖选型第 12 节）。下面按推荐的 Shorebird 写。

- `shorebird.yaml` 里 `auto_update: false`，由我们决定什么时候检查、检查哪个轨道。
- 同意隐私政策、拿到远程配置之后：
  1. 读分组号（首次随机生成 1–100，存 `prefs`）。
  2. 远程配置里取当前版本的补丁放量比例。分组号 ≤ 比例走 `beta` 轨道，否则走 `stable`。
  3. `checkForUpdate(track:)` 有新补丁就 `update(track:)` 静默下载。下次启动生效，不提示（产品 12.1）。
- 放量：新补丁先发 `beta` 轨道，比例从 5% 开始调；没问题后发到 `stable`，比例清零。
- 回退：控制台回滚补丁；补丁启动就崩时 Shorebird 在设备端自动退回上一个补丁（需要实测确认）。
- 「关于」页显示「版本 0.3.0（30）补丁 2」：版本名、构建号来自 `package_info_plus`，补丁号来自 `readCurrentPatch()`。崩溃上报和埋点都带补丁号。
- 范围：只修问题和不改变功能范围的小改动；新功能、新权限、新的数据收集都发新版本（产品 12.1）。发布清单里加这一条检查。
- CI：打 tag 发版时用 `shorebird release android` / `shorebird release ios` 代替 `flutter build`，补丁用手动触发的工作流 `shorebird patch`。Flutter 版本必须和 `.fvmrc` 一致。需要 `SHOREBIRD_TOKEN`。
- 新版本（商店版本）按比例发布受商店能力限制，见待确认 A11。

### 16.3 Web 新版提示

- 每次 Web 构建都带 `--build-number`，产物里的 `version.json` 有构建号；启动时 `package_info_plus` 读到的就是它。
- 回到前台（`visibilitychange`）和每 30 分钟，请求一次 `version.json?t=<时间戳>`，构建号变大就在顶部提示「有新版本，刷新一下」。点了才刷新，不强制，正在填的内容不丢（产品 12.1）。
- 不用 Service Worker（Flutter 的 Service Worker 已经标为过时），避免旧版本被缓存住。
- 托管的缓存头：`index.html`、`flutter_bootstrap.js`、`main.dart.js`、`version.json`、`assets/` 下的清单文件都设 `no-cache`（带 ETag 协商）；开 gzip 或 brotli。
- 构建用 `--no-web-resources-cdn`，CanvasKit 从我们自己的域名加载（默认的 `www.gstatic.com` 大陆访问不到）。

## 17. 远程配置与 A/B 测试

### 17.1 接口

由业务后端提供一个接口（现状差距 P1），客户端启动和回到前台时拉取。建议的形状（待确认 A5）：

```json
{
  "configVersion": 12,
  "flags": {
    "publish": { "on": true },
    "newShop": { "on": true },
    "comment": { "on": false, "reason": "评论区在调整，明天恢复" },
    "push": { "on": true },
    "topic": { "on": true },
    "autoCutout": { "on": false }
  },
  "params": {
    "mealWindows": { "breakfast": "05:00-10:30", "lunch": "10:30-14:30", "dinner": "14:30-20:30", "night": "20:30-05:00" },
    "batchSize": 8,
    "categoryOrder": ["staple", "snack", "drink", "dessert", "soup", "hot_pot", "grill", "cold_dish"],
    "shopRateMinVotes": 5,
    "distanceHideKm": 5
  },
  "campuses": [
    { "id": "software-park", "name": "软件园", "gcjLng": 0, "gcjLat": 0, "hubIds": [] }
  ],
  "announcements": [
    { "id": "a-1022", "level": "normal", "text": "……", "campusIds": [], "platforms": [], "minBuild": 0, "maxBuild": 0 }
  ],
  "maintenance": { "mode": "none", "until": null, "message": null },
  "versions": {
    "android": { "latestBuild": 30, "minBuild": 20, "storeUrl": "" },
    "ios": { "latestBuild": 30, "minBuild": 20, "storeUrl": "" }
  },
  "patchRollout": { "30": 5 },
  "experiments": { "turntable_cta": "b" },
  "privacyPolicyVersion": "2026-10-22"
}
```

- 请求带平台、构建号、当前校区，服务端按这些筛公告。
- 风控阈值也是运营参数（产品 12.2），但只在服务端用，不下发。

### 17.2 兜底

- 内置默认值 `assets/config/remote_defaults.json`，和上面的形状一样。
- 启动：先用缓存的快照，没有就用内置默认值，**不等网络**；再后台拉新的，拉到就替换并存下来。
- 拉取超时 3 s；失败不提示用户，用上次的（产品 12.2）。
- 回到前台时，距上次成功拉取超过 10 分钟就再拉一次。
- 逐项校验：某一项格式不对，只这一项退回默认值，不整份作废；不认识的键忽略。
- 接口没上线之前：只有内置默认值，功能都按开启处理，没有公告和维护提示（现状差距 2.1）。

### 17.3 各项怎么用

| 内容 | 用在哪 |
| --- | --- |
| 功能开关 | `featureStateProvider`，入口照常显示，点了提示「这个功能暂时关了」（第 8 节） |
| 饭点时间段 | `domain/rules/meal_time.dart` 按当前时间算饭点；手动选择保持到当前时间段结束（产品 4.5） |
| 推荐每批几道 | 转盘圆点数量 |
| 分类栏顺序 | 发现页分类栏 |
| 推荐率显示门槛 | 不满门槛只写「3 人评过」（产品 9.7） |
| 普通公告 | 发现页抽屉顶部一条，可以关掉，关掉的 id 记在 `prefs` |
| 重要公告 | 打开 App 时弹窗，看过一次不再弹 |
| 维护 | 只读：写操作被拦（第 8 节）；停服：进 `/maintenance`，写预计恢复时间 |
| 版本线 | 第 16 节 |
| 补丁放量 | 第 16.2 节 |
| 实验分组 | 17.4 |

### 17.4 A/B 测试

- 分组在服务端按账号算，放在配置的 `experiments` 里，同一个人换设备也在同一组（产品 12.3）。未登录时没有实验。
- 客户端读法集中在 `state/experiments.dart`：`variantOf('turntable_cta', 默认: 'control')`。拿不到就是对照组。
- 实验组件第一次真正显示时记一次曝光事件（第 19 节），分析时按曝光算。
- 代码评审时检查实验不碰产品 12.3 列的禁区（隐私和权限、协议和同意、举报和屏蔽、安全和风控提示、价格和距离的真实性），任何一组都不能少掉核心功能。
- 同一人最多 3 个实验、互斥规则在服务端保证。
- 实验结束后全量或撤掉，删掉分支代码，不留长期分叉。

### 17.5 远程配置不能做的事

不能打开新的数据收集或权限、不能改隐私政策承诺的做法、不能上线新功能（产品 12.2）。落到代码上：埋点事件和采集字段在代码里定义，配置只能关、不能加；功能开关只能关掉已有功能；「待接入」不受远程配置控制。

## 18. 认证跳转与人机验证

### 18.1 山大统一认证

- 只用于认证，不是登录方式（产品 6.3、7.1）。现状差距 P0：后端回调现在是签发登录，要改成记到当前账号；改好之前认证页的统一认证显示「待接入」，只开放邮箱认证。
- 推荐流程（待确认 A4）：
  1. 认证页调后端接口拿一个一次性、短时效的绑定票据（需要登录态）。
  2. 打开 `<API>/auth/sdu?ticket=<票据>`：App 用 `url_launcher` 的应用内浏览器（iOS SFSafariViewController，安卓 Custom Tabs）；Web 在当前标签页跳转。
  3. 学校页面完成后，后端用票据把结果记到对应账号，最后显示「认证完成，回到 App」页面（带一个回 App 的链接），Web 则跳回 `<Web>/verify`。
  4. 回到 App（`AppLifecycleListener` 的恢复事件）或回到 `/verify` 时，自动调 `/auth/verify` 和 `/user/info` 刷新状态；也可以点「我已完成，刷新一下」（产品 6.3）。
- 不用 WebView 打开学校页面：认证页写着「我们看不到你的统一认证密码」，用系统浏览器页更站得住；也不需要像 legacy 那样把 `satoken` 放进 WebView 请求头。
- 不把登录 token 放进 URL。

### 18.2 邮箱认证

`GET /auth/sendEmail` 发链接，用户在邮箱里点开完成；回到 App 时同样自动刷新状态。

### 18.3 人机验证

服务商待确认 D6（依赖选型第 15 节）。

- 触发：后端返回「需要人机验证」的业务码（A2）时，网络层把这个请求挂起，弹出人机验证；拿到票据后带上票据重发原请求；用户关掉验证就按失败处理。
- `HumanVerifier` 接口：App 用 `webview_flutter` 加载我们托管的 H5 页（里面是服务商的 JS），结果经 `JavaScriptChannel` 回传；Web 用条件导入，在页面里直接加载同一份 JS。
- 票据由后端调服务商接口校验，客户端不判断结果真假。
- 客户端基础节流（现状差距 2.1）：验证码 60 秒倒计时、提交类按钮防连点。

## 19. 统计埋点与崩溃上报

### 19.1 埋点

方案待确认 D5，推荐自建（依赖选型第 14 节）。

- 接口：`Analytics.track(事件)`。事件是一组固定的类型（`sealed class`），属性只有枚举、id、数字、时长，**没有自由文本**，从类型上保证不采集输入框内容（产品 12.5）。

| 事件 | 什么时候 | 主要属性 |
| --- | --- | --- |
| `app_open` | 冷启动、回到前台 | 来源：图标、推送、链接 |
| `page_view` | 页面离开时 | 页面名、停留毫秒 |
| `dish_shuffle` | 换一个（按钮或拖动） | 方式、批次内序号 |
| `dish_decide` | 就它了 | 菜 id、这次换了几次、从打开发现页到现在的毫秒 |
| `navigate_shop` | 导航去店里 | 店 id、选的地图 App |
| `publish_success` | 发布成功 | 照片数、是否新建店、用时 |
| `comment_success` | 写评论成功 | 是否带照片 |
| `verify_success` | 认证成功 | 方式 |
| `share` | 分享 | 对象类型、渠道 |
| `experiment_exposure` | 实验组件第一次显示 | 实验名、组 |
| `load_failed` | 显示了「没加载出来」 | 页面名、失败类型 |

- 公共属性：安装 ID、用户 id、平台、系统版本、设备型号、App 版本 + 构建号 + 补丁号、当前校区、会话 id。
- 产品 12.5 的指标怎么算：定下来的人数看 `dish_decide` 或 `navigate_shop` 的去重用户；换菜次数、定下来用时看 `dish_decide` 的属性；加载失败率看 `load_failed` / `page_view`；认证率、留存、内容供给用服务端数据。
- 上报：内存攒批，每 30 秒或满 20 条发一次；发不出去存进本地的 `analytics.queue`，最多 500 条，满了丢最旧的；回到前台、退出登录前尝试补发。
- 接口没上线前：只在调试日志里打印，不上报（现状差距 2.1）。
- 只在同意隐私政策后采集。

### 19.2 崩溃上报

方案待确认 D4，推荐自建 Sentry（依赖选型第 14 节）。

- 同意隐私政策后才初始化；`SENTRY_DSN` 为空时不启用。
- 配置：`environment` 取 `ENV_NAME`；`release` 为 `eat@<版本名>+<构建号>`，`dist` 为补丁号；`sendDefaultPii: false`；不开会话回放，不截屏；性能追踪先关（采样率 0）。
- `beforeSend` 去掉请求头、Cookie、请求体和 URL 的查询参数；用户信息只放账号 id。
- 面包屑：路由跳转（挂在 GoRouter 的观察者上）、网络请求（方法、路径模板、业务码）。
- 安卓、iOS 发版构建加 `--obfuscate --split-debug-info`，CI 用 `sentry_dart_plugin` 上传符号表；Web 构建生成 source map 并上传，`.map` 文件不部署到线上。`SENTRY_AUTH_TOKEN` 只在 CI Secrets。
- 反馈页自动带上版本号和补丁号，方便对上崩溃记录。

## 20. 多平台差异

产品 11.1 的表逐项落到实现：

| 项 | Android | iOS | Web | 代码位置 |
| --- | --- | --- | --- | --- |
| 统一认证 | 应用内浏览器（Custom Tabs）打开学校页面，回到 App 时刷新状态 | 同左（SFSafariViewController） | 当前标签页跳转，完成后回 `/verify` | `features/verify/` |
| 定位 | 系统权限；没 GMS 时用系统 LocationManager | 使用期间权限 | 浏览器权限，只在 HTTPS 下可用 | `core/platform/location/` |
| 加照片 | 拍照、相册多选 | 拍照、相册多选（PHPicker 不需要相册权限） | 文件选择框，手机浏览器可直接拍 | `core/platform/media/` |
| 压缩 | 原生编码 | 原生编码 | 浏览器 Canvas 编码 | 同上 |
| 导航去店里 | 已装的高德、百度、腾讯 | Apple 地图 + 已装的三家 | 高德网页版 | `core/platform/external_maps/` |
| 分享 | 系统分享面板 | 系统分享面板 | 支持 Web Share 时用系统分享，否则复制链接；微信里复制链接 | `core/platform/share/` |
| 打开分享链接 | App Links | Universal Links | 直接打开；微信里顶部「在 App 里打开」 | `router/deep_links.dart` |
| 推送 | 本地通知，App 在后台存活时 | 本地通知，基本只在刚退到后台时 | 没有，只看消息页 | `core/platform/push/` |

产品表之外，实现上还有这些差异：

| 项 | Android | iOS | Web |
| --- | --- | --- | --- |
| 热更新 | Shorebird | Shorebird | 不需要，提示「有新版本，刷新一下」 |
| 登录态 | Keystore | Keychain（卸载重装后残留，首次启动清理） | localStorage 加密存储（A10） |
| 本地存储 | `shared_preferences`（DataStore） | `shared_preferences`（NSUserDefaults） | localStorage，同一浏览器的标签页共用一份 |
| 图片缓存 | 磁盘 | 磁盘 | 浏览器 HTTP 缓存 |
| 人机验证 | WebView 加载 H5 | WebView 加载 H5 | 页面里直接加载 JS |
| 字体 | 内置 | 内置 | 后台加载 + 自托管回落字体 |
| 方向 | 手机竖屏 | 手机竖屏，iPad 横竖 | 不锁 |
| 返回 | 返回键：主页面先回发现再退出 | 侧滑返回 | 浏览器后退 |
| 资源加载 | 安装包内 | 安装包内 | `--no-web-resources-cdn`，CanvasKit 和字体从自己的域名加载 |

- 平台判断只在 `core/platform/` 里做。需要 `dart:io` 或 `package:web` 的代码用条件导入拆成 `_io.dart` 和 `_web.dart`，Web 构建不能引用 `webview_flutter`、`flutter_local_notifications` 这类没有 Web 实现的包的平台代码路径（编译能过，但运行时会抛异常）。
- Web 支持近两年的 Chrome、Safari、Edge、Firefox 和微信内置浏览器（产品 11.1）。微信里首屏要下载的东西（CanvasKit 压缩后约 2–3 MB、主程序、字体）见待确认 A14。
- 渲染器先用默认的 CanvasKit（JS 编译）；临时工程里 Wasm 预检通过，等主流程稳定后再评估 `--wasm`。

## 21. 测试策略

### 21.1 写什么测试

| 类型 | 覆盖什么 | 位置 |
| --- | --- | --- |
| 单元测试 | 纯函数：权限表、守卫、饭点、取色、撞色、坐标转换、距离和价格格式、菜名断行、消息 → 跳转、业务码 → 提示、版本比较、放量分组、远程配置校验、接口 JSON 解析 | `test/` 与 `lib/` 同构 |
| Widget 测试 | 设计组件的各状态（按钮按下和不可用、标签选中、面板）；页面用假仓库跑通主要状态（加载、成功、失败、空、没网、待接入、拦截） | 同上 |
| 无障碍检查 | 主要页面跑 `androidTapTargetGuideline`、`iOSTapTargetGuideline`（44px）、`labeledTapTargetGuideline`、`textContrastGuideline`；2 倍字号下不溢出 | 同上 |
| 契约测试 | 客户端用到的接口都在 `docs/api.openapi.yml` 里 | `test/contract/` |
| 令牌测试 | Dart 令牌和 `tokens.json` 一致 | `test/design/` |
| 依赖方向测试 | `lib/` 的 import 符合第 2.2 节的规则 | `test/architecture_test.dart` |

- 时间相关的逻辑都从 `clock` 取时间，测试里用 `withClock` 固定。
- 网络用一个假的 `HttpClientAdapter`（放 `test/support/`）返回样例 JSON，不起真服务器。
- mock 用 `mocktail`。

### 21.2 Golden 测试

第一批不做。组件和画板对齐稳定后，用 `alchemist` 的「CI golden」模式给核心组件（`Button` 各状态、`Chip`、`DishPlate`、9 个舞台色的 `Stage`、`NavBar`、`Panel`）加 golden，只在 CI（Linux）上生成和比对，打 `golden` 标签。原因：系统字体渲染在 macOS 和 Linux 上不同，本地生成的基准在 CI 上会对不上。

### 21.3 CI 里跑什么

- `check` 任务：`build_runner build --only-check`（生成文件忘了提交或过期就失败）、`dart format --set-exit-if-changed`、`flutter analyze`、`dart analyze --fatal-infos`（`riverpod_lint` 这类分析器插件的结果由它报告）、`flutter test`。契约、令牌、依赖方向测试都在 `flutter test` 里，不单独加任务。
- `web` 任务：改成 `flutter build web --release --no-web-resources-cdn --build-number=<run_number> --dart-define-from-file=...`。
- 打 tag 的发版构建：安卓、iOS 加混淆和符号表上传；Web 生成并上传 source map。热更新接入后改用 `shorebird release`（第 16.2 节）。
- 带原生代码的新依赖：单独一个 PR，看 CI 的 `android`、`ios` 任务能否编过（本地只构建 Web）。

### 21.4 手动检查

每次发测试包前，按清单在三端各走一遍主流程（登录、换菜、看详情、发布、导航去店里），另在微信内置浏览器里打开一次分享链接，用读屏软件走一遍登录和换菜（产品 11.3）。

## 22. 待确认

| 编号 | 事项 | 推荐 | 需要谁 |
| --- | --- | --- | --- |
| A1 | Web 和分享链接的域名、托管位置 | 一个 HTTPS 域名同时放 Web、反代 `/api`、放 `/.well-known/` 的 App Links / Universal Links 文件。要确认：域名；有没有 ICP 备案（境内 CDN 需要备案，境外托管在大陆首屏慢）；正式的安卓签名密钥（App Links 要它的指纹）；Apple 开发者账号（Universal Links、推送、TestFlight） | 产品负责人、后端 |
| A2 | 后端的业务码和约定 | 后端给出完整的错误码表，包括：登录过期、权限不足、需要同意、需要人机验证、功能已关闭、只读维护、操作受限、内容违规；确认 legacy 的 2xxxx、3xxxx 码是否仍然有效；`ErrorResponse` 字符串 `code` 的取值；发布、评论的服务端防重；推送附带数据里的 `link` 字段格式 | 后端 |
| A3 | 后端数据格式和存储 | 确认：GeoJSON（`location`、`boundary`、`center`）的坐标系；图片字段是完整 URL 还是 key；图片服务能否出缩略图；对象存储允许 Web 域名跨域 `PUT` 和读取（直传和取色都要），图片返回长缓存头；舞台色、两个备选色、封面裁切参数的字段格式（推荐 `stage-broth` 这样的字符串和 13.4 的三个数） | 后端 |
| A4 | 统一认证改为绑定票据 | App 用应用内浏览器打开学校页面，后端用一次性票据把结果记到当前账号，完成页给回 App 的链接；不在 URL 里带登录 token，不用 WebView | 后端 |
| A5 | 远程配置接口的形状 | 按 17.1 做一个接口，包含开关、参数、校区、公告、维护、版本线、补丁放量、实验分组、隐私政策版本 | 后端、产品负责人 |
| A6 | 轻提示的样式 | 产品里有「发布好了」「这个功能暂时关了」「没赞上，再试一次」这类短提示，设计规范没有对应组件。推荐在页面底部、`NavBar` 上方出现的 `ink` 底胶囊，2 秒消失，不挡操作 | 设计 |
| A7 | 隐私政策、用户协议更新后的重新同意 | 不做「重新同意」页（9.5）。推荐用远程配置里的版本号判断，本地版本更旧时回登录页重新勾选协议，不清登录态 | 产品负责人 |
| A8 | 宽屏时 `NavBar` 放哪 | 已定：放在左侧面板底部，发现、附近、我的一致（12.2，画板 `G-WideHome`、`G-WideNearby`） | — |
| A9 | 微信里的分享卡片 | 自定义标题和缩略图要用微信 JS-SDK，需要认证的公众号和备案域名。推荐先不做，微信里分享出去就是链接；其他 App 的链接预览可以由服务端给 `/dishes/:id` 这类地址输出带标题和图片的 meta | 产品负责人 |
| A10 | Web 登录态存在哪 | Web 上 token 只能存在浏览器里（加密的密钥也在浏览器），页面被注入脚本时能被读走。推荐先这样做并给 Web 配内容安全策略（CSP）；更安全的是后端改用 httpOnly Cookie，需要同源部署（A1） | 后端、产品负责人 |
| A11 | 新版本「先发 5%」 | 补丁能按比例放（16.2）。商店版本做不到任意比例：App Store 的分阶段发布是固定 7 天节奏，只影响自动更新；国内安卓商店各家支持不同；Web 刷新即全量。推荐：iOS 用分阶段发布，安卓按商店能力，Web 不分阶段，出问题靠回滚部署 | 产品负责人 |
| A12 | 安卓分发渠道 | 上哪些应用商店，还是官网下载 APK。影响「去更新」跳哪里、商店是否重签名（App Links 指纹）、厂商推送开通、APP 备案 | 产品负责人 |
| A13 | 「后台上传」的范围 | 理解为在发布页填表时并行上传；App 切到后台时不保证继续，回到前台自动重试失败的照片 | 产品负责人 |
| A14 | Web 在微信里的首屏 | Flutter Web 首屏要下载 CanvasKit（压缩后约 2–3 MB）、主程序和字体，在微信里打开分享链接会等几秒。推荐先做出来实测；不满意再考虑由服务端给分享链接输出一个轻量的菜品预览页，再进完整 Web 版 | 产品负责人 |
| A15 | 舞台菜名按词断行 | 「每行不超过四个字、按词断行」需要中文分词，Flutter 在 App 上没有现成的分词能力。推荐后端在发布时分好词，接口返回断行位置；没有之前客户端用简单规则兜底（每行 ≤ 4 字，尽量不拆开常见结尾词如「粉」「面」「饭」「云吞」） | 后端、产品负责人 |
