---
name: format-converter
description: GitHub MarkdownとSlackフォーマット間の相互変換。「Slackに貼り付けるためにMarkdownを変換して」「GitHub用にSlackの文章をMarkdownにして」「このREADMEをSlackで使いたい」「SlackメッセージをIssueの本文に」「Slack向けにフォーマット変換して」と言われたときに使う。MarkdownとSlack記法の違いを埋める変換ならこのスキルを必ず使うこと。
argument-hint: "<text-to-convert>"
---

# Format Converter: GitHub Markdown ↔ Slack

GitHub MarkdownとSlackは似て非なる記法を使う。このスキルは両者の間を正確に相互変換する。

## 変換方向

ユーザーが明示的に方向を指定する。曖昧な場合は確認する。

- **Markdown → Slack**: GitHubのIssue本文・README・PRコメントをSlackに貼る
- **Slack → Markdown**: SlackのメッセージをGitHubのIssue・PRコメントに転記する

## 変換の実行

変換は `scripts/convert.py` を使う（スキルディレクトリからの相対パス）：

```bash
# Markdown → Slack
python ~/.claude/skills/format-converter/scripts/convert.py --to-slack input.md

# Slack → Markdown  
python ~/.claude/skills/format-converter/scripts/convert.py --to-markdown input.txt

# 標準入力から
echo "**bold**" | python ~/.claude/skills/format-converter/scripts/convert.py --to-slack
```

スクリプトが使えない環境（ファイルシステム非対応など）は下記のルールに従って手動変換する。

## 変換ルール早見表

### Markdown → Slack

| 要素 | Markdown | Slack |
|------|----------|-------|
| 太字 | `**text**` / `__text__` | `*text*` |
| 斜体 | `*text*` / `_text_` | `_text_` |
| 取り消し線 | `~~text~~` | `~text~` |
| 太字+斜体 | `***text***` | `*_text_*` |
| インラインコード | `` `code` `` | `` `code` ``（同じ） |
| コードブロック | ` ```lang\ncode\n``` ` | ` ```\ncode\n``` `（言語指定を除去） |
| リンク | `[text](url)` | `<url\|text>` |
| 画像 | `![alt](url)` | `url`（URLのみ、Slackはインライン表示しない） |
| 見出し（全レベル） | `# H1` `## H2` など | `*H1*` `*H2*`（Slackに見出し概念なし） |
| 箇条書き | `- item` / `* item` / `+ item` | `• item` |
| ネスト箇条書き（2段） | `  - item` | `  ◦ item` |
| ネスト箇条書き（3段） | `    - item` | `    ▪ item` |
| タスク未完了 | `- [ ] item` | `☐ item` |
| タスク完了 | `- [x] item` | `☑ item` |
| 引用 | `> text` | `> text`（同じ） |
| 水平線 | `---` | （削除） |
| テーブル | GFM table | そのまま維持（区切り行を残すとSlackが表として描画する） |

### Slack → Markdown

| 要素 | Slack | Markdown |
|------|-------|----------|
| 太字 | `*text*` | `**text**` |
| 斜体 | `_text_` | `_text_`（同じ） |
| 取り消し線 | `~text~` | `~~text~~` |
| インラインコード | `` `code` `` | `` `code` ``（同じ） |
| コードブロック | ` ```\ncode\n``` ` | ` ```\ncode\n``` `（同じ） |
| リンク（ラベルあり） | `<url\|text>` | `[text](url)` |
| リンク（ラベルなし） | `<url>` | `url` |
| ユーザーメンション（表示名あり） | `<@U12345\|username>` | `@username` |
| ユーザーメンション（IDのみ） | `<@U12345>` | `@U12345`（表示名不明のためIDをそのまま使用） |
| チャンネルメンション | `<#C12345\|channel>` | `#channel` |
| 特殊メンション | `<!here>` / `<!channel>` / `<!everyone>` | `@here` / `@channel` / `@everyone` |
| 箇条書き | `• item` | `- item` |
| ネスト（2段） | `◦ item` | `  - item` |
| ネスト（3段） | `▪ item` | `    - item` |

## 注意点（手動変換時）

**コードブロックとインラインコードは最初に保護する。** 内部のテキストに変換ルールを誤適用しないよう、プレースホルダーに置き換えてから他の変換を行い、最後に復元する。

**太字とリスト記号の混同（Slack→Markdown方向）**  
Slackの `*text*` は太字だが、行頭の `* ` は箇条書きマーカー。`*text*` という形式（スペースなし・前後対称）のみを太字として扱う。

**テーブル変換（Markdown→Slack方向）**  
テーブルはそのまま維持する。区切り行（`|---|---|`）が残っていることがSlackの表描画に必要。除去すると表にならない。

## 出力形式

変換後のテキストのみを出力する。説明文・前後の比較・コードフェンスは不要。

判断が必要だった変換（画像URLに変換したなど）があれば、変換済みテキストの**後に1行**だけ補足する。
