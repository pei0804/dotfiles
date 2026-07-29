## コード設計

- 最初に思いついた案を一度疑う
- 賢さより可読性と保守性
- ネストするくらいならアーリーリターン
- 読めば分かる名前にする。説明が必要なら分割のサイン
- API にフィルター機能があればサーバーサイドで絞る。全件取得してローカルでフィルターしない
- タスクに必要な範囲を超えて機能追加・リファクタリング・抽象化をしない。仮定の将来要件に備えない
- コードを直接変えられるなら、フィーチャーフラグや後方互換シムでしのがず直接変える
- 起こり得ないケースのエラー処理・フォールバック・バリデーションを書かない。検証はシステム境界（ユーザー入力・外部 API）にだけ置き、内部コードとフレームワークの保証は信頼する

## 開発スタイル

- 不明瞭な指示は聞き返す。推測で埋めない
- TDD で進める: 探索 → Red → Green → Refactoring
- 想定外が出たら止まる。押し通さない
- 独立したサブタスクはサブエージェントに委任し、完了を待たずに並行して進める。脱線や文脈不足には介入する
- 出す前に staff engineer の目で読み直す。大きめの成果物は新しいコンテキストの検証サブエージェントで仕様と突き合わせる
- 進捗・完了の報告は、このセッションのツール結果で裏付けられることだけ書く。未検証のことは未検証と明示する

## Writing

- 箇条書きは最低限。並列なら箇条書き、順序なら数字付き、それ以外は文章
- AI向けドキュメント（AGENTS.md など）は断定する。どちらとも取れる書き方を避ける
- 日本語でダッシュ・横線記号（`—` `──` `―`）を使わない。ファイル編集でもチャット応答でも同じ。英語では可
- 日本語で箇条書きの直前に `：` を置かない

## 言語

- 略語・短縮形を使わない（例: Salesforce ×SF、Snowflake ×SF、Google Workspace ×GWS）
  - コード中の定着略語（API, URL, ID 等）と社内で定着した固有略語（ZERO, CMF 等）は除く
- 日本語の文章にカジュアルな英語表現を混ぜない（例: nit、LGTM、FYI、net positive）。技術用語・製品名は除く
- 公開リポジトリではドキュメントやコミットメッセージを英語で記述する

<important if="writing articles, Issues, ADRs, or Design Docs">
## 技術哲学

記事、Issue、ADR、Design Docなどを書くとき、`~/.claude/references/tech_philosophy.md` を読んで骨子とする。
</important>

<important if="writing or revising articles or long-form Japanese prose">
## 執筆哲学・推敲ルール

記事や長文の日本語を書く・推敲するとき、`~/.claude/references/writing_philosophy.md` を読む。執筆哲学に加えて、文体ルールと推敲ルール（ダッシュ禁止、直訳調の平易化、引用スタイル、冗長圧縮など）を定義している。
</important>

<important if="about to edit files or start implementation">
## Worktree First

ファイル編集を伴う作業を開始する前に、現在の作業環境を確認する。

- mainブランチの場合: worktreeを作成してから作業を開始する
- 既存ブランチでworktree外の場合: worktreeへの移行を提案する
- 作業開始時に「worktreeを作成しますか？」と確認する
- worktree の新ブランチから push するときは必ず明示 refspec を使う: `git push origin HEAD:refs/heads/<branch>`。グローバルに push.default=tracking が設定されているため、`git push -u origin <branch>` でも upstream（origin/main を指していることがある）へ push されるトラップがある。push 後に `git branch --set-upstream-to=origin/<branch>` で upstream を張り直す
</important>

<important if="working with Issues or Pull Requests">
## Issue/PR

- 作成時は `~/.claude/references/issue_pr_rules.md` を参照
</important>

<important if="starting a new session or managing plugins">
## References: Plugin Management

- セッション開始時は `~/.claude/references/plugin_management.md` を確認
</important>
