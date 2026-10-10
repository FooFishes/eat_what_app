# eat_what_app

## 开发环境

项目使用 FVM 管理 Flutter SDK，当前固定为 Flutter **3.47.7 stable**，
附带 Dart **3.13.5**。`.fvmrc` 与 GitHub Actions 中的版本应保持一致。

原生平台的最低系统版本为 Android 7.0（API 24）、iOS 15.0、macOS 12.0。

```sh
fvm install
fvm use --skip-pub-get
fvm flutter pub get
fvm dart run build_runner build
fvm flutter analyze
fvm flutter test
```

VS Code 的 SDK 路径由 `fvm use` 自动维护。开发和构建时使用
`fvm flutter`、`fvm dart`，以确保使用项目指定的 SDK。

## 组件预览

```sh
fvm flutter widget-preview start
```

预览定义位于 `lib/previews/component_previews.dart`，包含底部导航的不同宽度、
较大字体，以及图片网格的空白、部分图片和满九张状态。
预览中的导航切换、添加图片和删除图片均可交互，使用本地示例数据，无需登录或网络请求。
生成的 `.widget_preview/` 缓存已加入 Git 忽略规则。

普通数据模型使用 Dart 3.13 主构造函数，其他手写构造函数使用简写语法；
Freezed 状态类继续由代码生成器维护。Material 组件仍从 Flutter SDK 导入。
