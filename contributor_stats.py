#!/usr/bin/env python3
"""
统计 Git 仓库协作者代码提交量。

默认输出:
- 提交数
- 新增行
- 删除行
- 净增行
- 变更文件数
"""

import argparse
import csv
import json
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List, Optional, Tuple


@dataclass
class AuthorStat:
    name: str
    email: str
    commits: int = 0
    added: int = 0
    deleted: int = 0
    files: int = 0

    @property
    def net(self) -> int:
        return self.added - self.deleted


@dataclass
class CommitStat:
    commit: str
    author: str
    email: str
    commit_time: str
    subject: str
    added: int = 0
    deleted: int = 0
    files: int = 0

    @property
    def net(self) -> int:
        return self.added - self.deleted


def build_command(
    args: argparse.Namespace, revision: Optional[str] = None, detail: bool = False
) -> List[str]:
    date_style = "iso-strict" if detail else "short"
    format_style = (
        "@@@%H%x1f%an%x1f%ae%x1f%ad%x1f%s"
        if detail
        else "@@@%H%x1f%an%x1f%ae%x1f%ad"
    )
    cmd = [
        "git",
        "-c",
        "log.showSignature=false",
        "log",
        "--use-mailmap",
        "--numstat",
        f"--date={date_style}",
        f"--format={format_style}",
    ]

    if args.no_merges:
        cmd.append("--no-merges")
    if args.since:
        cmd.append(f"--since={args.since}")
    if args.until:
        cmd.append(f"--until={args.until}")
    cmd.append(revision or args.revision)
    if args.paths:
        cmd.append("--")
        cmd.extend(args.paths)
    return cmd


