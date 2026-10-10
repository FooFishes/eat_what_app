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
```

VS Code 的 SDK 路径由 `fvm use` 自动维护。开发和构建时使用
`fvm flutter`、`fvm dart`，以确保使用项目指定的 SDK。
