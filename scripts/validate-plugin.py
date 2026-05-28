#!/usr/bin/env python3
"""frontend-poc-pipeline 마켓플레이스 무결성 검증.

CI와 로컬 양쪽에서 동일하게 돌릴 수 있는 stdlib-only 검증 스크립트.
실패 시 종료 코드 1, 성공 시 0.

검사 항목:
  1. marketplace.json / plugin.json 파싱 + 버전 일치
  2. marketplace.json.plugins[].source 경로 실존
  3. hooks/hooks.json 파싱 + 참조 스크립트 실존·실행권한·bash -n 통과
  4. skills/*/SKILL.md 존재 + YAML frontmatter(name, description) 파싱
  5. SKILL.md name 필드와 디렉토리명 일치
  6. AGENTS.md / CLAUDE.md / GEMINI.md 라우팅 테이블의 스킬 경로가 실존
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MARKETPLACE = REPO_ROOT / ".claude-plugin" / "marketplace.json"
PLUGIN_ROOT = REPO_ROOT / "plugins" / "frontend-poc-pipeline"
PLUGIN_MANIFEST = PLUGIN_ROOT / ".claude-plugin" / "plugin.json"
HOOKS_JSON = PLUGIN_ROOT / "hooks" / "hooks.json"
SKILLS_DIR = PLUGIN_ROOT / "skills"
ROUTING_DOCS = ["AGENTS.md", "CLAUDE.md", "GEMINI.md"]

GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
RESET = "\033[0m"

errors: list[str] = []
warnings: list[str] = []
checks_passed = 0


def fail(msg: str) -> None:
    errors.append(msg)
    print(f"{RED}✗ {msg}{RESET}")


def warn(msg: str) -> None:
    warnings.append(msg)
    print(f"{YELLOW}! {msg}{RESET}")


def ok(msg: str) -> None:
    global checks_passed
    checks_passed += 1
    print(f"{GREEN}✓ {msg}{RESET}")


def load_json(path: Path) -> dict | None:
    if not path.exists():
        fail(f"missing file: {path.relative_to(REPO_ROOT)}")
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {path.relative_to(REPO_ROOT)}: {exc}")
        return None


def parse_frontmatter(text: str) -> dict[str, str] | None:
    """YAML frontmatter의 단일/멀티라인 스칼라만 처리. 라이브러리 없이도 충분."""
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end == -1:
        return None
    body = text[4:end]
    out: dict[str, str] = {}
    current_key: str | None = None
    buf: list[str] = []
    for raw in body.splitlines():
        if not raw.strip():
            if current_key is not None:
                buf.append("")
            continue
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$", raw)
        if m and not raw.startswith(" "):
            if current_key is not None:
                out[current_key] = "\n".join(buf).strip()
            current_key = m.group(1)
            val = m.group(2)
            buf = [] if val in {"|", ">", "|-", ">-"} else [val]
        else:
            if current_key is not None:
                buf.append(raw.strip())
    if current_key is not None:
        out[current_key] = "\n".join(buf).strip()
    # 따옴표 제거
    for k, v in list(out.items()):
        if len(v) >= 2 and v[0] == v[-1] and v[0] in {'"', "'"}:
            out[k] = v[1:-1]
    return out


def check_manifests() -> None:
    marketplace = load_json(MARKETPLACE)
    manifest = load_json(PLUGIN_MANIFEST)
    if not marketplace or not manifest:
        return

    mp_version = marketplace.get("metadata", {}).get("version")
    pl_version = manifest.get("version")
    if mp_version and pl_version and mp_version == pl_version:
        ok(f"version aligned: {mp_version}")
    else:
        fail(f"version mismatch: marketplace={mp_version} plugin={pl_version}")

    for entry in marketplace.get("plugins", []):
        source = entry.get("source", "")
        rel = source.lstrip("./")
        target = REPO_ROOT / rel
        if target.exists() and target.is_dir():
            ok(f"plugin source exists: {source}")
        else:
            fail(f"plugin source missing: {source}")


def check_hooks() -> None:
    if not HOOKS_JSON.exists():
        ok("hooks.json absent — plugin defines no hooks")
        return
    hooks_doc = load_json(HOOKS_JSON)
    if not hooks_doc:
        return
    referenced: set[Path] = set()
    pattern = re.compile(r'\${CLAUDE_PLUGIN_ROOT}/(hooks/[\w./-]+\.sh)')
    for stage, groups in hooks_doc.get("hooks", {}).items():
        for group in groups:
            for hook in group.get("hooks", []):
                cmd = hook.get("command", "")
                for m in pattern.finditer(cmd):
                    referenced.add(PLUGIN_ROOT / m.group(1))

    if not referenced:
        warn("hooks.json: ${CLAUDE_PLUGIN_ROOT} 참조가 없습니다 (검증 대상 없음)")
        return

    for script in sorted(referenced):
        if not script.exists():
            fail(f"hook script missing: {script.relative_to(REPO_ROOT)}")
            continue
        if not script.stat().st_mode & 0o111:
            fail(f"hook script not executable: {script.relative_to(REPO_ROOT)}")
            continue
        result = subprocess.run(
            ["bash", "-n", str(script)], capture_output=True, text=True
        )
        if result.returncode != 0:
            fail(
                f"hook script syntax error: {script.relative_to(REPO_ROOT)}\n{result.stderr.strip()}"
            )
        else:
            ok(f"hook script OK: {script.relative_to(REPO_ROOT)}")


def check_skills() -> set[str]:
    if not SKILLS_DIR.exists():
        fail(f"skills directory missing: {SKILLS_DIR.relative_to(REPO_ROOT)}")
        return set()
    skill_names: set[str] = set()
    for entry in sorted(SKILLS_DIR.iterdir()):
        if not entry.is_dir() or entry.name.startswith("."):
            continue
        skill_md = entry / "SKILL.md"
        if not skill_md.exists():
            fail(f"SKILL.md missing: skills/{entry.name}/")
            continue
        fm = parse_frontmatter(skill_md.read_text(encoding="utf-8"))
        if fm is None:
            fail(f"SKILL.md frontmatter missing or invalid: skills/{entry.name}/")
            continue
        name = fm.get("name", "").strip()
        description = fm.get("description", "").strip()
        if not name:
            fail(f"SKILL.md missing 'name' field: skills/{entry.name}/")
            continue
        if not description:
            fail(f"SKILL.md missing 'description' field: skills/{entry.name}/")
            continue
        if name != entry.name:
            fail(
                f"SKILL.md name '{name}' != directory '{entry.name}': skills/{entry.name}/"
            )
            continue
        ok(f"skill OK: {entry.name}")
        skill_names.add(entry.name)
    return skill_names


def check_routing_drift() -> None:
    """세 라우팅 doc의 'plugins/.../SKILL.md' 참조 라인이 동일한지 확인.

    AGENTS.md / CLAUDE.md / GEMINI.md 중 하나만 수정하고 다른 둘을 잊는
    회귀를 잡기 위함. 코드 펜스 안의 placeholder는 무시한다.
    """
    fenced = re.compile(r"```.*?```", re.DOTALL)
    line_sets: dict[str, list[str]] = {}
    for doc in ROUTING_DOCS:
        path = REPO_ROOT / doc
        if not path.exists():
            continue
        text = fenced.sub("", path.read_text(encoding="utf-8"))
        rows = []
        for raw in text.splitlines():
            stripped = raw.strip()
            if "/SKILL.md" in stripped and stripped.startswith("|"):
                rows.append(re.sub(r"\s+", " ", stripped))
        line_sets[doc] = sorted(rows)

    docs = sorted(line_sets)
    if len(docs) < 2:
        return
    reference = line_sets[docs[0]]
    drift_found = False
    for doc in docs[1:]:
        if line_sets[doc] != reference:
            only_a = sorted(set(reference) - set(line_sets[doc]))
            only_b = sorted(set(line_sets[doc]) - set(reference))
            details = []
            if only_a:
                details.append(f"only in {docs[0]}: {only_a}")
            if only_b:
                details.append(f"only in {doc}: {only_b}")
            fail(f"routing table drift {docs[0]} vs {doc}\n   " + "\n   ".join(details))
            drift_found = True
    if not drift_found:
        ok(f"routing tables aligned across {', '.join(docs)}")


def check_routing(skill_names: set[str]) -> None:
    if not skill_names:
        return
    skill_ref_pattern = re.compile(
        r"plugins/frontend-poc-pipeline/skills/([\w-]+)/SKILL\.md"
    )
    fenced = re.compile(r"```.*?```", re.DOTALL)
    for doc in ROUTING_DOCS:
        path = REPO_ROOT / doc
        if not path.exists():
            warn(f"routing doc missing: {doc}")
            continue
        text = fenced.sub("", path.read_text(encoding="utf-8"))
        refs = set(skill_ref_pattern.findall(text))
        unknown = refs - skill_names
        if unknown:
            fail(f"{doc}: 알 수 없는 스킬 참조 {sorted(unknown)}")
            continue
        ok(f"{doc}: routing table references {len(refs)} known skills")


def main() -> int:
    print(f"=== frontend-poc-pipeline plugin validator ===")
    print(f"repo: {REPO_ROOT}\n")
    check_manifests()
    check_hooks()
    skill_names = check_skills()
    check_routing(skill_names)
    check_routing_drift()

    print()
    print(f"checks passed: {checks_passed}")
    if warnings:
        print(f"warnings: {len(warnings)}")
    if errors:
        print(f"{RED}FAILED with {len(errors)} error(s){RESET}")
        return 1
    print(f"{GREEN}OK{RESET}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
