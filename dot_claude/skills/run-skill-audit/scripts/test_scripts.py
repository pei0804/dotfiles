#!/usr/bin/env python3
"""
Unit tests for run-skill-audit helper scripts.

Tests build_batches.py and merge_batches.py using synthetic data
to verify correctness without needing real session transcripts.

Usage:
    python3 test_scripts.py
"""

import json
import os
import sys
import tempfile
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def create_test_transcripts(workspace, num_sessions=10):
    """Create minimal synthetic transcripts.json."""
    sessions = []
    for i in range(num_sessions):
        sessions.append(
            {
                "session_id": f"test-session-{i}",
                "filepath": f"/fake/path/session-{i}.jsonl",
                "project_dir": "-Users-test-project-a"
                if i < 7
                else "-Users-test-project-b",
                "skills_loaded": [],
                "user_turn_count": 5,
                "turn_skill_map": [
                    {
                        "turn_index": j,
                        "user_message": f"test message {j}",
                        "skills_loaded_after": [],
                        "is_builtin_command": False,
                    }
                    for j in range(5)
                ],
            }
        )
    data = {
        "project_path": "test",
        "sessions": sessions,
        "summary": {"total_sessions": num_sessions, "total_user_turns": num_sessions * 5},
    }
    with open(f"{workspace}/transcripts.json", "w") as f:
        json.dump(data, f)
    return data


def create_test_manifest(workspace):
    """Create minimal synthetic skill-manifest.json."""
    manifest = {
        "skills": [
            {
                "name": "global-skill-a",
                "scope": "global",
                "description": "A global skill",
                "description_tokens": 10,
                "disable_model_invocation": False,
            },
            {
                "name": "global-skill-b",
                "scope": "global",
                "description": "Another global skill",
                "description_tokens": 12,
                "disable_model_invocation": True,
            },
            {
                "name": "local-skill-a",
                "scope": "project-local",
                "project_path": "/Users/test/project-a",
                "description": "A local skill",
                "description_tokens": 8,
                "disable_model_invocation": False,
            },
        ],
        "summary": {"total_skills": 3},
        "attention_budget": {"total_description_tokens": 30},
    }
    with open(f"{workspace}/skill-manifest.json", "w") as f:
        json.dump(manifest, f)
    return manifest


def create_test_batch_results(workspace, num_batches=2):
    """Create synthetic batch-audit files with intentional field name variants."""
    for i in range(num_batches):
        # Alternate between field name styles to test normalization
        if i == 0:
            stats = {
                "total_fires": 5,
                "correct_fires": 3,
                "false_positives": 2,
                "false_negatives": 0,
                "accuracy": 0.6,
            }
        else:
            stats = {
                "fire_count": 3,
                "correct": 2,
                "false_positive": 1,
                "false_negative": 0,
                "accuracy": 0.667,
            }

        data = {
            "skill_reports": [
                {
                    "skill_name": "test-skill",
                    "skill_path": "/fake/path",
                    "description_excerpt": "test",
                    "stats": stats,
                    "incidents": [],
                    "health_assessment": f"batch {i} assessment",
                }
            ],
            "competition_pairs": [],
            "coverage_gaps": [],
            "meta": {
                "sessions_analyzed": 5,
                "turns_analyzed": 25,
                "skill_fires_analyzed": stats.get("total_fires", stats.get("fire_count", 0)),
            },
        }
        with open(f"{workspace}/batch-audit-{i}.json", "w") as f:
            json.dump(data, f)


