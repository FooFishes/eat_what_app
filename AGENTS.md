# AGENTS.md

沙软今天吃什么（EatWhat）：校园觅食 App 的 Flutter 客户端，目标平台 Android、iOS、Web。应用 ID `you.v50to.eat`，Dart 包名 `eat`。

项目处于重写起点：`main` 上只有一个能编译的空壳，旧实现归档在 `legacy` 分支。

## 先读文档

产品行为、架构、选型以 `docs/` 为准，写代码前先读相关章节；代码与文档冲突时先问，不要自行改产品规则。

| 文件 | 内容 | 状态 |
| --- | --- | --- |
| `docs/EatWhat_产品文档.md` | 产品的最终形态：定位、用户与场景、核心概念、页面流程、权限、推荐、内容与消息规则 | 初稿 |
| `docs/EatWhat_现状差距.md` | 现有接口、画板离产品文档还差什么，补上之前客户端怎么过渡 | 初稿 |
| `docs/EatWhat_技术架构.md` | 分层、目录、启动、状态管理、路由、深链、网络、权限拦截、存储、离线缓存、令牌落地、屏幕适配、取色、地图、推送、多平台、测试 | 初稿 |
| `docs/EatWhat_依赖选型.md` | 装哪个包、哪条版本线、为什么 | 初稿 |
| `docs/EatWhat_开发计划.md` | 七个阶段，每个阶段要做的事和做完是什么样 | 已有 |
| `docs/api.openapi.yml` | 业务后端接口（OpenAPI 3.1） | 已有 |
| `docs/EatWhat_设计与实现.md` | 设计稿和 App 的关系：设计稿是方向不是规格，正本在 App 里，哪些要守、哪些 App 自己定 | 初稿 |
| `docs/guideline/COMMENT-STYLE.md` | 代码注释风格：What 与 Why 各写在哪、篇幅、语体、格式、不要写的东西 | 已有 |
| `prototype/design-system/README.md` | 舞台设计规范：页面结构、颜色、字体、间距、动效、文案、无障碍 | 快照（2026-10-22），不再更新 |
| `prototype/screens/*.dc.html` | 「G 定稿」各页面画板 | 快照（2026-10-22），不再更新 |

写代码时：

- 代码按技术架构文档组织，按开发计划的阶段推进。依赖在第一个用到它的阶段加入，不批量加。文档没覆盖的架构决定（新的全局状态、新的基础设施、跨层的约定）先提方案，写进技术架构文档、确认后再动代码。
- 行为以产品文档为准，接口以 `docs/api.openapi.yml` 为准；接口还没跟上产品文档的地方，按现状差距文档过渡。都没覆盖的行为，先问。
- 视觉以设计原则为准（「界面落地」一节），`prototype/` 是 2026-10-22 的设计快照，供参考，不是验收标准；具体数值和排布在 App 里按实际效果定，不回写设计稿。移动端该有的 UI/UX（手势、返回、安全区、键盘、生命周期、弱网、各种状态）是实现的职责，按平台惯例做，不等画板。见 `docs/EatWhat_设计与实现.md`。

## 目录

```text
lib/
  main.dart          入口，只调用 bootstrap()
  bootstrap.dart     启动顺序：读配置、本地 token 和同意记录，然后 runApp
  app.dart           EatApp（MaterialApp.router 根组件）
test/                Widget 测试与单元测试，文件名以 _test.dart 结尾
config/              环境配置，只有 example.json 入库
assets/              进 App 的资源：fonts/（子集化的字体和许可证）、emoji/（登录页用的动画表情，改编自 Twemoji，CC BY 4.0，每个有一张动图和一张首帧静态图，署名和许可证在 LICENSE-Twemoji.txt）、icons/（由 tool/icons.dart 从 prototype 复制并生成加粗变体）
tool/                只在开发机上跑的脚本：subset_fonts.py（字体子集化）、icons.dart（图标）、sync_api.sh（从 Apifox 同步接口定义）、baidu_ios_sdk.sh（下载百度地图 iOS SDK 并转成 xcframework，只能在 macOS 上跑，CI 的 iOS 构建会调用）
packages/
  eat_baidu_map/     本地插件：百度地图原生桥（Kotlin、Swift），和 App 同在一个 pub workspace，见技术架构 14.4
android/ ios/ web/   平台工程（flutter create 生成，按需修改）
docs/                文档与接口定义
prototype/
  design-system/     设计规范、tokens.json、各组件说明与预览
  screens/           定稿画板（.dc.html）与 canvas.json
  assets/            画板引用的菜品插画、实拍示例图与图标
.github/workflows/   CI
```

