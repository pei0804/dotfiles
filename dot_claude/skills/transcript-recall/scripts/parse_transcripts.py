#!/usr/bin/env python3
"""Parse transcript JSONL files and extract conversation summaries.

Sources:
  1. ~/.claude/transcripts/ (PreCompact backups)
  2. ~/.claude/projects/*/  (live session transcripts)

Usage:
  parse_transcripts.py [--after YYYY-MM-DD] [--before YYYY-MM-DD]
                       [--project KEYWORD] [--list] [--file PATH]
"""

import argparse
import json
import os
import re
from datetime import datetime
from glob import glob
from pathlib import Path


def find_transcripts():
    """Find all transcript JSONL files from both backup and live sources."""
    home = Path.home()
    files = []

    # 1. PreCompact backups
    backup_dir = home / ".claude" / "transcripts"
    if backup_dir.exists():
        for f in backup_dir.glob("*.jsonl"):
            # filename: 20260307-223835_session-id_trigger.jsonl
            m = re.match(r"^(\d{8}-\d{6})_", f.name)
            ts = None
            if m:
                ts = datetime.strptime(m.group(1), "%Y%m%d-%H%M%S")
            files.append({"path": str(f), "timestamp": ts, "source": "backup"})

    # 2. Live session transcripts
    projects_dir = home / ".claude" / "projects"
    if projects_dir.exists():
        for jsonl in projects_dir.glob("*/*.jsonl"):
            # Skip subagent transcripts
            if "subagents" in str(jsonl):
                continue
            stat = jsonl.stat()
            ts = datetime.fromtimestamp(stat.st_mtime)
            files.append({"path": str(jsonl), "timestamp": ts, "source": "session"})

    files.sort(key=lambda x: x["timestamp"] or datetime.min, reverse=True)
    return files


def extract_conversation(path, max_messages=50):
    """Extract user/assistant messages from a JSONL transcript."""
    messages = []
    metadata = {"path": path, "types": set()}

    with open(path) as f:
        for line in f:
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            t = obj.get("type", "")
            metadata["types"].add(t)

            if t not in ("user", "assistant"):
                continue

            msg = obj.get("message", {})
            if not isinstance(msg, dict):
                continue

            role = msg.get("role", t)
            content = msg.get("content", "")

            if isinstance(content, str):
                text = content
            elif isinstance(content, list):
                parts = []
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "text":
                        parts.append(block.get("text", ""))
                text = "\n".join(parts)
            else:
                text = str(content)

            text = text.strip()
            if not text:
                continue

            ts = obj.get("timestamp")

            messages.append({
                "role": role,
                "text": text[:2000],  # truncate very long messages
                "timestamp": ts,
            })

            if len(messages) >= max_messages:
                break

    metadata["types"] = list(metadata["types"])
    metadata["message_count"] = len(messages)
    return messages, metadata


def project_name_from_path(path):
    """Extract a readable project name from transcript path."""
    # From backup: just the filename
    if "/transcripts/" in path:
        return Path(path).stem

    # From session: parent dir name encodes the project path
    parent = Path(path).parent.name
    # Format: -Users-user-path-to-project
    parts = parent.split("-")
    # Find the meaningful part (after username)
    meaningful = []
    skip = True
    for i, p in enumerate(parts):
        if not p:
            continue
        if skip and p in ("Users", "home"):
            continue
        if skip and i > 0:
            skip = False
            continue  # skip username
        meaningful.append(p)

    return "/".join(meaningful[-3:]) if meaningful else parent


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--after", default=None)
    parser.add_argument("--before", default=None)
    parser.add_argument("--project", default=None, help="Filter by project keyword")
    parser.add_argument("--list", action="store_true", help="List transcripts only")
    parser.add_argument("--file", default=None, help="Parse a specific transcript file")
    args = parser.parse_args()

    after_date = datetime.fromisoformat(args.after).date() if args.after else None
    before_date = datetime.fromisoformat(args.before).date() if args.before else None

    if args.file:
        messages, metadata = extract_conversation(args.file)
        print(json.dumps({
            "file": args.file,
            "metadata": metadata,
            "messages": messages,
        }, ensure_ascii=False, indent=2))
        return

    transcripts = find_transcripts()

    # Apply filters
    filtered = []
    for t in transcripts:
        ts = t["timestamp"]
        if ts:
            if after_date and ts.date() < after_date:
                continue
            if before_date and ts.date() > before_date:
                continue

        project = project_name_from_path(t["path"])
        t["project"] = project

        if args.project and args.project.lower() not in project.lower():
            continue

        filtered.append(t)

    if args.list:
        listing = []
        for t in filtered[:30]:
            listing.append({
                "project": t["project"],
                "timestamp": t["timestamp"].isoformat() if t["timestamp"] else None,
                "source": t["source"],
                "path": t["path"],
            })
        print(json.dumps({"total": len(filtered), "transcripts": listing},
                         ensure_ascii=False, indent=2))
        return

    # Full extraction for top N transcripts
    results = []
    for t in filtered[:10]:
        messages, metadata = extract_conversation(t["path"])
        results.append({
            "project": t["project"],
            "timestamp": t["timestamp"].isoformat() if t["timestamp"] else None,
            "source": t["source"],
            "path": t["path"],
            "message_count": metadata["message_count"],
            "messages": messages,
        })

    print(json.dumps({"total": len(filtered), "shown": len(results),
                       "transcripts": results}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
