# dotfiles

```console
brew install chezmoi
chezmoi init --apply git@github.com:pei0804/dotfiles.git
make -C "$(chezmoi source-path)" all
```

## Agent instructions

`~/.agents/` is the source of truth for agent-facing instructions, skills, and reference documents. Every agent reaches it through a symlink or a thin wrapper, so one set of rules covers all of them.

| Path | Role |
|---|---|
| `~/.agents/AGENTS.md` | Vendor-neutral instructions. The source of truth |
| `~/.agents/skills/` | Skills in SKILL.md format |
| `~/.agents/references/` | Reference documents that the instructions and skills point to |
| `~/.claude/CLAUDE.md` | Imports `~/.agents/AGENTS.md`, then adds Claude Code specific instructions |
| `~/.claude/skills` | Symlink to `~/.agents/skills` |
| `~/.codex/AGENTS.md`, `~/.codex/skills` | Symlinks to the same files |
| `~/.gemini/GEMINI.md` | Symlink to `~/.agents/AGENTS.md`. Gemini CLI reads `~/.agents/skills/` natively |

Vendor-neutral rules go in `dot_agents/`. `dot_claude/` holds only what Claude Code alone has: hooks, settings, output styles, and plugin management.

## マニュアル設定

- [Docker](https://store.docker.com/editions/community/docker-ce-desktop-mac)
- [Google日本語入力](https://www.google.co.jp/ime/)
- JetBrains系
- Chrome
- VSCode
- Raycast
- StatusClock
- NightTone
- CelanShot X
- 1Password
- Zoom
