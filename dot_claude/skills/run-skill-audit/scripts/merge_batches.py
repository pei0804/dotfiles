#!/usr/bin/env python3
"""
merge_batches.py — Merge batch-audit-*.json files into a single audit-report.json.

Handles field name variants across batches (sub-agents may use slightly
different names for the same fields). Recalculates accuracy per skill.

Usage:
    python3 merge_batches.py --workspace <path>

Output:
    <workspace>/audit-report.json
"""

import json
import glob
import argparse


# Field name variants that sub-agents might use
FIRE_KEYS = ["fire_count", "total_fires", "fires"]
CORRECT_KEYS = ["correct", "correct_fires", "correct_count"]
FP_KEYS = ["false_positive", "false_positives", "fp"]
FN_KEYS = ["false_negative", "false_negatives", "fn"]
CONFUSED_KEYS = ["confused", "confused_count"]
EXPLICIT_KEYS = ["explicit_invocation", "explicit_invocations", "explicit"]


def get_stat(stats: dict, key_variants: list, default: int = 0) -> int:
    """Extract a stat value trying multiple possible field names."""
    for k in key_variants:
        if k in stats:
            return stats[k]
    return default


def main():
    parser = argparse.ArgumentParser(description="Merge batch audit results")
    parser.add_argument("--workspace", required=True, help="Workspace directory")
    args = parser.parse_args()

    batch_files = sorted(glob.glob(f"{args.workspace}/batch-audit-*.json"))
    if not batch_files:
        print("ERROR: No batch-audit-*.json files found")
        return 1

    skill_map = {}
    meta = {
        "sessions_analyzed": 0,
        "turns_analyzed": 0,
        "skill_fires_analyzed": 0,
        "skills_evaluated": 0,
        "batch_count": len(batch_files),
    }
    all_competition = []
    all_gaps = []

    for bf in batch_files:
        try:
            data = json.load(open(bf))
        except json.JSONDecodeError as e:
            print(f"WARNING: Failed to parse {bf}: {e}")
            continue

        m = data.get("meta", {})
        meta["sessions_analyzed"] += m.get("sessions_analyzed", 0)
        meta["turns_analyzed"] += m.get("turns_analyzed", 0)
        meta["skill_fires_analyzed"] += m.get(
            "skill_fires_analyzed", m.get("total_skill_fires", 0)
        )

        # skill_reports can be a list (common) or dict
        reports = data.get("skill_reports", [])
        if isinstance(reports, dict):
            reports = [{"skill_name": k, **v} for k, v in reports.items()]

        for report in reports:
            name = report.get("skill_name", "")
            stats = report.get("stats", {})
            if name not in skill_map:
                skill_map[name] = {
                    "skill_name": name,
                    "skill_path": report.get("skill_path", ""),
                    "description_excerpt": report.get("description_excerpt", ""),
                    "stats": {
                        "total_fires": 0,
                        "correct_fires": 0,
                        "false_positives": 0,
                        "false_negatives": 0,
                        "accuracy": None,
                    },
                    "health_assessment": "",
                    "incidents": [],
                }
            sr = skill_map[name]
            sr["stats"]["total_fires"] += get_stat(stats, FIRE_KEYS)
            sr["stats"]["correct_fires"] += get_stat(stats, CORRECT_KEYS)
            sr["stats"]["false_positives"] += get_stat(stats, FP_KEYS)
            sr["stats"]["false_negatives"] += get_stat(stats, FN_KEYS)
            sr["incidents"].extend(report.get("incidents", []))
            if report.get("health_assessment"):
                sr["health_assessment"] = report["health_assessment"]

        all_competition.extend(data.get("competition_pairs", []))
        all_gaps.extend(data.get("coverage_gaps", []))

    # Recalculate accuracy
    for sr in skill_map.values():
        s = sr["stats"]
        total = s["correct_fires"] + s["false_positives"] + s["false_negatives"]
        s["accuracy"] = round(s["correct_fires"] / total, 3) if total > 0 else None

    # Deduplicate competition pairs
    seen = set()
    unique_pairs = []
    for p in all_competition:
        key = tuple(sorted([p.get("skill_a", ""), p.get("skill_b", "")]))
        if key not in seen:
            seen.add(key)
            unique_pairs.append(p)

    # Deduplicate coverage gaps
    seen_gaps = set()
    unique_gaps = []
    for g in all_gaps:
        key = g.get("unmet_intent", "") or g.get("description", "") or str(g)
        if key not in seen_gaps:
            seen_gaps.add(key)
            unique_gaps.append(g)

    meta["skills_evaluated"] = len(skill_map)

    output = {
        "meta": meta,
        "skill_reports": list(skill_map.values()),
        "competition_pairs": unique_pairs,
        "coverage_gaps": unique_gaps,
    }

    output_path = f"{args.workspace}/audit-report.json"
    with open(output_path, "w") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    # Print summary
    print(f"Merged {len(batch_files)} batches → {output_path}")
    print(f"Sessions: {meta['sessions_analyzed']}, Turns: {meta['turns_analyzed']}")
    print(f"Skills: {meta['skills_evaluated']}, Competition pairs: {len(unique_pairs)}")
    print()
    for sr in sorted(skill_map.values(), key=lambda x: -x["stats"]["total_fires"]):
        s = sr["stats"]
        acc = f"{s['accuracy']:.1%}" if s["accuracy"] is not None else "N/A"
        print(
            f"  {sr['skill_name']}: fires={s['total_fires']}, "
            f"correct={s['correct_fires']}, fp={s['false_positives']}, "
            f"fn={s['false_negatives']}, accuracy={acc}"
        )


if __name__ == "__main__":
    main()
