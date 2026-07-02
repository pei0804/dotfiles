---
description: 自分の PR を tech-reviewer の観点でセルフレビューし、指摘ごとに「取り込む／取り込まない」をユーザーに確認してから直接ブランチに修正をコミット・push するスキル。「セルフレビューして」「自分のPR見直して」「レビュー依頼前にチェック」「PR#123をセルフレビュー」「push前に確認して」「レビュー依頼前にラスト確認」などと言われたときに使う。レビュアーに依頼する前のラスト一押しに使うこと。技術記事のセルフレビューには tech-article-reviewer を使う。
argument-hint: "<pr-number-or-url>"
allowed-tools:
  - Bash(gh *)
  - Bash(git *)
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Agent
---

# Self Review

自分の PR を自分でレビューし、指摘ごとに取り込み判断してブランチに直接反映するスキル。

`tech-reviewer` の六軸フレームでレビューし、`review-response` の per-item UX で取り込み判断する。GitHub には投稿しない。コミット → push で完了。

## 前提

- 対象は自分の PR（引数で PR 番号を指定）
- レビューは「人間にしか判断できないこと」に絞る。フォーマット・lint・型エラーは対象外
- 取り込み判断は全件ユーザーに確認する。**唯一の例外**: コメント・文字列リテラル・docstring 内の明白な typo（識別子・公開 API 名・設定キーは含まない）だけ無言で適用する
- GitHub には投稿しない。コミット → push のみで完了

## インプット

- 引数: PR 番号または URL（必須）
- 未指定の場合はユーザーに確認する（自動検出はしない）

## 手順

### 1. PR 情報を取得

```bash
# PR のメタ情報
gh pr view <number> --json number,title,body,headRefName,baseRefName,url

# diff
gh pr diff <number>
```

diff が 500 行を超える場合は、以下の優先順で読む:
- **優先度高**: ビジネスロジック・API 定義・データモデル・設定ファイル
- **優先度低**: テスト・ドキュメント・自動生成ファイル

リポジトリ名とログインユーザーを動的に取得しておく（Step 6 の push / worktree 操作で使う）:

```bash
gh repo view --json nameWithOwner --jq .nameWithOwner
gh api user --jq .login
```

### 2. レビューをサブエージェントに委譲

**サブエージェントで実行する理由**: 自分が書いたコードをレビューするときほど思い込みが邪魔をする。第三者の目で見ることでバイアスを排除する。

Agent ツールで新しいサブエージェントを作成し、以下をすべて渡してレビューを依頼する。

#### サブエージェントに渡す情報

- PR のタイトル・本文・diff（Step 1 で取得したもの）
- 必要に応じてリポジトリ内の関連コード（`Read` / `Grep` / `Glob` で取得）
- `~/.claude/skills/tech-reviewer/SKILL.md` を読み、その「レビューの姿勢」と「レビュー観点（人間にしか判断できないこと）」の PR 向けの問いに従うよう指示（哲学者名・引用を本文に書かない禁止ルールを含む）
- 技術哲学: `~/.claude/references/tech_philosophy.md` を読むよう指示
- 以下の出力フォーマット（tech-reviewer のフォーマットではなくこちらを使う）

#### サブエージェントへの出力フォーマット指定

以下のフォーマットで結果を返すよう指示する:

```
## レビューサマリー

**対象:** PR #<number> — <title>
**結論:** Approved / Changes Requested / Comments

**全体評価:** [良い点を2-3行で]

**要検討（3つ以内）:**
1. 指摘: [問題の説明]
   なぜ: [なぜ問題か]
   改善案: [具体的な対応策]
   場所: [file:line または "全体"]
   カテゴリ: design | behavior | naming | typo | other

**軽微:**
- 指摘: [...]
  改善案: [...]
  場所: [file:line]
  カテゴリ: design | behavior | naming | typo | other

**Good:**
- [積極的に評価したい判断・設計]
```

`typo` カテゴリは **コメント・文字列リテラル・docstring 内のスペルミスのみ**。識別子・公開 API 名・設定キー・i18n キーはカテゴリを `naming` または `other` とする（影響範囲が自明でないため）。

### 3. レビュー結果を表示

サブエージェントの出力をそのままユーザーに提示する。

**要検討がゼロ件のとき**は「セルフレビュー OK — 気になる点はなかった」で終わってよい。フォーマットを埋めるための指摘を捏造しない。

### 4. 取り込み判断を振り分ける

各 `要検討` 項目と `軽微` 項目を以下で振り分ける:

- **自動適用候補**: カテゴリが `typo` かつ改善案が一意な単純置換（コメント・文字列リテラル・docstring 内のみ）
- **Ask 対象**: それ以外すべて

自動適用候補の一覧をユーザーに事前報告する（適用後も報告する）。

### 5. Ask 対象を per-item でユーザーに提示

すべての Ask 対象をまとめて提示してから、ユーザーの指示を待つ:

---

**指摘 1/N** — `path:line`
> [指摘の内容]
> なぜ: [理由]
> 改善案: [対応策]

**推奨**: 取り込む／取り込まない
**理由**: [推奨の根拠]

---

提示後、「全部取り込む」「2番だけスキップ」「3番は別のアプローチで」など、ユーザーの粒度別の指示を待つ。

### 6. 適用

ユーザーの判断が揃ったら実装に移る。

#### worktree を確保

```bash
# PR ブランチの worktree を探す
git worktree list | grep <head-ref>
```

worktree がなければ作成:

```bash
git worktree add .worktrees/<short-name> <head-ref>
```

main ブランチにいる場合は必ず worktree を作ってから作業する（`CLAUDE.md` "Worktree First" ルール）。

#### 変更を実装してコミット

- 関連性の高い指摘は 1 コミットにまとめる。無関係な指摘は分ける
- コミットメッセージは `CLAUDE.md` のルール（Session トレーラー + Co-Authored-By）に従う
- push 前に `git diff` または `git show` で差分を確認する

```bash
git push origin <head-ref>
```

上流が進んでいて fast-forward できない場合は force push せず止めてユーザーに確認する。

### 7. 完了報告

```
## セルフレビュー完了

**適用済み（コミット）:**
- <commit-hash>: [変更内容の概要]

**自動適用した typo:**
- `path:line` — "<before>" → "<after>"

**スキップした指摘:**
- 指摘 N: [理由]
```

## 注意事項

- `要検討` は最大 3 件。問題がなければ 0 でいい。埋めるための指摘を捏造しない
- typo 自動適用の範囲: **コメント・文字列リテラル・docstring のみ**。識別子・公開 API・設定キーには手を出さない
- レビューの姿勢・禁止事項（哲学者名・引用の禁止など）は tech-reviewer の SKILL.md に従う
- GitHub には投稿しない（`gh pr review` / `gh issue comment` は使わない）
