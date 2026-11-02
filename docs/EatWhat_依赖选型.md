# EatWhat 依赖选型

> 2026-10-22 初稿。依据产品文档（2026-10-22）、现状差距（2026-10-22）、接口 `auth-renewal-20261019`、设计规范与画板「G 定稿」（2026-10-22）。
>
> 2026-10-25：按接口 `tencent-captcha-20261024` 定下人机验证用腾讯云（第 15 节、D6），`webview_flutter` 只用于人机验证。
>
> 2026-11-03：底部导航的标签胶囊改用 `liquid_glass_widgets` 的液态玻璃（总表）。

本文记录装哪个包、锁哪条版本线、为什么不选另一个。新增依赖前先查这里，表里没有的先提出来，确定后补进本文再改 `pubspec.yaml`。这些包在代码里怎么用，见 `EatWhat_技术架构.md`。

## 0. 约定与查证方式

- **一类问题一个方案**。下面每一类只选一个包；不选的写在「不选」里，以后想换先改本文。
- **版本怎么查的**。表里每个版本都在 2026-10-22 从 pub.dev 接口查过发布日期和 SDK 约束；再在一个临时工程里用 Flutter 3.47.7 / Dart 3.13.5 把所有选中的包一起 `pub get` 解析通过，并 `flutter build web --release --no-web-resources-cdn` 编译通过。没查证的版本会标出来。
- **Android、iOS 由 CI 验证**。本地只允许构建 Web，所以带原生代码的包能不能在 AGP 9.1 / iOS 15 上编过，要看 CI 的 `android`、`ios` 任务。每个带原生代码的包第一次加进来时单独一个 PR。
- **约束写法**：`^x.y.z`，锁主版本。`pubspec.lock` 入库。升级走 `build(deps): 升级 xxx 至 x.y.z` 的提交。
- **加的时机**：按开发计划，在第一个用到它的阶段加入，「何时加」一列写的就是阶段；加入时把这一列改成「已引入」。不提前装。
- **代码生成只用两处**：Provider 用 `riverpod_generator`，接口 DTO 用 `json_serializable`，都经 `build_runner`。不用 `freezed`、`retrofit`、`go_router_builder`。理由见第 3、5 节。
- 标「待确认」的条目汇总在文末。

## 1. 总表

**运行时依赖**

「何时加」对应开发计划的阶段。

| 类别 | 包 | 版本 | 发布日期 | Android | iOS | Web | 何时加 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 设计库（Material） | `material_ui` | `^1.8.0` | 2026-10-20 | ✅ | ✅ | ✅ | 已引入（阶段一） |
| 状态管理 | `flutter_riverpod` | `^3.4.3` | 2026-09-03 | ✅ | ✅ | ✅ | 已引入（阶段一） |
| Provider 注解 | `riverpod_annotation` | `^4.0.7` | 2026-09-03 | ✅ | ✅ | ✅ | 已引入（阶段一） |
| 路由 | `go_router` | `^18.1.1` | 2026-10-20 | ✅ | ✅ | ✅ | 已引入（阶段一） |
| Web URL 策略 | `flutter_web_plugins` | SDK 自带 | — | — | — | ✅ | 已引入（阶段一） |
| SVG 图标 | `flutter_svg` | `^2.3.0` | 2026-05-08 | ✅ | ✅ | ✅ | 已引入（阶段一） |
| 读预编译的 SVG | `vector_graphics` | `^1.2.4` | 2026-10-19 | ✅ | ✅ | ✅ | 已引入（阶段一），见第 9.2 节 |
| 网络 | `dio` | `^5.11.1` | 2026-09-04 | ✅ | ✅ | ✅ | 已引入（阶段二） |
| JSON 注解 | `json_annotation` | `^4.12.0` | 2026-05-15 | ✅ | ✅ | ✅ | 已引入（阶段二） |
| 安全存储 | `flutter_secure_storage` | `^11.2.0` | 2026-09-16 | ✅ | ✅ | ✅ | 已引入（阶段二） |
| 本地存储 | `shared_preferences` | `^2.5.6` | 2026-10-05 | ✅ | ✅ | ✅ | 已引入（阶段二：同意记录、卸载重装检测） |
| 版本号 | `package_info_plus` | `^10.2.2` | 2026-10-01 | ✅ | ✅ | ✅ | 已引入（阶段二） |
| 打开链接、外部地图、认证页 | `url_launcher` | `^6.3.3` | 2026-10-02 | ✅ | ✅ | ✅ | 已引入（阶段二） |
| 人机验证容器 | `webview_flutter` | `^4.14.1` | 2026-07-07 | ✅ | ✅ | —（Web 直接加载 JS） | 已引入（阶段二）。只用于人机验证，见第 15 节；统一认证用 `url_launcher` 的应用内浏览器，不用 WebView（技术架构 18.1） |
| 可注入时钟 | `clock` | `^1.1.3` | 2026-08-28 | ✅ | ✅ | ✅ | 已引入（阶段二：验证码倒计时；阶段三还用于饭点、「12 分钟前」） |
| Web 互操作 | `web` | `^1.1.1` | 2025-02-26 | — | — | ✅ | 已引入（阶段二：Web 上加载人机验证的 JS；阶段三还用于判断微信内置浏览器） |
| 网络图片与缓存 | `cached_network_image` | `^4.0.5` | 2026-10-21 | ✅ | ✅ | ✅ | 已引入（阶段三） |
| 定位 | `geolocator` | `^14.1.2` | 2026-10-19 | ✅ | ✅ | ✅（仅 HTTPS） | 已引入（阶段三） |
| 地图 | `flutter_map` | `^8.3.2` | 2026-08-27 | ✅ | ✅ | ✅ | 已引入（阶段三），底图待确认 D1 |
| 地图坐标类型 | `latlong2` | `^0.10.1` | 2026-04-27 | ✅ | ✅ | ✅ | 已引入（阶段三） |
| 系统分享 | `share_plus` | `^13.3.1` | 2026-10-01 | ✅ | ✅ | ✅（不支持时复制链接） | 已引入（阶段三） |
| 选图 | `image_picker` | `^1.2.4` | 2026-10-06 | ✅ | ✅ | ✅ | 已引入（阶段四） |
| 压缩 | `flutter_image_compress` | `^2.5.1` | 2026-07-25 | ✅ | ✅ | ✅（只用 `compressWithList`） | 已引入（阶段四） |
| 崩溃上报 | `sentry_flutter` | `^10.1.0`（解析到 10.2.0） | 2026-10-22 | ✅ | ✅ | ✅ | 已引入（阶段五），服务端待确认 D4。安卓要求 `minSdk` 26 |
| 网络请求的崩溃上下文 | `sentry_dio` | `^10.1.0`（解析到 10.2.0） | 2026-10-22 | ✅ | ✅ | ✅ | 已引入（阶段五） |
| 热更新 | `shorebird_code_push` | `^2.0.7` | 2026-07-09 | ✅ | ✅ | —（Web 刷新即新版） | 已引入（阶段五），国内网络实测待确认 D3 |
| 设备信息 | `device_info_plus` | `^13.3.0` | 2026-10-01 | ✅ | ✅ | ✅ | 暂不引入：反馈接口不收设备型号（见后端反馈），后端加上字段后随反馈一起加 |
| 深链 | `app_links` | `^7.2.2` | 2026-10-06 | ✅ | ✅ | 不用 | 已引入（统一认证回跳，2026-11-02）；分享链接还没排 |
| 液态玻璃（底部导航） | `liquid_glass_widgets` | `^1.16.1` | 2026-10-30 | ✅ | ✅ | ✅（CanvasKit 上用轻量着色器） | 已引入（2026-11-03）。只用于 `EatNavBar` 的标签胶囊，发布按钮仍是 `ink` 实心。同类里近 30 天下载量最高（12 万），不依赖其他包；`liquid_glass_renderer` 点赞更多但只有 1.0.0-dev 预发布版，不选 |
| 本地通知 | `flutter_local_notifications` | `^22.3.2` | 2026-10-12 | ✅ | ✅ | — | 开发计划还没排 |

