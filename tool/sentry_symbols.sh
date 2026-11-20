#!/usr/bin/env bash
# 把混淆构建的 Dart 符号表, 混淆映射和 iOS 的 dSYM 上传到 Sentry, 发版构建 (build.yml) 和补丁 (patch.yml) 共用.
#
# 符号表和 dSYM 用来还原堆栈, 混淆映射用来还原错误标题里的类名. 它们都按调试文件的 debug id 关联, 和 release 无关,
# 所以补丁的符号表也传到发版的 release 下; release 只用来在 Sentry 里建版本记录.
#
# sentry_dart_plugin 找不到文件时只打警告, 映射上传失败也不改退出码, 所以这里先检查文件,
# 跑完再看插件输出的映射上传汇总, 缺文件或有一次没传上就失败.
#
# 用法: tool/sentry_symbols.sh <release> <符号表目录> [<混淆映射> [<dSYM 目录>]]
#   安卓发版和补丁: tool/sentry_symbols.sh eat@1.2.3+62 build/symbols build/app/obfuscation.map.json
#   iOS 发版: 再给出 xcarchive 的 dSYMs 目录, 只用来检查里面有 App.framework.dSYM. 映射和它配对, 安卓则和符号表配对.
#   iOS 补丁: 只给符号表目录. 补丁改动的代码在解释器里跑, 没有自己的 dSYM, 也存不出映射.
# dSYM 由插件在默认位置 (build/ios 下, 包括 build/ios/archive) 自己找, 所以 dSYM 目录要在 build/ios 下.
#
# 环境变量 SENTRY_URL, SENTRY_ORG, SENTRY_PROJECT, SENTRY_AUTH_TOKEN 都要有; 要先 flutter pub get.
set -euo pipefail

if [[ $# -lt 2 || $# -gt 4 ]]; then
  echo "用法: $0 <release> <符号表目录> [<混淆映射> [<dSYM 目录>]]" >&2
  exit 2
fi

release=$1 symbols=$2 map=${3:-} dsyms=${4:-}
: "${SENTRY_URL:?} ${SENTRY_ORG:?} ${SENTRY_PROJECT:?} ${SENTRY_AUTH_TOKEN:?}"

if ! compgen -G "$symbols/app*.symbols" > /dev/null; then
  echo "::error::$symbols 下没有 Dart 符号表 (app*.symbols)"
  exit 1
fi
if [[ -n $map && ! -s $map ]]; then
  echo "::error::没有混淆映射 $map"
  exit 1
fi
if [[ -n $dsyms && ! -f $dsyms/App.framework.dSYM/Contents/Resources/DWARF/App ]]; then
  echo "::error::$dsyms 下没有 App.framework.dSYM"
  exit 1
fi

# ignore_missing 只管 set-commits: 浅克隆里找不到上一个版本的提交时不报错. 和符号表无关.
args=(
  --sentry-define=url="$SENTRY_URL"
  --sentry-define=org="$SENTRY_ORG"
  --sentry-define=project="$SENTRY_PROJECT"
  --sentry-define=release="$release"
  --sentry-define=upload_debug_symbols=true
  --sentry-define=upload_source_maps=false
  --sentry-define=symbols_path="$symbols"
  --sentry-define=ignore_missing=true
)
if [[ -n $map ]]; then
  args+=(--sentry-define=dart_symbol_map_path="$map")
fi

log=$(mktemp)
trap 'rm -f "$log"' EXIT

dart run sentry_dart_plugin "${args[@]}" | tee "$log"

if [[ -z $map ]]; then
  exit 0
fi

# 映射按每个配对的调试文件各传一次, 汇总写作 attempted=N, succeeded=N, failed=0.
summary=$(sed 's/\x1b\[[0-9;]*m//g' "$log" | grep -o 'attempted=[0-9]*, succeeded=[0-9]*, failed=[0-9]*' | tail -n 1 || true)
if [[ ! $summary =~ ^attempted=([1-9][0-9]*),\ succeeded=([0-9]+),\ failed=0$ ]] ||
  [[ ${BASH_REMATCH[1]} != "${BASH_REMATCH[2]}" ]]; then
  echo "::error::混淆映射没有全部传上 Sentry: ${summary:-没有找到可配对的调试文件}"
  exit 1
fi
