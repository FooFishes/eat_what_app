// swift-tools-version: 5.9

import PackageDescription

// Frameworks/ 下的 xcframework 由仓库根目录的 tool/number_auth_sdk.py 从阿里云控制台下载的压缩包里安装, 随插件入库.
let package = Package(
  name: "eat_number_auth",
  platforms: [
    .iOS("15.0")
  ],
  products: [
    .library(name: "eat-number-auth", targets: ["eat_number_auth"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "eat_number_auth",
      dependencies: ["ATAuthSDK", "YTXMonitor", "YTXOperators"],
      linkerSettings: [
        // 阿里云接入文档要求的系统库和链接参数. 静态库里有 Objective-C 分类, 需要 -ObjC.
        .linkedFramework("Network"),
        .linkedLibrary("c++"),
        .unsafeFlags(["-ObjC"]),
      ]
    ),
    .binaryTarget(name: "ATAuthSDK", path: "Frameworks/ATAuthSDK.xcframework"),
    .binaryTarget(name: "YTXMonitor", path: "Frameworks/YTXMonitor.xcframework"),
    .binaryTarget(name: "YTXOperators", path: "Frameworks/YTXOperators.xcframework"),
  ]
)
