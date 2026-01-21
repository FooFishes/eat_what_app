#!/usr/bin/env python3
import os
import json
import subprocess
import sys
import argparse
from datetime import datetime


def run(cmd: list[str], cwd: str | None = None, check: bool = False) -> str:
    result = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if check and result.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{result.stderr}")
    return result.stdout.strip()


def detect_range_from_event() -> tuple[str | None, str | None, str]:
    """Return (base, head, mode). mode in {pr, tag, push, unknown}."""
    event_name = os.getenv("GITHUB_EVENT_NAME", "").lower()
    event_path = os.getenv("GITHUB_EVENT_PATH")
    ref = os.getenv("GITHUB_REF", "")
    base = head = None
    mode = "unknown"
    payload = {}
    if event_path and os.path.exists(event_path):
        try:
            with open(event_path, "r", encoding="utf-8") as f:
                payload = json.load(f)
        except Exception:
            payload = {}

    if event_name == "pull_request":
        pr = payload.get("pull_request", {})
        base = (pr.get("base") or {}).get("sha")
        head = (pr.get("head") or {}).get("sha")
        mode = "pr"
    elif event_name == "push":
        # Tag push is also a push event when using on.push.tags.
        if ref.startswith("refs/tags/"):
            mode = "tag"
            # For tags, compute previous tag if possible.
            # We'll leave base=None and resolve via git later.
            head = os.getenv("GITHUB_SHA")
        else:
            mode = "push"
            base = payload.get("before")
            head = payload.get("after")
    elif event_name == "workflow_dispatch":
        mode = "push"
        head = os.getenv("GITHUB_SHA")

    return base, head, mode


def discover_previous_tag(head: str | None) -> str | None:
    # Ensure tags are available
    try:
        run(["git", "fetch", "--tags", "--force", "--quiet"], check=False)
    except Exception:
        pass
    # Try previous tag relative to head
    if head:
        out = run(["git", "describe", "--tags", "--abbrev=0", f"{head}^"], check=False)
        if out:
            return out
    # Fallback: latest tag excluding current
    tags = run(["git", "tag", "--sort=-creatordate"], check=False).splitlines()
    if len(tags) >= 2:
        return tags[1]
    return tags[0] if tags else None


def get_latest_tag_name() -> str | None:
    # Try the nearest tag reachable from HEAD
    desc = run(["git", "describe", "--tags", "--abbrev=0"], check=False)
    if desc:
        return desc
    # Fallback: newest by date
    tags = run(["git", "tag", "--sort=-creatordate"], check=False).splitlines()
    return tags[0] if tags else None


def get_root_commit() -> str | None:
    return run(["git", "rev-list", "--max-parents=0", "HEAD"], check=False) or None


def get_empty_tree() -> str:
    # Standard empty tree hash can vary by impl, compute it
    h = run(["git", "hash-object", "-t", "tree", "/dev/null"], check=False)
    return h or "4b825dc642cb6eb9a060e54bf8d69288fbee4904"


def collect_commits_for_range(base: str | None, head: str, from_root: bool) -> tuple[str, str, list[str]]:
    """Return (range_expr, shortstat, commit_lines) for desired range.

    - If from_root is True, include the root commit; compute diff vs empty tree.
    - Otherwise, use base..head.
    """
    # Ensure we have enough history; ignore failures
    try:
        run(["git", "fetch", "--deepen=500", "--quiet"], check=False)
        run(["git", "fetch", "--tags", "--force", "--quiet"], check=False)
    except Exception:
        pass

    if from_root:
        range_expr = f"{base}..{head}" if base else head
        # Shortstat/files from empty tree to HEAD
        empty = get_empty_tree()
        shortstat = run(["git", "diff", "--shortstat", empty, head], check=False)
        logs = run(["git", "log", "--no-color", "--pretty=format:%h %s"], check=False)
    else:
        range_expr = f"{base}..{head}"
        shortstat = run(["git", "diff", "--shortstat", range_expr], check=False)
        logs = run(["git", "log", "--no-color", "--pretty=format:%h %s", range_expr], check=False)

    commit_lines = [c for c in logs.splitlines() if c.strip()]
    if not commit_lines:
        logs = run(["git", "log", "-n", "30", "--pretty=format:%h %s"], check=False)
        commit_lines = [c for c in logs.splitlines() if c.strip()]
    return range_expr, shortstat, commit_lines


def collect_changed_files(range_expr: str, from_root: bool, head: str, limit: int = 200) -> list[str]:
    if from_root:
        empty = get_empty_tree()
        out = run(["git", "diff", "--name-status", empty, head], check=False)
    else:
        out = run(["git", "diff", "--name-status", range_expr], check=False)
    files = [l for l in out.splitlines() if l.strip()]
    return files[:limit]


PROMPT_TEMPLATE = """
你是一名资深发布经理，请基于下面的提交与变更，生成一份面向用户的发布说明（中文，Markdown）。

要求：
- 风格专业、简洁，先给出一句话的高层摘要。
- 以模块化小节输出：新增、修复、优化/改进、性能、文档、构建/CI、重构、测试、其他。
- 识别并高亮“破坏性变更”（如存在），单独列一节并给出迁移指引。
- 尽量从 conventional commits（feat/fix/refactor/chore/docs/test/build/ci/perf）中归类，小心避免重复。
- 若信息不足，可从文件路径和提交信息推断模块/功能点；但不要臆造细节。

元信息：
- 仓库：{repo}
- 事件：{event}（{mode}）
- 版本：{version}
- 提交范围：{range_expr}
- 变更统计：{shortstat}

提交列表（按时间倒序）：
{commits}

文件变更（name-status，最多 {files_count} 条）：
{files}

请输出纯 Markdown，不要包含额外解释。
"""