`lib/` 按技术架构文档分层，目录在开发计划阶段一建好：

- `core/` 和业务无关的基础设施（环境配置、网络、存储、失败与提示文案、坐标、格式化、平台能力、埋点）
- `design/` 令牌、主题、舞台色与取色算法、图标和设计规范里的组件，不认识业务数据
- `domain/` 领域模型和产品规则（权限表、饭点、校验等），纯 Dart，不做 IO
- `data/` 按后端资源分组的接口类和 repository，负责缓存和转成领域模型
- `state/` 跨页面共享的状态（登录态、账号状态、同意记录、远程配置、位置、未读数等）
- `features/` 按页面分组，放页面、页面私有组件和页面的 provider
- `router/` 路由表、路径常量、守卫、深链处理、主页面外壳

依赖只能往下层走，具体哪层能依赖哪层见技术架构第 2 节的表；功能之间不互相导入，跳到别的页面用 `router/paths.dart` 的路径常量。`test/architecture_test.dart` 检查这条规则。

## 环境与命令

Flutter 由 FVM 管理，版本只写在 `.fvmrc`（当前 3.47.7 stable，附带 Dart 3.13.5）。CI 从 `.fvmrc` 读取版本，升级 Flutter 只改这一个文件。一律用 `fvm flutter` / `fvm dart`，不要用全局的 `flutter`。

```bash
fvm install                              # 安装 .fvmrc 指定的 SDK
fvm flutter pub get
fvm dart run build_runner build          # 改了 @riverpod、@JsonSerializable 后重新生成；开发时可用 watch
# 改了 packages/eat_baidu_map/pigeons/messages.dart 后, 在该目录重新生成并格式化三端接口
fvm dart run pigeon --input pigeons/messages.dart && fvm dart format lib/src/messages.g.dart
fvm dart format .
fvm flutter analyze
fvm dart analyze --fatal-infos           # riverpod_lint 等分析器插件的结果只在这里报告
fvm flutter test
fvm flutter build web --release
fvm flutter run -d chrome                # 要调接口时加 --dart-define-from-file=config/dev.json；端口固定 5173，见 web_dev_config.yaml
```

改完代码至少跑上面从 `build_runner` 到 `flutter test` 这几步。CI 用 `build_runner build --only-check` 检查生成文件是否最新，Pigeon 的生成文件也重新生成一遍比对，用 `--set-exit-if-changed` 检查格式，任何一步不过都会让构建失败；两种 `analyze` 都要求零问题。

环境配置（接口地址等）编译期传入：复制 `config/example.json` 为 `config/dev.json` 再填值，`config/` 下除样例外的 JSON 不入库。不传时也能启动，只是调不了接口。

本地验证默认用 Web，Android 也可以在本地构建和测试。不要在本地构建 iOS（`flutter build ios`、`ipa` 等），也不要在模拟器或真机上实际运行 iOS，除非用户明确允许；iOS 的构建交给 CI。

## 平台

**Android**

- `applicationId` 与 `namespace` 都是 `you.v50to.eat`，入口 `android/app/src/main/kotlin/you/v50to/eat/MainActivity.kt`。
- Gradle 用 Kotlin DSL：AGP 9.1.0、Gradle 9.3.1、Kotlin 2.4.0，Java / JVM target 17。`targetSdk` 跟随 Flutter 默认值；`minSdk` 取 Flutter 默认值和 26 中较大的一个（`sentry_flutter` 要求 26）。
- release 用 `android/key.properties` 指向的上传密钥签名，文件不存在时回落 debug 签名。密钥和 `key.properties` 不入库，CI 从 Secrets 还原（见下文 CI）。

**iOS**

- Bundle ID `you.v50to.eat`（测试 target 为 `you.v50to.eat.RunnerTests`），最低 iOS 15.0。
- CI 只做未签名构建；签名、描述文件、TestFlight 上传另行配置，证书不入库。

**Web**

- 入口 `web/index.html`，PWA 信息在 `web/manifest.json`。

应用显示名「沙软今天吃什么」写在 `android/app/src/main/AndroidManifest.xml`（`android:label`）、`ios/Runner/Info.plist`（`CFBundleDisplayName`）、`web/manifest.json`（`name`、`short_name`）、`web/index.html`（`<title>`、`apple-mobile-web-app-title`）四处，改名时一起改。

## 接口

