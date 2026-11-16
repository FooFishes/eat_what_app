"""把阿里云号码认证 SDK 装进本地插件 packages/eat_number_auth/.

SDK 只能登录阿里云号码认证控制台下载 (概览 → API & SDK → 号码认证 → APP 端), 没有公开的下载地址和 Maven 仓库,
所以二进制随插件入库. 升级 SDK 时下载安卓和 iOS (静态库, 含 xcframework) 两个压缩包, 解压后运行:

    python tool/number_auth_sdk.py <安卓包解压目录> <iOS 包解压目录>

安卓: SDK/ 下的三个 aar 按 Maven 目录结构放到 android/maven/, 库模块不能直接依赖本地 aar 文件.
      坐标的 group 是自定的 local.aliyun.pnvs, 版本取自文件名. 版本变了要同步改 android/build.gradle.kts.
iOS:  SDK/xcframeworks/ 下的三个 xcframework 复制到 ios/eat_number_auth/Frameworks/,
      并把各切片 Info.plist 的 MinimumOSVersion 改成 App 的最低系统版本.
      Xcode 把这些 framework 嵌进 App, 两边不一致时 App Store Connect 以 90208 拒收.
"""

import plistlib
import re
import shutil
import sys
from pathlib import Path

GROUP = "local.aliyun.pnvs"
IOS_MIN_VERSION = "15.0"

PLUGIN = Path(__file__).resolve().parent.parent / "packages" / "eat_number_auth"
MAVEN = PLUGIN / "android" / "maven"
FRAMEWORKS = PLUGIN / "ios" / "eat_number_auth" / "Frameworks"

# 文件名前缀 → Maven 的 artifactId.
AARS = {
    "auth_number_product": "auth-number-product",
    "logger": "logger",
    "main": "main",
}

POM = """<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>{group}</groupId>
  <artifactId>{artifact}</artifactId>
  <version>{version}</version>
  <packaging>aar</packaging>
</project>
"""


def install_android(sdk: Path) -> None:
    shutil.rmtree(MAVEN, ignore_errors=True)
    for prefix, artifact in AARS.items():
        matches = sorted(sdk.glob(f"{prefix}-*.aar"))
        if len(matches) != 1:
            sys.exit(f"{sdk} 下应当正好有一个 {prefix}-*.aar, 找到 {len(matches)} 个")
        version = re.match(rf"{prefix}-(\d+(?:\.\d+)+)", matches[0].name).group(1)
        target = MAVEN.joinpath(*GROUP.split("."), artifact, version)
        target.mkdir(parents=True)
        shutil.copyfile(matches[0], target / f"{artifact}-{version}.aar")
        (target / f"{artifact}-{version}.pom").write_text(
            POM.format(group=GROUP, artifact=artifact, version=version),
            encoding="utf-8",
            newline="\n",
        )
        print(f"安卓 {GROUP}:{artifact}:{version}")


def install_ios(sdk: Path) -> None:
    sources = sorted(sdk.glob("*.xcframework"))
    if not sources:
        sys.exit(f"{sdk} 下没有 xcframework, 下载时选静态库版本")
    shutil.rmtree(FRAMEWORKS, ignore_errors=True)
    FRAMEWORKS.mkdir(parents=True)
    for source in sources:
        target = FRAMEWORKS / source.name
        shutil.copytree(source, target)
        version = ""
        for info in target.glob("*/*.framework/Info.plist"):
            raw = info.read_bytes()
            plist = plistlib.loads(raw)
            version = plist.get("CFBundleShortVersionString", "")
            plist["MinimumOSVersion"] = IOS_MIN_VERSION
            binary = raw.startswith(b"bplist")
            info.write_bytes(
                plistlib.dumps(
                    plist,
                    fmt=plistlib.FMT_BINARY if binary else plistlib.FMT_XML,
                )
            )
        print(f"iOS {source.name} {version}")


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    android, ios = (Path(arg) for arg in sys.argv[1:])
    install_android(android / "SDK")
    install_ios(ios / "SDK" / "xcframeworks")
    print("版本变了的话, 同步改 packages/eat_number_auth/android/build.gradle.kts 里的版本号")


if __name__ == "__main__":
    main()