**开发依赖与工具**

| 类别 | 包或工具 | 版本 | 发布日期 | 何时加 |
| --- | --- | --- | --- | --- |
| 静态检查 | `flutter_lints` | `^6.0.0` | 2025-05-27 | 已有 |
| 代码生成 | `build_runner` | `^2.16.2` | 2026-10-07 | 已引入（阶段一） |
| Provider 生成 | `riverpod_generator` | `^4.0.9` | 2026-09-03 | 已引入（阶段一） |
| Provider 写法检查（分析器插件） | `riverpod_lint` | `^3.1.9` | 2026-09-03 | 已引入（阶段一）。写在 `analysis_options.yaml` 的 `plugins`，不进 `pubspec.yaml` |
| SVG 预编译（资源转换器） | `vector_graphics_compiler` | `^1.3.2` | 2026-10-15 | 已引入（阶段一） |
| 字体子集化 | fonttools（Python 工具，不进 pubspec，`tool/subset_fonts.py` 调用） | 不锁，实测 4.60.2 | — | 已引入（阶段一，只在开发机用） |
| JSON 生成 | `json_serializable` | `^6.15.2` | 2026-10-20 | 已引入（阶段二） |
| 测试 mock | `mocktail` | `^1.0.5` | 2026-04-10 | 第一次需要 mock 时。阶段二的测试用 `test/support/fakes.dart` 里的内存实现和假网络适配器就够了，没有加 |
| 读 `docs/api.openapi.yml` 做契约测试 | `yaml` | `^3.1.4` | 2026-08-28 | 已引入（阶段二） |
| 上传符号表、source map | `sentry_dart_plugin` | `^3.4.0` | 2026-05-28 | 已引入（阶段五），只在 CI 的发版构建运行 |
| 热更新命令行 | Shorebird CLI（不进 pubspec） | 跟随 `.fvmrc` 的 Flutter 版本 | — | 已引入（阶段五），CI 用 `shorebirdtech/setup-shorebird` 安装 |
| Golden 测试 | `alchemist` | `^0.14.1` | 2026-10-08 | 组件稳定后（见技术架构「测试策略」） |

`build_runner` 最新是 2.17.1，但它要求 `build` 5.x，而 `riverpod_generator` 4.0.9 只支持 `build` 5 以下，所以锁 2.16 线；`riverpod_generator` 放开 `build` 5 以后再升。

**SDK 自带、不用另装**：`flutter_test`、`integration_test`（以后需要时）。`flutter_localizations` 由 `material_ui` 带进来，本地化代理用 `GlobalMaterialLocalizations.delegates`，不要再直接 `import 'package:flutter_localizations/...'`，否则和 `material_ui` 里的同名类冲突（临时工程里实测报 `ambiguous_import`）。

**明确不用**

| 包 | 原因 |
| --- | --- |
| `firebase_*`（Messaging、Remote Config、Crashlytics、Analytics） | Google 服务在中国大陆不可用，多数国产安卓机没有 GMS |
| `google_fonts` | 运行时从 `fonts.gstatic.com` 下载字体，大陆访问不到 |
| `hive_ce`、`hive_ce_flutter` | 和 `shared_preferences` 同类，只留一个，见第 6 节 |
| `freezed` | 要求工厂构造函数，和 AGENTS.md「普通数据模型用主构造函数」冲突；DTO 用 `json_serializable` 就够 |
| `retrofit`、`go_router_builder` | 接口类和路由表手写，见第 4、5 节 |
| `palette_generator` | pub.dev 已标为 discontinued，算法也和规范要求的不同 |
| `image_cropper` | 原生裁切界面，做不出 `G-Crop` 的样子；我们只存裁切参数，不需要真的裁图 |
| `flutter_web_auth_2` | 统一认证用应用内浏览器打开、回到 App 时刷新状态即可，见第 10 节和技术架构第 18 节 |
| `map_launcher` | 用 `url_launcher` 自己拼外部地图 URL 就够，见第 7.3 节 |
| `geocoding` | 安卓端依赖 Google 地理编码，没 GMS 就失败；商圈判断走接口 `/hub/locate` |
| `connectivity_plus`、`permission_handler` | 暂不需要：没网从请求失败判断；定位、推送、相册的权限由各自的包申请 |

## 2. 基础：Flutter / Dart 版本与升级策略

**现状**：Flutter 3.47.7 stable，Dart 3.13.5，只写在 `.fvmrc`，CI 从它读版本。

**规则**

