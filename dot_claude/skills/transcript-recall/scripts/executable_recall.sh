#!/bin/bash
# Recall past transcripts
# Usage: recall.sh [--after YYYY-MM-DD] [--before YYYY-MM-DD] [--project KEYWORD] [--list] [--file PATH]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/parse_transcripts.py" "$@"
