## Issue & PR Rules

### Permalink Usage

Always use GitHub permalinks (commit SHA-based) when referencing source code in Issues and PRs.

- Never use branch-based links (`/blob/main/...`)
- Always use commit SHA-based links (`/blob/abc1234/...`)
- Use `#L10-L20` format for line ranges

### Referencing Issues and PRs

When mentioning an Issue or PR in body text, always link it at the point of mention.

- Write a full link, e.g. `[#123](https://github.com/org/repo/issues/123)` — never a bare `#123`, even within the same repository. A bare reference breaks the moment the text is copied outside GitHub
- Keep the link text to the number only. Embedding the title makes the link stale when the title changes
- Never paste a bare URL into body text
- A trailing "references" list is optional and never a substitute for linking at the point of mention

### Scripts Require Tests

When writing one-shot scripts (batch replacements, migrations, etc.), always write test code alongside them.

- Write the script and its tests together — never mark a script task as complete without tests
- Tests must verify correctness using real input/output samples
- PRs must describe what the script does and what tests were passed