- `pubspec.yaml` 的 `environment` 保持 `sdk: ^3.13.5`，再加 `flutter: '>=3.47.0'`：`material_ui` 和 `go_router` 18 都要求 Flutter 3.47 / 3.44 以上，写明下限可以让过旧的本地 SDK 直接报错。
- **补丁版本**（3.47.x）：出了就升，单独一个提交，CI 三端通过即可。
- **小版本**（3.48 等季度版本）：发布后等 2–4 周再升。升之前确认四件事：`material_ui`、`go_router`、`flutter_riverpod`、`sentry_flutter` 已发布兼容版本；Shorebird 已支持该 Flutter 版本（它的文档写季度版本一般 5 个工作日内支持，补丁版本 1 个工作日内）。
- 升级只改 `.fvmrc`，提交标题 `build(deps): 升级 Flutter 至 x.y.z`。升完跑 `fvm dart format .`、`fvm flutter analyze`、`fvm flutter test`、`fvm flutter build web --release`，并在 Chrome 和手机 Safari 上点一遍主流程。

**Material 库独立成包**

Flutter 3.44 起冻结了框架里的 `package:flutter/material.dart`，3.47 起可以改用独立的 `material_ui` 包，框架内的版本计划在之后的稳定版标为过时。我们阶段一就用 `material_ui`，原因：

- `go_router` 18.0.0 起已经迁到 `material_ui`。它判断「是不是 Material App」时找的是 `material_ui` 里的 `MaterialApp`（`go_router-18.1.1/lib/src/pages/material.dart`）。如果我们还用框架里的 `MaterialApp`，类型对不上，页面过渡会走非 Material 的分支。
- 迟早要迁，现在 `lib/` 只有两个文件，最便宜。
- 迁移命令：`fvm dart fix --apply --code=migrate_design_widgets`。现有 `lib/app.dart` 还引用 `package:flutter/material.dart`，搭架构时一起迁。

我们几乎不用 Material 的视觉组件（见技术架构「设计令牌落地」），用它主要是 `MaterialApp.router`、本地化、文本选择菜单和输入框。

## 3. 状态管理

**选**：`flutter_riverpod ^3.4.3` + `riverpod_annotation ^4.0.7`，Provider 用 `riverpod_generator ^4.0.9` 生成，`riverpod_lint ^3.1.9` 检查写法。

**为什么**

- 依赖注入和状态在一套里：接口客户端、存储、配置都是 Provider，测试时用 `overrides` 换成假的，不需要另一个 DI 库。
- 页面数据天然是「按 id 取、离开页面释放」：`autoDispose` + `family` 正好对应菜品详情、餐厅详情这类页面。
- 3.x 的几个特性和我们的需求对得上：
  - 不可见的组件会暂停监听（靠 `TickerMode` 判断），`StatefulShellRoute` 切走的分支自动暂停，不白白刷新。
  - 失败自动重试，可以在 `ProviderScope(retry: ...)` 统一定策略（只重试网络错误、不重试业务错误）。
- legacy 用的也是 Riverpod，团队熟悉。
- 用生成器：`@riverpod` 写一个函数或类就得到 Provider，`family`、`autoDispose` 由参数和注解决定，不用自己挑 `AsyncNotifierProvider.autoDispose.family` 这类组合；Riverpod 3 的文档和示例也以生成器写法为主。

**不选**

| 方案 | 原因 |
| --- | --- |
| `flutter_bloc` 9.1.1 | 事件、状态、Bloc 三件套样板多；依赖注入还要另配 |
| `provider` 6.1.5+1 | Riverpod 的前身，`BuildContext` 依赖强，异步和释放要自己管 |
| `signals_flutter` 7.1.0 | 社区小，和路由、测试的配合资料少 |

**注意**

- 3.x 的 `Mutation`、离线持久化（`riverpod_sqflite`）还是实验特性，不用。离线缓存自己做（技术架构「离线与缓存」）。
- `StateProvider`、`StateNotifierProvider` 在 3.x 已移到 `legacy.dart`，不用；统一用 `Notifier` / `AsyncNotifier`。
- pub.dev 上 `flutter_riverpod` 3.4.3 的平台标签没列 Web，但它是纯 Dart，临时工程的 Web 构建通过，`riverpod` 本身标了 Web。
- legacy 迁到 Freezed + `riverpod_generator` 的重构停在 24 个编译错误上（交接文档 `docs/refactor_handoff.md`），问题出在生成文件和源文件对不上。这次的约束：生成文件入库但不手改，CI 每次重新生成并比对（技术架构第 21.3 节），不用 Freezed。
- `riverpod_lint` 3.1.9 用的是新的分析器插件机制（`analysis_options.yaml` 的 `plugins`），不再依赖 `custom_lint`。它写在 `analysis_options.yaml` 里，由分析器自己拉取，不进 `pubspec.yaml`；结果只有 `dart analyze` 报告（实测 `flutter analyze` 看不到），CI 里单独跑一步。

## 4. 路由

**选**：`go_router ^18.1.1`，手写路由表，不用 `go_router_builder`。

**为什么**

- Flutter 官方维护（publisher 是 flutter.dev）。
- `StatefulShellRoute` 正好对应三个主页面各自保留状态、`NavBar` 悬浮在外层的结构（设计规范预设，技术架构里确认采用）。
- 顶层 `redirect` + `refreshListenable` 做登录拦截、强制更新、维护；17.5 起支持路由 `metadata`，可以标「是否需要登录」。
- Web 上地址栏就是路由，分享链接、深链和 Web 用同一套路径。

**不选**：`auto_route` 11.2.0（依赖代码生成）；自己写 Navigator 2.0（工作量大，URL 同步、深链都要自己做）。

## 5. 网络与序列化

**网络选**：`dio ^5.11.1`。

- 拦截器：鉴权头、业务 `code` 解析、错误转换、日志，都放在拦截器里，业务代码只拿结果。
- 上传进度（`onSendProgress`）：发布页的「照片没传完时按钮显示进度」要用。
- `CancelToken`：页面释放时取消请求。
- 三端都能用；Web 上走浏览器的 XHR。

不选 `http` 1.6.0：没有拦截器和上传进度，要自己包一层，最后就是半个 dio。

**序列化选**：`json_serializable ^6.15.2` + `json_annotation ^4.12.0`。

- 只给 `data/` 里的 DTO 用：`@JsonSerializable` 生成 `fromJson`，字段和接口一一对应，接口改了字段，重新生成就行，不用手写一堆取字段的代码。
- DTO 照接口写成可空（接口文档里几乎每个字段都是 `anyOf: [type, null]`），repository 转领域模型时补默认值，进到 UI 的模型尽量不为空。领域模型不做 JSON。
- 不用 `freezed`：它要求工厂构造函数，和 AGENTS.md「普通数据模型用主构造函数」冲突；DTO 只读不改，用不上它的 `copyWith` 和联合类型。
- 和 `riverpod_generator` 共用一个 `build_runner`，生成文件的约定相同（技术架构第 4.1 节）。

