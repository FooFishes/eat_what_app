#!/usr/bin/env bash
# 从通用 APK 拆出单架构 APK: 删掉其他架构的 lib/<abi>/, 重新对齐, 用同一把密钥重签.
#
# 不用 flutter build apk --split-per-abi: shorebird release 不支持这个选项, 而发版走 Shorebird.
# 拆出来的包和通用包里同一架构的 libapp.so 完全一样, Shorebird 补丁照样能打上.
# versionCode 也保持原样 (--split-per-abi 会加上 1000 * 架构号), 和 AAB、iOS 共用一个构建号.
#
# 用法: tool/split_apk.sh <通用 APK> <输出目录> <名字前缀> <abi>...
#   如 tool/split_apk.sh app-release.apk out app arm64-v8a 输出 out/app-arm64-v8a.apk
#
# 签名: android/key.properties 存在时用它指向的上传密钥 (和 build.gradle.kts 一致),
# 否则用 debug 密钥 ~/.android/debug.keystore, 和 release 构建回落 debug 签名时一样.
#
# 依赖 Android SDK 的 build-tools (zipalign 要 35 及以上, 才有 -P), 由 ANDROID_HOME 或 ANDROID_SDK_ROOT 指出; 还依赖 zip, unzip.
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "用法: $0 <通用 APK> <输出目录> <名字前缀> <abi>..." >&2
  exit 2
fi

apk=$1 out=$2 prefix=$3
shift 3

root=$(cd "$(dirname "$0")/.." && pwd)
sdk=${ANDROID_HOME:-${ANDROID_SDK_ROOT:?需要 ANDROID_HOME 或 ANDROID_SDK_ROOT}}
build_tools=$(find "$sdk/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)
zipalign="$build_tools/zipalign"
apksigner="$build_tools/apksigner"

props="$root/android/key.properties"
if [[ -f "$props" ]]; then
  prop() { sed -n "s/^$1=//p" "$props" | tr -d '\r'; }
  # storeFile 相对 android/app 解析, 和 build.gradle.kts 里的 file(...) 一致.
  store=$(prop storeFile)
  [[ "$store" = /* ]] || store="$root/android/app/$store"
  sign_args=(--ks "$store" --ks-key-alias "$(prop keyAlias)"
    --ks-pass "pass:$(prop storePassword)" --key-pass "pass:$(prop keyPassword)")
else
  sign_args=(--ks "$HOME/.android/debug.keystore" --ks-key-alias androiddebugkey
    --ks-pass pass:android --key-pass pass:android)
fi

abis=$(unzip -Z1 "$apk" 'lib/*' | cut -d/ -f2 | sort -u)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$out"

for abi in "$@"; do
  if ! grep -qx "$abi" <<<"$abis"; then
    echo "通用 APK 里没有 $abi, 现有: $(echo $abis)" >&2
    exit 1
  fi
  cp "$apk" "$work/stripped.apk"
  for other in $abis; do
    [[ "$other" = "$abi" ]] || zip -qd "$work/stripped.apk" "lib/$other/*"
  done
  # -P 16: 不压缩的 .so 按 16 KB 页对齐, 和 AGP 的默认一致.
  "$zipalign" -f -P 16 4 "$work/stripped.apk" "$work/aligned.apk"
  "$apksigner" sign "${sign_args[@]}" --out "$out/$prefix-$abi.apk" "$work/aligned.apk"
  "$apksigner" verify "$out/$prefix-$abi.apk"
  rm -f "$out/$prefix-$abi.apk.idsig"
done
