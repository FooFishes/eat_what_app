# EatWhat 依赖选型

本文记录装哪个包、哪条版本线、为什么不选另一个。新增依赖前先查这里，表里没有的先提出来，确定后补进本文再改 `pubspec.yaml`。

结论基于 2026-10-22 在 Flutter 3.47.7 / Dart 3.13.5 上的实测：用下文的清单做了真实的依赖解析、`build_runner` 生成、`flutter analyze` / `dart analyze` 和 `flutter build web --release`（含 Wasm 预检），细节见文末「验证记录」。版本号是当天解析出的最新可用版本。界面需求按 PR #11 同步后的设计稿（MingCute 图标、底部面板 `Panel`、开关 `Switch` 以及登录、搜索、评论、设置等页面）核对过。

## 总表

### 采用

依赖不一次性全加：每个包在第一个用到它的功能 PR 里加入，同一个 PR 里把本表的「状态」改成「已引入」。

| 用途 | 包 | 约束 | 什么时候加 | 状态 |
| --- | --- | --- | --- | --- |
| Material 组件、`ThemeExtension`、中文本地化 | `material_ui` | `^1.8.0` | 搭骨架时 | 待引入 |
| 状态管理 | `flutter_riverpod` | `^3.4.3` | 搭骨架时 | 待引入 |
| provider 注解 | `riverpod_annotation` | `^4.0.7` | 同上 | 待引入 |
| 路由 | `go_router` | `^18.1.1` | 搭骨架时 | 待引入 |
| SVG 图标和插画 | `flutter_svg` | `^2.3.0` | 搭骨架时（底部导航就要用图标） | 待引入 |
| HTTP | `dio` | `^5.11.1` | 接第一个接口时 | 待引入 |
| JSON 注解 | `json_annotation` | `^4.12.0` | 接第一个接口时 | 待引入 |
| 登录态（token） | `flutter_secure_storage` | `^11.2.0` | 做登录时 | 待引入 |
| 普通偏好 | `shared_preferences` | `^2.5.6` | 第一次需要本地偏好时 | 待引入 |
| 统一认证 WebView | `webview_flutter` | `^4.14.1` | 做统一认证登录时 | 待引入 |
| 打开外链、调起地图导航 | `url_launcher` | `^6.3.3` | 登录页协议链接 / 「导航去店里」 | 待引入 |
| 选图、拍照 | `image_picker` | `^1.2.4` | 做发布时 | 待引入 |
| 网络图片缓存 | `cached_network_image` | `^4.0.5` | 第一个展示网络图片的页面 | 待引入 |
| 地图 | `flutter_map` | `^8.3.2` | 做附近页时 | 待引入 |
| 经纬度类型 | `latlong2` | `^0.10.1` | 同上（`flutter_map` 的坐标类型来自它） | 待引入 |
| 定位 | `geolocator` | `^14.1.2` | 做附近页 / 选店时 | 待引入 |
| 系统分享 | `share_plus` | `^13.3.1` | 做菜品、餐厅、专题页的分享时 | 待引入 |
| 版本号 | `package_info_plus` | `^10.2.2` | 做关于页 / 反馈时 | 待引入 |
| 设备型号 | `device_info_plus` | `^13.3.0` | 做反馈时 | 待引入 |
| 崩溃与性能监控 | `sentry_flutter`、`sentry_dio` | `^10.1.0` | 第一次分发测试包之前 | 待引入 |
| 热更新补丁号 | `shorebird_code_push` | `^2.0.7` | 和 Shorebird 一起，第一次分发测试包之前 | 待引入 |

开发依赖：

| 用途 | 包 | 约束 | 什么时候加 | 状态 |
| --- | --- | --- | --- | --- |
| 代码规范 | `flutter_lints` | `^6.0.0` | 已有 | 已引入 |
| 测试 | `flutter_test`（SDK） | — | 已有 | 已引入 |
| 代码生成 | `build_runner` | `^2.16.2`（原因见「状态管理」） | 搭骨架时（第一个 provider 就要生成） | 待引入 |
| provider 生成 | `riverpod_generator` | `^4.0.9` | 同上 | 待引入 |
| JSON 生成 | `json_serializable` | `^6.15.2` | 接第一个接口时 | 待引入 |
| Mock | `mocktail` | `^1.0.5` | 第一个需要替身的测试 | 待引入 |
| Riverpod 规则检查 | `riverpod_lint`（写在 `analysis_options.yaml` 的 `plugins`，不进 `pubspec.yaml`） | `3.1.9` | 和 `flutter_riverpod` 一起 | 待引入 |
| 符号表、source map 上传 | `sentry_dart_plugin` | `^3.4.0` | 和 Sentry 一起，只在 CI 里跑 | 待引入 |

