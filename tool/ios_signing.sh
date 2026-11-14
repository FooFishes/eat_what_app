#!/usr/bin/env bash
# 在构建机上准备 iOS 发布签名: 导入发布证书, 安装 App Store 描述文件, 生成只作用于 Runner 的
# 签名配置和导出选项. 只在 CI 上运行, 不改开发机的钥匙串.
#
#   tool/ios_signing.sh setup     准备签名
#   tool/ios_signing.sh cleanup   删除临时钥匙串 (构建结束后总是运行)
#
# setup 需要的环境变量:
#   IOS_DIST_CERT_P12_BASE64   发布证书 (.p12) 的 base64
#   IOS_DIST_CERT_PASSWORD     .p12 的密码
#   IOS_PROFILE_BASE64         App Store 描述文件 (.mobileprovision) 的 base64
#
# 产物 (都不入库):
#   ios/Flutter/Signing.xcconfig   Release.xcconfig 用 #include? 引入, 只有 Runner target 读它.
#                                  不能用命令行或 FLUTTER_XCODE_* 传签名设置: 那样会作用到每个 target,
#                                  插件的资源包会报 "does not support provisioning profiles".
#   build/ios/ExportOptions.plist  flutter build ipa --export-options-plist 用.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
KEYCHAIN="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/eat-signing.keychain-db"
BUNDLE_ID=you.v50to.eat

cleanup() {
  if [[ -f "$KEYCHAIN" ]]; then
    security delete-keychain "$KEYCHAIN" || true
  fi
  rm -f "$ROOT/ios/Flutter/Signing.xcconfig"
}

setup() {
  for name in IOS_DIST_CERT_P12_BASE64 IOS_DIST_CERT_PASSWORD IOS_PROFILE_BASE64; do
    if [[ -z "${!name:-}" ]]; then
      echo "缺少环境变量 $name" >&2
      exit 2
    fi
  done

  local work password profile info name uuid team app_id
  work=$(mktemp -d)
  trap 'rm -rf "$work"' RETURN

  # 临时钥匙串, 密码随机生成, 只在这台构建机上用.
  password=$(openssl rand -hex 16)
  printf '%s' "$IOS_DIST_CERT_P12_BASE64" | base64 --decode > "$work/cert.p12"
  security create-keychain -p "$password" "$KEYCHAIN"
  security set-keychain-settings -lut 21600 "$KEYCHAIN"
  security unlock-keychain -p "$password" "$KEYCHAIN"
  security import "$work/cert.p12" -k "$KEYCHAIN" -P "$IOS_DIST_CERT_PASSWORD" -f pkcs12 -A -t cert
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$password" "$KEYCHAIN" > /dev/null
  # 把临时钥匙串加到搜索列表最前面, codesign 才找得到证书.
  local existing
  existing=$(security list-keychains -d user | tr -d '"')
  # shellcheck disable=SC2086
  security list-keychains -d user -s "$KEYCHAIN" $existing

  profile="$work/profile.mobileprovision"
  printf '%s' "$IOS_PROFILE_BASE64" | base64 --decode > "$profile"
  info="$work/profile.plist"
  security cms -D -i "$profile" > "$info"
  name=$(/usr/libexec/PlistBuddy -c 'Print :Name' "$info")
  uuid=$(/usr/libexec/PlistBuddy -c 'Print :UUID' "$info")
  team=$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "$info")
  app_id=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$info")
  if [[ "$app_id" != "$team.$BUNDLE_ID" ]]; then
    echo "描述文件 $name 对应的是 $app_id, 不是 $team.$BUNDLE_ID" >&2
    exit 1
  fi

  # Xcode 26 起从 UserData 下读描述文件, 旧版本读 MobileDevice 下的, 两处都放.
  for dir in "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles" \
    "$HOME/Library/MobileDevice/Provisioning Profiles"; do
    mkdir -p "$dir"
    cp "$profile" "$dir/$uuid.mobileprovision"
  done

  cat > "$ROOT/ios/Flutter/Signing.xcconfig" <<EOF
// 由 tool/ios_signing.sh 生成, 不入库.
DEVELOPMENT_TEAM = $team
CODE_SIGN_STYLE = Manual
CODE_SIGN_IDENTITY = Apple Distribution
PROVISIONING_PROFILE_SPECIFIER = $name
EOF

  mkdir -p "$ROOT/build/ios"
  cat > "$ROOT/build/ios/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>export</string>
  <key>teamID</key><string>$team</string>
  <key>signingStyle</key><string>manual</string>
  <key>signingCertificate</key><string>Apple Distribution</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>$BUNDLE_ID</key><string>$name</string>
  </dict>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
EOF
  echo "已准备签名: 团队 $team, 描述文件 $name"
}

case "${1:-}" in
  setup) setup ;;
  cleanup) cleanup ;;
  *)
    echo "用法: $0 setup|cleanup" >&2
    exit 2
    ;;
esac