**不由 `docs/api.openapi.yml` 生成客户端**

| 理由 | 说明 |
| --- | --- |
| 规模不大 | 103 个操作，去掉 Activity、Admin、`*Conflict`、CatalogImport、Location 后，客户端要用的约 45 个 |
| 规范写法难生成 | OpenAPI 3.1，字段普遍是 `anyOf: [type, null]`；`AuthReply.data` 是三种结构的 `anyOf`；`ErrorResponse.code` 可能是整数也可能是字符串。主流生成器（`openapi_generator` 7.0.0 包装的 dart-dio 模板、`swagger_parser` 1.45.0）对 3.1 的支持不完整 |
| 每个响应都套了 `Result_*` 外壳 | 生成出来每个接口一个外壳类型，业务 `code` 还得自己判断 |
| 接口还会大改 | 现状差距列了约 30 项接口变化（手机号登录、推荐参数、评论、专题……），生成的代码会频繁整体重来 |
| 风格不合 | 生成代码用工厂构造或 `built_value`，不符合项目写法 |

替代做法：每个接口分组手写一个 `XxxApi` 类，DTO 用 `json_serializable`；加一个**契约测试**，用 `yaml` 包读 `docs/api.openapi.yml`，检查客户端用到的每个「方法 + 路径」都在文档里。后端更新接口文件后跑测试就知道哪里对不上。

## 6. 本地存储与安全存储

| 存什么 | 选 | 说明 |
| --- | --- | --- |
| 登录 token、`tokenName`、安装 ID | `flutter_secure_storage ^11.2.0` | Android Keystore、iOS Keychain；Web 用 WebCrypto 加密后存 localStorage（密钥也在浏览器里，挡不住 XSS，见技术架构待确认 A10） |
| 偏好设置、接口缓存、埋点队列 | `shared_preferences ^2.5.6` | 用 `SharedPreferencesAsync`，键加前缀分组（`prefs.*`、`cache.*`、`analytics.queue`，见技术架构 9.1）；值是基本类型或 JSON 字符串。安卓走 DataStore，iOS 走 NSUserDefaults，Web 走 localStorage |

**为什么是 `shared_preferences`**

- 开发计划选定。Flutter 官方维护，三端都有，不需要代码生成，也不用在启动时额外打开什么。
- 我们要存的都是键值：偏好、几百 KB 的 JSON 缓存（看过的菜品详情、上一批推荐）、埋点队列。

**代价和约束**

- 安卓、iOS 会把整份数据读进内存，iOS 的 NSUserDefaults 还会在启动时整个读进来，所以不适合放大缓存。`CacheStore` 把总量控制在 1 MB 左右，超了按最近访问淘汰（技术架构 10.1）。
- Web 的 localStorage 每个域名约 5 MB，同一浏览器的标签页共用一份。
- 缓存和偏好丢一点无所谓，必须可靠的数据（token）放安全存储。

**不选**

| 方案 | 原因 |
| --- | --- |
| `hive_ce` 2.22.0 | 能放更大的缓存，Web 用 IndexedDB；但和 `shared_preferences` 同类，一类只留一个 |
| `drift` 2.35.2 | 关系型数据库，需要代码生成；我们没有需要查询的本地数据 |
| `sembast` 3.9.0 | 可用，但用户少，资料少 |
| `sqflite` | 不支持 Web |

## 7. 地图与定位，跳转外部地图 App

### 7.1 地图：`flutter_map ^8.3.2` + 天地图瓦片（待确认 D1）

产品要求 Web 和 App 功能一致，附近页还有一堆自定义表现：圆形菜图标记、选中放大加舞台色外圈、商圈虚线范围、宽屏左侧面板、地图出问题退回列表。

**推荐**：`flutter_map`（纯 Flutter 绘制）+ 天地图（自然资源部的国家地理信息公共服务平台）的 XYZ 瓦片：`vec_w` 矢量底图加 `cva_w` 注记，请求带 `tk` Key。

| | flutter_map + 天地图 | 高德原生 SDK + 高德 JS API |
| --- | --- | --- |
| 三端 | 一套代码 | App 用原生 SDK，Web 要另写一套 JS API 版本 |
| 标记 | 直接用 Flutter 组件（`DishPlate` 缩小版），动画随便做 | 要把组件截成位图再交给原生 |
| 和抽屉叠放、手势 | 普通组件，没有冲突 | 平台视图（PlatformView），滚动和手势冲突多，安卓上性能差 |
| Flutter 插件 | `flutter_map` 2026-08 仍在发布，publisher 已验证 | 官方 `amap_flutter_map` 3.0.0 停在 2021-11，SDK 约束 `<3.0.0`，Dart 3 不能用；社区版 `amap_map` 1.0.15 停在 2025-03，只有 Android、iOS |
| 坐标系 | 天地图是 CGCS2000（和 WGS-84 差厘米级）；后端存 GCJ-02，要在客户端转换 | GCJ-02，和后端一致 |
| 审图号 | 天地图瓦片自带，按要求显示标识 | 自带 |
| 费用和授权 | 注册开发者申请 Key；调用量上限和使用条款以控制台为准，未查证 | 商业 App 有授权和计费规则，按开发者主体去控制台确认 |
| 视觉 | 底图样式不能自定义，只能整体加色彩滤镜靠近 `map-ground`，做不到严格按 `map-*` 令牌 | 可以在控制台做自定义样式 |
| 底图质量 | 校园周边的路网、POI 可能不如高德细 | 好 |

其他看过的：`flutter_baidu_mapapi_map` 4.0.2（百度官方，2026-09 仍在更新，但只有 Android、iOS，默认 BD-09 坐标）；`tencent_map_flutter` 0.1.0（2024-05 后没更新）。境外瓦片（OSM、Mapbox）在大陆慢，而且没有审图号。

**坐标类型**：`latlong2 ^0.10.1`（`flutter_map` 要求 `<0.11.0`）。GCJ-02 和 WGS-84 的互转自己写（公开算法，几十行，带单元测试），不引包。

### 7.2 定位：`geolocator ^14.1.2`

