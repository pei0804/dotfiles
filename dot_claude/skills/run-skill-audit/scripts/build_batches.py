#!/usr/bin/env python3
"""
build_batches.py — Build routing-audit batches from transcripts and skill manifest.

Groups sessions by their visible skill set (global-only vs project-local),
then caps total batch count via greedy merging.

Usage:
    python3 build_batches.py --workspace <path> [--batch-size 60] [--max-batches 12]

Output:
    <workspace>/batches.json
"""

import json
import argparse
from collections import defaultdict


def main():
    parser = argparse.ArgumentParser(description="Build routing-audit batches")
    parser.add_argument("--workspace", required=True, help="Workspace directory")
    parser.add_argument("--batch-size", type=int, default=60, help="Max sessions per batch")
    parser.add_argument("--max-batches", type=int, default=12, help="Max total batches")
    args = parser.parse_args()

    data = json.load(open(f"{args.workspace}/transcripts.json"))
    manifest = json.load(open(f"{args.workspace}/skill-manifest.json"))
    sessions = data["sessions"]

    # Identify global vs project-local skills
    global_skills = [s for s in manifest["skills"] if s["scope"] == "global"]
    global_names = [s["name"] for s in global_skills]
    project_local = defaultdict(list)
    for s in manifest["skills"]:
        if s["scope"] == "project-local" and s.get("project_path"):
            project_local[s["project_path"]].append(s)

    def find_local_skills(project_dir):
        for pp, skills in project_local.items():
            encoded = pp.replace("/", "-").replace(".", "-")
            if encoded.lstrip("-") in project_dir.lstrip("-"):
                return skills
        return []

    # Separate sessions by skill visibility
    global_only_indices = []
    local_project_groups = defaultdict(list)

    for i, s in enumerate(sessions):
        pdir = s.get("project_dir", "unknown")
        locals_ = find_local_skills(pdir)
        if locals_:
            local_project_groups[pdir].append(i)
        else:
            global_only_indices.append(i)

    # Build batches
    batches = []

    # 1) Pool global-only sessions
    for chunk_start in range(0, len(global_only_indices), args.batch_size):
        chunk = global_only_indices[chunk_start : chunk_start + args.batch_size]
        batches.append(
            {
                "session_indices": chunk,
                "label": "global-only (mixed projects)",
                "visible_skill_names": global_names,
            }
        )

    # 2) Group projects with same local skill set
    by_skill_set = defaultdict(list)
    for pdir, indices in local_project_groups.items():
        local_names = tuple(sorted(s["name"] for s in find_local_skills(pdir)))
        by_skill_set[local_names].extend(indices)

    local_batches = []
    for local_names, indices in by_skill_set.items():
        visible = global_names + list(local_names)
        for chunk_start in range(0, len(indices), args.batch_size):
            chunk = indices[chunk_start : chunk_start + args.batch_size]
            local_batches.append(
                {
                    "session_indices": chunk,
                    "label": f"local skills: {', '.join(local_names[:3])}{'...' if len(local_names) > 3 else ''}",
                    "visible_skill_names": visible,
                    "_local_set": set(local_names),
                }
            )

    # 3) Merge if too many batches
    remaining_budget = args.max_batches - len(batches)
    while len(local_batches) > remaining_budget and len(local_batches) > 1:
        smallest_idx = min(
            range(len(local_batches)),
            key=lambda i: len(local_batches[i]["session_indices"]),
        )
        smallest = local_batches.pop(smallest_idx)
        best_idx, best_extra = 0, float("inf")
        for j, b in enumerate(local_batches):
            extra = len(smallest["_local_set"] - b["_local_set"]) + len(
                b["_local_set"] - smallest["_local_set"]
            )
            if extra < best_extra:
                best_idx, best_extra = j, extra
        target = local_batches[best_idx]
        target["session_indices"].extend(smallest["session_indices"])
        target["_local_set"] = target["_local_set"] | smallest["_local_set"]
        merged_local = sorted(target["_local_set"])
        target["visible_skill_names"] = global_names + merged_local
        target["label"] = f"merged local skills: {', '.join(merged_local[:3])}{'...' if len(merged_local) > 3 else ''}"

    for b in local_batches:
        b.pop("_local_set", None)
        batches.append(b)

    # Add DMI info
    dmi_skills = {s["name"] for s in manifest["skills"] if s.get("disable_model_invocation")}
    for b in batches:
        b["dmi_skill_names"] = sorted(set(b["visible_skill_names"]) & dmi_skills)

    # Write output
    output_path = f"{args.workspace}/batches.json"
    with open(output_path, "w") as f:
        json.dump(batches, f, indent=2, ensure_ascii=False)

    # Print summary
    total_sessions = sum(len(b["session_indices"]) for b in batches)
    print(f"Built {len(batches)} batches covering {total_sessions} sessions")
    for i, b in enumerate(batches):
        print(
            f"  Batch {i}: {len(b['session_indices'])} sessions, "
            f"{len(b['visible_skill_names'])} skills — {b['label']}"
        )
    print(f"Output: {output_path}")


if __name__ == "__main__":
    main()
