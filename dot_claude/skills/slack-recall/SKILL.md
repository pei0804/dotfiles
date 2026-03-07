---
description: 過去のSlack発言からチャンネル別に活動サマリーを生成する。「今週何してた？」「先週の振り返り」「Slackで何話してた？」「活動まとめ」などと聞かれたときに使う。
allowed-tools:
  - mcp__slack__slack_search_public_and_private
---

# Slack Recall

自分の過去のSlack発言を検索し、チャンネル別に何をしていたかのサマリーを生成する。

## 前提

- デフォルト期間: 過去5営業日（ユーザーが期間を指定した場合はそれに従う）
- Slack user_id はローカル設定ファイルから読み込む

## 手順

### 0. 設定ファイルの読み込み

スキルのベースディレクトリにある `config.json` を Read ツールで読む。

- パス: `~/.claude/skills/slack-recall/config.json`
- 形式: `{"slack_user_id": "UXXXXXXXX"}`

ファイルが存在しない場合:
1. ユーザーに Slack の user_id を聞く
2. `~/.claude/skills/slack-recall/config.json` に書き込む
3. 続行する

### 1. 発言を検索

`slack_search_public_and_private` で自分の発言を取得する。
`USER_ID` は config.json から読み取った値を使う。

```
query: "from:<@USER_ID> after:YYYY-MM-DD"
sort: "timestamp"
sort_dir: "desc"
limit: 20
include_context: false
response_format: "concise"
```

- `after` の日付は、今日から5営業日前（≒7日前）を設定する
- 結果が20件ヒットした場合は `cursor` を使って次ページも取得する
- 全件取得するまで繰り返す（ただし上限100件程度で打ち切る）

### 2. チャンネル別にグルーピング

取得した発言をチャンネル名でグルーピングする。

### 3. チャンネル別サマリーを生成

以下の形式で出力する:

```
## Slack活動サマリー（MM/DD〜MM/DD）

発言数: XX件 / チャンネル数: YY

### #channel-name（N件）
- やっていたことのサマリー（箇条書き）
- 具体的なトピックや決定事項があれば含める

### #another-channel（N件）
- ...
```

- チャンネルは発言数が多い順に並べる
- DMの場合は「DM with 相手の名前」と表示する
- 同じ内容を複数チャンネルに投稿している場合（Wrapup等）はまとめて言及する
- 各チャンネルのサマリーは2〜4行程度に簡潔にまとめる
- URLリンクの羅列だけの発言は「リンク共有」程度にまとめる
