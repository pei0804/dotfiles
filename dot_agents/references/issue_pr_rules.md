## Issue & PR Rules

### State the Assumed Reader

Decide who an Issue or PR is written for before drafting it, and confirm that reader with the user.

- Name the reader's role and team, and state what knowledge can be taken as given
- Write it into the background section as prose — do not add a separate "Assumed Reader" heading
- Match the vocabulary to that reader: exact table, column, and command names when only engineers read it; the words the business already uses when business readers do; formal terms explained on first use when both read it

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
