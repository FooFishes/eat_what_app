#!/usr/bin/env python3
import os
import json
import subprocess
import argparse
from datetime import datetime


def run(cmd: list[str], check: bool = False) -> str:
    r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if check and r.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{r.stderr}")
    return r.stdout.strip()


def get_latest_tag_name() -> str | None:
    desc = run(["git", "describe", "--tags", "--abbrev=0"], check=False)
    if desc:
        return desc
    tags = run(["git", "tag", "--sort=-creatordate"], check=False).splitlines()
    return tags[0] if tags else None


def discover_previous_tag(head: str | None) -> str | None:
    try:
        run(["git", "fetch", "--tags", "--force", "--quiet"], check=False)
    except Exception:
        pass
    if head:
        out = run(["git", "describe", "--tags", "--abbrev=0", f"{head}^"], check=False)
        if out:
            return out
    tags = run(["git", "tag", "--sort=-creatordate"], check=False).splitlines()
    if len(tags) >= 2:
        return tags[1]
    return tags[0] if tags else None


def collect_commits(base: str | None, head: str, from_root: bool) -> tuple[str, list[str]]:
    try:
        run(["git", "fetch", "--deepen=500", "--quiet"], check=False)
        run(["git", "fetch", "--tags", "--force", "--quiet"], check=False)
    except Exception:
        pass

    if from_root:
        rng = f"{base}..{head}" if base else head
        logs = run(["git", "log", "--no-color", "--pretty=format:%h %s"], check=False)
    else:
        rng = f"{base}..{head}"
        logs = run(["git", "log", "--no-color", "--pretty=format:%h %s", rng], check=False)

    lines = [l for l in logs.splitlines() if l.strip()]
    if not lines:
        logs = run(["git", "log", "-n", "30", "--pretty=format:%h %s"], check=False)
        lines = [l for l in logs.splitlines() if l.strip()]
    return rng, lines


def strip_conventional_prefix(message: str) -> str:
    msg = message
    # Remove short hash if present
    if len(msg) > 8 and msg[7] == ' ':
        msg = msg[8:]
    # Drop common conventional commit prefixes
    parts = msg.split(": ", 1)
    if len(parts) == 2 and any(parts[0].lower().startswith(p) for p in [
        "feat", "fix", "perf", "docs", "refactor", "test", "build", "ci", "chore", "style"
    ]):
        msg = parts[1]
    # Also handle scope like feat(ui): xxx
    if "):" in msg.split(" ", 1)[0]:
        prefix, rest = msg.split(": ", 1) if ": " in msg else (msg, "")
        for p in ["feat", "fix", "perf", "docs", "refactor", "test", "build", "ci", "chore", "style"]:
            if prefix.lower().startswith(p + "(") and rest:
                msg = rest
                break
    return msg.strip()


def group_for_user(commits: list[str]) -> dict[str, list[str]]:
    groups = {"新功能": [], "修复": [], "改进": []}
    for line in commits:
        raw = line.split(" ", 1)[1] if " " in line else line
        low = raw.lower()
        # Map types to user-visible buckets; hide docs/build/ci/refactor/test by default
        if low.startswith("feat"):
            groups["新功能"].append(strip_conventional_prefix(line))
        elif low.startswith("fix"):
            groups["修复"].append(strip_conventional_prefix(line))
        elif low.startswith("perf") or low.startswith("style") or low.startswith("chore"):
            groups["改进"].append(strip_conventional_prefix(line))
        else:
            # For other types, include only if they look user-facing
            keywords = ["ui", "体验", "crash", "崩溃", "稳定性", "速度", "体验优化", "兼容", "性能", "启动", "显示", "通知", "登录", "支付", "同步"]
            if any(k in raw for k in keywords):
                groups["改进"].append(strip_conventional_prefix(line))
    return groups


USER_PROMPT = """
你是一名产品运营，请将以下提交信息概括为“面向最终用户”的更新日志（中文，Markdown）：

输出规则：
- 开头用 1 句通俗摘要（不超过 30 字）。
- 用 3 个小节展示：新功能、修复、改进。仅包含用户可感知的变化，忽略内部重构/CI/测试/文档。
- 用短句和口语化表达，避免术语和模块名；不出现 commit id。
- 每个条目不超过 1 行；如无对应内容，则省略该小节。
- 适合 App 内“本次更新”弹窗展示。

提交列表：
{bullets}
"""