def list_branches() -> List[str]:
    cmd = [
        "git",
        "for-each-ref",
        "--format=%(refname)",
        "refs/heads",
        "refs/remotes",
    ]
    try:
        raw = subprocess.check_output(
            cmd,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
    except subprocess.CalledProcessError as exc:
        print(f"Failed to list branches: {exc}", file=sys.stderr)
        return []

    branches: List[str] = []
    seen = set()
    for line in raw.splitlines():
        ref = line.strip()
        if not ref:
            continue
        if ref.startswith("refs/heads/"):
            branch = ref[len("refs/heads/") :]
        elif ref.startswith("refs/remotes/"):
            branch = ref[len("refs/remotes/") :]
            # 跳过远程头指针以及远程根引用(如 origin)
            if branch.endswith("/HEAD"):
                continue
            if "/" not in branch:
                continue
        else:
            continue
        if branch in seen:
            continue
        seen.add(branch)
        branches.append(branch)
    return branches


def author_key(name: str, email: str, group_by: str) -> str:
    if group_by == "name":
        return name
    if group_by == "email":
        return email
    return f"{name}\x1f{email}"


def parse_stats(raw: str, group_by: str) -> Dict[str, AuthorStat]:
    stats: Dict[str, AuthorStat] = {}
    current_stat: Optional[AuthorStat] = None

    for line in raw.splitlines():
        if not line:
            continue

        if line.startswith("@@@"):
            header = line[3:]
            parts = header.split("\x1f")
            if len(parts) < 4:
                current_stat = None
                continue
            _, name, email, _ = parts[:4]
            key = author_key(name, email, group_by)
            if key not in stats:
                stats[key] = AuthorStat(name=name, email=email)
            current_stat = stats[key]
            current_stat.commits += 1
            continue

        if current_stat is None:
            continue

        cols = line.split("\t")
        if len(cols) < 3:
            continue
        add_col, del_col = cols[0], cols[1]
        if add_col == "-" or del_col == "-":
            # 二进制文件不参与行数统计
            continue
        try:
            added = int(add_col)
            deleted = int(del_col)
        except ValueError:
            continue

        current_stat.added += added
        current_stat.deleted += deleted
        current_stat.files += 1
    return stats


def parse_commit_stats(raw: str) -> List[CommitStat]:
    commits: List[CommitStat] = []
    current_commit: Optional[CommitStat] = None

    for line in raw.splitlines():
        if not line:
            continue

        if line.startswith("@@@"):
            header = line[3:]
            parts = header.split("\x1f")
            if len(parts) < 5:
                current_commit = None
                continue
            commit_hash, author, email, commit_time, subject = parts[:5]
            current_commit = CommitStat(
                commit=commit_hash,
                author=author,
                email=email,
                commit_time=commit_time,
                subject=subject,
            )
            commits.append(current_commit)
            continue

        if current_commit is None:
            continue

        cols = line.split("\t")
        if len(cols) < 3:
            continue
        add_col, del_col = cols[0], cols[1]
        if add_col == "-" or del_col == "-":
            # 二进制文件不参与行数统计
            continue
        try:
            added = int(add_col)
            deleted = int(del_col)
        except ValueError:
            continue

        current_commit.added += added
        current_commit.deleted += deleted
        current_commit.files += 1
    return commits


def sort_stats(
    stats: Dict[str, AuthorStat], sort_by: str
) -> List[Tuple[str, AuthorStat]]:
    rows = list(stats.items())

    if sort_by == "author":
        rows.sort(key=lambda item: item[1].name.lower())
        return rows

    key_map = {
        "commits": lambda item: item[1].commits,
        "added": lambda item: item[1].added,
        "deleted": lambda item: item[1].deleted,
        "net": lambda item: item[1].net,
        "files": lambda item: item[1].files,
    }
    rows.sort(key=key_map[sort_by], reverse=True)
    return rows


def sort_commit_stats(commits: List[CommitStat], sort_by: str) -> List[CommitStat]:
    if sort_by == "time":
        return commits
    key_map = {
        "author": lambda item: item.author.lower(),
        "added": lambda item: item.added,
        "deleted": lambda item: item.deleted,
        "net": lambda item: item.net,
        "files": lambda item: item.files,
    }
    reverse = sort_by != "author"
    return sorted(commits, key=key_map[sort_by], reverse=reverse)


def author_match(name: str, email: str, keyword: str) -> bool:
    kw = keyword.lower()
    return kw in name.lower() or kw in email.lower()


def parse_time(time_str: str) -> Optional[datetime]:
    try:
        return datetime.fromisoformat(time_str)
    except ValueError:
        return None


def format_interval(seconds: int) -> str:
    if seconds < 60:
        return f"{seconds}s"
    minutes, sec = divmod(seconds, 60)
    if minutes < 60:
        return f"{minutes}m {sec}s"
    hours, minute = divmod(minutes, 60)
    if hours < 24:
        return f"{hours}h {minute}m"
    days, hour = divmod(hours, 24)
    return f"{days}d {hour}h"


def intervals_since_prev(commits: List[CommitStat]) -> List[str]:
    result: List[str] = []
    prev_time: Optional[datetime] = None

    for commit in commits:
        current_time = parse_time(commit.commit_time)
        if prev_time is None or current_time is None:
            result.append("-")
        else:
            delta = abs(int((prev_time - current_time).total_seconds()))
            result.append(format_interval(delta))
        prev_time = current_time
    return result


def add_delete_text(commit: CommitStat) -> str:
    return f"+{commit.added}/-{commit.deleted}"


def write_table(rows: List[Tuple[str, AuthorStat]], show_email: bool) -> None:
    headers = ["Author"]
    if show_email:
        headers.append("Email")
    headers.extend(["Commits", "Added", "Deleted", "Net", "Files"])

    table_rows: List[List[str]] = []
    for _, stat in rows:
        one_row = [stat.name]
        if show_email:
            one_row.append(stat.email)
        one_row.extend(
            [
                str(stat.commits),
                str(stat.added),
                str(stat.deleted),
                str(stat.net),
                str(stat.files),
            ]
        )
        table_rows.append(one_row)

    if not table_rows:
        print("No commit data found with current filters.")
        return

    widths = [len(h) for h in headers]
    for row in table_rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(cell))

    def render(row: List[str]) -> str:
        return "  ".join(cell.ljust(widths[i]) for i, cell in enumerate(row))

    print(render(headers))
    print("  ".join("-" * w for w in widths))
    for row in table_rows:
        print(render(row))


