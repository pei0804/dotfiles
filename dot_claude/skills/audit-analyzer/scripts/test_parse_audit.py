#!/usr/bin/env python3
"""Tests for parse_audit.py."""

import json
import subprocess
import tempfile
import textwrap
from pathlib import Path

SCRIPT = Path(__file__).parent / "parse_audit.py"


def run_parser(log_content, *args):
    with tempfile.NamedTemporaryFile(mode="w", suffix=".log", delete=False) as f:
        f.write(log_content)
        f.flush()
        result = subprocess.run(
            ["python3", str(SCRIPT), f.name, *args],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"stderr: {result.stderr}"
        return json.loads(result.stdout)


SAMPLE_LOG = textwrap.dedent("""\
    2026-03-07T10:00:00 /Users/user/project-a git status
    2026-03-07T10:05:00 /Users/user/project-a git commit -m "feat: add feature"
    2026-03-07T11:00:00 /Users/user/project-b npm test
    2026-03-07T14:00:00 /Users/user/project-a git push origin main --force
    2026-03-08T09:00:00 /Users/user/project-c python3 main.py
    2026-03-08T15:00:00 /Users/user/project-a git reset --hard HEAD~1
""")


def test_total_commands():
    data = run_parser(SAMPLE_LOG)
    assert data["total_commands"] == 6


def test_period():
    data = run_parser(SAMPLE_LOG)
    assert data["period"]["from"] == "2026-03-07T10:00:00"
    assert data["period"]["to"] == "2026-03-08T15:00:00"


def test_after_filter():
    data = run_parser(SAMPLE_LOG, "--after", "2026-03-08")
    assert data["total_commands"] == 2


def test_before_filter():
    data = run_parser(SAMPLE_LOG, "--before", "2026-03-07")
    assert data["total_commands"] == 4


def test_date_range_filter():
    data = run_parser(SAMPLE_LOG, "--after", "2026-03-07", "--before", "2026-03-07")
    assert data["total_commands"] == 4


def test_project_grouping():
    data = run_parser(SAMPLE_LOG)
    projects = {p["name"]: p["count"] for p in data["projects"]}
    assert projects["user/project-a"] == 4
    assert projects["user/project-b"] == 1
    assert projects["user/project-c"] == 1


def test_top_commands():
    data = run_parser(SAMPLE_LOG)
    cmds = {c["command"]: c["count"] for c in data["top_commands"]}
    assert cmds["git"] == 4
    assert cmds["npm"] == 1
    assert cmds["python3"] == 1


def test_hourly_distribution():
    data = run_parser(SAMPLE_LOG)
    dist = data["hourly_distribution"]
    assert dist["10"] == 2
    assert dist["11"] == 1
    assert dist["14"] == 1
    assert dist["9"] == 1
    assert dist["15"] == 1
    assert dist["0"] == 0


def test_dangerous_commands_detected():
    data = run_parser(SAMPLE_LOG)
    dangerous = data["dangerous_commands"]
    assert len(dangerous) == 2
    patterns = [d["pattern"] for d in dangerous]
    assert "--force" in patterns
    assert "reset --hard" in patterns


def test_dangerous_commands_content():
    data = run_parser(SAMPLE_LOG)
    dangerous = data["dangerous_commands"]
    force_cmd = next(d for d in dangerous if d["pattern"] == "--force")
    assert "git push origin main --force" in force_cmd["command"]


def test_empty_log():
    data = run_parser("")
    assert data["total_commands"] == 0


def test_no_match_filter():
    data = run_parser(SAMPLE_LOG, "--after", "2099-01-01")
    assert data["total_commands"] == 0


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    passed = failed = 0
    for t in tests:
        try:
            t()
            print(f"  PASS  {t.__name__}")
            passed += 1
        except Exception as e:
            print(f"  FAIL  {t.__name__}: {e}")
            failed += 1
    print(f"\n{passed} passed, {failed} failed")
    exit(1 if failed else 0)