- 安卓：README 写明用 FusedLocationProviderClient，没有时退回系统的 LocationManager，所以没装 GMS 的国产机也能定位。精度只要能算「320 m」就够。
- iOS：CoreLocation，只要「使用期间」权限，不要后台定位（产品 7.6）。
- Web：浏览器定位，**只在 HTTPS 下可用**；`getLastKnownPosition`、`openAppSettings` 在 Web 上会抛 `UnsupportedError`，调用前判断平台。
- 返回 WGS-84，转 GCJ-02 后再给接口（接口参数是 `gcjLng`、`gcjLat`）。
- 权限申请用它自带的 `checkPermission` / `requestPermission`，不另装权限库。

**不选**：`location` 10.0.2（同类，选一个）；高德、百度定位 SDK（`amap_flutter_location` 3.0.0 停在 2021，`flutter_bmflocation` 3.8.5 只有移动端，还要多列一个第三方 SDK）。

### 7.3 跳转外部地图 App：`url_launcher ^6.3.3`

用 URL Scheme 拼导航链接，装了几个就列几个（技术架构「导航去店里」有完整表）：

- iOS：Apple 地图（系统自带）、高德 `iosamap://`、百度 `baidumap://`、腾讯 `qqmap://`。要在 `Info.plist` 的 `LSApplicationQueriesSchemes` 里声明，否则 `canLaunchUrl` 永远返回否。
- 安卓：高德 `androidamap://`、百度 `baidumap://`、腾讯 `qqmap://`。安卓 11 起要在 `AndroidManifest.xml` 的 `<queries>` 里声明。
- Web：打开高德网页版导航 `https://uri.amap.com/navigation?...`，手机浏览器里会尝试唤起高德。

**不选** `map_launcher` 7.0.0：它也要同样的声明，还要多一层坐标系处理的黑盒；我们只需要 4 个 Scheme。

`url_launcher` 同时用来打开协议页、商店页、学校统一认证页（`LaunchMode.inAppBrowserView`，iOS 是 SFSafariViewController，安卓是 Custom Tabs）。

## 8. 图片选择、压缩、裁切、取色与去背景

| 环节 | 选 | 说明 |
| --- | --- | --- |
| 选择 | `image_picker ^1.2.4` | 拍照、相册多选（`pickMultiImage(limit:)`）。Web 上是文件选择框，手机浏览器可以直接拍。iOS 相册走系统 PHPicker，不需要相册权限；拍照要在 `Info.plist` 写 `NSCameraUsageDescription`（老系统的相册兜底另写了 `NSPhotoLibraryUsageDescription`） |
| 压缩 | `flutter_image_compress ^2.5.1` | 三端统一用 `compressWithList`（Web 不支持按文件压缩）。输出 JPEG；默认 `keepExif: false`，**去掉 EXIF**，照片里的 GPS 位置不会传上去；方向统一校正。Web 上靠浏览器 Canvas 编码。`minWidth`、`minHeight` 实际是按短边缩的上限，要先读原图尺寸、按长边 2048 换算（`core/platform/photo_picker.dart`） |
| 裁切 | 自己写 | 「调整照片」只产出裁切参数（圆心和缩放），随菜品保存，不生成裁好的图。头像需要真的裁：用 `PictureRecorder` 画出圆形区域，`toByteData` 拿 PNG，再交给压缩转 JPEG |
| 取色 | 自己写 | 只看圆内像素、按饱和度加权、吸附到 9 个 `stage-*`。用 `ui.instantiateImageCodec` 按小尺寸解码拿像素，纯 Dart 计算，三端一致 |
| 去背景 | 不在客户端做（待确认 D8） | 见下 |

**去背景为什么不在客户端**：设备端抠图三端没有统一方案。Google ML Kit 的主体分割依赖 Google Play 服务（国产机没有），iOS 的 Vision 前景分割要 iOS 17，Web 没有原生能力。推荐由后端在上传完成后生成去背景版本，客户端只负责开关和显示。开关本身在远程配置里能单独关。

**不选**：`image` 4.12.0（纯 Dart 编解码，大图在 Web 主线程上会卡，没有 isolate）；`image_cropper` 13.0.0；`extended_image` 10.1.0（图片加载和编辑一体，和 `cached_network_image` 同类）；`palette_generator`（已 discontinued）。

**网络图片**：`cached_network_image ^4.0.5`。安卓、iOS 有磁盘缓存（离线能看看过的菜）；Web 依赖浏览器 HTTP 缓存，需要图片服务器给缓存头（技术架构待确认 A3）。

## 9. 字体与图标

### 9.1 字体（待确认 D7）

| 字体 | 用途 | 来源与许可 | 原始大小 | 做法 |
| --- | --- | --- | --- | --- |
| Noto Sans SC | 全部中文，主角文字 900 | Google Fonts，OFL | 可变字体 `NotoSansSC[wght].ttf` 17,772,300 字节 | 子集化后内置 |
| Inter | 价格、距离、计数等数字 | Google Fonts，OFL | 可变字体 `Inter[opsz,wght].ttf` 876,576 字节 | 子集化到数字、拉丁字母和 `¥` 后内置 |

- 两个都用**可变字体**，一份文件覆盖所有字重。Flutter 3.47 的 `FontWeight` 直接设置可变字体的 `wght` 轴，文字样式里写 `fontWeight` 就行；Inter 另按字号设 `opsz`（技术架构 11.5）。
- 数字原先用设计稿里的 Bricolage Grotesque，字形个性强，小字号下 `6 8 9`、`3 5` 不好认，换成为屏幕小字号设计的 Inter。Inter 字形开口大，带等宽数字 `tnum`。
- Noto Sans SC 全量 17.8 MB 太大。`tool/subset_fonts.py` 裁到 GB 2312 的全部字符（6763 个汉字加符号）、ASCII 和几段常用标点，实测 3,939,760 字节、7801 个字符；Inter 只留 ASCII 和 `¥` 等几个符号，保留全部 OpenType 特性，173,704 字节。子集化用 fonttools 4.60.2（支持 Python 3.9 的最后一版）。子集外的生僻字在安卓、iOS 上由系统字体补上，样子略有不同但不会缺字。
- 设计规范说 iOS 可以回落到苹方，但苹方最粗只有 Semibold，做不出 900 的主角字，所以三端都内置。
- **Web 的问题**：
  - 内置字体会在引擎初始化时全部下载，几 MB 的中文字体会拖慢首屏，在微信里更明显。推荐 Web 不在 `pubspec.yaml` 的 `fonts` 里声明 Noto，而是作为普通资源，启动后用 `FontLoader` 在后台加载，加载完自动重排；加载前用回落字体显示。具体效果要做一次 Web 实验确认。
  - Flutter Web 缺字时默认去 `fonts.gstatic.com` 取回落字体（包括 emoji），大陆访问不到。构建时用 `--no-web-resources-cdn`，并把 `fontFallbackBaseUrl` 指向我们自己托管的回落字体副本，否则用户评论里的 emoji 和生僻字在 Web 上显示成方块。
