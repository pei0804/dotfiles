## コード設計

- 最初に思いついた案を一度疑う
- 賢さより可読性と保守性
- ネストするくらいならアーリーリターン
- 読めば分かる名前にする。説明が必要なら分割のサイン
- コメントは Why だけ。What はコードに語らせる
- 迷ったら言語の慣習に合わせる
- API にフィルター機能があればサーバーサイドで絞る。全件取得してローカルでフィルターしない

## 開発スタイル

- 不明瞭な指示は聞き返す。推測で埋めない
- TDD で進める: 探索 → Red → Green → Refactoring
- 想定外が出たら止まる。押し通さない
- 出す前に staff engineer の目で読み直す

## Writing

- 箇条書きは最低限。並列なら箇条書き、順序なら数字付き、それ以外は文章
- AI向けドキュメント（AGENTS.md など）は断定する。どちらとも取れる書き方を避ける
- 日本語の文章で `—`（em dash）を使わない。英語では可
- 日本語で箇条書きの直前に `：` を置かない

## 言語

- 略語・短縮形を使わない（例: Salesforce ×SF、Snowflake ×SF）
  - コード中の定着略語（API, URL, ID 等）は除く
- 公開リポジトリではドキュメントやコミットメッセージを英語で記述する

<important if="writing articles, Issues, ADRs, or Design Docs">
## 技術哲学

記事、Issue、ADR、Design Docなどを書くとき、`~/.claude/references/tech_philosophy.md` を読んで骨子とする。
</important>

<important if="about to edit files or start implementation">
## Worktree First

ファイル編集を伴う作業を開始する前に、現在の作業環境を確認する。

- mainブランチの場合: worktreeを作成してから作業を開始する
- 既存ブランチでworktree外の場合: worktreeへの移行を提案する
- 作業開始時に「worktreeを作成しますか？」と確認する
</important>

<important if="working with Issues or Pull Requests">
## Issue/PR

- 作成時は `~/.claude/references/issue_pr_rules.md` を参照
</important>

<important if="starting a new session or managing plugins">
## References: Plugin Management

- セッション開始時は `~/.claude/references/plugin_management.md` を確認
</important>
