---
name: run-skill-audit
description: >-
  スキルポートフォリオの健全性を監査する。セッションログからルーティング精度・誤発火・競合を分析し、
  HTMLレポートと改善パッチを生成する。「スキル監査」「skill audit」「スキルの精度を分析」
  「誤発火を調べたい」「スキルルーティング分析」「スキルの健全性チェック」
  「ルーティング精度」「スキルが正しく発火しているか確認」などのリクエストに対応する。
  スキルのdescriptionを最適化したいだけならskill-creatorを使うこと。
  このスキルはポートフォリオ全体を実セッションデータで検証するもの。
---

# Run Skill Audit

skill-auditor のワークフローを一括実行するオーケストレーションスキル。
データ収集からHTMLレポート生成・パッチ適用まで、すべてのステップを自動化する。

このスキルは `scripts/` 配下のヘルパースクリプトと、
skill-auditor 本体（`~/.claude/skills/skill-auditor/`）のスクリプト・エージェント定義を
組み合わせて動作する。

## 前提

- `~/.claude/skills/skill-auditor/` がインストール済みであること
- 未インストールの場合は自動インストール:
  ```bash
  git clone --depth 1 https://github.com/nyosegawa/skills.git /tmp/nyosegawa-skills
  cp -r /tmp/nyosegawa-skills/skills/skill-auditor ~/.claude/skills/skill-auditor
  ```

## パス定義

スキル内で使う変数名:
- `SKILL_AUDITOR_DIR`: `~/.claude/skills/skill-auditor`
- `RUN_SKILL_AUDIT_DIR`: このスキルのディレクトリ（`~/.claude/skills/run-skill-audit`）
- `BASE_DIR`: レポートのベースディレクトリ
  - current-project mode: `<project_root>/.claude/skill-report/`
  - cross-project mode: `~/.claude/skill-report/`
- `WORKSPACE`: `${BASE_DIR}/<RUN_ID>`（タイムスタンプ付き）

## ワークフロー

### Step 0: 確認

ユーザーに2点だけ確認（デフォルト値を提示して即決できるように）:
1. **言語**: デフォルトは会話言語と同じ（日本語なら日本語）
2. **スコープ**: デフォルトは「現在のプロジェクトのみ」

### Step 1: ワークスペース作成 & データ収集

```bash
RUN_ID=$(date +%Y-%m-%dT%H-%M-%S)
WORKSPACE=${BASE_DIR}/${RUN_ID}
mkdir -p ${WORKSPACE}

# current-project mode
python3 ${SKILL_AUDITOR_DIR}/scripts/collect_transcripts.py \
  --cwd "$(pwd)" --days 14 \
  --output ${WORKSPACE}/transcripts.json --verbose

# cross-project mode（スコープが全プロジェクトの場合）
# python3 ${SKILL_AUDITOR_DIR}/scripts/collect_transcripts.py all --days 14 \
#   --output ${WORKSPACE}/transcripts.json --verbose

python3 ${SKILL_AUDITOR_DIR}/scripts/collect_skills.py \
  --output ${WORKSPACE}/skill-manifest.json --verbose
```

収集サマリーをユーザーに報告: "N sessions, M turns, K skills"

### Step 2: バッチ構成

専用スクリプトでバッチを構成する。プロジェクト固有のローカルスキルを持つセッションは
別バッチに分離され、グローバルスキルのみのセッションはプールされる。

```bash
python3 ${RUN_SKILL_AUDIT_DIR}/scripts/build_batches.py \
  --workspace ${WORKSPACE}
```

出力: `${WORKSPACE}/batches.json`

### Step 3: ルーティング監査（並列サブエージェント）

`batches.json` を読み、バッチ数だけサブエージェントを `run_in_background: true` で並列起動。

