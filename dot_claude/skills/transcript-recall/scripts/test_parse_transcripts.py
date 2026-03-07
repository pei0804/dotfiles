#!/usr/bin/env python3
"""Tests for parse_transcripts.py."""

import json
import subprocess
import tempfile
from pathlib import Path

SCRIPT = Path(__file__).parent / "parse_transcripts.py"


def run_parser(*args):
    result = subprocess.run(
        ["python3", str(SCRIPT), *args],
        capture_output=True, text=True,
    )
    assert result.returncode == 0, f"stderr: {result.stderr}"
    return json.loads(result.stdout)


def make_transcript(messages):
    """Create a temp JSONL transcript file."""
    lines = []
    for role, text in messages:
        obj = {
            "type": role,
            "message": {"role": role, "content": text},
            "timestamp": "2026-03-07T10:00:00Z",
        }
        lines.append(json.dumps(obj))
    f = tempfile.NamedTemporaryFile(mode="w", suffix=".jsonl", delete=False)
    f.write("\n".join(lines))
    f.flush()
    return f.name


def test_parse_single_file():
    path = make_transcript([
        ("user", "Fix the bug in main.py"),
        ("assistant", "I'll look at main.py and fix the issue."),
        ("user", "Thanks, also add tests"),
    ])
    data = run_parser("--file", path)
    assert data["metadata"]["message_count"] == 3
    assert data["messages"][0]["role"] == "user"
    assert "Fix the bug" in data["messages"][0]["text"]
    assert data["messages"][1]["role"] == "assistant"


def test_parse_empty_file():
    f = tempfile.NamedTemporaryFile(mode="w", suffix=".jsonl", delete=False)
    f.write("")
    f.flush()
    data = run_parser("--file", f.name)
    assert data["metadata"]["message_count"] == 0
    assert data["messages"] == []


def test_parse_non_conversation_types():
    """Non-user/assistant types should be skipped."""
    lines = [
        json.dumps({"type": "progress", "data": "compiling..."}),
        json.dumps({"type": "agent-setting", "setting": "foo"}),
        json.dumps({"type": "user", "message": {"role": "user", "content": "hello"}}),
    ]
    f = tempfile.NamedTemporaryFile(mode="w", suffix=".jsonl", delete=False)
    f.write("\n".join(lines))
    f.flush()
    data = run_parser("--file", f.name)
    assert data["metadata"]["message_count"] == 1
    assert data["messages"][0]["text"] == "hello"


def test_parse_content_blocks():
    """Content as array of blocks should be joined."""
    obj = {
        "type": "assistant",
        "message": {
            "role": "assistant",
            "content": [
                {"type": "text", "text": "First part."},
                {"type": "text", "text": "Second part."},
                {"type": "tool_use", "name": "Bash"},
            ],
        },
    }
    f = tempfile.NamedTemporaryFile(mode="w", suffix=".jsonl", delete=False)
    f.write(json.dumps(obj))
    f.flush()
    data = run_parser("--file", f.name)
    assert data["metadata"]["message_count"] == 1
    assert "First part." in data["messages"][0]["text"]
    assert "Second part." in data["messages"][0]["text"]


def test_truncation():
    """Very long messages should be truncated."""
    long_text = "x" * 5000
    path = make_transcript([("user", long_text)])
    data = run_parser("--file", path)
    assert len(data["messages"][0]["text"]) == 2000


def test_empty_messages_skipped():
    """Messages with empty content should be skipped."""
    path = make_transcript([
        ("user", ""),
        ("assistant", "   "),
        ("user", "actual content"),
    ])
    data = run_parser("--file", path)
    assert data["metadata"]["message_count"] == 1
    assert data["messages"][0]["text"] == "actual content"


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
