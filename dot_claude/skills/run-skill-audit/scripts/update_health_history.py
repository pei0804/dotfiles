#!/usr/bin/env python3
"""
update_health_history.py — Append current run summary to health-history.json.

Reads audit-report.json and portfolio-analysis.json from the workspace,
creates a summary entry, and appends to the shared health-history.json.
Shows delta from previous run if available.

Usage:
    python3 update_health_history.py --workspace <path> --base-dir <path>

Output:
    <base_dir>/health-history.json (append)
"""

import json
import os
import argparse
from datetime import datetime


def main():
    parser = argparse.ArgumentParser(description="Update health history")
    parser.add_argument("--workspace", required=True)
    parser.add_argument("--base-dir", required=True)
    args = parser.parse_args()

    history_file = f"{args.base_dir}/health-history.json"

    # Load existing history
    if os.path.exists(history_file):
        history = json.load(open(history_file))
    else:
        history = []

    # Read current run data
    audit = json.load(open(f"{args.workspace}/audit-report.json"))
    meta = audit.get("meta", {})

    # Try to read portfolio analysis for health score
    portfolio_file = f"{args.workspace}/portfolio-analysis.json"
    portfolio_health = "unknown"
    routing_accuracy_avg = 0.0
    token_total = 0

    if os.path.exists(portfolio_file):
        portfolio = json.load(open(portfolio_file))
        ph = portfolio.get("portfolio_health", {})
        portfolio_health = ph.get("overall_score", "unknown")
        routing_accuracy_avg = ph.get("routing_accuracy_avg", 0.0)
        ab = portfolio.get("attention_budget", {})
        token_total = ab.get("total_tokens", 0)

    # Count patches if improvement-proposals.json exists
    proposals_file = f"{args.workspace}/improvement-proposals.json"
    patches_proposed = 0
    if os.path.exists(proposals_file):
        proposals = json.load(open(proposals_file))
        patches_proposed = len(proposals.get("patches", []))

    entry = {
        "timestamp": datetime.now().isoformat(),
        "sessions_analyzed": meta.get("sessions_analyzed", 0),
        "turns_analyzed": meta.get("turns_analyzed", 0),
        "portfolio_health": portfolio_health,
        "routing_accuracy_avg": routing_accuracy_avg,
        "total_description_tokens": token_total,
        "competition_conflicts": len(audit.get("competition_pairs", [])),
        "coverage_gaps": len(audit.get("coverage_gaps", [])),
        "skills_audited": meta.get("skills_evaluated", 0),
        "patches_proposed": patches_proposed,
    }

    # Show delta
    if history:
        prev = history[-1]
        prev_acc = prev.get("routing_accuracy_avg", 0)
        print(f"前回: {prev_acc:.1%} → 今回: {entry['routing_accuracy_avg']:.1%}")
        delta = entry["routing_accuracy_avg"] - prev_acc
        print(f"変化: {delta:+.1%}")
    else:
        print("初回実行（比較対象なし）")

    history.append(entry)

    with open(history_file, "w") as f:
        json.dump(history, f, indent=2, ensure_ascii=False)
    print(f"Updated: {history_file}")


if __name__ == "__main__":
    main()