- 依据是 `docs/api.openapi.yml`（`info.version` 标明版本）。它对应后端当前源码的完整契约，包含尚未部署的接口，客户端不手改；发现与实际行为不一致时记下来反馈给后端，再同步新版文件。同步用 `APIFOX_TOKEN=<API 访问令牌> tool/sync_api.sh`，从 Apifox 业务模块导出 OpenAPI 3.1 YAML 覆盖该文件；令牌只放环境变量，不入库。同步后看 `git diff`，字段改名或结构变化要连同受影响的 DTO 一起改。
- 客户端按后端最新源码开发，不为已部署的旧版本写兼容分支。字段、校验、业务码有疑问时直接读后端源码和 `docs/api/frontend-contract.md`。
- 主要分组：Auth、User、Food、Restaurant、Notification、Upload、Location、AccountConsent 等；`Activity`（年夜饭、地域美食）产品上不做，客户端不调用；`Admin`、`FoodTagAdmin`、`CatalogImport`、`*Conflict` 等是管理与运维接口，客户端一般用不到。
- 鉴权：请求头 `satoken: Bearer <tokenValue>`，头名以登录接口返回的 `tokenName` 为准，不要写死。
- HTTP 200 也可能带非零业务 `code`，每个响应都要检查业务 `code`；角色、认证状态、同意状态等由服务端判断，客户端只做展示层面的拦截。
- 数据跨境同意由用户在一个最简的对话框里点同意，客户端不代用户同意；不做单独的同意页面（`G-RegisterConfirm`、`G-DataNotice`、`G-Reconsent` 只作文案参考），见技术架构 9.5。
- `servers` 里第一项 `/api` 是业务入口的反代前缀；接口地址做成按环境配置，不要把 IP、端口写进代码。

## 界面落地

下面是产品的风格原则，写界面前读这里就够了；想知道为什么这样，看 `prototype/design-system/README.md`，构思页面时看相关画板。这些原则要守住，其余的具体数值和排布由 App 按实际效果定。

- **令牌**：颜色、间距、圆角、阴影、动效都用 `lib/design/` 里的令牌（`ThemeExtension` 和常量），正本在 Dart 里，初值来自设计快照。业务代码不写裸色值和魔法数字。
- **页面结构**：有主角菜的页面用「舞台 + 抽屉」（`Stage` + `Sheet`，抽屉上压舞台 32px）；消息、选店、搜索、评论、设置等列表页用白底；临时的选择和填写用底部面板（`Panel`），只回答一个问题的确认、拦截和同意用居中的对话框（`EatDialog`），背后都是一层 `scrim`，不跳新页面。附近页以地图当舞台。页面左右边距 `space-20`。
- **舞台色**：只有 9 个 `stage-*`，做成枚举，每个值自带文字色和次按钮色，深浅写死。从照片取色只看圆形取景内的像素，按饱和度加权后吸附到最近的 `stage-*`，不可靠时用分类默认色。
- **导航**：`NavBar` 只出现在发现、附近、我的三个主页面，悬浮在内容上方；滚动列表底部留出约 100px。
- **颜色**：没有品牌主色，主操作用 `ink` 实心；`warn` 只用于提示用户该做什么，且必须配文字。
- **字体**：中文 Noto Sans SC，Inter 只用于数字（价格、距离、计数）。字号用 `EatTextStyles` 的预设，偏差不大的地方先用预设；字重只用 400、600、700、800，800 只给舞台上的主角。选中态靠字重，不靠颜色。
- **形状**：能点的都是胶囊；盘子、地图标记和头像永远是正圆（`DishPlate` 带 8px 白色盘沿），列表缩略图是方圆角（`radius-thumb`），推荐流方块是圆角方图。阴影只用在规范列出的几处，不给卡片加投影。
- **图标**：MingCute Line 一套，24 网格 2px 描边，按用途命名，SVG 在 `assets/icons/`，颜色用 `currentColor` 跟着文字。只有赞过 `heart-on`、收藏过 `bookmark-on` 用实心，不混用其他图标库，不用 emoji。
- **文案**：短句。引导（标题、按钮、空状态）可以用同学之间说话的语气；提示和报错（轻提示、校验、拦截、确认、系统消息、失败）用规范短句，不用「一下」「吧」「开小差」这类口语，不显示错误码；距离「320 m」、价格「¥18」；专题、标签用「」引用；不用 emoji 和感叹号。唯一的例外是登录页的两个动画表情，介绍文案末尾的思考表情和「先逛逛」卷角后面的眼睛：用 `assets/emoji/` 里的图片（`lib/design/icons/emoji.dart`），不用系统 emoji 字体，其他位置不加。还没有接口的功能照样画出来，旁边放「待接入」虚线标签（`Chip`）。
- **动效与无障碍**：转盘吸附 680ms 回弹曲线、舞台换色 500ms、按钮按下下沉 1px；系统开启减少动态效果时停掉自动动画。点击区域不小于 44px，文字对比不低于 4.5:1，可滑动的操作都要有按钮替代。
- `prototype/assets/` 里的插画、示例图和图标只用于对照设计；要进 App 的资源复制到项目自己的 `assets/` 并在 `pubspec.yaml` 声明。插画只用于空状态、引导和演示，不能冒充用户上传的照片。
- `.dc.html` 依赖 Claude Design 运行时，本地打开只能看静态结构。读法见 `prototype/README.md`。