def build_prompt(repo: str, event: str, mode: str, version: str, range_expr: str, shortstat: str,
                 commits: list[str], files: list[str]) -> str:
    return PROMPT_TEMPLATE.format(
        repo=repo,
        event=event,
        mode=mode,
        version=version,
        range_expr=range_expr,
        shortstat=shortstat or "",
        commits="\n".join(f"- {c}" for c in commits[:300]),
        files_count=len(files),
        files="\n".join(f"- {f}" for f in files),
    )


def call_openai(prompt: str) -> str:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY is not set.")
    # Prefer the new OpenAI SDK (>=1.0)
    try:
        from openai import OpenAI  # type: ignore
        base_url = os.getenv("OPENAI_BASE_URL")
        client = OpenAI(api_key=api_key, base_url=base_url) if base_url else OpenAI(api_key=api_key)
        model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
        resp = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "You are a helpful release manager."},
                {"role": "user", "content": prompt},
            ],
            temperature=0.2,
            max_tokens=1200,
        )
        return (resp.choices[0].message.content or "").strip()
    except Exception as e:
        # Fallback: try legacy API via requests
        import requests
        base_url = os.getenv("OPENAI_BASE_URL", "https://api.openai.com")
        url = base_url.rstrip("/") + "/v1/chat/completions"
        headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
        data = {
            "model": os.getenv("OPENAI_MODEL", "gpt-4o"),
            "messages": [
                {"role": "system", "content": "You are a helpful release manager."},
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.2,
            "max_tokens": 1200,
        }
        r = requests.post(url, headers=headers, json=data, timeout=60)
        r.raise_for_status()
        j = r.json()
        return (j["choices"][0]["message"]["content"] or "").strip()


def naive_notes(commits: list[str], shortstat: str, version: str) -> str:
    # Simple local grouping if no API key is available
    groups = {
        "新增": [], "修复": [], "优化/改进": [], "文档": [], "构建/CI": [], "重构": [], "性能": [], "测试": [], "其他": []
    }
    for line in commits:
        msg = line.split(" ", 1)[1] if " " in line else line
        lower = msg.lower()
        if lower.startswith("feat"):
            groups["新增"].append(msg)
        elif lower.startswith("fix"):
            groups["修复"].append(msg)
        elif lower.startswith("docs"):
            groups["文档"].append(msg)
        elif lower.startswith("build") or lower.startswith("ci") or lower.startswith("chore(ci)"):
            groups["构建/CI"].append(msg)
        elif lower.startswith("refactor"):
            groups["重构"].append(msg)
        elif lower.startswith("perf"):
            groups["性能"].append(msg)
        elif lower.startswith("test"):
            groups["测试"].append(msg)
        elif lower.startswith("chore") or lower.startswith("style"):
            groups["优化/改进"].append(msg)
        else:
            groups["其他"].append(msg)

    lines = [f"# 发布说明 {version}", "", f"> 变更统计：{shortstat or '无'}", ""]
    for title, items in groups.items():
        if items:
            lines.append(f"## {title}")
            lines.extend([f"- {i}" for i in items])
            lines.append("")
    lines.append("## 升级建议")
    lines.append("- 建议在测试环境验证后再上线。")
    lines.append("- 如遇问题，可回滚至上一个稳定版本。")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate release notes from commits/diff using LLM")
    parser.add_argument("--base", help="Base ref/sha", default=None)
    parser.add_argument("--head", help="Head ref/sha", default=None)
    parser.add_argument("--output", help="Output file", default="release_notes.md")
    args = parser.parse_args()

    repo = os.getenv("GITHUB_REPOSITORY", "unknown")
    event = os.getenv("GITHUB_EVENT_NAME", "unknown")
    ref = os.getenv("GITHUB_REF", "")
    app_version = os.getenv("APP_VERSION")
    version = app_version or (os.getenv("GITHUB_REF_NAME") if ref.startswith("refs/tags/") else datetime.utcnow().strftime("%Y%m%d") + "-" + (os.getenv("GITHUB_SHA", "")[:7]))

    # Always compute range from last tag to HEAD; if no tag, from repository root to HEAD
    try:
        run(["git", "fetch", "--tags", "--force", "--quiet"], check=False)
    except Exception:
        pass
    latest_tag = get_latest_tag_name()
    head = run(["git", "rev-parse", "HEAD"], check=False)
    if latest_tag:
        base = run(["git", "rev-list", "-n", "1", latest_tag], check=False) or None
        from_root = False
    else:
        base = get_root_commit()
        from_root = True

    # Allow CLI overrides if provided explicitly
    if args.base:
        base = args.base
        # If user overrides base, treat as not-root unless explicitly first commit
        from_root = (base == get_root_commit())
    if args.head:
        head = args.head

    range_expr, shortstat, commit_lines = collect_commits_for_range(base, head, from_root)
    changed_files = collect_changed_files(range_expr, from_root, head)
    mode = "tag_to_head" if latest_tag else "root_to_head"
    prompt = build_prompt(repo, event, mode, version, range_expr, shortstat, commit_lines, changed_files)

    content: str = ""
    try:
        content = call_openai(prompt)
    except Exception:
        content = ""
    # If LLM returned empty or whitespace, fall back to local notes
    if not content or not content.strip():
        content = naive_notes(commit_lines, shortstat, str(version))

    with open(args.output, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"[release_notes] base={latest_tag or 'ROOT'} head={head} range='{range_expr}' commits={len(commit_lines)} shortstat_len={len(shortstat or '')}")
    print(f"Release notes written to {args.output}")


if __name__ == "__main__":
    main()
