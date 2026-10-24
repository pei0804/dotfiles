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

### Attach Images and PDFs with `gh --attach`

When an Issue, PR, or comment needs a figure, screenshot, or document, upload the file with `gh ... --attach '<path>#<alt text>'` (gh 2.99.0+). Do not substitute a repository path link or a prose description.

- Supported types are png, jpg, jpeg, gif, webp, svg, mp4, mov, webm. SVG can be attached as is
- PDFs cannot be attached. Convert every page to PNG first and attach the PNGs: `pdftoppm -png -r 150 input.pdf out` (`-singlefile` for one page)
- A reference in the body is rewritten to the uploaded URL only when its path matches the attached path exactly. Attaching from a temp directory while writing `![alt](./file.png)` leaves a broken link plus an appended image. Either reference the exact path you attach, or write no reference and let the image be appended
- After posting, read the body back and confirm every image points to `https://github.com/user-attachments/...`
