---
description: Claude Codeの監査ログ（command-audit.log）を解析し、実行コマンドのサマリー・頻出コマンド・プロジェクト別活動・時間帯分析・危険コマンド検出を行う。「監査ログ見せて」「今日何やった？（コマンド）」「どんなコマンド実行した？」「audit log」「コマンド履歴」などと聞かれたときに使う。Slackではなくコマンド実行履歴の話をしている場合はこのスキルを使う。
---

# Audit Log Analyzer

`~/.claude/command-audit.log` に記録されたClaude Codeの全Bashコマンド実行履歴を解析する。

## ログ形式

```
{ISO8601タイムスタンプ} {作業ディレクトリ} {コマンド}
```

例: `2026-03-07T22:36:54 /Users/user/project git status`

## 手順

### 1. パーサースクリプトで解析

`~/.claude/skills/audit-analyzer/scripts/parse-audit.sh` を実行してJSONを取得する。

期間を指定する場合:
```bash
~/.claude/skills/audit-analyzer/scripts/parse-audit.sh --after 2026-03-01 --before 2026-03-07
```

期間が指定されない場合:
- 「今日」→ `--after {今日の日付}`
- 「今週」→ `--after {今週月曜の日付}`
- 指定なし → フィルタなし（全期間）

### 2. 結果を整形して出力

パーサーが返すJSON構造:
- `total_commands`: 総コマンド数
- `projects`: プロジェクト別の実行数とサンプルコマンド
- `top_commands`: 頻出コマンドランキング
- `hourly_distribution`: 時間帯別の実行数
- `dangerous_commands`: 危険パターンにマッチしたコマンド

以下の形式で出力する:

```
## コマンド実行サマリー（MM/DD〜MM/DD）

総コマンド数: XX

### プロジェクト別
| プロジェクト | コマンド数 | 主な操作 |
|---|---|---|
| repo-name | N | git操作、テスト実行 etc |

### 頻出コマンド TOP 10
| # | コマンド | 回数 |
|---|---|---|
| 1 | git | 42 |

### 時間帯別アクティビティ
棒グラフ的に可視化（テキストで）

### ⚠️ 危険コマンド検出（あれば）
- {timestamp} {command} — パターン: {pattern}
```

- プロジェクトの「主な操作」はサンプルコマンドから推測して簡潔にまとめる
- 危険コマンドが0件の場合はセクション自体を省略する
- 時間帯は活動がある時間帯のみ表示する