- 不用 `google_fonts`（运行时从境外下载）。
- 字体文件放项目 `assets/fonts/`，在 `pubspec.yaml` 声明；`prototype/` 里的资源不直接引用。子集化脚本放 `tool/`，输出入库，CI 不跑。

### 9.2 图标：`flutter_svg ^2.3.0` + `vector_graphics ^1.2.4` + `vector_graphics_compiler ^1.3.2`

- 图标是 MingCute Line 的 SVG（设计规范 `Icon`）。从 `prototype/assets/icons/` 复制到项目 `assets/icons/`，按文件名引用。
- `pubspec.yaml` 里给 `assets/icons/` 配 `vector_graphics_compiler` 资源转换器，构建时把 SVG 预编译成二进制，运行时不解析 XML。预编译的资源要用 `vector_graphics` 的 `AssetBytesLoader` 读（`SvgPicture(AssetBytesLoader(...))`），`flutter_svg` 没有导出它，所以 `vector_graphics` 也写进直接依赖；它本来就是 `flutter_svg` 的依赖，版本跟着走。
- 颜色：图标都是单色，用 `colorFilter: ColorFilter.mode(颜色, BlendMode.srcIn)` 跟着所在文字变色；赞过的心形是 `stage-tomato`。
- 小尺寸加粗描边（14px 用 2.6、16px 用 2.4、18px 用 2.13）：运行时不能改预编译图标的描边，用 `tool/icons.dart` 为描边类图标预先生成 14、16、18 三套变体，放在 `assets/icons/14/` 这样的子目录里。少数图标本身是填充轮廓（如 `image`、`followed`），不参与加粗。
- 不用图标字体：描边类图标转字体要先轮廓化，小尺寸加粗也做不了。

## 10. 系统分享与深链

| 用途 | 选 | 说明 |
| --- | --- | --- |
| 系统分享面板 | `share_plus ^13.3.1` | 安卓、iOS 弹系统分享；Web 在支持 Web Share API 的浏览器上调起系统分享。微信内置浏览器不支持，改为复制链接 |
| 复制链接 | SDK 的 `Clipboard` | 不用包 |
| 深链（App Links、Universal Links、自定义 Scheme） | `app_links ^7.2.2` | 冷启动和运行中收到的链接都从它拿，统一交给我们自己的深链处理器 |

**为什么要 `app_links`，而不是 Flutter 自带的深链**：统一用 `app_links` 接收、自己分发，分享链接、通知点击、认证回跳只有一个入口，方便做白名单和埋点。另外，极光等推送的 README 写明，Flutter 3.29 起安卓厂商通道的离线推送点开会被 Flutter 当成深链处理而白屏，要在 `AndroidManifest.xml` 关掉 `flutter_deeplinking_enabled`；现在就关掉、自己接，以后接远程推送不用再改深链。iOS 同样关掉 `FlutterDeepLinkingEnabled`，保持两端一致。

**不选**：微信 JS-SDK（自定义分享卡片需要认证公众号和备案域名，见技术架构待确认 A9）；`flutter_web_auth_2` 5.1.0（安卓上依赖 Chrome 的 Auth Tab，没装 Chrome 的国产机表现不确定；统一认证不需要回调拿结果，见技术架构第 18 节）。

## 11. 推送

**现在不接远程推送**：安卓厂商通道和 iOS APNs 都先不做，不引入极光等推送 SDK。先用本地通知顶上，所有推送能力都经过技术架构里的 `PushService` 接口，以后接远程推送只加一个实现，调用方不改。

**选**：`flutter_local_notifications ^22.3.2`（2026-10-12，publisher dexterx.dev）。

- 用途：App 在后台但进程还活着时，拉到新消息后弹系统通知；点通知按站内路径跳转。App 被杀、iOS 挂起后收不到，消息照常在消息页看。规则和限制见技术架构「推送」。
- 同时负责申请通知权限：安卓 13 起的 `POST_NOTIFICATIONS`、iOS 的通知授权，对应产品 10.4「第一次发布成功后再问」。
- 不联网、不收集设备信息，不属于第三方 SDK，不进第 17 节的清单；隐私政策里说明通知权限的用途即可。
- Web 不支持（产品 11.1 Web 没有推送），用空实现。临时工程里换上它后 Web 构建照常通过。
- 23.0.0 还在 dev 版，先锁 22.x。

**以后接远程推送时再选（待确认 D2）**

| 方案 | 包与版本 | 平台 | 备注 |
| --- | --- | --- | --- |
| 极光推送 | `jpush_flutter` 3.5.9（2026-10，publisher 未验证） | Android、iOS | 按要求先不接 |
| 个推 | `getuiflut` 0.2.41（2026-05，publisher getui.com） | Android、iOS | 能力和极光相近 |
| 友盟+ U-Push | `umeng_push_sdk` 2.4.0（2025-11） | Android、iOS | 更新慢 |
| 阿里云推送 | `aliyun_push` 1.2.0（2026-05） | Android、iOS | 按量计费，需要阿里云账号 |
| 腾讯云 IM 推送 | `tencent_cloud_chat_push` | Android、iOS | 绑定腾讯 IM，太重 |
| FCM | `firebase_messaging` 17.0.0 | — | 大陆不可用 |
| 单接华为 | `huawei_push` 6.15.0+300 | 只有华为 | 覆盖不全 |

国内安卓机大多没有 GMS，要到达率就得接各厂商通道（华为、荣耀、小米、OPPO、vivo），部分厂商要求企业开发者。到时候要先定开发者主体、服务商和费用。

## 12. 热更新（待确认 D3）

**推荐**：Shorebird，`shorebird_code_push ^2.0.7` + Shorebird CLI。