def write_csv(rows: List[Tuple[str, AuthorStat]], show_email: bool) -> None:
    headers = ["author"]
    if show_email:
        headers.append("email")
    headers.extend(["commits", "added", "deleted", "net", "files"])

    writer = csv.writer(sys.stdout)
    writer.writerow(headers)
    for _, stat in rows:
        row = [stat.name]
        if show_email:
            row.append(stat.email)
        row.extend([stat.commits, stat.added, stat.deleted, stat.net, stat.files])
        writer.writerow(row)


def write_json(rows: List[Tuple[str, AuthorStat]], show_email: bool) -> None:
    payload = []
    for _, stat in rows:
        obj = {
            "author": stat.name,
            "commits": stat.commits,
            "added": stat.added,
            "deleted": stat.deleted,
            "net": stat.net,
            "files": stat.files,
        }
        if show_email:
            obj["email"] = stat.email
        payload.append(obj)
    print(json.dumps(payload, ensure_ascii=False, indent=2))


def write_commit_table(
    commits: List[CommitStat], show_email: bool, full: bool = False
) -> None:
    headers = ["Time", "Commit", "Author", "SincePrev", "Add/Del", "Files", "Net"]
    if full:
        if show_email:
            headers.append("Email")
        headers.append("Subject")

    table_rows: List[List[str]] = []
    intervals = intervals_since_prev(commits)
    for idx, commit in enumerate(commits):
        one_row = [
            commit.commit_time,
            commit.commit[:10],
            commit.author,
            intervals[idx],
            add_delete_text(commit),
            str(commit.files),
            str(commit.net),
        ]
        if full:
            if show_email:
                one_row.append(commit.email)
            one_row.append(commit.subject)
        table_rows.append(one_row)

    if not table_rows:
        print("No commit data found with current filters.")
        return

    widths = [len(h) for h in headers]
    for row in table_rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(cell))

    def render(row: List[str]) -> str:
        return "  ".join(cell.ljust(widths[i]) for i, cell in enumerate(row))

    print(render(headers))
    print("  ".join("-" * w for w in widths))
    for row in table_rows:
        print(render(row))


def write_commit_csv(
    commits: List[CommitStat], show_email: bool, full: bool = False
) -> None:
    headers = ["time", "commit", "author", "since_prev", "add_delete", "files", "net"]
    if full:
        if show_email:
            headers.append("email")
        headers.append("subject")

    writer = csv.writer(sys.stdout)
    writer.writerow(headers)
    intervals = intervals_since_prev(commits)
    for idx, commit in enumerate(commits):
        row = [
            commit.commit_time,
            commit.commit,
            commit.author,
            intervals[idx],
            add_delete_text(commit),
            commit.files,
            commit.net,
        ]
        if full:
            if show_email:
                row.append(commit.email)
            row.append(commit.subject)
        writer.writerow(row)


def write_commit_json(
    commits: List[CommitStat], show_email: bool, full: bool = False
) -> None:
    payload = []
    intervals = intervals_since_prev(commits)
    for idx, commit in enumerate(commits):
        obj = {
            "time": commit.commit_time,
            "commit": commit.commit,
            "author": commit.author,
            "since_prev": intervals[idx],
            "add_delete": add_delete_text(commit),
            "files": commit.files,
            "net": commit.net,
        }
        if full:
            if show_email:
                obj["email"] = commit.email
            obj.update(
                {
                    "subject": commit.subject,
                }
            )
        payload.append(obj)
    print(json.dumps(payload, ensure_ascii=False, indent=2))


def write_table_by_branch(
    branch_rows: List[Tuple[str, List[Tuple[str, AuthorStat]]]], show_email: bool
) -> None:
    if not branch_rows:
        print("No commit data found with current filters.")
        return

    for index, (branch, rows) in enumerate(branch_rows):
        print(f"[{branch}]")
        write_table(rows, show_email=show_email)
        if index != len(branch_rows) - 1:
            print()


def write_csv_by_branch(
    branch_rows: List[Tuple[str, List[Tuple[str, AuthorStat]]]], show_email: bool
) -> None:
    headers = ["branch", "author"]
    if show_email:
        headers.append("email")
    headers.extend(["commits", "added", "deleted", "net", "files"])

    writer = csv.writer(sys.stdout)
    writer.writerow(headers)

    for branch, rows in branch_rows:
        for _, stat in rows:
            row = [branch, stat.name]
            if show_email:
                row.append(stat.email)
            row.extend([stat.commits, stat.added, stat.deleted, stat.net, stat.files])
            writer.writerow(row)


