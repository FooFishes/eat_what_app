// swift-tools-version: 5.9

import PackageDescription

// Frameworks/ 下的 xcframework 不入库, 由仓库根目录的 tool/baidu_ios_sdk.sh 从百度 CDN 下载并转换生成.
let package = Package(
  name: "eat_baidu_map",
  platforms: [
    .iOS("15.0")
  ],
  products: [
    .library(name: "eat-baidu-map", targets: ["eat_baidu_map"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "eat_baidu_map",
      dependencies: ["BaiduMapAPI_Base", "BaiduMapAPI_Map", "zstd"],
      linkerSettings: [
        // 百度 podspec 里列出的系统库. 静态库里有 Objective-C 分类, 需要 -ObjC.
        .linkedFramework("Accelerate"),
        .linkedFramework("AVFAudio"),
        .linkedFramework("CoreGraphics"),
        .linkedFramework("CoreLocation"),
        .linkedFramework("CoreTelephony"),
        .linkedFramework("OpenGLES"),
        .linkedFramework("QuartzCore"),
        .linkedFramework("Security"),
        .linkedFramework("SystemConfiguration"),
        .linkedLibrary("c++"),
        .linkedLibrary("sqlite3"),
        .linkedLibrary("z"),
        .unsafeFlags(["-ObjC"]),
      ]
    ),
    .binaryTarget(name: "BaiduMapAPI_Base", path: "Frameworks/BaiduMapAPI_Base.xcframework"),
    .binaryTarget(name: "BaiduMapAPI_Map", path: "Frameworks/BaiduMapAPI_Map.xcframework"),
    .binaryTarget(name: "zstd", path: "Frameworks/zstd.xcframework"),
  ]
)