以后需要时再评估、目前不加：`flutter_launcher_icons`、`flutter_native_splash`（有正式图标和启动图时）、`integration_test`（SDK 自带，写端到端测试时）、`smooth_sheets`（附近页抽屉先用内置的 `DraggableScrollableSheet`，底部面板 `Panel` 用内置的 `showModalBottomSheet`，满足不了时再看）、`flutter_image_compress`（`image_picker` 自带的压缩不够用时）、推送 SDK（见「推送」）。

### 不用

| 包 | 不用的原因 |
| --- | --- |
| `freezed` | 见「网络与序列化」。主构造函数 + `sealed` 已覆盖大部分需求 |
| `go_router_builder`、`auto_route` | 见「路由」 |
| `retrofit`、`swagger_parser`、`openapi_generator`、`tonik` | 见「网络与序列化」，不从 OpenAPI 生成客户端 |
| `http` | 和 `dio` 同类，只留一个 |
| `flutter_bloc`、`provider`、`signals` | 和 Riverpod 同类 |
| `permission_handler` | 定位权限 `geolocator` 自带；Android 13+ 的系统选图器和 iOS 的 PHPicker 都不需要相册权限；拍照权限 `image_picker` 自己申请。通知权限等接推送时再看 |
| `geocoding` | 不需要逆地理编码，商圈由后端 `/hub/locate` 按坐标返回 |
| `flutter_inappwebview` | 最后一个稳定版 6.1.5 发布于 2024-10，之后只有 beta；`legacy` 用的就是 beta。统一认证只需要拦截回调地址，官方 `webview_flutter` 够用 |
| `flutter_web_auth_2` | 需要后端把回调重定向到 App 的自定义 scheme，现有 `/auth/callback` 做不到 |
| `image_cropper`、`crop_your_image`、`extended_image` | 见「图片」。裁切只保存位置和缩放，不输出新图片；它们自带的界面也对不上「调整照片」画板 |
| `lucide_icons_flutter` 等图标包 | 设计改用 MingCute Line，SVG 已在 `prototype/assets/icons/`，见「字体与图标」 |
| 由 SVG 生成图标字体 | 字体不支持描边，要先把描边转成轮廓；20px 以下加粗描边的规则还要再生成几套字体。78 个图标不值得这条工具链 |
| `connectivity_plus` | 它只知道有没有联网接口，不知道服务器连不连得上。「没网」状态按请求失败判断 |
| `palette_generator` | 已在 pub.dev 标为 discontinued；设计规定的取色算法也和它不同 |
| `google_fonts` | 运行时从 Google 的字体 CDN 下载，在国内不可靠。字体打包进 App，见「字体与图标」 |
| `hive_ce`、`drift`、`sqflite` | 目前没有需要本地数据库的功能 |
| `maplibre`、`maplibre_gl`、`vector_map_tiles` | 见「地图与定位」 |
| 高德、百度、腾讯地图的 Flutter 插件 | 见「地图与定位」 |
| Firebase Crashlytics、Bugly | 不支持 Web；Firebase 依赖的 Google 服务在国内不可用 |

## 基础：Flutter / Dart 版本与升级策略

- 版本只写在 `.fvmrc`（当前 3.47.7 / Dart 3.13.5），CI 从这里读取。
- 依赖约束一律写 `^x.y.z`，不写 `any`。实测 `sentry_flutter: any` 会被解析到 8.14.2 而不是 10.x，写成 `^10.1.0` 才能拿到新版（原因见「监控与崩溃上报」）。
- `pubspec.lock` 入库。补丁版本可以随功能 PR 顺手升；次版本和主版本单独一个 PR，标题如 `build(deps): 升级 go_router 至 18.2.0`。
- 升级 Flutter 之前先看代码生成链（`analyzer`、`build`、`source_gen`）跟上没有：生成器跟不上新版 analyzer 是最常见的升级阻塞点。本文只用 `riverpod_generator` 和 `json_serializable` 两个生成器，升级前确认这两个都已支持新版 Dart 的语法和 analyzer。

### Material 改用 `material_ui`