def build_prompt(commits: list[str]) -> str:
    bullets = "\n".join(f"- {strip_conventional_prefix(c)}" for c in commits[:200])
    return USER_PROMPT.format(bullets=bullets)


def call_openai(prompt: str) -> str:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY is not set")
    try:
        from openai import OpenAI  # type: ignore
        base_url = os.getenv("OPENAI_BASE_URL")
        client = OpenAI(api_key=api_key, base_url=base_url) if base_url else OpenAI(api_key=api_key)
        model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
        resp = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "You turn commit lists into user-facing app update notes in Chinese."},
                {"role": "user", "content": prompt},
            ],
            temperature=0.3,
            max_tokens=800,
        )
        return (resp.choices[0].message.content or "").strip()
    except Exception:
        # Fallback to legacy API via requests
        import requests
        base_url = os.getenv("OPENAI_BASE_URL", "https://api.openai.com")
        url = base_url.rstrip("/") + "/v1/chat/completions"
        headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
        data = {
            "model": os.getenv("OPENAI_MODEL", "gpt-4o"),
            "messages": [
                {"role": "system", "content": "You turn commit lists into user-facing app update notes in Chinese."},
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.3,
            "max_tokens": 800,
        }
        r = requests.post(url, headers=headers, json=data, timeout=60)
        r.raise_for_status()
        j = r.json()
        return (j["choices"][0]["message"]["content"] or "").strip()


def naive_user_notes(commits: list[str], version: str) -> str:
    groups = group_for_user(commits)
    # Summary line: try to describe roughly
    counts = [k for k, v in groups.items() if v]
    if "新功能" in counts:
        summary = "本次更新带来新功能与体验优化"
    elif "修复" in counts and "改进" in counts:
        summary = "修复若干问题并优化使用体验"
    elif "修复" in counts:
        summary = "修复若干已知问题"
    else:
        summary = "优化使用体验"

    lines = [f"# 更新日志 {version}", "", f"> {summary}", ""]
    if groups["新功能"]:
        lines.append("## 新功能")
        lines.extend(f"- {m}" for m in groups["新功能"])
        lines.append("")
    if groups["修复"]:
        lines.append("## 修复")
        lines.extend(f"- {m}" for m in groups["修复"])
        lines.append("")
    if groups["改进"]:
        lines.append("## 改进")
        lines.extend(f"- {m}" for m in groups["改进"])
        lines.append("")
    return "\n".join(lines).strip() + "\n"


def main():
    parser = argparse.ArgumentParser(description="Generate user-facing changelog")
    parser.add_argument("--output", default="user_changelog.md")
    args = parser.parse_args()

    ref = os.getenv("GITHUB_REF", "")
    app_version = os.getenv("APP_VERSION")
    version = app_version or (os.getenv("GITHUB_REF_NAME") if ref.startswith("refs/tags/") else datetime.utcnow().strftime("%Y%m%d") + "-" + (os.getenv("GITHUB_SHA", "")[:7]))

    # Compute range: last tag -> HEAD; if no tag, from repository root
    try:
        run(["git", "fetch", "--tags", "--force", "--quiet"], check=False)
    except Exception:
        pass
    latest = get_latest_tag_name()
    head = run(["git", "rev-parse", "HEAD"], check=False)
    if latest:
        base = run(["git", "rev-list", "-n", "1", latest], check=False) or None
        from_root = False
    else:
        base = run(["git", "rev-list", "--max-parents=0", "HEAD"], check=False) or None
        from_root = True

    _range, commits = collect_commits(base, head, from_root)

    content: str = ""
    try:
        prompt = build_prompt(commits)
        content = call_openai(prompt)
    except Exception:
        content = ""
    if not content or not content.strip():
        content = naive_user_notes(commits, str(version))

    with open(args.output, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"[user_changelog] base={(latest or 'ROOT')} head={head} range={_range} commits={len(commits)}")
    print(f"User changelog written to {args.output}")


if __name__ == "__main__":
    main()
