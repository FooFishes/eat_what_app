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
    """Return (range_expr, shortstat, commit_lines) for desired range."""
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


def filter_user_relevant_commits(commits: list[str], files: list[str]) -> list[str]:
    """Filter commits to only include user-relevant changes."""
    filtered = []
    
    # Keywords that indicate user-relevant changes
    user_keywords = [
        "ui", "界面", "用户", "体验", "交互", "显示", "界面",
        "功能", "特性", "feature", "新增", "添加",
        "修复", "fix", "bug", "问题", "错误", "异常", "崩溃", "crash",
        "性能", "优化", "perf", "速度", "内存", "响应",
        "安全", "security", "权限", "认证", "加密",
        "兼容", "支持", "适配", "版本"
    ]
    
    # File patterns that indicate user-relevant changes
    user_file_patterns = [
        "lib/", "src/", "app/",  # Main application code
        "assets/", "images/", "fonts/",  # UI assets
        "pubspec.yaml", "package.json",  # Dependencies that might affect users
    ]
    
    # Patterns to exclude (internal/technical only)
    exclude_patterns = [
        "test/", "tests/", "_test.dart", ".test.js",
        "docs/", "README", "CHANGELOG",
        ".github/", "scripts/", "tools/",
        ".gitignore", ".editorconfig", ".vscode/",
        "build.gradle", "Podfile", "CMakeLists.txt"
    ]
    
    for commit in commits:
        commit_lower = commit.lower()
        
        # Always include if it has user-relevant keywords
        if any(keyword in commit_lower for keyword in user_keywords):
            filtered.append(commit)
            continue
            
        # Check if related files are user-relevant
        commit_hash = commit.split()[0] if commit else ""
        if commit_hash:
            # Get files changed in this commit
            try:
                commit_files = run(["git", "show", "--name-only", "--format=", commit_hash], check=False)
                commit_file_list = [f.strip() for f in commit_files.splitlines() if f.strip()]
                
                # Include if any file matches user patterns and doesn't match exclude patterns
                for file in commit_file_list:
                    if any(pattern in file for pattern in exclude_patterns):
                        continue
                    if any(pattern in file for pattern in user_file_patterns):
                        filtered.append(commit)
                        break
            except:
                # If we can't get file info, include the commit to be safe
                filtered.append(commit)
    
    return filtered


IMPROVED_PROMPT_TEMPLATE = """
你是一名资深产品经理，请基于下面的提交与变更，生成一份面向开发者和技术用户的发布说明（中文，Markdown）。

核心要求：
- 开头用一句话概括本次发布的核心价值和主要变化
- 按重要性和用户影响程度分类，使用emoji增强可读性
- 过滤掉纯内部技术细节，重点突出用户可感知的变化
- 使用通俗易懂的语言，避免过于技术化的表述

分类规则：
🎉 **新功能** - 用户可直接使用的新特性
🐛 **问题修复** - 解决的bug和异常情况  
⚡ **性能优化** - 速度、内存、响应时间等改进
🔧 **功能改进** - 现有功能的增强和优化
📱 **用户体验** - 界面、交互、易用性改进
🔒 **安全性** - 安全相关的修复和增强
🏗️ **架构优化** - 重要的技术架构改进（仅包含对用户有影响的）

过滤规则：
- 忽略纯测试代码更新（test/spec文件）
- 忽略文档更新（README、docs等，除非是重要的API文档）
- 忽略CI/CD配置变更（.github、build脚本等，除非影响发布流程）
- 忽略代码格式化、重构（除非带来性能提升）
- 忽略依赖版本更新（除非修复安全问题或带来新功能）

元信息：
- 仓库：{repo}
- 版本：{version}
- 提交范围：{range_expr}
- 变更统计：{shortstat}

提交列表（已过滤，按时间倒序）：
{commits}

文件变更（name-status，最多 {files_count} 条）：
{files}

输出格式要求：
# 发布说明 {version}

> [一句话概括本次发布的核心价值]

## 🎉 新功能
[如果有新功能]

## 🐛 问题修复  
[如果有bug修复]

## ⚡ 性能优化
[如果有性能改进]

## 🔧 功能改进
[如果有功能增强]

## 📱 用户体验
[如果有UX改进]

## 🔒 安全性
[如果有安全相关更新]

## 🏗️ 架构优化
[如果有重要的架构改进]

## 📋 其他说明
[如果有其他重要信息]

请输出纯 Markdown，不要包含额外解释。如果某个分类没有内容，请省略该分类。
"""


