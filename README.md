# 沙软今天吃什么

EatWhat 的 Flutter 客户端，面向 Android、iOS 与 Web，应用 ID `you.v50to.eat`。

项目正在从头重写，旧实现归档在 [`legacy`](../../tree/legacy) 分支。

## 开发

使用 [FVM](https://fvm.app) 管理 Flutter，版本见 `.fvmrc`。

```sh
fvm install
fvm flutter pub get
fvm flutter run
```

要调接口时，复制 `config/example.json` 为 `config/dev.json` 填好地址，运行时加 `--dart-define-from-file=config/dev.json`。

提交前：

```sh
fvm dart run build_runner build
fvm dart format .
fvm flutter analyze
fvm dart analyze --fatal-infos
fvm flutter test
```

## 目录

- `lib/`：应用代码
- `docs/`：产品文档、现状差距、技术架构、依赖选型、开发计划，以及接口文档 `api.openapi.yml`
- `prototype/`：界面设计（舞台设计规范与定稿画板）
- `.github/workflows/build.yml`：CI，检查通过后并行构建 Android、iOS（未签名）与 Web

协作约定见 [AGENTS.md](AGENTS.md)。
