#!/usr/bin/env python3
"""
이 프로젝트가 사용하는 MCP 서버를 Claude → Codex + Gemini로 동기화한다.

정의 출처:  ~/.claude.json  (Claude Code의 mcpServers)
대상:       codex CLI, gemini CLI

기본 동작:
  1) Claude 설정에서 PROJECT_SERVERS 목록의 서버 정의를 읽는다.
  2) codex / gemini에 동일한 정의(env 포함)를 add 한다.
  3) 같은 이름의 정의가 이미 있으면 --force 가 있을 때만 remove 후 재등록.

Usage:
  python3 scripts/sync-project-mcp.py                # 동기화
  python3 scripts/sync-project-mcp.py --dry-run      # 실제 변경 없이 명령만 출력
  python3 scripts/sync-project-mcp.py --force        # 기존 정의 덮어쓰기
  python3 scripts/sync-project-mcp.py --only codex   # 한 쪽만
  python3 scripts/sync-project-mcp.py --servers apidog,pencil
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict, Iterable, List, Sequence

CLAUDE_CONFIG = Path.home() / ".claude.json"

# 이 프로젝트의 SKILL.md들이 의존하는 MCP 서버 목록.
# (mcp__<name>__ 호출 또는 스킬 흐름상 필요한 외부 시스템)
PROJECT_SERVERS: List[str] = [
    "apidog",
    "mcp-atlassian-nestads",
    "pencil",
    "bitbucket-nestads",
]

SECRET_KEY_HINTS = ("TOKEN", "PASSWORD", "SECRET", "KEY", "COOKIE")


def mask(value: str) -> str:
    if not value:
        return ""
    if len(value) <= 6:
        return "***"
    return value[:2] + "***" + value[-2:]


def is_secret(env_key: str) -> bool:
    upper = env_key.upper()
    return any(h in upper for h in SECRET_KEY_HINTS)


def load_definitions(names: Sequence[str]) -> Dict[str, dict]:
    if not CLAUDE_CONFIG.exists():
        sys.exit(f"error: Claude config not found at {CLAUDE_CONFIG}")
    data = json.loads(CLAUDE_CONFIG.read_text())
    servers = data.get("mcpServers") or {}
    missing = [n for n in names if n not in servers]
    if missing:
        sys.exit(f"error: not defined in Claude: {', '.join(missing)}")
    return {n: servers[n] for n in names}


def check_cli(cli: str) -> bool:
    return shutil.which(cli) is not None


def cli_already_has(cli: str, name: str) -> bool:
    try:
        r = subprocess.run(
            [cli, "mcp", "list"], capture_output=True, text=True, check=False
        )
    except FileNotFoundError:
        return False
    # 단순 substring 매칭 — 두 CLI 모두 "name:" 또는 "name " 형태로 출력
    out = (r.stdout or "") + (r.stderr or "")
    for line in out.splitlines():
        stripped = line.strip()
        if stripped.startswith(name + ":") or stripped.startswith(name + " "):
            return True
    return False


def build_codex_cmd(name: str, definition: dict) -> List[str]:
    cmd = ["codex", "mcp", "add", name]
    for k, v in (definition.get("env") or {}).items():
        cmd += ["--env", f"{k}={v}"]
    cmd.append("--")
    cmd.append(definition["command"])
    cmd.extend(definition.get("args") or [])
    return cmd


def build_gemini_cmd(name: str, definition: dict) -> List[str]:
    # gemini mcp add [-e KEY=value]... -s user <name> <command> [args...]
    cmd = ["gemini", "mcp", "add", "-s", "user"]
    for k, v in (definition.get("env") or {}).items():
        cmd += ["-e", f"{k}={v}"]
    cmd += [name, definition["command"]]
    cmd.extend(definition.get("args") or [])
    return cmd


def display(cmd: Sequence[str], env: Dict[str, str] | None) -> str:
    """env 값을 마스킹해서 출력용 문자열로 변환."""
    out: List[str] = []
    i = 0
    while i < len(cmd):
        tok = cmd[i]
        if tok in ("--env", "-e") and i + 1 < len(cmd):
            kv = cmd[i + 1]
            if "=" in kv:
                k, v = kv.split("=", 1)
                shown = mask(v) if is_secret(k) else v
                out += [tok, f"{k}={shown}"]
            else:
                out += [tok, kv]
            i += 2
        else:
            out.append(tok)
            i += 1
    return " ".join(out)


def remove_quiet(cli: str, name: str) -> None:
    subprocess.run(
        [cli, "mcp", "remove", name],
        capture_output=True,
        text=True,
        check=False,
    )


def sync_one(
    cli: str,
    name: str,
    definition: dict,
    *,
    dry_run: bool,
    force: bool,
) -> str:
    if cli == "codex":
        cmd = build_codex_cmd(name, definition)
    elif cli == "gemini":
        cmd = build_gemini_cmd(name, definition)
    else:
        return f"skip ({cli}: unsupported)"

    has = cli_already_has(cli, name)
    if has and not force:
        return f"skip (already exists; use --force to overwrite)"

    rendered = display(cmd, definition.get("env"))
    if dry_run:
        prefix = "would remove + " if has else ""
        return f"DRY-RUN: {prefix}{rendered}"

    if has and force:
        remove_quiet(cli, name)
    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        stderr = (r.stderr or r.stdout or "").strip().splitlines()
        tail = " | ".join(stderr[-3:]) if stderr else ""
        return f"FAIL (exit {r.returncode}): {tail}"
    return "ok"


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Sync project MCP servers from Claude → Codex + Gemini"
    )
    p.add_argument("--dry-run", action="store_true", help="명령만 출력, 실제 변경 없음")
    p.add_argument("--force", action="store_true", help="기존 정의가 있어도 덮어쓰기")
    p.add_argument(
        "--only",
        choices=("codex", "gemini"),
        help="한쪽 CLI만 동기화",
    )
    p.add_argument(
        "--servers",
        help=f"동기화할 서버 이름(쉼표 구분). 기본: {','.join(PROJECT_SERVERS)}",
    )
    return p.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(list(argv) if argv is not None else sys.argv[1:])
    names = (
        [s.strip() for s in args.servers.split(",") if s.strip()]
        if args.servers
        else PROJECT_SERVERS
    )
    defs = load_definitions(names)

    targets = ("codex", "gemini") if not args.only else (args.only,)

    for cli in targets:
        print(f"\n=== {cli} ===")
        if not check_cli(cli):
            print(f"{cli}: NOT INSTALLED on PATH — skip")
            continue
        for name in names:
            status = sync_one(
                cli,
                name,
                defs[name],
                dry_run=args.dry_run,
                force=args.force,
            )
            print(f"  {name:<28s} {status}")

    print("\nDone." if not args.dry_run else "\n(dry-run) Nothing changed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