def build_improved_prompt(repo: str, version: str, range_expr: str, shortstat: str,
                         commits: list[str], files: list[str]) -> str:
    return IMPROVED_PROMPT_TEMPLATE.format(
        repo=repo,
        version=version,
        range_expr=range_expr,
        shortstat=shortstat or "",
        commits="\n".join(f"- {c}" for c in commits[:200]),
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
                {"role": "system", "content": "You are a helpful product manager who creates user-focused release notes."},
                {"role": "user", "content": prompt},
            ],
            temperature=0.2,
            max_tokens=1500,
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
                {"role": "system", "content": "You are a helpful product manager who creates user-focused release notes."},
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.2,
            "max_tokens": 1500,
        }
        r = requests.post(url, headers=headers, json=data, timeout=60)
        r.raise_for_status()
        j = r.json()
        return (j["choices"][0]["message"]["content"] or "").strip()


def improved_naive_notes(commits: list[str], shortstat: str, version: str) -> str:
    # Improved local grouping with better categorization
    groups = {
        "🎉 新功能": [], 
        "🐛 问题修复": [], 
        "⚡ 性能优化": [], 
        "🔧 功能改进": [], 
        "📱 用户体验": [],
        "🔒 安全性": [],
        "🏗️ 架构优化": []
    }
    
    for line in commits:
        msg = line.split(" ", 1)[1] if " " in line else line
        lower = msg.lower()
        
        if any(keyword in lower for keyword in ["feat", "新增", "添加", "功能", "特性"]):
            groups["🎉 新功能"].append(msg)
        elif any(keyword in lower for keyword in ["fix", "修复", "bug", "问题", "错误", "崩溃"]):
            groups["🐛 问题修复"].append(msg)
        elif any(keyword in lower for keyword in ["perf", "性能", "优化", "速度", "内存"]):
            groups["⚡ 性能优化"].append(msg)
        elif any(keyword in lower for keyword in ["ui", "界面", "体验", "交互", "显示"]):
            groups["📱 用户体验"].append(msg)
        elif any(keyword in lower for keyword in ["security", "安全", "权限", "认证"]):
            groups["🔒 安全性"].append(msg)
        elif any(keyword in lower for keyword in ["refactor", "重构", "架构"]):
            groups["🏗️ 架构优化"].append(msg)
        else:
            groups["🔧 功能改进"].append(msg)

    lines = [f"# 发布说明 {version}", "", f"> 本次发布包含功能改进和问题修复", ""]
    
    for title, items in groups.items():
        if items:
            lines.append(f"## {title}")
            lines.extend([f"- {i}" for i in items[:10]])  # Limit to 10 items per category
            lines.append("")
    
    if shortstat:
        lines.append("## 📊 变更统计")
        lines.append(f"- {shortstat}")
        lines.append("")
        
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate improved release notes from commits/diff using LLM")
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
        from_root = (base == get_root_commit())
    if args.head:
        head = args.head

    range_expr, shortstat, commit_lines = collect_commits_for_range(base, head, from_root)
    changed_files = collect_changed_files(range_expr, from_root, head)
    
    # Filter commits to user-relevant ones
    filtered_commits = filter_user_relevant_commits(commit_lines, changed_files)
    
    prompt = build_improved_prompt(repo, version, range_expr, shortstat, filtered_commits, changed_files)

    content: str = ""
    try:
        content = call_openai(prompt)
    except Exception as e:
        print(f"Warning: OpenAI API failed: {e}", file=sys.stderr)
        content = ""
    
    # If LLM returned empty or whitespace, fall back to local notes
    if not content or not content.strip():
        content = improved_naive_notes(filtered_commits, shortstat, str(version))

    with open(args.output, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"[release_notes_improved] base={latest_tag or 'ROOT'} head={head} range='{range_expr}' commits={len(commit_lines)} filtered={len(filtered_commits)} shortstat_len={len(shortstat or '')}")
    print(f"Improved release notes written to {args.output}")


if __name__ == "__main__":
    main()
