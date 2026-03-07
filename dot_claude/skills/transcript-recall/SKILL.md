---
description: 過去のClaude Codeセッションのトランスクリプト（会話ログ）を検索・閲覧する。「前のセッションで何話してた？」「昨日のセッション見せて」「あのとき何やってたっけ」「過去の会話」「transcript」「セッション履歴」などと聞かれたときに使う。コマンド実行履歴ではなく会話内容を振り返りたい場合はこのスキルを使う。
---

# Transcript Recall

過去のClaude Codeセッションの会話ログを検索・閲覧するスキル。

## データソース

2種類のトランスクリプトを検索する:

1. **PreCompactバックアップ** (`~/.claude/transcripts/`) — コンテキスト圧縮前に自動保存されたもの
2. **ライブセッション** (`~/.claude/projects/*/*.jsonl`) — 各セッションの完全なログ

## 手順

### 1. まず一覧を取得

ユーザーが探しているセッションを特定するため、まず `--list` で一覧を表示する。

```bash
~/.claude/skills/transcript-recall/scripts/recall.sh --list
```

期間やプロジェクトで絞り込む場合:
```bash
# 日付フィルタ
~/.claude/skills/transcript-recall/scripts/recall.sh --list --after 2026-03-01

# プロジェクト名でフィルタ（部分一致）
~/.claude/skills/transcript-recall/scripts/recall.sh --list --project glimmer
```

期間の解釈:
- 「昨日」→ `--after {昨日} --before {昨日}`
- 「今週」→ `--after {今週月曜}`
- 「最近」→ フィルタなし（新しい順に表示）

### 2. ユーザーと対象を確認

一覧を見せて、どのセッションを見たいか確認する。複数ある場合はプロジェクト名・日時で特定できるよう案内する。

### 3. 特定セッションの内容を取得

```bash
~/.claude/skills/transcript-recall/scripts/recall.sh --file /path/to/transcript.jsonl
```

### 4. 内容をサマリーとして出力

以下の形式で出力する:

```
## セッション振り返り

**プロジェクト**: project-name
**日時**: YYYY-MM-DD HH:MM
**メッセージ数**: N件

### やったこと
- ユーザーのリクエストとClaudeの対応を時系列で箇条書き
- 重要な決定事項や成果物を含める

### キーポイント
- 特に重要な発見、問題解決、決定事項
```

- 会話の流れを追って、何を依頼し何が完了したかを簡潔にまとめる
- コードの変更があればファイル名と概要を含める
- 長い会話は要点のみに絞る（全文引用はしない）