def write_json_by_branch(
    branch_rows: List[Tuple[str, List[Tuple[str, AuthorStat]]]], show_email: bool
) -> None:
    payload = {}
    for branch, rows in branch_rows:
        items = []
        for _, stat in rows:
            obj = {
                "author": stat.name,
                "commits": stat.commits,
                "added": stat.added,
                "deleted": stat.deleted,
                "net": stat.net,
                "files": stat.files,
            }
            if show_email:
                obj["email"] = stat.email
            items.append(obj)
        payload[branch] = items
    print(json.dumps(payload, ensure_ascii=False, indent=2))


def write_commit_table_by_branch(
    branch_rows: List[Tuple[str, List[CommitStat]]], show_email: bool, full: bool = False
) -> None:
    if not branch_rows:
        print("No commit data found with current filters.")
        return

    for index, (branch, rows) in enumerate(branch_rows):
        print(f"[{branch}]")
        write_commit_table(rows, show_email=show_email, full=full)
        if index != len(branch_rows) - 1:
            print()


def write_commit_csv_by_branch(
    branch_rows: List[Tuple[str, List[CommitStat]]], show_email: bool, full: bool = False
) -> None:
    headers = [
        "branch",
        "time",
        "commit",
        "author",
        "since_prev",
        "add_delete",
        "files",
        "net",
    ]
    if full:
        if show_email:
            headers.append("email")
        headers.append("subject")

    writer = csv.writer(sys.stdout)
    writer.writerow(headers)
    for branch, commits in branch_rows:
        intervals = intervals_since_prev(commits)
        for idx, commit in enumerate(commits):
            row = [
                branch,
                commit.commit_time,
                commit.commit,
                commit.author,
                intervals[idx],
                add_delete_text(commit),
                commit.files,
                commit.net,
            ]
            if full:
                if show_email:
                    row.append(commit.email)
                row.append(commit.subject)
            writer.writerow(row)


