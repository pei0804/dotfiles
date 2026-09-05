#!/usr/bin/env python3
"""
Convert between GitHub Markdown and Slack formatting.

Usage:
  python convert.py --to-slack input.md
  python convert.py --to-markdown input.txt
  cat input.md | python convert.py --to-slack
"""

import re
import sys
import argparse


def _protect_code(text):
    """Replace code blocks and inline code with placeholders."""
    code_blocks = {}
    cb_idx = [0]
    inline_codes = {}
    ic_idx = [0]

    def save_fenced(m):
        key = f"\x00CB{cb_idx[0]}\x00"
        code_blocks[key] = m.group(0)
        cb_idx[0] += 1
        return key

    def save_inline(m):
        key = f"\x00IC{ic_idx[0]}\x00"
        inline_codes[key] = m.group(0)
        ic_idx[0] += 1
        return key

    text = re.sub(r'```[\w]*\n[\s\S]*?```', save_fenced, text)
    text = re.sub(r'`[^`\n]+`', save_inline, text)
    return text, code_blocks, inline_codes


def _restore_code(text, code_blocks, inline_codes):
    for key, val in inline_codes.items():
        text = text.replace(key, val)
    for key, val in code_blocks.items():
        text = text.replace(key, val)
    return text


def md_to_slack(text: str) -> str:
    text, code_blocks, inline_codes = _protect_code(text)

    # Strip language specifier from fenced code blocks
    code_blocks = {
        k: re.sub(r'^```\w+\n', '```\n', v)
        for k, v in code_blocks.items()
    }

    # Headers → bold (use placeholder to protect from italic pass)
    text = re.sub(
        r'^#{1,6}\s+(.+)$',
        lambda m: f'\x00BOLD\x00{m.group(1).strip()}\x00BOLD\x00',
        text,
        flags=re.MULTILINE,
    )

    # Bold + italic (before bold/italic individually)
    # ***text*** → *_text_* in Slack (bold+italic)
    text = re.sub(
        r'\*\*\*(.+?)\*\*\*',
        lambda m: f'\x00BOLD\x00_{ m.group(1) }_\x00BOLD\x00',
        text,
        flags=re.DOTALL,
    )

    # Bold: **text** or __text__ → placeholder first to protect from italic pass
    text = re.sub(
        r'\*\*(.+?)\*\*',
        lambda m: f'\x00BOLD\x00{ m.group(1) }\x00BOLD\x00',
        text,
        flags=re.DOTALL,
    )
    text = re.sub(
        r'__(.+?)__',
        lambda m: f'\x00BOLD\x00{ m.group(1) }\x00BOLD\x00',
        text,
        flags=re.DOTALL,
    )

    # Italic: *text* → _text_  (only original Markdown italic, not placeholders)
    text = re.sub(r'(?<![*_\w])\*([^*\n]+?)\*(?![*\w])', r'_\1_', text)

    # Restore bold placeholders → Slack *text*
    text = text.replace('\x00BOLD\x00', '*')

    # Strikethrough: ~~text~~ → ~text~
    text = re.sub(r'~~(.+?)~~', r'~\1~', text, flags=re.DOTALL)

    # Images: ![alt](url) → url  (must come before links)
    text = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', r'\2', text)

    # Links: [text](url) → <url|text>
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<\2|\1>', text)

    # Task lists (before regular list markers)
    text = re.sub(r'^(\s*)-\s+\[x\]\s+', r'\1☑ ', text, flags=re.MULTILINE | re.IGNORECASE)
    text = re.sub(r'^(\s*)-\s+\[\s\]\s+', r'\1☐ ', text, flags=re.MULTILINE)

    # Unordered lists with nesting support
    def list_bullet(m):
        indent = m.group(1)
        level = len(indent) // 2
        bullets = ['•', '◦', '▪']
        return indent + bullets[min(level, 2)] + ' '

    text = re.sub(r'^(\s*)[-*+]\s+', list_bullet, text, flags=re.MULTILINE)

    # Horizontal rules → remove
    text = re.sub(r'^[-*_]{3,}\s*$', '', text, flags=re.MULTILINE)

    # Tables: leave as-is including separator rows (|---|---|).
    # Slack renders pipe tables as proper tables when the separator row is present.

    text = _restore_code(text, code_blocks, inline_codes)

    # Collapse triple+ blank lines
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()


def slack_to_md(text: str) -> str:
    text, code_blocks, inline_codes = _protect_code(text)

    # User mentions: <@U12345|username> → @username, <@U12345> → @U12345
    text = re.sub(r'<@([A-Z0-9]+)\|([^>]+)>', r'@\2', text)
    text = re.sub(r'<@([A-Z0-9]+)>', r'@\1', text)

    # Channel mentions: <#C12345|channel-name> → #channel-name
    text = re.sub(r'<#([A-Z0-9]+)\|([^>]+)>', r'#\2', text)

    # Special broadcast mentions
    text = re.sub(r'<!here>', '@here', text)
    text = re.sub(r'<!channel>', '@channel', text)
    text = re.sub(r'<!everyone>', '@everyone', text)

    # Links: <url|text> → [text](url), <url> → url
    text = re.sub(r'<(https?://[^|>]+)\|([^>]+)>', r'[\2](\1)', text)
    text = re.sub(r'<(https?://[^>]+)>', r'\1', text)

    # Bold: *text* → **text**
    # Avoid matching list-style "* " at line start, or lone asterisks
    text = re.sub(r'(?<![*\w])\*([^*\n]+?)\*(?![*\w])', r'**\1**', text)

    # Strikethrough: ~text~ → ~~text~~
    text = re.sub(r'(?<![~])\~([^~\n]+?)\~(?![~])', r'~~\1~~', text)

    # Bullet points
    text = re.sub(r'^• ', '- ', text, flags=re.MULTILINE)
    text = re.sub(r'^  ◦ ', '  - ', text, flags=re.MULTILINE)
    text = re.sub(r'^    ▪ ', '    - ', text, flags=re.MULTILINE)

    text = _restore_code(text, code_blocks, inline_codes)
    return text.strip()


def main():
    parser = argparse.ArgumentParser(
        description='Convert between GitHub Markdown and Slack formatting'
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--to-slack', action='store_true', help='Markdown → Slack')
    group.add_argument('--to-markdown', action='store_true', help='Slack → Markdown')
    parser.add_argument('file', nargs='?', help='Input file (omit to read from stdin)')

    args = parser.parse_args()

    if args.file:
        with open(args.file, encoding='utf-8') as f:
            text = f.read()
    else:
        text = sys.stdin.read()

    result = md_to_slack(text) if args.to_slack else slack_to_md(text)

    sys.stdout.write(result)
    if not result.endswith('\n'):
        sys.stdout.write('\n')


if __name__ == '__main__':
    main()
