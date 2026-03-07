#!/usr/bin/env python3
"""Parse command-audit.log and output structured JSON."""

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("log_file")
    parser.add_argument("--after", default=None)
    parser.add_argument("--before", default=None)
    args = parser.parse_args()

    after_date = datetime.fromisoformat(args.after).date() if args.after else None
    before_date = datetime.fromisoformat(args.before).date() if args.before else None

    entries = []
    with open(args.log_file) as f:
        for line in f:
            line = line.rstrip("\n")
            m = re.match(r"^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})\s+(\S+)\s+(.*)", line)
            if not m:
                continue
            ts_str, cwd, cmd = m.groups()
            ts = datetime.fromisoformat(ts_str)

            if after_date and ts.date() < after_date:
                continue
            if before_date and ts.date() > before_date:
                continue

            entries.append({"timestamp": ts_str, "cwd": cwd, "command": cmd, "dt": ts})

    if not entries:
        print(json.dumps({"total_commands": 0, "message": "No entries found"}))
        return

    total = len(entries)
    first_ts = entries[0]["dt"]
    last_ts = entries[-1]["dt"]

    # Project breakdown
    project_counter = Counter()
    project_commands = defaultdict(list)
    for e in entries:
        parts = e["cwd"].rstrip("/").split("/")
        project = "/".join(parts[-2:]) if len(parts) >= 2 else e["cwd"]
        project_counter[project] += 1
        project_commands[project].append(e["command"])

    # Command frequency
    cmd_counter = Counter()
    for e in entries:
        first = e["command"].split()[0] if e["command"].strip() else "(empty)"
        first = first.split("/")[-1]
        cmd_counter[first] += 1

    # Hourly distribution
    hour_counter = Counter()
    for e in entries:
        hour_counter[e["dt"].hour] += 1

    # Dangerous commands
    dangerous_patterns = [
        "--force", "reset --hard", "drop table", "truncate",
    ]
    dangerous = []
    for e in entries:
        for p in dangerous_patterns:
            if p.lower() in e["command"].lower():
                dangerous.append({
                    "timestamp": e["timestamp"],
                    "cwd": e["cwd"],
                    "command": e["command"],
                    "pattern": p,
                })
                break

    result = {
        "period": {"from": first_ts.isoformat(), "to": last_ts.isoformat()},
        "total_commands": total,
        "projects": [
            {
                "name": p,
                "count": c,
                "sample_commands": project_commands[p][:5],
            }
            for p, c in project_counter.most_common(20)
        ],
        "top_commands": [
            {"command": c, "count": n} for c, n in cmd_counter.most_common(15)
        ],
        "hourly_distribution": {
            str(h): hour_counter.get(h, 0) for h in range(24)
        },
        "dangerous_commands": dangerous,
    }

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
