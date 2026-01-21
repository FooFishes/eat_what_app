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


def filter_user_facing_commits(commits: list[str]) -> list[str]:
    """Filter commits to only include user-facing changes."""
    filtered = []
    
    # Exclude patterns (technical/internal changes)
    exclude_patterns = [
        "test", "测试", "单元测试", "集成测试",
        "docs", "文档", "readme", "changelog",
        "ci", "cd", "github", "workflow", "action",
        "build", "构建", "编译", "打包",
        "refactor", "重构", "代码整理", "格式化",
        "lint", "格式检查", "代码规范",
        "dependency", "依赖", "升级", "更新依赖",
        "config", "配置", "设置文件",
        "merge", "合并", "conflict", "冲突"
    ]
    
    # Include patterns (user-facing changes)
    include_patterns = [
        "feat", "feature", "新功能", "新增", "添加",
        "fix", "修复", "解决", "bug", "问题", "错误", "异常", "崩溃",
        "ui", "界面", "用户界面", "显示", "布局", "样式",
        "ux", "体验", "用户体验", "交互", "操作",
        "perf", "性能", "优化", "速度", "响应", "内存",
        "security", "安全", "权限", "认证", "加密",
        "api", "接口", "功能", "特性",
        "support", "支持", "兼容", "适配"
    ]
    
    for commit in commits:
        commit_lower = commit.lower()
        
        # Skip if matches exclude patterns
        if any(pattern in commit_lower for pattern in exclude_patterns):
            continue
            
        # Include if matches include patterns or looks user-relevant
        if any(pattern in commit_lower for pattern in include_patterns):
            filtered.append(commit)
            continue
            
        # Include commits that don't match exclude patterns and seem substantial
        if len(commit.split()) >= 3:  # At least 3 words, likely substantial
            filtered.append(commit)
    
    return filtered


def group_for_user_improved(commits: list[str]) -> dict[str, list[str]]:
    """Group commits into user-friendly categories with better classification."""
    groups = {"🎉 新功能": [], "🐛 问题修复": [], "✨ 体验优化": []}
    
    for line in commits:
        raw = line.split(" ", 1)[1] if " " in line else line
        low = raw.lower()
        clean_msg = strip_conventional_prefix(line)
        
        # Classify into user-friendly categories
        if any(keyword in low for keyword in ["feat", "feature", "新功能", "新增", "添加", "支持"]):
            groups["🎉 新功能"].append(clean_msg)
        elif any(keyword in low for keyword in ["fix", "修复", "解决", "bug", "问题", "错误", "异常", "崩溃"]):
            groups["🐛 问题修复"].append(clean_msg)
        elif any(keyword in low for keyword in [
            "perf", "性能", "优化", "速度", "响应", "内存",
            "ui", "界面", "显示", "布局", "样式", "体验", "交互",
            "improve", "改进", "增强", "提升", "完善"
        ]):
            groups["✨ 体验优化"].append(clean_msg)
        else:
            # Default to experience optimization for other changes
            groups["✨ 体验优化"].append(clean_msg)
    
    return groups


IMPROVED_USER_PROMPT = """
你是一名产品运营，请将以下提交信息概括为"面向最终用户"的更新日志（中文，Markdown）：

输出规则：
- 开头用 1 句通俗摘要（不超过 30 字），要让普通用户能理解
- 用 emoji 和简洁的小节展示：🎉 新功能、🐛 问题修复、✨ 体验优化
- 仅包含用户可感知的变化，完全忽略内部重构/CI/测试/文档/依赖更新
- 用口语化表达，避免技术术语和模块名；不出现 commit id 和文件名
- 每个条目用简短的一句话描述，突出用户价值
- 适合在飞书消息、App内弹窗、应用商店更新说明中展示
- 如果某个分类没有内容，则完全省略该分类

示例格式：
# 更新内容

> 本次更新优化了使用体验并修复了若干问题

## 🎉 新功能
- 新增了某某功能，让您可以...
- 支持某某操作，提升工作效率

## 🐛 问题修复  
- 修复了某某情况下的异常问题
- 解决了某某功能偶尔失效的问题

## ✨ 体验优化
- 优化了某某界面的显示效果
- 提升了某某操作的响应速度

提交列表：
{bullets}

请严格按照上述格式输出，使用通俗易懂的语言。
"""


def build_improved_prompt(commits: list[str]) -> str:
    bullets = "\n".join(f"- {strip_conventional_prefix(c)}" for c in commits[:100])
    return IMPROVED_USER_PROMPT.format(bullets=bullets)


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
                {"role": "system", "content": "You are a product manager who creates user-friendly app update notes in Chinese. Focus on user value and avoid technical jargon."},
                {"role": "user", "content": prompt},
            ],
            temperature=0.3,
            max_tokens=1000,
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
                {"role": "system", "content": "You are a product manager who creates user-friendly app update notes in Chinese. Focus on user value and avoid technical jargon."},
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.3,
            "max_tokens": 1000,
        }
        r = requests.post(url, headers=headers, json=data, timeout=60)
        r.raise_for_status()
        j = r.json()
        return (j["choices"][0]["message"]["content"] or "").strip()


def improved_naive_user_notes(commits: list[str], version: str) -> str:
    groups = group_for_user_improved(commits)
    
    # Generate summary based on what's included
    has_features = bool(groups["🎉 新功能"])
    has_fixes = bool(groups["🐛 问题修复"])
    has_improvements = bool(groups["✨ 体验优化"])
    
    if has_features and has_fixes:
        summary = "本次更新带来新功能并修复了若干问题"
    elif has_features:
        summary = "本次更新新增了实用功能"
    elif has_fixes and has_improvements:
        summary = "本次更新修复问题并优化了使用体验"
    elif has_fixes:
        summary = "本次更新修复了若干已知问题"
    elif has_improvements:
        summary = "本次更新优化了使用体验"
    else:
        summary = "本次更新包含功能改进"

    lines = [f"# 更新内容", "", f"> {summary}", ""]
    
    for title, items in groups.items():
        if items:
            lines.append(f"## {title}")
            # Limit items and make them more user-friendly
            for item in items[:8]:  # Max 8 items per category
                # Clean up the message to be more user-friendly
                clean_item = item
                if len(clean_item) > 50:
                    clean_item = clean_item[:47] + "..."
                lines.append(f"- {clean_item}")
            lines.append("")
    
    return "\n".join(lines).strip() + "\n"


def main():
    parser = argparse.ArgumentParser(description="Generate improved user-facing changelog")
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
    
    # Filter to user-facing commits only
    user_commits = filter_user_facing_commits(commits)

    content: str = ""
    try:
        prompt = build_improved_prompt(user_commits)
        content = call_openai(prompt)
    except Exception as e:
        print(f"Warning: OpenAI API failed: {e}")
        content = ""
    
    if not content or not content.strip():
        content = improved_naive_user_notes(user_commits, str(version))

    with open(args.output, "w", encoding="utf-8") as f:
        f.write(content)
    
    print(f"[user_changelog_improved] base={(latest or 'ROOT')} head={head} range={_range} commits={len(commits)} user_facing={len(user_commits)}")
    print(f"Improved user changelog written to {args.output}")


if __name__ == "__main__":
    main()
