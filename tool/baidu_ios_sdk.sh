#!/usr/bin/env bash
# 下载百度地图 iOS SDK, 转成 Swift Package 能用的 xcframework. 只能在 macOS 上运行.
#
# 百度没有 Swift Package, CocoaPods 用的压缩包里是 fat 静态 .framework (真机 arm64 + 模拟器 x86_64),
# 单个文件超过 GitHub 的 100 MB 上限, 不能入库. 这里按固定地址下载, 校验 SHA-256,
# 用 lipo 拆开两种切片, 补上 Info.plist, 再用 xcodebuild 合成 xcframework.
#
# 产物 (都不入库):
#   packages/eat_baidu_map/ios/eat_baidu_map/Frameworks/*.xcframework   插件的 Package.swift 引用
#   packages/eat_baidu_map/ios/eat_baidu_map/Frameworks/mapapi.bundle   SDK 从 main bundle 读取, 构建时复制进 Runner
#
# 升级 SDK 时改 VERSION 和 SHA256, 并同步检查 Android 的 BaiduMapSDK_Map 版本.
set -euo pipefail

VERSION=7.2.0
SHA256=a81bec93feedf4e209b73bda44f23887f686e0c3bfebe897921fbd9dd1fcf4ed
URL="https://lbsyun-baidu.cdn.bcebos.com/iossdk/map/$VERSION/BaiduMapKitV$VERSION.zip"

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/packages/eat_baidu_map/ios/eat_baidu_map/Frameworks"
STAMP="$OUT/.sha256"

if [[ -f "$STAMP" && "$(cat "$STAMP")" == "$SHA256" ]]; then
  echo "百度地图 iOS SDK $VERSION 已就绪"
  exit 0
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "下载百度地图 iOS SDK $VERSION"
curl -fsSL "$URL" -o "$WORK/kit.zip"
echo "$SHA256  $WORK/kit.zip" | shasum -a 256 -c -
unzip -q "$WORK/kit.zip" -d "$WORK" -x '__MACOSX/*'
KIT="$WORK/BaiduMapKit"

rm -rf "$OUT"
mkdir -p "$OUT"

# 静态 framework 没有 Info.plist, xcodebuild -create-xcframework 需要它.
info_plist() {
  cat > "$1/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>$2</string>
  <key>CFBundleIdentifier</key><string>com.baidu.$2</string>
  <key>CFBundleName</key><string>$2</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>MinimumOSVersion</key><string>12.0</string>
</dict>
</plist>
PLIST
}

framework() {
  local name=$1
  local src="$KIT/$name.framework"
  for slice in device:arm64 simulator:x86_64; do
    local dir="$WORK/${slice%%:*}"
    mkdir -p "$dir"
    cp -R "$src" "$dir/"
    rm -rf "$dir/$name.framework"/*.bundle "$dir/$name.framework/.DS_Store"
    lipo "$src/$name" -thin "${slice##*:}" -output "$dir/$name.framework/$name"
    info_plist "$dir/$name.framework" "$name"
  done
  xcodebuild -create-xcframework \
    -framework "$WORK/device/$name.framework" \
    -framework "$WORK/simulator/$name.framework" \
    -output "$OUT/$name.xcframework"
}

framework BaiduMapAPI_Base
framework BaiduMapAPI_Map
framework BaiduMapAPI_Search

mkdir -p "$WORK/zstd/device" "$WORK/zstd/simulator"
lipo "$KIT/thirdlibs/libzstd.a" -thin arm64 -output "$WORK/zstd/device/libzstd.a"
lipo "$KIT/thirdlibs/libzstd.a" -thin x86_64 -output "$WORK/zstd/simulator/libzstd.a"
xcodebuild -create-xcframework \
  -library "$WORK/zstd/device/libzstd.a" \
  -library "$WORK/zstd/simulator/libzstd.a" \
  -output "$OUT/zstd.xcframework"

cp -R "$KIT/BaiduMapAPI_Map.framework/mapapi.bundle" "$OUT/mapapi.bundle"
echo "$SHA256" > "$STAMP"
echo "已生成 $OUT"
