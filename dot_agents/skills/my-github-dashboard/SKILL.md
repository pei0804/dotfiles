---
description: 自分がOpenしたGitHub Issue・PRを過去3ヶ月分取得し、リポジトリ別にグルーピングして一覧表示する。「自分のIssue」「自分のPR」「GitHub一覧」「何が残ってる？」などと聞かれたときに使う。
allowed-tools:
  - Bash(gh *)
---

# My GitHub Dashboard

自分が作成した Open な Issue と PR を過去3ヶ月分取得し、見やすく表示する。

## 手順

### 1. Issue と PR を並列で取得

```bash
# Issues
gh search issues --author=@me --state=open --limit 50 --json repository,number,title,labels,createdAt -- "created:>$(date -v-3m +%Y-%m-%d)"

# PRs
gh search prs --author=@me --state=open --limit 50 --json repository,number,title,labels,createdAt -- "created:>$(date -v-3m +%Y-%m-%d)"
```

両方を並列で実行すること。

### 2. リポジトリ別にグルーピングして表示

リポジトリごとにまとめ、以下の形式で表示する:

```
## repo-name

### Issues (N件)
| # | タイトル | ラベル | 作成日 |
|---|---------|--------|--------|

### PRs (N件)
| # | タイトル | 作成日 |
|---|---------|--------|
```

- リポジトリは Issue + PR の合計件数が多い順に並べる
- 各リポジトリ内では作成日の新しい順
- ラベルがない場合は `-` を表示
- 作成日は `YYYY-MM-DD` 形式
- Issue/PR が0件のセクションは省略する

### 3. サマリーを冒頭に表示

一覧の前に総数を表示する:

```
Open Issues: XX件 / Open PRs: YY件（過去3ヶ月）
```