def test_build_batches():
    """Test that build_batches.py produces valid batches."""
    print("Test: build_batches.py")
    with tempfile.TemporaryDirectory() as workspace:
        create_test_transcripts(workspace, num_sessions=10)
        create_test_manifest(workspace)

        result = subprocess.run(
            [sys.executable, f"{SCRIPT_DIR}/build_batches.py", "--workspace", workspace],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"build_batches failed: {result.stderr}"

        batches = json.load(open(f"{workspace}/batches.json"))
        assert isinstance(batches, list), "batches should be a list"
        assert len(batches) > 0, "should have at least 1 batch"

        # Check structure
        for b in batches:
            assert "session_indices" in b, "batch missing session_indices"
            assert "visible_skill_names" in b, "batch missing visible_skill_names"
            assert "dmi_skill_names" in b, "batch missing dmi_skill_names"
            assert len(b["session_indices"]) > 0, "batch has no sessions"

        # Check DMI skills detected
        all_dmi = set()
        for b in batches:
            all_dmi.update(b["dmi_skill_names"])
        assert "global-skill-b" in all_dmi, "should detect DMI skill"

        # Check all sessions are covered
        all_indices = []
        for b in batches:
            all_indices.extend(b["session_indices"])
        assert sorted(all_indices) == list(range(10)), "all 10 sessions should be in batches"

        print("  PASS: batches.json structure is valid")
        print(f"  PASS: {len(batches)} batches, {len(all_indices)} sessions covered")
        print(f"  PASS: DMI skills detected: {all_dmi}")


def test_merge_batches():
    """Test that merge_batches.py handles field name variants correctly."""
    print("Test: merge_batches.py")
    with tempfile.TemporaryDirectory() as workspace:
        create_test_batch_results(workspace, num_batches=2)

        result = subprocess.run(
            [sys.executable, f"{SCRIPT_DIR}/merge_batches.py", "--workspace", workspace],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"merge_batches failed: {result.stderr}"

        report = json.load(open(f"{workspace}/audit-report.json"))

        # Check structure
        assert "meta" in report
        assert "skill_reports" in report
        assert isinstance(report["skill_reports"], list)

        # Check meta totals
        meta = report["meta"]
        assert meta["sessions_analyzed"] == 10, f"expected 10 sessions, got {meta['sessions_analyzed']}"
        assert meta["turns_analyzed"] == 50, f"expected 50 turns, got {meta['turns_analyzed']}"

        # Check skill stats merged correctly despite field name variants
        skill = report["skill_reports"][0]
        stats = skill["stats"]
        assert stats["total_fires"] == 8, f"expected 8 fires (5+3), got {stats['total_fires']}"
        assert stats["correct_fires"] == 5, f"expected 5 correct (3+2), got {stats['correct_fires']}"
        assert stats["false_positives"] == 3, f"expected 3 FP (2+1), got {stats['false_positives']}"

        # Check accuracy recalculated
        expected_acc = round(5 / (5 + 3 + 0), 3)
        assert stats["accuracy"] == expected_acc, f"expected accuracy {expected_acc}, got {stats['accuracy']}"

        print("  PASS: field name normalization works (total_fires/fire_count)")
        print(f"  PASS: merged stats correct: fires={stats['total_fires']}, correct={stats['correct_fires']}, fp={stats['false_positives']}")
        print(f"  PASS: accuracy recalculated: {stats['accuracy']}")


def test_update_health_history():
    """Test health history append logic."""
    print("Test: update_health_history.py")
    with tempfile.TemporaryDirectory() as workspace:
        base_dir = workspace

        # Create minimal audit-report.json
        audit = {
            "meta": {"sessions_analyzed": 100, "turns_analyzed": 500, "skills_evaluated": 10},
            "competition_pairs": [{"skill_a": "a", "skill_b": "b"}],
            "coverage_gaps": [],
        }
        with open(f"{workspace}/audit-report.json", "w") as f:
            json.dump(audit, f)

        # Create minimal portfolio-analysis.json
        portfolio = {
            "portfolio_health": {
                "overall_score": "needs_attention",
                "routing_accuracy_avg": 0.75,
            },
            "attention_budget": {"total_tokens": 500},
        }
        with open(f"{workspace}/portfolio-analysis.json", "w") as f:
            json.dump(portfolio, f)

        result = subprocess.run(
            [
                sys.executable,
                f"{SCRIPT_DIR}/update_health_history.py",
                "--workspace",
                workspace,
                "--base-dir",
                base_dir,
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"update_health_history failed: {result.stderr}"

        history = json.load(open(f"{base_dir}/health-history.json"))
        assert len(history) == 1, "should have 1 entry"
        entry = history[0]
        assert entry["sessions_analyzed"] == 100
        assert entry["routing_accuracy_avg"] == 0.75
        assert entry["portfolio_health"] == "needs_attention"
        assert entry["competition_conflicts"] == 1
        assert "timestamp" in entry

        # Run again to test delta display
        result2 = subprocess.run(
            [
                sys.executable,
                f"{SCRIPT_DIR}/update_health_history.py",
                "--workspace",
                workspace,
                "--base-dir",
                base_dir,
            ],
            capture_output=True,
            text=True,
        )
        assert result2.returncode == 0
        history2 = json.load(open(f"{base_dir}/health-history.json"))
        assert len(history2) == 2, "should have 2 entries after second run"
        assert "前回" in result2.stdout, "should show delta comparison"

        print("  PASS: health history created and appended correctly")
        print("  PASS: delta comparison works on second run")


if __name__ == "__main__":
    print("=" * 60)
    print("run-skill-audit script tests")
    print("=" * 60)
    print()

    passed = 0
    failed = 0

    for test_fn in [test_build_batches, test_merge_batches, test_update_health_history]:
        try:
            test_fn()
            passed += 1
            print()
        except Exception as e:
            failed += 1
            print(f"  FAIL: {e}")
            print()

    print("=" * 60)
    print(f"Results: {passed} passed, {failed} failed")
    print("=" * 60)
    sys.exit(1 if failed > 0 else 0)
