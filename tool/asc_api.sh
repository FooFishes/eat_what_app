# App Store Connect API 的公共部分, 由 tool/build_number.sh 和 tool/testflight_upload.sh 用 source 引入.
# 只用 curl, jq, openssl, 不依赖 CI.
#
# 需要的环境变量:
#   ASC_KEY_ID      App Store Connect API 密钥 ID
#   ASC_ISSUER_ID   Issuer ID
#   ASC_KEY_P8      .p8 私钥的内容 (或用 ASC_KEY_PATH 指向 .p8 文件)
#   ASC_APP_ID      App 的 Apple ID (数字)
#
# 引入后可用: $API, $WORK (临时目录, 退出时删除), asc_get URL, asc_delete URL.

API="${ASC_API_BASE:-https://api.appstoreconnect.apple.com}"

for name in ASC_KEY_ID ASC_ISSUER_ID ASC_APP_ID; do
  if [[ -z "${!name:-}" ]]; then
    echo "缺少环境变量 $name" >&2
    exit 2
  fi
done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

ASC_KEY_FILE="$WORK/key.p8"
if [[ -n "${ASC_KEY_P8:-}" ]]; then
  printf '%s\n' "$ASC_KEY_P8" > "$ASC_KEY_FILE"
elif [[ -n "${ASC_KEY_PATH:-}" ]]; then
  cp "$ASC_KEY_PATH" "$ASC_KEY_FILE"
else
  echo "缺少环境变量 ASC_KEY_P8 或 ASC_KEY_PATH" >&2
  exit 2
fi

asc_b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

# ES256 的 JWT, 有效 10 分钟. openssl 输出的签名是 DER 编码, JWT 要的是 r 和 s 各 32 字节直接拼接.
asc_jwt() {
  local now header payload input der hex r s
  now=$(date +%s)
  header=$(printf '{"alg":"ES256","kid":"%s","typ":"JWT"}' "$ASC_KEY_ID" | asc_b64url)
  payload=$(printf '{"iss":"%s","iat":%d,"exp":%d,"aud":"appstoreconnect-v1"}' \
    "$ASC_ISSUER_ID" "$now" $((now + 600)) | asc_b64url)
  input="$header.$payload"
  der="$WORK/sig.der"
  printf '%s' "$input" | openssl dgst -sha256 -sign "$ASC_KEY_FILE" -out "$der"
  hex=$(openssl asn1parse -inform DER -in "$der" | awk -F: '/INTEGER/ {print $NF}')
  r=$(sed -n 1p <<< "$hex")
  s=$(sed -n 2p <<< "$hex")
  # 去掉符号位补的 00, 再左补到 64 个十六进制字符.
  r=$(printf '%064s' "${r#00}" | tr ' ' 0)
  s=$(printf '%064s' "${s#00}" | tr ' ' 0)
  printf '%s.%s' "$input" "$(printf '%b' "$(printf '%s%s' "$r" "$s" | sed 's/../\\x&/g')" | asc_b64url)"
}

asc_get() {
  curl -fsS --retry 3 -H "Authorization: Bearer $(asc_jwt)" "$1"
}

asc_delete() {
  curl -fsS --retry 3 -X DELETE -H "Authorization: Bearer $(asc_jwt)" "$1"
}