各サブエージェントへの指示:
```
Read ${SKILL_AUDITOR_DIR}/agents/routing-analyst.md for your analysis instructions.
Read ${WORKSPACE}/skill-manifest.json for skill definitions.
Read ${WORKSPACE}/transcripts.json for session data.
Only analyze sessions with these indices: [batch.session_indices]
Only evaluate against these skills: [batch.visible_skill_names]
These skills have disable-model-invocation and NEVER auto-fire: [batch.dmi_skill_names]
Write ALL output text in [言語].
Write your analysis as JSON to /tmp/batch-audit-{i}.json
following the exact schema in ${SKILL_AUDITOR_DIR}/schemas/schemas.md (audit-report.json section).
```

**ファイル書き込みの注意**: main ブランチ保護 hook がある環境では、
サブエージェントに `/tmp/` へ書かせてから `cp` でワークスペースにコピーする。

全バッチ完了後:
```bash
cp /tmp/batch-audit-*.json ${WORKSPACE}/
```

### Step 4: 結果マージ

専用スクリプトでマージ。サブエージェント間のフィールド名の揺れ
（`total_fires` vs `fire_count` 等）を自動正規化する。

```bash
python3 ${RUN_SKILL_AUDIT_DIR}/scripts/merge_batches.py \
  --workspace ${WORKSPACE}
```

出力: `${WORKSPACE}/audit-report.json`

### Step 5: ポートフォリオ分析 & 改善提案（並列サブエージェント）

2つのサブエージェントを `run_in_background: true` で並列起動:

**portfolio-analyst:**
```
Read ${SKILL_AUDITOR_DIR}/agents/portfolio-analyst.md for instructions.
Read ${WORKSPACE}/skill-manifest.json for skill definitions and attention budget.
Read ${WORKSPACE}/audit-report.json for the routing audit results.
Write ALL output text in [言語].
Write to /tmp/portfolio-analysis.json, then:
cp /tmp/portfolio-analysis.json ${WORKSPACE}/portfolio-analysis.json
```

**improvement-planner:**
```
Read ${SKILL_AUDITOR_DIR}/agents/improvement-planner.md for instructions.
Read ${WORKSPACE}/audit-report.json for routing audit results.
Read ${WORKSPACE}/portfolio-analysis.json for portfolio analysis.
Read ${WORKSPACE}/skill-manifest.json for current skill definitions.
Write ALL output text in [言語].
Write to /tmp/improvement-proposals.json, then:
cp /tmp/improvement-proposals.json ${WORKSPACE}/improvement-proposals.json
mkdir -p ${WORKSPACE}/patches
cp /tmp/patches/*.patch.json ${WORKSPACE}/patches/
```

### Step 6: HTMLレポート生成 & 表示

```bash
python3 ${SKILL_AUDITOR_DIR}/scripts/generate_report.py \
  --workspace ${WORKSPACE}
open ${WORKSPACE}/skill-audit-report.html
```

### Step 7: Health History 更新

```bash
python3 ${RUN_SKILL_AUDIT_DIR}/scripts/update_health_history.py \
  --workspace ${WORKSPACE} --base-dir ${BASE_DIR}
```

### Step 8: サマリー報告 & パッチ適用

以下をユーザーに報告:
- 分析セッション数・ターン数
- ルーティング精度が低いスキル（テーブル形式）
- 競合ペア・カバレッジギャップ
- パッチ提案の一覧（優先度・before/after・期待改善率）

パッチの適用を確認し、承認されたら:
1. worktree を作成（main ブランチ保護がある場合）
2. パッチの `proposed_description` で各 SKILL.md の description を更新
3. コミット → push → PR 作成（draft）

## トラブルシューティング

- **"No project found"**: `--cwd` でプロジェクトルートを明示指定
- **サブエージェントのファイル書き込みがブロックされる**: `/tmp/` 経由で書き込み→cp
- **マージ後の stats が全て 0**: フィールド名の揺れ。`merge_batches.py` が自動対応するので
  手動マージせずスクリプトを使うこと
- **セッション数が少ない**: `--days` を増やす（デフォルト14日）
