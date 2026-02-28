---
description: 溜まったgit worktreeを一覧表示し、不要なものを一括削除する
allowed-tools:
  - Bash(git *)
  - Bash(rm *)
  - Bash(ls *)
  - Bash(find *)
---

# Worktree一括クリーンアップ

各リポジトリの `.claude/worktrees/` に溜まったworktreeを一覧表示し、不要なものを削除する。

## 手順

### 1. 現在のworktreeを一覧表示

```bash
git worktree list
```

メインworktree以外のエントリを対象とする。
`.claude/worktrees/` 配下のものをClaude Code作成のworktreeとして識別する。

### 2. 各worktreeの状態を調査

対象の各worktreeについて以下を収集し、テーブル形式で表示する:

| # | パス | ブランチ | 最終コミット | 未コミット変更 |
|---|------|---------|-------------|---------------|

各worktreeについて:

```bash
# ブランチと最終コミット日時
git -C <worktree-path> log -1 --format='%ci %s' 2>/dev/null

# 未コミット変更の有無
git -C <worktree-path> status --porcelain 2>/dev/null
```

### 3. ユーザーに削除対象を確認

AskUserQuestion で以下の選択肢を提示する:

- **全て削除**: `.claude/worktrees/` 配下の全worktreeを削除
- **選択して削除**: 番号を指定して削除対象を選ぶ
- **キャンセル**: 何もしない

**重要**: 未コミット変更があるworktreeには警告を表示する。

### 4. 削除実行

```bash
# worktreeを削除（未コミット変更がある場合は --force）
git worktree remove <worktree-path>
# または強制削除が必要な場合
git worktree remove --force <worktree-path>
```

すべての削除が完了したら:

```bash
# 残骸を掃除
git worktree prune
```

### 5. 不要ブランチの削除提案

削除したworktreeに対応するローカルブランチを特定する:

```bash
git branch --list
```

対応するブランチがあればユーザーに削除するか確認し、承認されたら:

```bash
git branch -D <branch-name>
```

### 6. 結果報告

削除結果をテーブル形式でまとめて報告する:

| worktree | ブランチ | 結果 |
|----------|---------|------|
| ... | ... | 削除済 / スキップ |
