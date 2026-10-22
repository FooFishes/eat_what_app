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
| `docs/guideline/COMMENT-STYLE.md` | 代码注释风格：What 与 Why 各写在哪、篇幅、语体、格式、不要写的东西 | 已有 |
| `prototype/design-system/README.md` | 舞台设计规范：页面结构、颜色、字体、间距、动效、文案、无障碍 | 已有 |
| `prototype/screens/*.dc.html` | 「G 定稿」各页面画板 | 已有 |

写代码时：

- 代码按技术架构文档组织，按开发计划的阶段推进。依赖在第一个用到它的阶段加入，不批量加。文档没覆盖的架构决定（新的全局状态、新的基础设施、跨层的约定）先提方案，写进技术架构文档、确认后再动代码。
- 行为以产品文档为准，视觉以 `prototype/` 为准，接口以 `docs/api.openapi.yml` 为准；接口或画板还没跟上产品文档的地方，按现状差距文档过渡。都没覆盖的行为，先问。

## 目录

```text
lib/
  main.dart          入口，只调用 bootstrap()
  bootstrap.dart     启动顺序：读配置、本地 token 和同意记录，然后 runApp
  app.dart           EatApp（MaterialApp.router 根组件）
test/                Widget 测试与单元测试，文件名以 _test.dart 结尾
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
- `router/` 路由表、守卫、深链处理、主页面外壳

依赖只能往下层走，具体哪层能依赖哪层见技术架构第 2 节的表；功能之间不互相导入，跳到别的页面用路由路径。`test/architecture_test.dart` 检查这条规则。

## 环境与命令

Flutter 由 FVM 管理，版本只写在 `.fvmrc`（当前 3.47.7 stable，附带 Dart 3.13.5）。CI 从 `.fvmrc` 读取版本，升级 Flutter 只改这一个文件。一律用 `fvm flutter` / `fvm dart`，不要用全局的 `flutter`。

```bash
fvm install                              # 安装 .fvmrc 指定的 SDK
fvm flutter pub get
fvm dart format .
fvm flutter analyze
fvm flutter test
fvm flutter build web --release          # 本地唯一允许的构建
fvm flutter run -d chrome
```

改完代码至少跑 `fvm dart format .`、`fvm flutter analyze`、`fvm flutter test`。CI 用 `--set-exit-if-changed` 检查格式，没格式化的代码会让构建失败；`analyze` 要求零问题。

本地验证只允许构建 Web。不要在本地构建 Android、iOS（`flutter build apk`、`appbundle`、`ios`、`ipa` 等），也不要在模拟器或真机上实际运行 iOS，除非用户明确允许；Android、iOS 的构建交给 CI。

## 平台

**Android**

- `applicationId` 与 `namespace` 都是 `you.v50to.eat`，入口 `android/app/src/main/kotlin/you/v50to/eat/MainActivity.kt`。
- Gradle 用 Kotlin DSL：AGP 9.1.0、Gradle 9.3.1、Kotlin 2.4.0，Java / JVM target 17。`minSdk`、`targetSdk` 跟随 Flutter 默认值。
- release 目前用 debug 签名。接入上传密钥时，密钥和 `android/key.properties` 不入库，CI 通过 Secrets 注入；`legacy` 分支的 `android/app/build.gradle.kts` 有读取 `key.properties`、缺失时回落 debug 签名的写法可参考。

**iOS**

- Bundle ID `you.v50to.eat`（测试 target 为 `you.v50to.eat.RunnerTests`），最低 iOS 15.0。
- CI 只做未签名构建；签名、描述文件、TestFlight 上传另行配置，证书不入库。

**Web**

- 入口 `web/index.html`，PWA 信息在 `web/manifest.json`。

应用显示名「沙软今天吃什么」写在 `android/app/src/main/AndroidManifest.xml`（`android:label`）、`ios/Runner/Info.plist`（`CFBundleDisplayName`）、`web/manifest.json`（`name`、`short_name`）、`web/index.html`（`<title>`、`apple-mobile-web-app-title`）四处，改名时一起改。

## 接口

- 唯一依据是 `docs/api.openapi.yml`（`info.version` 标明版本）。它由后端根据已发布的服务生成，客户端不手改；发现与实际行为不一致时记下来反馈给后端，再同步新版文件。
- 主要分组：Auth、User、Food、Restaurant、Notification、Upload、Location、AccountConsent 等；`Activity`（年夜饭、地域美食）产品上不做，客户端不调用；`Admin`、`FoodTagAdmin`、`CatalogImport`、`*Conflict` 等是管理与运维接口，客户端一般用不到。
- 鉴权：请求头 `satoken: Bearer <tokenValue>`，头名以登录接口返回的 `tokenName` 为准，不要写死。
- HTTP 200 也可能带非零业务 `code`，每个响应都要检查业务 `code`；角色、认证状态、同意状态等由服务端判断，客户端只做展示层面的拦截。
- 数据存放同意按产品文档：注册时单独勾选，说明有变化时进「重新同意」页（`G-Reconsent`）。接口现在还是校内站、境外站两套逻辑，过渡做法见现状差距 2.1 和技术架构 9.4。
- `servers` 里第一项 `/api` 是业务入口的反代前缀；接口地址做成按环境配置，不要把 IP、端口写进代码。

## 界面落地

写界面前先读 `prototype/design-system/README.md`，再看对应组件的 `components/<Name>/README.md` 和相关画板。下面是最容易出错的几条，细节以规范为准。

- **令牌**：颜色、间距、圆角、阴影、动效都来自 `prototype/design-system/tokens.json`，在 Flutter 里做成 `ThemeExtension`。业务代码不写裸色值和魔法数字。
- **页面结构**：有主角菜的页面用「舞台 + 抽屉」（`Stage` + `Sheet`，抽屉上压舞台 32px）；消息、选店、搜索、评论、设置等列表页用白底；临时的选择和确认用底部面板（`Panel`，背后一层 `scrim`），不跳新页面。附近页以地图当舞台。页面左右边距 `space-20`。
- **舞台色**：只有 9 个 `stage-*`，做成枚举，每个值自带文字色和次按钮色，深浅写死。从照片取色只看圆形取景内的像素，按饱和度加权后吸附到最近的 `stage-*`，不可靠时用分类默认色。
- **导航**：`NavBar` 只出现在发现、附近、我的三个主页面，悬浮在内容上方；滚动列表底部留出约 100px。
- **颜色**：没有品牌主色，主操作用 `ink` 实心；`warn` 只用于提示用户该做什么，且必须配文字。
- **字体**：中文 Noto Sans SC，主角文字用 900；Bricolage Grotesque 只用于数字（价格、距离、计数）。选中态靠字重，不靠颜色。
- **形状**：能点的都是胶囊；盘子、地图标记和头像永远是正圆（`DishPlate` 带 8px 白色盘沿），列表缩略图是方圆角（`radius-thumb`），推荐流方块是圆角方图。阴影只用在规范列出的几处，不给卡片加投影。
- **图标**：MingCute Line 一套，24 网格 2px 描边，按用途命名，SVG 在 `prototype/assets/icons/`，颜色用 `currentColor` 跟着文字。只有赞过 `heart-on`、收藏过 `bookmark-on` 用实心，不混用其他图标库，不用 emoji。
- **文案**：同学之间说话的语气，短句；距离「320 m」、价格「¥18」；专题、标签用「」引用；不用 emoji 和感叹号。还没有接口的功能照样画出来，旁边放「待接入」虚线标签（`Chip`）。
- **动效与无障碍**：转盘吸附 680ms 回弹曲线、舞台换色 500ms、按钮按下下沉 1px；系统开启减少动态效果时停掉自动动画。点击区域不小于 44px，文字对比不低于 4.5:1，可滑动的操作都要有按钮替代。
- `prototype/assets/` 里的插画、示例图和图标只用于对照设计；要进 App 的资源复制到项目自己的 `assets/` 并在 `pubspec.yaml` 声明。插画只用于空状态、引导和演示，不能冒充用户上传的照片。
- `.dc.html` 依赖 Claude Design 运行时，本地打开只能看静态结构。读法见 `prototype/README.md`。

## 代码约定

- 遵守 `analysis_options.yaml`（`flutter_lints`），`fvm flutter analyze` 零问题。
- 沿用 Dart 3.13 的写法：组件和其他手写构造函数用简写 `const new({super.key});`；普通数据模型用主构造函数，如 `class TokenResponse({required final String tokenValue}) { ... }`。
- 包内导入用 `package:eat/...`，不用相对路径跨目录导入。
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

1. `check`（ubuntu）：读取 `.fvmrc` 版本，`dart format` 检查、`flutter analyze`、`flutter test`。
2. 通过后并行构建，产物保留 14 天：
   - `android`（ubuntu，JDK 17）：release APK 与 AAB，debug 签名。
   - `ios`（macOS）：未签名的 `Runner.app`，打包为 zip。
   - `web`（ubuntu）：`build/web`。

构建号取 `github.run_number`，版本名取 `pubspec.yaml` 的 `version`。目前没有部署和发布步骤；加签名、上传商店或部署 Web 时，凭据走 GitHub Secrets。