- 官方文档列出当前支持 Flutter 3.47.7（Dart 3.13.5），且是默认版本。
- 只更新 Dart 代码，下载后**下次启动生效**，没有提示，和产品 12.1 一致。
- 控制台可以回滚补丁（远程卸载，退回上一个补丁或原始版本）。补丁启动就崩时设备端自动退回，这一点只在 Shorebird 博客里看到，具体条件要验证。
- 按比例放量：官方指南的做法是关掉自动更新（`shorebird.yaml` 里 `auto_update: false`），设备第一次启动时随机分组 1–100，比例从我们自己的远程配置读，组号不大于比例的走 `beta` 轨道，其余走 `stable`。不需要 Firestore。
- `readCurrentPatch()` 拿补丁号，显示在「关于」里。
- 苹果审核：Shorebird 在 iOS 上用解释器执行改动的代码，它声明符合 App Store 规则；我们还要守住产品 12.1 的范围（只修问题，不加功能、权限和数据收集）。
- 费用：免费档每月 5000 次补丁安装，Pro 每月 20 美元（官网 2026-10 价格）。
- 构建方式会变：发版要用 `shorebird release android/ios` 代替 `flutter build`，CI 需要 `SHOREBIRD_TOKEN`。

**风险**：Shorebird 的接口和补丁下载在境外，大陆网络能不能稳定拉到补丁，没查到资料，要实测。实测不过就不做热更新，只靠建议更新和强制更新。

**不选**：58 同城的 Fair、`flutter_eval` 这类动态化方案，都要求按它们的 DSL 或子集写代码，限制太多；自己做服务端驱动 UI，工作量远超收益。

## 13. 远程配置与 A/B 测试

**选**：不引入第三方，由业务后端提供一个配置接口，客户端只用 `dio` 和 `shared_preferences`。

- 产品要的内容（功能开关、运营参数、公告、维护、版本线、实验分组、补丁放量比例）都是简单的 JSON，一个接口就够。
- A/B 测试要求「按账号分组，换设备也一样」，分组在服务端按账号算最直接，客户端只读结果。
- 不多一个数据处理方，隐私政策不用多列。

**不选**：`firebase_remote_config` 7.0.0（大陆不可用）；GrowthBook、Unleash、Flagsmith 这类开关服务（多部署一个服务或多一个境外处理方）；火山引擎 A/B（多一个境内 SDK 和数据处理方）。

接口形状和默认值兜底见技术架构「远程配置与 A/B 测试」。接口在现状差距里是 P1，没好之前用内置默认值。

## 14. 统计埋点、监控与崩溃上报

**崩溃上报（服务端待确认 D4）**：`sentry_flutter ^10.1.0`，服务端自建（legacy 用过 `sentry.orbithy.com`）。

- 三端都支持；Web 能上传 source map，安卓、iOS 能上传混淆符号表（`sentry_dart_plugin ^3.4.0`，只在 CI 用）。
- 自建意味着数据和业务数据一样存在境外，要先有用户的跨站同步同意（技术架构 9.5），隐私政策里要写上崩溃信息。
- **版本要显式写 `^10.1.0`**：临时工程里不写版本时，解析器因为 `jni` 的版本选到了 8.14.2；写明 `^10.1.0` 后正常解析到 10.1.0。
- 吸取 legacy 的教训：
  - `SENTRY_AUTH_TOKEN` 只放 CI Secrets，不写进 `pubspec.yaml` 的 `sentry:` 段（legacy 提交过）。
  - legacy 在 `runApp` 前就初始化 Sentry，还开了 100% 的会话回放。新实现同意隐私政策后才初始化，**不开会话回放**（会录到输入框内容，违反产品 12.5）。
  - legacy 把 `.sentry-native/` 运行目录提交进了仓库，`.gitignore` 要加上。
- `sentry_dio` 和 `sentry_flutter` 一起在阶段五加入，给崩溃带上最近的网络请求；性能追踪先不开。

**统计埋点（已定 D5，2026-11-02）**：自建，客户端批量上报到业务后端的 `/telemetry`。这个接口带上报同意的管理，后端源码已有，还没部署；没部署之前只在调试日志输出。不引包。崩溃仍走 Sentry，两条通道不合并。

| 方案 | 不选的原因 |
| --- | --- |
| 友盟+ `umeng_common_sdk` 1.3.1 / `umeng_apm_sdk` 2.3.7 | 只有 Android、iOS，没有 Web；数据存在境内另一家，隐私政策多列一家 |
| 腾讯 Bugly | 官方 Flutter 插件 `bugly_crash` 0.0.6 停在 2021，SDK 约束 `<3.0.0`；社区版 `flutter_bugly` 1.1.1 非官方 |
| 神策 `sensors_analytics_flutter_plugin` 4.2.4 | 要部署神策服务，太重 |
| PostHog `posthog_flutter` 5.56.1 | 云服务在境外，自建也重 |
| Firebase Crashlytics / Analytics | 大陆不可用 |

## 15. 人机验证

产品 12.4：每次发验证码前都先过人机验证，没有风险时自动通过，有风险时才要用户动手。

**服务商**：腾讯云验证码国际站。后端已经接好（接口版本 `tencent-captcha-20261024`，待部署），初始化参数由 `/auth/captcha/config` 每次下发，流程见技术架构 18.3。

**做法**：腾讯云验证码没有官方 Flutter 接入，只有 Web JS。App 里用 `webview_flutter ^4.14.1` 加载我们托管的一个 H5 页面，页面按接口给的 `scriptUrl` 加载腾讯的 JS，验证结果通过 `JavaScriptChannel` 传回；Web 端直接在页面里加载同一份 JS（`dart:js_interop` + `web` 包）。拿到票据后放进请求头交给后端，后端调腾讯的接口校验。

- `webview_flutter` 不支持 Web（pub.dev 平台只有 Android、iOS、macOS），Web 端不能引用它，用条件导入隔开。
- 要实测：国际站的 JS（`ca.turing.captcha.qcloud.com`）在大陆各运营商和校园网下的加载速度和成功率。

当时比较过的其他方案：阿里云验证码 2.0 有官方的 Flutter WebView 接入文档；极验有官方插件 `gt4_flutter_plugin` 0.1.6，但只有 Android、iOS，Web 还要另接 JS；Cloudflare Turnstile、reCAPTCHA 在大陆访问没保障或不可用。

## 16. 开发与测试工具

