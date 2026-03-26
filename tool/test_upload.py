#!/usr/bin/env python3
"""
上传全流程测试脚本（零外部依赖，仅用标准库）

用法:
    python3 tool/test_upload.py
    python3 tool/test_upload.py docs/res_1.png docs/res_2.png
"""

import getpass
import json
import mimetypes
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

BASE_URL = "https://v50to.you/api/v1"
ORIGIN_SUFFIX = ".digitaloceanspaces.com"
CDN_SUFFIX = ".cdn.digitaloceanspaces.com"

# ── ANSI 颜色 ──────────────────────────────────────────────────────────────────
R = "\033[0m"
BOLD = "\033[1m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
BLUE = "\033[34m"


def hr():
    print(f"{CYAN}{'─' * 56}{R}")

def step(msg):
    print(f"\n{BOLD}{BLUE}▶ {msg}{R}")

def ok(msg):
    print(f"{GREEN}✔ {msg}{R}")

def warn(msg):
    print(f"{YELLOW}⚠ {msg}{R}")

def err(msg):
    print(f"{RED}✘ {msg}{R}")

def pjson(data):
    return json.dumps(data, indent=2, ensure_ascii=False)


# ── MIME 推断 ──────────────────────────────────────────────────────────────────
def mime_type(filename: str) -> str:
    ext = filename.rsplit(".", 1)[-1].lower()
    return {
        "jpg": "image/jpeg", "jpeg": "image/jpeg",
        "png": "image/png",  "webp": "image/webp",
        "gif": "image/gif",  "bmp": "image/bmp",
    }.get(ext, "image/jpeg")


# ── HTTP 工具 ──────────────────────────────────────────────────────────────────
def post_json(url: str, body: dict, token: str | None = None) -> dict:
    data = json.dumps(body).encode()
    req = urllib.request.Request(
        url, data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    if token:
        req.add_header("satoken", f"Bearer {token}")

    try:
        with urllib.request.urlopen(req) as resp:
            print(f"  HTTP {resp.status}")
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        print(f"  HTTP {e.code}")
        raw = e.read().decode()
        try:
            return json.loads(raw)
        except Exception:
            return {"_raw": raw}


def put_file(url: str, data: bytes, content_type: str):
    """返回 (status_code, reason, headers_dict)"""
    req = urllib.request.Request(
        url, data=data,
        headers={
            "Content-Type": content_type,
            "Content-Length": str(len(data)),
        },
        method="PUT",
    )
    try:
        with urllib.request.urlopen(req) as resp:
            headers = dict(resp.headers)
            return resp.status, resp.reason, headers
    except urllib.error.HTTPError as e:
        headers = dict(e.headers) if e.headers else {}
        return e.code, e.reason, headers


# ── 主程序 ─────────────────────────────────────────────────────────────────────
def main():
    project_dir = Path(__file__).parent.parent

    # 确定测试图片
    if len(sys.argv) > 1:
        image_files = [Path(p) for p in sys.argv[1:]]
    else:
        image_files = [project_dir / "docs" / "profile_1.png"]

    print(f"\n{BOLD}测试图片:{R}")
    for f in image_files:
        if not f.exists():
            err(f"文件不存在: {f}")
            sys.exit(1)
        size_kb = f.stat().st_size / 1024
        print(f"  • {f}  ({size_kb:.1f} KB)")

    # ── Step 0: 登录 ────────────────────────────────────────────────────────────
    hr()
    step("Step 0  登录获取 Token")

    username = input("用户名 (email): ").strip()
    password = getpass.getpass("密码: ")

    print(f"\n{BOLD}请求: POST {BASE_URL}/auth/login{R}")
    login_resp = post_json(f"{BASE_URL}/auth/login", {
        "username": "FooFish",
        "password": "123456",
        "device": "APP",
    })

    print(f"\n{BOLD}登录响应:{R}")
    print(pjson(login_resp))

    data = login_resp.get("data") or {}
    token = data.get("tokenValue")
    if not token:
        err("未能从响应中提取 token，请检查上方响应结构")
        sys.exit(1)
    ok(f"Token: {token[:20]}...")

    # ── Step 1: 预签名请求 ───────────────────────────────────────────────────────
    hr()
    step("Step 1  请求预签名 URL  POST /upload/presign/batch")

    files_payload = [
        {
            "fileName": f.name,
            "contentType": mime_type(f.name),
            "fileSize": f.stat().st_size,
        }
        for f in image_files
    ]
    presign_body = {"biz": "foods", "files": files_payload}

    print(f"\n{BOLD}请求体:{R}")
    print(pjson(presign_body))
    print()

    presign_resp = post_json(
        f"{BASE_URL}/upload/presign/batch",
        presign_body,
        token=token,
    )

    print(f"\n{BOLD}完整响应:{R}")
    print(pjson(presign_resp))

    file_list = (presign_resp.get("data") or {}).get("files") or []
    if not file_list:
        err("未能提取 files 列表")
        sys.exit(1)
    ok(f"获取到 {len(file_list)} 个预签名条目")

    # ── Step 2: URL 结构分析 ─────────────────────────────────────────────────────
    hr()
    step("Step 2  URL 结构分析")

    for i, item in enumerate(file_list):
        put_url: str = item["putUrl"]
        key: str = item["key"]
        expire_at = item["expireAt"]

        from urllib.parse import urlparse, urlencode
        parsed = urlparse(put_url)
        host = parsed.netloc
        cdn_host = host.replace(ORIGIN_SUFFIX, CDN_SUFFIX)
        params_preview = "&".join(list(parsed.query.split("&"))[:3]) + " ..."

        cdn_put_url = put_url.replace(host, cdn_host, 1)

        print(f"\n{BOLD}[图片 {i+1}]{R}")
        print(f"  key        : {CYAN}{key}{R}")
        print(f"  expireAt   : {expire_at}")
        print()
        print(f"  {BOLD}putUrl（源站 PUT）{R}")
        print(f"    host   : {host}")
        print(f"    path   : {parsed.path}")
        print(f"    params : {params_preview}")
        print()
        print(f"  {BOLD}读取链接对比{R}")
        print(f"    源站 GET : https://{host}{key}")
        print(f"    CDN GET  : https://{cdn_host}{key}")
        print()
        print(f"  {BOLD}CDN 替换预签名 URL（通常因 Host 签名不匹配而返回 403）{R}")
        print(f"    {cdn_put_url}")

    # ── Step 3: PUT 上传 ─────────────────────────────────────────────────────────
    hr()
    step("Step 3  PUT 上传文件")

    INTERESTING_HEADERS = {
        "etag", "x-amz-request-id", "x-amz-id-2",
        "x-request-id", "server", "date", "content-length",
    }

    for i, item in enumerate(file_list):
        put_url = item["putUrl"]
        f = image_files[i]
        content_type = mime_type(f.name)
        data_bytes = f.read_bytes()

        print(f"\n{BOLD}[图片 {i+1}] {f.name}{R}")
        print(f"  Content-Type : {content_type}")
        print(f"  Size         : {len(data_bytes)} bytes")

        status, reason, headers = put_file(put_url, data_bytes, content_type)

        print(f"  HTTP 状态    : {status} {reason}")
        print(f"  {BOLD}响应头:{R}")
        for k, v in headers.items():
            if k.lower() in INTERESTING_HEADERS:
                print(f"    {k}: {v}")

        if status == 200:
            ok(f"上传成功 [图片 {i+1}]")
        else:
            warn(f"返回非 200 状态码: {status}")

    hr()
    ok("测试完成")


if __name__ == "__main__":
    main()
