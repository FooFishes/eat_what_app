#!/usr/bin/env bash
# 算出下一次上传用的构建号, 打印到标准输出. 不依赖 CI, 本地和任何 CI 上都能运行.
#
# 构建号以 App Store Connect 为准: 取这个 App 用过的最大构建号再加 1, 两处一起查:
# - 构建列表 (/v1/builds): 处理完成的构建, 不分版本.
# - 上传记录 (/v1/apps/{id}/buildUploads): 上传一开始就有记录, 包括还在处理和处理失败的.
#   刚传完的构建要过几分钟才进构建列表, 只查构建列表会撞号.
# 取全部版本里的最大值, 号码全局只增不减, Android 的 versionCode 也直接用它.
#
# 同一时间只能有一个构建在 "查号 -> 构建 -> 上传" 之间, 否则两次构建会拿到同一个号.
# 这由调用方保证 (CI 的并发锁), 锁要一直持有到上传命令返回.
#
# 需要的环境变量:
#   ASC_KEY_ID      App Store Connect API 密钥 ID
#   ASC_ISSUER_ID   Issuer ID
#   ASC_KEY_P8      .p8 私钥的内容 (或用 ASC_KEY_PATH 指向 .p8 文件)
#   ASC_APP_ID      App 的 Apple ID (数字)
# 可选:
#   BUILD_NUMBER_MIN  构建号下限. 结果至少是这个值, 用来越过以前用 CI 运行号发出去的安卓包.
#
# 依赖 curl, jq, openssl. 查询失败时退出码非 0, 不猜号.
set -euo pipefail

# shellcheck source=tool/asc_api.sh
source "$(dirname "$0")/asc_api.sh"

# 按 links.next 翻完所有页, 用 jq 表达式取出每条记录的构建号, 每行一个.
collect() {
  local url=$1 filter=$2 page
  while [[ -n "$url" && "$url" != null ]]; do
    page="$WORK/page.json"
    asc_get "$url" > "$page"
    jq -r "$filter" "$page"
    url=$(jq -r '.links.next // empty' "$page")
  done
}

{
  collect "$API/v1/builds?filter%5Bapp%5D=$ASC_APP_ID&fields%5Bbuilds%5D=version&limit=200" \
    '.data[].attributes.version'
  collect "$API/v1/apps/$ASC_APP_ID/buildUploads?fields%5BbuildUploads%5D=cfBundleVersion&limit=200" \
    '.data[].attributes.cfBundleVersion'
} > "$WORK/numbers"

# 构建号可以是 1 到 3 段数字 (如 152.1), 比较第一段就够: 第一段最大值加 1 一定比所有已用的号大.
max=$(cut -d. -f1 "$WORK/numbers" | grep -E '^[0-9]+$' | sort -n | tail -1 || true)
next=$(( ${max:-0} + 1 ))
min=${BUILD_NUMBER_MIN:-0}
if (( next < min )); then
  next=$min
fi
echo "$next"