Flutter 3.47 把 Material 和 Cupertino 拆成了独立的 `material_ui`、`cupertino_ui` 包，SDK 内置的 `package:flutter/material.dart` 预计在 11 月的稳定版正式标记为 deprecated（[破坏性变更说明](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui)、[3.47 发布说明](https://flutter.dev/blog/whats-new-in-flutter-3-47)）。CI 要求 `analyze` 零问题，到时所有 `import 'package:flutter/material.dart'` 都会报 deprecated，迟早要迁。现在 `lib/` 里只有两个文件，从第一行就用 `material_ui` 成本最低。

- 导入改成 `package:material_ui/material_ui.dart`。迁移现有代码可以用 `dart fix --apply --code=migrate_design_widgets`。
- 本地化：`localizationsDelegates: GlobalMaterialLocalizations.delegates`，`supportedLocales` 只放 `zh_CN`。这一个列表已经包含 Material、Cupertino、Widgets 三套代理，不需要再单独依赖 `flutter_localizations`。
- 设计令牌要做成 `ThemeExtension`，它挂在 `ThemeData` 上，所以虽然界面不是 Material 风格，仍然用 `MaterialApp.router` 作根组件。
- 不单独加 `cupertino_ui`，`material_ui` 已经依赖它。`uses-material-design: true` 保留，Material 组件内部的默认图标要用。
- 过渡期的兼容问题：本文选的包里，`flutter_map`、`sentry_flutter`、`webview_flutter`、`flutter_riverpod`，以及 `cached_network_image` 依赖的 `octo_image`，还在导入旧的 `package:flutter/material.dart`（`go_router`、`cached_network_image` 本身已经迁了）。它们大多只用到基础类型，不读主题，不影响使用。如果某个旧库组件确实需要 `Theme.of` 或 `MaterialLocalizations.of`，只在那一小块外面包 `MaterialUiCompatibilityBridge`。注意这个桥接组件本身也标了 deprecated，用的地方要加 `// ignore: deprecated_member_use` 并写明原因。

## 状态管理

选 **`flutter_riverpod` 3 + `riverpod_generator`**：provider 一律用 `@riverpod` 注解写，由生成器生成，不手写 `Provider(...)`。

为什么是 Riverpod：

- 这个 App 的大部分页面是「请求接口、显示加载 / 失败 / 内容」，`AsyncValue` 直接对应这三种状态。
- 菜品详情、餐厅详情这类按 id 取数据的页面用带参数的 provider，离开页面自动释放。
- 测试时用 `ProviderContainer` / `ProviderScope(overrides: ...)` 替换仓库层，不需要依赖注入框架。
- `legacy` 用的就是 Riverpod 3，团队熟悉。

为什么用生成器：

- 写法统一：函数式 provider 和 `Notifier` 都只是一个注解，参数直接写成函数参数，不用在 `FutureProvider.autoDispose.family` 这类组合里挑，也不用写泛型。
- 默认自动释放，常驻的（登录态等）显式写 `@Riverpod(keepAlive: true)`，一眼能看出哪些常驻。
- 本来就有 `json_serializable` 这条生成链，再加一个生成器不增加新工具和 CI 步骤。

```dart
part 'session.g.dart';

@Riverpod(keepAlive: true)
class Session extends _$Session {
  @override
  TokenResponse? build() => null;

  void signIn(TokenResponse token) => state = token;
}

@riverpod
Future<List<Dish>> nearbyDishes(
  Ref ref, {
  required double lat,
  required double lng,
}) async {
  final token = ref.watch(sessionProvider);
  // ...
}
```

使用处是 `ref.watch(sessionProvider)`、`ref.watch(nearbyDishesProvider(lat: lat, lng: lng))`。`Ref` 和注解来自 `riverpod_annotation`，`ProviderScope`、`ConsumerWidget` 仍来自 `flutter_riverpod`。生成的 `*.g.dart` 和 JSON 的一样入库（见「JSON」）。

代价：

- **`build_runner` 停在 2.16.2**。`riverpod_generator` 4.0.9 限制 `build < 5.0.0`，实测加入后 `build_runner` 从 2.17.1 退回 2.16.2，`build` 从 5.0.0 退回 4.0.11。`json_serializable`（6.15.2）和 `analyzer`（14.6.0，能解析主构造函数）仍是最新版，所以眼下没有实际损失：`build_runner` 2.17 新增的是实验性的共享 part 文件和 `serve` 命令的修复，这里都用不到。约束写 `^2.16.2`，等 `riverpod_generator` 放开 `build` 5 再单独一个 PR 升上去。以后再出现生成器跟不上 analyzer 的情况，升级 Flutter 要等它。
- 每个 provider 文件多一个 `.g.dart`，改了 provider 的签名要重新生成。开发时开着 `dart run build_runner watch`。

`riverpod_lint` 一起用。除了通用规则，它还检查生成器的写法，实测 `functional_ref`（函数式 provider 第一个参数必须是 `Ref`）、`notifier_extends`（`Notifier` 必须继承生成的 `_$Xxx`）、`only_use_keep_alive_inside_keep_alive`（常驻 provider 不能依赖会被释放的 provider）都会报。它通过新的 analyzer 插件机制安装，写在 `analysis_options.yaml`：

```yaml
plugins:
  riverpod_lint: 3.1.9
```

实测 **`dart analyze` 会报出它的规则，`flutter analyze` 不会**（3.47.7）。引入时 CI 的 check 步骤要加一行 `dart analyze`。

不选的同类方案：`flutter_bloc` 样板代码多，一个页面要写 event、state、bloc 三份；`provider` 的作者已经推荐迁到 Riverpod；`signals` 社区小，异步和依赖注入要自己补。

## 路由

选 **`go_router`**（flutter.dev 维护），不用 `go_router_builder`。

- 设计规范要求 `NavBar` 放在 `StatefulShellRoute` 外层的 `Stack` 里，三个主页面各自保留导航栈，这正是 `go_router` 的 `StatefulShellRoute.indexedStack`。
- 未登录拦截用 `redirect`，配合 Riverpod 的登录态。
- Web 用路径式 URL：`usePathUrlStrategy()`，来自 SDK 自带的 `flutter_web_plugins`，不用另装包。
- 页面一共十几个，路径用常量集中管理就够，不需要 `go_router_builder` 的类型安全路由。它 4.5.2 同样限制 `build < 5.0.0`，加进来不会让版本锁更紧，以后路由参数变多、手写容易出错时可以再提。`auto_route` 和 `go_router` 同类，只留一个。

## 网络与序列化

### HTTP：`dio`

- 拦截器正好对应接口约定的几件事：从登录返回的 `tokenName` 读头名（不写死 `satoken`）、给请求加 `Bearer` 头；HTTP 200 也检查业务 `code`，非零转成统一的业务异常；登录失效时清 token 并回到登录页。
- 上传走预签名：先 `/upload/presign`，再向 `putUrl` PUT 原始字节，再 `/upload/complete`。`dio` 的 `onSendProgress` 可以直接驱动上传进度，`CancelToken` 可以中途取消。
- 和 `sentry_dio` 配合，请求会自动记进 Sentry 的面包屑和性能追踪。
- 接口地址按环境配置：`--dart-define-from-file=config/<env>.json`，代码里用 `String.fromEnvironment` 读取，SDK 自带，不需要 `flutter_dotenv`、`envied` 一类的包。含密钥的配置文件不入库。

`http` 也能做，但拦截、进度、取消都要自己写，不选。

### JSON：`json_serializable`

- 数据模型按 AGENTS.md 的约定用主构造函数，`fromJson` / `toJson` 交给 `json_serializable` 生成。实测 6.15.2 已支持主构造函数：

  ```dart
  @JsonSerializable()
  class TokenResponse({
    required final String tokenName,
    required final String tokenValue,
    final int? tokenTimeout,
  }) {
    factory fromJson(Map<String, dynamic> json) => _$TokenResponseFromJson(json);

    Map<String, dynamic> toJson() => _$TokenResponseToJson(this);
  }
  ```

- 接口里「数字有时是字符串」这类不规整的字段，用 `@JsonKey(fromJson: ...)` 或 `JsonConverter` 处理，不在业务代码里到处判断。
- 生成的 `*.g.dart`（JSON 和 provider 的）入库（和 `legacy` 一致），这样 IDE 打开就能用、CI 的 Android / iOS / Web 三个构建 job 不用各跑一遍生成。CI 的 check 步骤加一次 `dart run build_runner build` 后 `git diff --exit-code`，防止忘了重新生成。
- 不用 `freezed`：主构造函数已经把数据类写得很短，联合类型用 Dart 3 的 `sealed class` + 模式匹配。`freezed` 4.0 也支持主构造函数，以后页面状态的 `copyWith` 写得太累，可以再单独提出来加。

### 不从 OpenAPI 生成客户端

`docs/api.openapi.yml` 只作为对照依据，客户端代码手写。实测用 `swagger_parser` 1.45.0 生成：

- 直接读 YAML 会在解析数字时崩溃，要先转成 JSON 才能跑。
- 生成了 17 个客户端、101 个请求、143 个数据类，共 162 个文件、5736 行，管理端接口也在里面。
- 规范里几乎所有字段都写成 `anyOf: [T, null]`，生成的模型全部可空，连 `FoodVOResponse` 的 `id`、`name` 也是可空的；`ErrorResponse.code` 是 `int | string`，生成为 `dynamic`；每种 `Result_*` 包装各生成一个类；方法名形如 `authControllerLoginPost`。
- `AuthReply.data` 是没有判别字段的联合类型，生成代码跑完 `build_runner` 后 `dart analyze` 报 4 个问题。

生成的类型直接拿来写界面，到处都要判空、转换，不比手写省事。做法：按接口分组（Auth、Food、Restaurant 等）手写很薄的 API 类，只写客户端真正调用的接口；一个通用方法负责解开 `Result` 包装、检查 `code`；模型按实际返回决定哪些字段可空。规范更新时对照 `info.version` 看变更，有出入按 AGENTS.md 反馈给后端。

## 本地存储与安全存储

| 存什么 | 用什么 |
| --- | --- |
| 登录 token 和 `tokenName` | `flutter_secure_storage`：iOS Keychain、Android Keystore 加密；Web 上是 WebCrypto 加密后放 localStorage，防不了同源脚本，但 Web 版本来也没有更安全的地方 |
| 已同意的协议版本、上次所在商圈、最近搜过的词等普通偏好 | `shared_preferences`，用新的 `SharedPreferencesAsync` 接口 |

目前没有离线浏览、草稿箱这类需要本地数据库的功能，不加 `drift` / `sqflite` / `hive_ce`。将来要做时优先考虑 `drift`（全平台含 Web、类型安全）。

## 地图与定位

### 地图引擎：`flutter_map`

- 纯 Flutter 实现，Android、iOS、Web 一套代码；实测 Web 构建和 Wasm 预检都能通过。
- 标记就是普通 Flutter 组件。`MapPin` 要放圆形招牌菜图、选中后放大并加舞台色外圈、下面挂店名胶囊、整体作为带 `aria-label` 的按钮，用组件写很直接；原生地图 SDK 只能用位图做标记，交互和无障碍都要绕路。
- 商圈范围是虚线圆角框：`PolygonLayer` 支持 `StrokePattern.dashed`。
- 不涉及原生 SDK 的隐私合规初始化。

不选的引擎：

- **高德 / 百度 / 腾讯的 Flutter 插件**：高德官方插件 `amap_flutter_map` 停在 2021 年、不支持 Dart 3；社区分支 `amap_map` 最后发布于 2025-03；百度、腾讯的插件只支持 Android、iOS。三家都没有 Web，要另写一套 JS 版本。
- **`maplibre` / `maplibre_gl`**：矢量地图、样式完全可控，但 `maplibre` 还是 0.3.x，标记是图层而不是组件；`flutter_map` 的矢量瓦片插件 `vector_map_tiles` 停在 2024 年，只兼容 `flutter_map` 7。

### 底图来源：天地图

用天地图的栅格瓦片（2026-10-22 确定）。官方平台、有审图号，申请 key 即可使用，不需要自己搭制图和托管。

- 只用 `flutter_map` 的 `TileLayer` 加载，不引入天地图的 SDK，不需要额外的包。
- key 用 `--dart-define` 注入，不入库。
- 天地图的坐标是 CGCS2000（约等于 WGS-84），后端是 GCJ-02：显示后端的店铺、商圈时先从 GCJ-02 转成 WGS-84，见下文「定位与坐标」。
- 瓦片样式改不了，只能整体调色向 `map-ground` 靠，和画板会有差距。做附近页时和设计一起定调色参数。
- Web 端加载瓦片要求瓦片服务器返回 CORS 头，做附近页时先验证，不满足就经自己的服务器反代。

底图只是 `TileLayer` 的地址和坐标转换，以后要换不影响页面代码。没选的两个来源：

| 来源 | 没选的原因 |
| --- | --- |
| 按设计自制底图（OSM 数据按 `map-*` 色板渲染成瓦片，放对象存储） | 最贴合画板，但要一次性做制图；OSM 数据没有审图号，上架国内应用商店有被拒的风险。以后要贴合设计可以再换 |
| 高德瓦片地址 | 坐标是 GCJ-02、数据最全，但公开的瓦片地址不是给第三方引擎用的正式产品，有违反服务条款的风险；样式同样改不了 |

### 定位与坐标

- **`geolocator`**：取当前位置，自带权限检查和申请，Web 走浏览器定位。
- 设备和浏览器给的是 WGS-84，后端接口（`/hub/locate`、`/restaurant/search` 等的 `gcjLng` / `gcjLat`）要的是 GCJ-02；天地图底图又是 WGS-84 一侧。所以两个方向都要转：调接口前 WGS-84 转 GCJ-02，把后端的店铺、商圈画到底图上前 GCJ-02 转 WGS-84。转换公式是公开的，几十行，手写工具函数并配单元测试，不引入包。
- 「导航去店里」用 `url_launcher` 打开高德地图（App 或网页版的 URI API），高德用的就是 GCJ-02，后端坐标直接传。

## 图片：选择、裁切与取色

- **选图、拍照：`image_picker`**。设 `maxWidth` / `imageQuality` 由平台原生缩放压缩后再上传，不另加压缩库。Android 13+ 走系统照片选择器，iOS 走 PHPicker，都不需要相册权限。iOS 上 HEIC 等非 JPEG/PNG/GIF 格式会重新编码成 JPEG（看过 `image_picker_ios` 源码），上传时声明的 `contentType` 因此是确定的；真机上再确认一次。
- **调整照片：手写**。设计要求保存的是「主菜在圆圈里的位置和缩放」，原图照常上传，`DishPlate` 按保存的参数显示，`DishTile` 直接用原图。所以不需要输出裁切后的新图片，拖动、缩放、缩放滑条用 `GestureDetector` + `Transform` 写，界面按 `G-Crop` 画板。
- **头像：同一套手势，多一步出图**。编辑资料里换头像也是拖动、缩放进圆圈，但头像只存一个地址，要上传裁好的方图：用 `dart:ui` 的 `PictureRecorder` 按选定的位置画到 512×512 再导出 PNG，不需要裁切库。PNG 体积不合适时再考虑用 `image` 包编码 JPEG。
- **舞台取色：手写**。用 `dart:ui` 把图片按小尺寸解码（各平台含 Web 都能用），只取圆圈内的像素，按饱和度加权求主色调，再在感知均匀的色彩空间（如 OKLab）里吸附到 9 个 `stage-*`，给出两个备选；饱和度太低时用分类默认色。算法是纯函数，用 `prototype/assets/photos/` 里的实拍图写单元测试，对照 `G-PhotoPipeline` 的结果。
- **网络图片：`cached_network_image`**。移动端有磁盘缓存，推荐流、转盘反复出现同一批图时不重复下载；Web 端用浏览器缓存。
- **插画：`flutter_svg`**。`prototype/assets/dishes/*.svg` 复制到项目 `assets/` 后用于空状态和引导。
- **自动去背景（画板上标「测试中」）：先不做**。没有覆盖 Android、iOS、Web 三端的端侧方案（ML Kit 的主体分割只有 Android，iOS 的 Vision 抠图要 iOS 17）。按设计规范，效果不好时本来就退回圆形裁切；需要时再评估服务端处理。

## 字体与图标

### 字体：打包进 App，不用 `google_fonts`

- Noto Sans SC 和 Bricolage Grotesque 都是 OFL 授权，可以随 App 分发。
- 不用 `google_fonts`：它在运行时从 Google 的字体 CDN 下载，国内网络下不可靠。
- Web 尤其要打包：Flutter Web 遇到没有声明的中文字形时，默认也去 Google 的 CDN 拉 Noto 字体，国内会出现方块或长时间空白。
- 用可变字体，每个字族一个文件。Flutter 3.47 里 `FontWeight` 会直接设置可变字体的 `wght` 轴（SDK 源码 `FontWeight` 注释有说明），设计规范用到的 400 到 900 各档都不用单独放文件。
- Noto Sans SC 完整字库在 10 MB 以上，要做子集：保留《通用规范汉字表》的字和常用符号，用 fonttools 的 `pyftsubset` 生成，脚本放仓库里。fonttools 是 Python 开发工具，不进 `pubspec.yaml`。子集外的生僻字在移动端回落系统字体（iOS 是苹方，设计规范允许）。
- Bricolage Grotesque 只用于数字，子集只留数字、`¥`、`.`、`m`、`k` 和空格。

### 图标：`flutter_svg` 渲染设计稿里的 SVG

设计稿的图标是 MingCute Line（Apache-2.0），78 个按用途命名的 SVG 在 `prototype/assets/icons/`，描边写 `stroke="currentColor"`、`stroke-width="2"`，只有 `heart-on`、`bookmark-on` 是实心填充。规范要求按文件名引用、颜色跟着文字、20px 以下加粗描边（14px 用 2.6、16px 用 2.4、18px 用 2.13）。

- 这批 SVG 原样复制到项目的 `assets/icons/`，用插画已经要用的 `flutter_svg` 渲染，不再加图标包，一类问题一个方案。
- 封装一个图标组件：按用途名找文件；颜色默认取 `IconTheme`，通过 `SvgTheme(currentColor: ...)` 传给 SVG；按尺寸把 `stroke-width="2"` 换成规范里的数值再交给 `SvgPicture.string`；只有图标的按钮写 `semanticsLabel`，旁边有文字时排除出语义树。这个做法在 Flutter 3.47.7 上实测可行，见「验证记录」。
- SVG 是异步加载的，第一次出现会晚一帧。底部导航这类首屏图标在启动时预先加载。Widget 测试里要用 `tester.runAsync` 等资源加载完。
- 用途名做成枚举或常量，和 `prototype/design-system/assets/Icons/README.md` 的对照表一一对应，缺图标时按那里的规则补。

## 登录与认证

手机号验证码登录、密码登录都是普通表单，不需要额外的包。需要包的是山大统一认证，登录页和学生认证页（`G-Verify`）都会用到：

- **移动端：`webview_flutter`**。WebView 打开 `/auth/sdu`，在 `NavigationDelegate` 里拦截跳到回调地址（带 `token` 参数）的那次导航，再调用回调接口换取结果。`legacy` 用 `flutter_inappwebview` 做了同样的事，换成官方包不影响流程。
- **Web：整页跳转**。浏览器里 iframe 方式拿不到跨域的跳转地址，只能整页跳到统一认证，再由后端把结果带回 Web 版的地址。
- 山大邮箱认证「回到这里会自动刷新」用 SDK 自带的 `AppLifecycleListener`，回到前台时重新查认证状态。
- 《隐私政策》《用户协议》《数据存放说明》用 `url_launcher` 打开或做成 App 内页面，不另加包。

## 分享

菜品、餐厅、专题页右上角有分享。

- **`share_plus`**：调起系统分享面板；Web 上走浏览器的 Web Share API，浏览器不支持时由我们退回复制链接。
- 复制链接、复制文字用 SDK 自带的 `Clipboard`。
- 分享出去的链接指向 Web 版对应页面，所以 Web 版路由要和 App 里的页面一一对应（`go_router` 的路径式 URL 已经满足）。

## 版本号、设备型号与补丁号

关于页显示版本和补丁号，反馈会附上版本、补丁号和设备型号。

- **版本号：`package_info_plus`**。读 `pubspec.yaml` 的 `version` 和构建号，三端都支持。Sentry 也依赖它，不额外增加体积。
- **设备型号：`device_info_plus`**。Android 取厂商和型号，iOS 取机型，Web 取浏览器和系统。
- **补丁号：`shorebird_code_push`**。用 `ShorebirdUpdater().readCurrentPatch()` 读当前补丁号，没有补丁时为空。不是 Shorebird 构建的包（本地调试、普通 `flutter build`）和 Web 上 `isAvailable` 为 `false`，读不到补丁号（看过它的 Web 实现）。Web 上关于页怎么显示，做时和设计对一下。

### 热更新：Shorebird

2026-10-22 确定接入 Shorebird，第一次分发测试包时和 Sentry 一起接。Android、iOS 发版后，Dart 层的修复可以不经应用商店直接推给用户；原生代码和插件的改动仍然要重新发版。Web 每次部署就是最新版，不用它。

- **CLI 不进 `pubspec.yaml`**：Shorebird 的命令行工具装在开发机和 CI 上；`shorebird init` 生成的 `shorebird.yaml`（含 `app_id`，不是密钥）入库。
- **发版方式**：要推补丁的版本必须用 `shorebird release android` / `shorebird release ios` 构建，修复用 `shorebird patch` 推送。CI 里只在打 `v*` tag 的发版构建改用 shorebird；PR 和 `main` 的构建保持 `flutter build`，避免每次提交都在 Shorebird 上生成一个版本。登录凭据放 GitHub Secrets（`SHOREBIRD_TOKEN`）。iOS 目前只做未签名构建，shorebird 有对应的不签名参数，接入时按官方文档配。
- **Flutter 版本**：Shorebird 用自己维护的 Flutter 版本构建，`.fvmrc` 里的版本要在它支持的列表里。以后升级 Flutter 先确认 Shorebird 已支持该版本。
- **和 Sentry 配合**：上报时把补丁号带进 Sentry 的 release 信息，崩溃能对应到具体补丁；补丁的符号表同样在 CI 里上传。
- **接入时先验证**：Shorebird 是否已支持 Flutter 3.47.7；国内网络下检查和下载补丁的速度；免费额度够不够测试阶段用。

## 推送

通知设置页（`G-SettingsNotify`）标着「待接入」，`docs/api.openapi.yml` 里也还没有登记推送设备的接口，所以现在不选型。到时要考虑的约束先记在这里：

- 国内多数 Android 手机没有 Google 服务，用不了 FCM，要接各家厂商通道（华为、小米、OPPO、vivo、荣耀），一般通过极光、个推这类聚合推送 SDK 接。
- iOS 走 APNs，聚合推送 SDK 一般也包了。
- 设计写明网页版没有推送，Web 不用考虑。
- 「系统通知关着，去打开」要读通知权限并跳到系统设置，到时用推送 SDK 自带的接口，或再评估 `permission_handler`。

## 监控与崩溃上报

选 **Sentry**（`sentry_flutter` + `sentry_dio`），在第一次分发测试包之前接入。

- 三端都支持，Web 端可以上传 source map，`legacy` 也用的 Sentry。Firebase Crashlytics 和 Bugly 都不支持 Web，Firebase 在国内还依赖不可用的 Google 服务。
- 约束必须写 `^10.1.0`。Sentry 10.1.0 把 `jni` 锁在 `<1.1.0`，求解器在 `any` 下会选择保留新版 `shared_preferences_android` 而把 Sentry 退回 8.14.2。写死 `^10.1.0` 后 `shared_preferences_android` 会停在 2.4.28，功能上没有影响，等 Sentry 放开 `jni` 再升。
- DSN 用 `--dart-define` 注入。符号表和 source map 由 `sentry_dart_plugin` 在 CI 里上传，auth token 只放 GitHub Secrets（`SENTRY_AUTH_TOKEN`），**`pubspec.yaml` 里不写任何 `sentry:` 凭据**。`legacy` 分支曾把 token 写进 `pubspec.yaml`，那个 token 如果还没作废，接入前先去 Sentry 后台作废。

## 开发与测试工具

| 工具 | 说明 |
| --- | --- |
| `flutter_lints` | 已有，AGENTS.md 规定的规则集，不换 `very_good_analysis` |
| `riverpod_lint` | analyzer 插件，见「状态管理」；CI 要加 `dart analyze` |
| `build_runner` + `riverpod_generator` + `json_serializable` | 一条生成链、两个生成器。首次生成约 1 分钟（AOT 模式），之后增量生成；开发时开着 `dart run build_runner watch` |
| `mocktail` | 不需要代码生成的 mock，配合 Riverpod 的 override 替换仓库层；不用 `mockito`（要生成代码） |
| Widget Preview | Flutter 3.47 起稳定，SDK 自带，写组件时用来对照设计稿 |
| `integration_test` | SDK 自带，以后写端到端测试时启用 |

网络层测试用实现 `HttpClientAdapter` 的假适配器或直接 override 仓库，不引入 `http_mock_adapter`（最后发布于 2023 年）。

## 验证记录

2026-10-22，在临时目录用本仓库代码做的验证，没有改动仓库里的 `pubspec.yaml`：

- **依赖解析**：上面「采用」表和开发依赖表里的全部包，`flutter pub get` 解析成功。除受 `riverpod_generator` 限制的 `build_runner` 2.16.2、`build` 4.0.11 外，各包均为当天最新版（Sentry 需写 `^10.1.0`，见上）。
- **代码生成**：`build_runner` 2.16.2 + `riverpod_generator` 4.0.9 + `json_serializable` 6.15.2 在同一次构建里生成成功，覆盖主构造函数写的模型（见「JSON」）、常驻的 `Notifier`、带命名参数的函数式 provider、带参数的 `AsyncNotifier`，以及和 provider 写在同一文件里的主构造函数类。用 `ProviderContainer.test()` 写的单元测试通过。
- **生成器的版本锁**：不加 `riverpod_generator` 时 `build_runner` 是 2.17.1、`build` 是 5.0.0；加入后分别退到 2.16.2、4.0.11，`build_config` 从 1.4.0 退到 1.3.3，其余不变。它还带进 `mockito`、`freezed_annotation` 两个传递依赖，只在开发依赖里，不进 App。再加 `freezed` 4.0.3、`go_router_builder` 4.5.2，结果相同。
- **material_ui**：用 `material_ui` 的 `MaterialApp.router` + `go_router` + `ProviderScope` + `flutter_map`（组件标记）搭了一个最小页面，`flutter analyze` 唯一的提示是 `MaterialUiCompatibilityBridge` 的 deprecated。
- **图标**：把 PR #11 的 78 个 MingCute SVG 放进 `assets/icons/`，用 `flutter_svg` 按「图标」一节的做法渲染（`currentColor` 换色、按尺寸改描边），Widget 测试通过，Web 构建通过。
- **补充的包**：加入 `share_plus`、`package_info_plus`、`device_info_plus`、`shorebird_code_push` 并去掉图标包后重新解析，结果不变（Sentry 10.1.0）。Shorebird CLI 本身没有在这里验证。
- **Web 构建**：`flutter build web --release` 成功，Wasm 预检通过；页面接上生成的 provider 后再次构建也成功。
- **riverpod_lint**：在 `analysis_options.yaml` 声明插件后，`dart analyze` 报出 `missing_provider_scope`、`avoid_public_notifier_properties`，以及故意写错的生成器代码上的 `functional_ref`、`notifier_extends`、`only_use_keep_alive_inside_keep_alive`；`flutter analyze` 都没有报。
- **OpenAPI 生成**：`swagger_parser` 1.45.0 的结果见「不从 OpenAPI 生成客户端」。