| 工具 | 版本 | 用途 |
| --- | --- | --- |
| `flutter_lints` | `^6.0.0` | 已有，`fvm flutter analyze` 零问题 |
| `build_runner` | `^2.16.2` | 跑 `riverpod_generator`、`json_serializable`；`fvm dart run build_runner build` |
| `riverpod_generator` | `^4.0.9` | 生成 Provider |
| `riverpod_lint` | `^3.1.9` | 分析器插件，写在 `analysis_options.yaml`；结果只有 `fvm dart analyze` 报告，`flutter analyze` 看不到 |
| `json_serializable` | `^6.15.2` | 生成 DTO 的 `fromJson`（阶段二） |
| `mocktail` | `^1.0.5` | mock 仓库、接口；不需要代码生成（不选 `mockito` 5.8.1，它的空安全写法要生成） |
| `yaml` | `^3.1.4` | 契约测试读 `docs/api.openapi.yml` |
| `clock` | `^1.1.3` | 运行时依赖，饭点、「12 分钟前」、验证码倒计时都从 `clock.now()` 取时间，测试里用 `withClock` 固定时间 |
| `vector_graphics_compiler` | `^1.3.2` | SVG 资源转换器 |
| `sentry_dart_plugin` | `^3.4.0` | CI 上传符号表、source map；令牌只从环境变量 `SENTRY_AUTH_TOKEN` 读 |
| `alchemist` | `^0.14.1` | 以后做 golden 测试时用，它的「CI golden」模式不受操作系统字体渲染差异影响 |
| `integration_test` | SDK | 以后做端到端测试时用 |
| fonttools `pyftsubset` | 不锁 | 字体子集化脚本 |

不加 `very_good_analysis` 等更严的规则集，先守住 `flutter_lints` 零问题。

## 17. 隐私合规：第三方 SDK

**规则**

- 同意《隐私政策》之前，不初始化任何会联网或收集设备信息的 SDK。我们没有游客模式，同意发生在登录页，所以登录前只有登录页和协议页在运行。
- 下表进隐私政策的「第三方 SDK 清单」，写明 SDK 名称、提供方、用途、收集的信息、隐私政策链接。新增 SDK 时同步更新本表和隐私政策。
- 系统能力（定位、相机、相册、通知权限）不是第三方 SDK，但要在隐私政策里说明用途和时机。

| SDK | 提供方 | 用途 | 收集的信息（以对方隐私政策为准） | 初始化时机 | 数据去向 |
| --- | --- | --- | --- | --- | --- |
| Shorebird | Shorebird（境外服务） | 热更新 | 应用版本、补丁号、平台与 CPU 架构、随机客户端标识 | 同意隐私政策后 | 境外 |
| 天地图 | 自然资源部天地图 | 地图底图 | 请求瓦片时的 IP 和地图范围 | 打开附近、新建店时 | 境内 |
| 腾讯云验证码（国际站） | 腾讯云 | 风控 | 设备环境、操作行为 | 每次发验证码前 | 国际站，存放地待确认 |
| Sentry（自建） | 我们自己部署，不是第三方 | 崩溃上报 | 崩溃堆栈、设备型号、系统版本、App 版本、账号 ID | 同意隐私政策后 | 境外，和业务数据同处 |

## 18. 密钥与配置

| 名称 | 用在哪 | 性质 | 放哪 |
| --- | --- | --- | --- |
| 环境配置（接口地址、Web 地址等） | 客户端 | 公开 | `config/<环境>.json`（未跟踪），CI 用 Secret 写出；仓库只放 `config/example.json` |
| 天地图 Key | 客户端 | 公开，在控制台限制域名或应用 | 同上 |
| Sentry DSN | 客户端 | 公开 | 环境配置 |
| `SENTRY_AUTH_TOKEN` | CI 上传符号表 | 机密 | CI Secret，不写进 `pubspec.yaml` |
| `SHOREBIRD_TOKEN` | CI 发版和补丁 | 机密 | CI Secret（`shorebird.yaml` 里的 `app_id` 不是机密，可以入库） |
| 安卓上传密钥、`android/key.properties` | 签名 | 机密 | CI Secret；`build.gradle.kts` 参考 legacy 的「缺失时回落 debug 签名」写法 |
| iOS 证书、描述文件、App Store Connect API Key | 签名、上传 | 机密 | CI Secret |
| 腾讯验证码 AppSecretKey、云 API 密钥 | 后端 | 机密 | 后端。客户端用的 AppId 由 `/auth/captcha/config` 每次下发，不进环境配置 |

`--dart-define-from-file` 传进去的值会编进安装包，只能放公开的值。`.gitignore` 要补上 `config/*.json`（保留 `example.json`）、`android/key.properties`、`*.jks`、`.sentry-native/`。

## 19. 待确认

| 编号 | 事项 | 推荐 | 需要谁 |
| --- | --- | --- | --- |
| D1 | 地图底图用哪家 | `flutter_map` + 天地图：三端一套代码，标记和面板都是普通组件，Key 免费申请。代价是底图样式只能加滤镜靠近 `map-*` 令牌，路网和 POI 可能不如高德细；要申请 Key、确认调用量上限和使用条款、按要求显示天地图标识和审图号。若选高德，App 和 Web 要各写一套地图，并确认商业授权 | 产品负责人、设计 |
| D2 | 远程推送什么时候接、接哪家 | 现在只用本地通知（第 11 节）。要接时先定开发者主体（个人还是企业，部分厂商通道要求企业）、服务商和费用，再按 `PushService` 加一个远程实现 | 产品负责人 |
| D3 | 热更新是否用 Shorebird | 推荐用，但先做一次实测：在校园网和三大运营商网络下能否稳定下载补丁、回滚是否生效。不过就不做热更新，只保留建议更新和强制更新。用的话发版流程改用 `shorebird release`，需要付费档时再定 | 产品负责人 |
| D4 | 崩溃上报的 Sentry 放哪、谁维护 | 沿用自建 Sentry（legacy 的 `sentry.orbithy.com` 或新部署），数据和业务一起在境外，写进隐私政策。要确认谁维护、大陆访问速度 | 产品负责人、后端 |
| D5 | 统计埋点自建还是用第三方 | 已定（2026-11-02）：自建，上报到后端 `/telemetry`；崩溃仍用 Sentry | — |
| D6 | 人机验证服务商 | 已定：腾讯云验证码国际站，后端已接（第 15 节）。还要实测国际站 JS 在大陆网络下的表现，确认验证数据的存放地写进隐私政策 | 产品负责人、后端 |
| D7 | 中文字体怎么内置 | 三端内置 Noto Sans SC 可变字体的 GB 2312 子集（预计 4–5 MB，待实测），子集外的字由系统字体补；Web 上字体后台加载、先用回落字体显示，并自托管回落字体。要接受安装包变大、Web 首屏前几百毫秒字形不同 | 产品负责人、设计 |
| D8 | 自动去背景放哪做 | 放后端：上传完成后生成去背景版本，客户端只管开关和显示。客户端三端没有统一的抠图能力 | 产品负责人、后端 |
