## Workflow Orchestration

### Plan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

### Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests - then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Dotfiles Management (chezmoi)

- **絶対に `~/.config/` や `~/.claude/` を直接編集しない**
- dotfiles の変更は必ず chezmoi ソース (`~/.local/share/chezmoi/`) 側を編集する
  - `~/.config/foo/bar` → `~/.local/share/chezmoi/dot_config/foo/bar` を編集
  - `~/.claude/CLAUDE.md` → `~/.local/share/chezmoi/dot_claude/CLAUDE.md` を編集
- 編集後は `chezmoi apply` で反映する
- 新しいファイルを管理対象に追加する場合は `chezmoi add <path>` を使う

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

## Plugin Management

### cekernel plugin auto-update
- On session start, pull the latest main for the cekernel plugin:
  ```bash
  git -C ~/.claude/plugins/marketplaces/clonable-eden-plugins pull origin main --quiet
  ```

## Issue & PR Rules

### Permalink Usage

Always use GitHub permalinks (commit SHA-based) when referencing source code in Issues and PRs.

- Never use branch-based links (`/blob/main/...`)
- Always use commit SHA-based links (`/blob/abc1234/...`)
- Use `#L10-L20` format for line ranges

### Scripts Require Tests

When writing one-shot scripts (batch replacements, migrations, etc.), always write test code alongside them.

- Write the script and its tests together — never mark a script task as complete without tests
- Tests must verify correctness using real input/output samples
- PRs must describe what the script does and what tests were passed
