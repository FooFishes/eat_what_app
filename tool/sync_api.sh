#!/usr/bin/env bash
# 从 Apifox 导出业务模块的 OpenAPI 3.1 YAML，覆盖 docs/api.openapi.yml。
#
# 用法：
#
#     APIFOX_TOKEN=<API 访问令牌> tool/sync_api.sh
#
# 令牌在 Apifox「账号设置 → API 访问令牌」创建，只从环境变量读，不写进仓库。
# 走的是开放 API 的 /v1/projects/{id}/export-openapi；CLI 用的 /api/v1 那条会忽略 oasVersion
# 和 exportFormat，只给 3.0.1 JSON。环境选测试环境，servers 才会写出 https://v50to.you/api。
# 下载结果不是 3.1 YAML 时不覆盖原文件。同步后用 git diff 看改了什么，再一起提交。

set -euo pipefail

PROJECT_ID=7737416
MODULE_ID=8746030
ENVIRONMENT_ID=41960666

: "${APIFOX_TOKEN:?需要设置环境变量 APIFOX_TOKEN}"

root="$(cd "$(dirname "$0")/.." && pwd)"
target="$root/docs/api.openapi.yml"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

status="$(curl -sS -o "$tmp" -w '%{http_code}' -X POST \
  "https://api.apifox.com/v1/projects/$PROJECT_ID/export-openapi?locale=zh-CN" \
  -H 'X-Apifox-Api-Version: 2024-03-28' \
  -H "Authorization: Bearer $APIFOX_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
    \"scope\": {\"type\": \"ALL\"},
    \"moduleId\": $MODULE_ID,
    \"environmentIds\": [$ENVIRONMENT_ID],
    \"oasVersion\": \"3.1\",
    \"exportFormat\": \"YAML\",
    \"options\": {\"includeApifoxExtensionProperties\": false, \"addFoldersToTags\": false}
  }")"

if [[ "$status" != 200 ]]; then
  echo "导出失败：HTTP $status" >&2
  head -c 500 "$tmp" >&2
  echo >&2
  exit 1
fi

if ! head -n 1 "$tmp" | grep -q '^openapi: 3\.1\.'; then
  echo "导出结果不是 OpenAPI 3.1 YAML，未覆盖原文件。开头是：" >&2
  head -c 300 "$tmp" >&2
  echo >&2
  exit 1
fi

mv "$tmp" "$target"
trap - EXIT
version="$(grep -m 1 '^  version:' "$target" | sed 's/^  version: *//')"
echo "已更新 docs/api.openapi.yml（info.version: $version）"
