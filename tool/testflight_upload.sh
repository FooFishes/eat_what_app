#!/usr/bin/env bash
# 把签好名的 IPA 上传到 TestFlight. 不依赖 CI.
#
#   tool/testflight_upload.sh build/ios/ipa/eat.ipa
#
# 上传前清掉同一版本号和构建号下 "等待上传" 且没有文件的空记录: 有些环境里 Xcode 导出 App Store IPA 时
# 会在 App Store Connect 里先建一条这样的记录, 不清掉的话这个号算已占用, 上传会被拒.
# 有文件或已经进入处理的记录不碰.
#
# 上传是同步的: 命令返回时上传记录已经存在, 之后查构建号一定能看到它.
#
# 环境变量见 tool/asc_api.sh.
set -euo pipefail

IPA=${1:?用法: $0 <ipa>}
# shellcheck source=tool/asc_api.sh
source "$(dirname "$0")/asc_api.sh"

plist="$WORK/Info.plist"
unzip -p "$IPA" 'Payload/*.app/Info.plist' > "$plist"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")
build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist")
echo "上传 $version ($build)"

asc_get "$API/v1/apps/$ASC_APP_ID/buildUploads?filter%5BcfBundleShortVersionString%5D=$version&filter%5BcfBundleVersion%5D=$build&filter%5Bstate%5D=AWAITING_UPLOAD" \
  | jq -r '.data[].id' > "$WORK/pending"
while read -r id; do
  [[ -n "$id" ]] || continue
  files=$(asc_get "$API/v1/buildUploads/$id/buildUploadFiles" | jq '.data | length')
  if [[ "$files" == 0 ]]; then
    echo "删除空的上传记录 $id"
    asc_delete "$API/v1/buildUploads/$id"
  fi
done < "$WORK/pending"

# altool 从 --p8-file-path 读私钥, 文件名要求是 AuthKey_<密钥 ID>.p8.
key="$WORK/AuthKey_$ASC_KEY_ID.p8"
cp "$ASC_KEY_FILE" "$key"
xcrun altool --upload-app --type ios --file "$IPA" \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" --p8-file-path "$key"
