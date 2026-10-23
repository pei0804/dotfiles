---
name: review-response
description: 自分のPRに届いたレビューコメントをまとめて処理するスキル。コメントを全件取得 → Claude が取り込む/取り込まない推奨を提示 → ユーザーが最終判断 → 取り込む場合は実装・コミット・"fix <hash>" で返信、取り込まない場合は理由を書いて返信する。「レビューコメントに対応して」「コメントへの返事」「レビュー対応」などと言われたときに使う。
argument-hint: "<pr-number-or-url>"
allowed-tools:
  - Bash(gh *)
  - Bash(git *)
  - Read
  - Edit
  - Write
---

# PR レビューコメント対応

自分の PR に届いたレビューコメントを一括処理する。

## インプット

PR 番号または URL。引数が未指定の場合はユーザーに確認する。

## 手順

### 1. コメントを全件取得

diff 上の行コメント（Review comments）を取得する:

```bash
gh api --paginate repos/{owner}/{repo}/pulls/<number>/comments \
  --jq '.[] | {id, path, line, body, in_reply_to_id, user: .user.login}'
```

PR スレッドのコメントも必要なら:

```bash
gh pr view <number> --comments
```

### 2. 未対応コメントを絞り込む

以下は除外する:

- `in_reply_to_id` が存在する（返信コメント自体）
- 自分（`gh api user --jq .login`）が投稿したコメント
- すでに自分が返信済みのスレッド（同じ `path + line` に自分の返信がある）
- Bot のコメント

残ったコメントが対応対象。

### 3. 推奨を提示してユーザーに判断を仰ぐ

全コメントをまとめて以下の形式で提示する。ユーザーが最終判断を下すので、Claude は推奨と根拠を明示する。

---

**コメント 1/N** — `path:line`
> レビュアーのコメント（原文）

**推奨**: 取り込む
**理由**: ～（なぜ取り込むべきか）

---

**コメント 2/N** — `path:line`
> レビュアーのコメント（原文）

**推奨**: 取り込まない
**理由**: ～（なぜ取り込まないか。代替案があれば添える）

---

提示後、「全部OK」「2番だけ断る」「1番は自分で判断するから3番だけやって」など、ユーザーの指示を待つ。

### 4. 取り込む場合

#### 4a. worktree を特定

```bash
git worktree list | grep <branch-name>
```

worktree がなければ作成:

```bash
git worktree add .worktrees/<short-name> <branch-name>
```

#### 4b. 変更を実装してコミット

コミットメッセージはリポジトリの `AGENTS.md`・`CLAUDE.md` の規約に従う。

```bash
git push origin <branch-name>
```

#### 4c. コメントに返信

```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments/<comment-id>/replies \
  -X POST -f body="fix <commit-hash>"
```

複数のコメントをまとめて1コミットで対応した場合は、同じハッシュを全員に返信してよい。

### 5. 取り込まない場合

なぜ取り込まないかを明確に書いて返信する:

```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments/<comment-id>/replies \
  -X POST -f body="<理由>"
```

理由には「スコープ外」「設計上の意図がある」「別の方法で対応済み」など、レビュアーが納得できる根拠を含める。

## 注意事項

- 関連性の高い変更は1コミットにまとめる。無関係な変更は分ける
- push 前に diff を確認する（`git diff` または `git show`）
- 返信済みコメントを誤って二重返信しないよう、実行前に必ず現状を確認する
