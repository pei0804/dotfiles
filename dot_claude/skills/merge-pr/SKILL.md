---
description: PRブランチをmainに追従させ、CIを待ち、マージする（リトライループ付き）
argument-hint: "<pr-number-or-url> [pr-number-or-url ...]"
allowed-tools:
  - Bash(gh *)
  - Bash(git *)
  - Bash(sleep *)
  - Bash(open *)
---

# PRマージ（ブランチ更新 + CI待機ループ）

指定されたPRを受け取り、ブランチ更新 → CI待機 → マージ を自動で繰り返す。
複数PRが渡された場合は、渡された順番に1つずつ処理する。

## 前提

- merge commit のみ許可のリポジトリを想定（squash/rebase は無効）
- `fail-ci` 等の必須チェックが CI成功時に `skipped` になるケースでは `gh pr merge` がブロックされるため、マージには **GitHub API (`gh api`) を直接使う**
- ブランチ保護で strict status checks が有効（ブランチがbase最新でないとマージ不可）

## 手順

### 0. 引数の解析とリポジトリ情報取得

- 引数が未指定の場合、ユーザーに確認する
- URLが渡された場合（`https://github.com/.../pull/1234`）、PR番号を抽出する
- 複数PRが渡された場合、リストとして保持し順番に処理する
- リポジトリの `owner/repo` を取得する:

```bash
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

以降、取得した値を `<owner/repo>` として使用する。

### 1. PRごとに以下を実行（順番に処理）

処理中のPRと残りのPR数を報告する（例: 「PR #1234 を処理します（1/3）」）

#### 1a. PRの状態確認

```bash
gh pr view <number> --json state,title,headRefName,baseRefName,mergeStateStatus,url
```

以下を確認:
- PRがopenであること（closed/mergedならスキップして次のPRへ）
- merge conflictがないこと（conflictがあればユーザーに報告してスキップ）

#### 1b. ループ開始（最大5回）

各イテレーションの開始時に「ループ N/5」と報告する。

##### マージ可能状態の確認

```bash
gh pr view <number> --json mergeStateStatus --jq '.mergeStateStatus'
```

`mergeStateStatus` の値で判断:
- `BEHIND` → ブランチ更新へ
- `BLOCKED` → CI待機へ
- `CLEAN` → マージ実行へ
- `DIRTY` → merge conflict。ユーザーに報告してこのPRはスキップ
- `UNSTABLE` → CIが失敗している。ユーザーに報告してこのPRはスキップ
- `UNKNOWN` → GitHubが計算中。`sleep 10` して再取得する（最大3回）

##### ブランチ更新（baseブランチをマージ）

GitHub APIでブランチを更新する（ローカルを汚さない）:

```bash
gh api repos/<owner/repo>/pulls/<number>/update-branch -X PUT
```

成功したら「ブランチを更新しました。CIの完了を待ちます。」と報告し、CI待機へ。

エラーの場合（merge conflictなど）、エラーメッセージをユーザーに報告してこのPRはスキップ。

##### CI完了を待機

**重要**: ブランチ更新直後はチェックが未開始の場合がある。`sleep 15` してから `--watch` を実行する。

```bash
sleep 15 && gh pr checks <number> --watch --fail-fast
```

- 全チェックpassで終了 → マージ可能状態の確認に戻る
- いずれかのチェックがfail → チェック結果を表示し、ユーザーに報告してこのPRはスキップ

##### マージ実行

GitHub APIで直接マージする（`gh pr merge` は必須チェックの skipped 問題があるため使わない）:

```bash
gh api repos/<owner/repo>/pulls/<number>/merge -X PUT -f merge_method=merge
```

**成功の場合**: 「PR #<number> をマージしました」と報告してループ終了。次のPRへ。

**失敗の場合**: レスポンスを確認する。

- `"Head branch was modified"` や `"Base branch was modified"` など、ブランチの遅れが原因 → ループ先頭に戻る
- その他のエラー → フォールバックへ

##### フォールバック: ブラウザでマージ

APIマージが失敗した場合:

```bash
open "https://github.com/<owner/repo>/pull/<number>"
```

ユーザーに以下を伝える:
> APIからのマージに失敗しました。ブラウザでPRページを開きました。GitHub UIからマージしてください。
> エラー内容: (エラーメッセージ)

#### 1c. ループ上限到達

5回ループしてもマージできなかった場合:
- PRページをブラウザで開く
- ユーザーに報告し、次のPRの処理に進む

### 2. 全体の結果報告

全PRの処理が完了したら、結果をテーブル形式でまとめて報告する:

| PR | タイトル | 結果 |
|---|---|---|
| #1234 | ... | merged / skipped / failed |