def write_commit_json_by_branch(
    branch_rows: List[Tuple[str, List[CommitStat]]], show_email: bool, full: bool = False
) -> None:
    payload = {}
    for branch, commits in branch_rows:
        items = []
        intervals = intervals_since_prev(commits)
        for idx, commit in enumerate(commits):
            obj = {
                "time": commit.commit_time,
                "commit": commit.commit,
                "author": commit.author,
                "since_prev": intervals[idx],
                "add_delete": add_delete_text(commit),
                "files": commit.files,
                "net": commit.net,
            }
            if full:
                if show_email:
                    obj["email"] = commit.email
                obj.update(
                    {
                        "subject": commit.subject,
                    }
                )
            items.append(obj)
        payload[branch] = items
    print(json.dumps(payload, ensure_ascii=False, indent=2))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="contributor_stats.py",
        description="统计当前仓库每个协作者的提交代码量",
    )
    parser.add_argument(
        "--revision",
        default="HEAD",
        help="统计的提交范围起点，默认 HEAD（例如 main、HEAD~100..HEAD）",
    )
    parser.add_argument(
        "-a",
        "--all-refs",
        action="store_true",
        help="按分支统计所有本地/远程分支",
    )
    parser.add_argument("--since", help="起始时间，例如 2025-01-01")
    parser.add_argument("--until", help="结束时间，例如 2025-12-31")
    parser.add_argument("--no-merges", action="store_true", help="排除 merge 提交")
    parser.add_argument(
        "--view",
        choices=["author", "commit"],
        default="author",
        help="输出维度：author=按协作者汇总，commit=按提交明细",
    )
    parser.add_argument(
        "--group-by",
        choices=["name", "email", "name-email"],
        default="name-email",
        help="协作者分组方式",
    )
    parser.add_argument(
        "--sort-by",
        choices=["commits", "added", "deleted", "net", "files", "author"],
        default="net",
        help="排序字段",
    )
    parser.add_argument(
        "--commit-sort",
        choices=["time", "added", "deleted", "net", "files", "author"],
        default="time",
        help="commit 明细排序字段",
    )
    parser.add_argument(
        "--author-filter",
        help="作者过滤关键字（匹配作者名或邮箱）",
    )
    parser.add_argument(
        "--commit-full",
        action="store_true",
        help="commit 明细输出完整字段（默认输出 time/commit/author/since_prev/add_delete/files/net）",
    )
    parser.add_argument("--top", type=int, default=0, help="仅展示前 N 名，0 为展示全部")
    parser.add_argument(
        "--format",
        choices=["table", "csv", "json"],
        default="table",
        help="输出格式",
    )
    parser.add_argument(
        "paths",
        nargs="*",
        help="可选路径过滤，例如 lib test",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    show_email = args.group_by != "name" or args.view == "commit"

    def run_log(revision: Optional[str], detail: bool) -> Optional[str]:
        cmd = build_command(args, revision=revision, detail=detail)
        try:
            return subprocess.check_output(
                cmd,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
        except subprocess.CalledProcessError as exc:
            label = revision if revision else args.revision
            print(f"Failed to run git log for {label}: {exc}", file=sys.stderr)
            return None

    if args.all_refs:
        if args.view == "author":
            branch_rows: List[Tuple[str, List[Tuple[str, AuthorStat]]]] = []
            for branch in list_branches():
                raw = run_log(revision=branch, detail=False)
                if raw is None:
                    continue
                stats = parse_stats(raw, args.group_by)
                rows = sort_stats(stats, args.sort_by)
                if args.author_filter:
                    rows = [
                        item
                        for item in rows
                        if author_match(item[1].name, item[1].email, args.author_filter)
                    ]
                if args.top > 0:
                    rows = rows[: args.top]
                if rows:
                    branch_rows.append((branch, rows))

            if args.format == "table":
                write_table_by_branch(branch_rows, show_email=show_email)
            elif args.format == "csv":
                write_csv_by_branch(branch_rows, show_email=show_email)
            else:
                write_json_by_branch(branch_rows, show_email=show_email)
        else:
            branch_rows: List[Tuple[str, List[CommitStat]]] = []
            for branch in list_branches():
                raw = run_log(revision=branch, detail=True)
                if raw is None:
                    continue
                commits = parse_commit_stats(raw)
                if args.author_filter:
                    commits = [
                        item
                        for item in commits
                        if author_match(item.author, item.email, args.author_filter)
                    ]
                commits = sort_commit_stats(commits, args.commit_sort)
                if args.top > 0:
                    commits = commits[: args.top]
                if commits:
                    branch_rows.append((branch, commits))

            if args.format == "table":
                write_commit_table_by_branch(
                    branch_rows, show_email=show_email, full=args.commit_full
                )
            elif args.format == "csv":
                write_commit_csv_by_branch(
                    branch_rows, show_email=show_email, full=args.commit_full
                )
            else:
                write_commit_json_by_branch(
                    branch_rows, show_email=show_email, full=args.commit_full
                )
    else:
        raw = run_log(revision=None, detail=(args.view == "commit"))
        if raw is None:
            return 1

        if args.view == "author":
            stats = parse_stats(raw, args.group_by)
            rows = sort_stats(stats, args.sort_by)
            if args.author_filter:
                rows = [
                    item
                    for item in rows
                    if author_match(item[1].name, item[1].email, args.author_filter)
                ]
            if args.top > 0:
                rows = rows[: args.top]

            if args.format == "table":
                write_table(rows, show_email=show_email)
            elif args.format == "csv":
                write_csv(rows, show_email=show_email)
            else:
                write_json(rows, show_email=show_email)
        else:
            commits = parse_commit_stats(raw)
            if args.author_filter:
                commits = [
                    item
                    for item in commits
                    if author_match(item.author, item.email, args.author_filter)
                ]
            commits = sort_commit_stats(commits, args.commit_sort)
            if args.top > 0:
                commits = commits[: args.top]

            if args.format == "table":
                write_commit_table(commits, show_email=show_email, full=args.commit_full)
            elif args.format == "csv":
                write_commit_csv(commits, show_email=show_email, full=args.commit_full)
            else:
                write_commit_json(commits, show_email=show_email, full=args.commit_full)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
