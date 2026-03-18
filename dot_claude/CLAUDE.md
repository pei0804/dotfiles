## Workflow

- 非自明なタスク（3ステップ以上 or 設計判断あり）は plan mode で始める
- 途中で想定外が起きたら即 re-plan。押し通さない
- 完了前に「staff engineer が承認するか？」で自己チェック
- 非自明な変更では「もっとエレガントな方法は？」と一度立ち止まる

## Self-Improvement

- ユーザーから修正を受けたら `tasks/lessons.md` にパターンを記録
- セッション開始時に該当プロジェクトの lessons を確認

## Task Management

1. `tasks/todo.md` に計画を書く → 確認を取る → 実行しながらチェック
2. 修正を受けたら `tasks/lessons.md` を更新

## 技術哲学

記事、Issue、ADR、Design Docなどを書くとき、`~/.claude/references/tech_philosophy.md` を読んで骨子とする。

## Worktree First

ファイル編集を伴う作業を開始する前に、現在の作業環境を確認する。

- mainブランチの場合: worktreeを作成してから作業を開始する
- 既存ブランチでworktree外の場合: worktreeへの移行を提案する
- 作業開始時に「worktreeを作成しますか？」と確認する

## References

- Issue/PR作成時は `~/.claude/references/issue_pr_rules.md` を参照
- セッション開始時は `~/.claude/references/plugin_management.md` を確認
