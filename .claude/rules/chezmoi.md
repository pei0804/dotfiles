---
globs: "dot_*/**"
description: chezmoi管理下のdotfilesを編集する際の安全ルール
---

## Dotfiles Management (chezmoi)

- **絶対に `~/.config/` や `~/.claude/` を直接編集しない**
- dotfiles の変更は必ず chezmoi ソース (`~/.local/share/chezmoi/`) 側を編集する
  - `~/.config/foo/bar` → `~/.local/share/chezmoi/dot_config/foo/bar` を編集
  - `~/.claude/CLAUDE.md` → `~/.local/share/chezmoi/dot_claude/CLAUDE.md` を編集
- 編集後は `chezmoi apply` で反映する
- 新しいファイルを管理対象に追加する場合は `chezmoi add <path>` を使う