## 代码约定

- 遵守 `analysis_options.yaml`（`flutter_lints` 和 `riverpod_lint` 插件），两种 `analyze` 都零问题。
- Provider 用 `riverpod_generator` 的 `@riverpod` 写，接口 DTO 用 `json_serializable`，路由表手写。生成的 `*.g.dart` 入库、不手改，源文件改了就重新生成一起提交。
- 沿用 Dart 3.13 的写法：组件和其他手写构造函数用简写 `const new({super.key});`；普通数据模型用主构造函数，如 `class TokenResponse({required final String tokenValue}) { ... }`。
- 包内导入用 `package:eat/...`，不用相对路径跨目录导入。
- Material 用独立的 `material_ui` 包（`package:material_ui/material_ui.dart`），不直接导入 `package:flutter/material.dart` 和 `flutter_localizations`；只需要基础组件时导入 `package:flutter/widgets.dart`。
- 注释按 `docs/guideline/COMMENT-STYLE.md` 写：只在读者会停下来看的地方写，写成文档注释、单独占行，不写行尾注释。
- 新增依赖前先查 `docs/EatWhat_依赖选型.md`，表里没有的先提出来。一类问题只用一个方案，不引入同类库。
- 密钥、token、签名文件、`.env` 一律不入库，用本地未跟踪文件或 CI Secrets。`legacy` 分支的 `pubspec.yaml` 曾提交过 Sentry auth token，不要重蹈覆辙。
- 界面文字用中文，按设计规范的用词；文档用中文撰写。
- 新功能配测试：纯逻辑写单元测试，组件和页面写 Widget 测试。

## 分支与提交

- `main` 是主分支，新代码都在这里。`legacy` 是旧实现的只读归档，不往里提交、不合并回 `main`；可以参考它的实现细节（如统一认证流程、签名配置），但不要整块搬代码。
- 直接在仓库目录里改，不用 git worktree。
- 提交信息遵循 Conventional Commits，标题用中文，如 `feat(discover): 转盘换菜`、`build(deps): 升级 go_router 至 18.0.2`、`ci: 构建 Web 产物`。

## CI

`.github/workflows/build.yml` 在 `main` 的 push 与 PR、`v*` tag 和手动触发时运行：

1. `check`（ubuntu）：读取 `.fvmrc` 版本，生成文件检查（`build_runner build --only-check` 和 Pigeon 重新生成比对）、`dart format` 检查、`flutter analyze`、`dart analyze --fatal-infos`、`flutter test`。
2. 通过后并行构建，产物保留 14 天：
   - `android`（ubuntu，JDK 17）：release APK 与 AAB。配了上传密钥用它签名，否则 debug 签名。
   - `ios`（macOS）：先跑 `tool/baidu_ios_sdk.sh` 准备百度地图 SDK（按脚本内容缓存），再出未签名的 `Runner.app`，打包为 zip。
   - `web`（ubuntu）：`build/web`，带 `--no-web-resources-cdn`，不含 source map。
3. `v*` tag 的构建另外：Android 混淆 Dart 代码，Web 生成 source map，两者都上传到 Sentry；配了 `SHOREBIRD_TOKEN` 且仓库里有 `shorebird.yaml` 时，Android 改用 `shorebird release`。

`.github/workflows/patch.yml` 手动触发，给已发布的 Android 版本推 Shorebird 补丁，默认只试跑不上传。

构建号取 `github.run_number`，版本名取 `pubspec.yaml` 的 `version`。用到的凭据和配置都在 GitHub 上，缺了就跳过对应步骤：

| 名字 | 类型 | 用途 |
| --- | --- | --- |
| `APP_CONFIG` | Secret | `config/*.json` 的内容，构建时写成 `config/ci.json` 传入；缺了产物调不了接口 |
| `ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD` | Secret | 安卓上传密钥（keystore 文件经 base64 编码） |
| `SENTRY_AUTH_TOKEN` | Secret | 上传符号表和 source map |
| `SENTRY_URL`、`SENTRY_ORG`、`SENTRY_PROJECT` | Variable | Sentry 服务地址、组织和项目 |
| `SHOREBIRD_TOKEN` | Secret | `shorebird release` 和 `shorebird patch` |

还没有部署 Web 和上传商店的步骤。
