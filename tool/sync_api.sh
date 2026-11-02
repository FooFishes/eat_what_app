#!/usr/bin/env bash
# 从本地的后端仓库复制完整源码契约, 覆盖 docs/api.openapi.yml.
#
# 用法:
#
#     EATWHAT_BACKEND_DIR=<后端仓库目录> tool/sync_api.sh
#
# 完整源码契约 (docs/api/business-openapi.yaml) 由后端按当前源码离线生成, 包含尚未部署的接口.
# 客户端按后端最新源码开发, 不使用只含已部署接口的 business-openapi-deployed.yaml.
#
# 复制前先在后端仓库切到要对齐的分支并拉取最新提交.
# 源文件不是 OpenAPI 3.1 YAML 时不覆盖原文件. 同步后用 git diff 检查改动, 再一并提交.

set -euo pipefail

: "${EATWHAT_BACKEND_DIR:?需要设置环境变量 EATWHAT_BACKEND_DIR}"

root="$(cd "$(dirname "$0")/.." && pwd)"
source="$EATWHAT_BACKEND_DIR/docs/api/business-openapi.yaml"
target="$root/docs/api.openapi.yml"

if [[ ! -f "$source" ]]; then
  echo "找不到 $source" >&2
  exit 1
fi

if ! head -n 1 "$source" | grep -q '^openapi: 3\.1\.'; then
  echo "源文件不是 OpenAPI 3.1 YAML，未覆盖原文件。开头是：" >&2
  head -c 300 "$source" >&2
  echo >&2
  exit 1
fi

cp "$source" "$target"
branch="$(git -C "$EATWHAT_BACKEND_DIR" branch --show-current 2>/dev/null || true)"
commit="$(git -C "$EATWHAT_BACKEND_DIR" rev-parse --short HEAD 2>/dev/null || true)"
version="$(grep -m 1 '^  version:' "$target" | sed 's/^  version: *//')"
echo "已更新 docs/api.openapi.yml（info.version: $version，后端 $branch@$commit）"
