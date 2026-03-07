#!/bin/bash
# Backup transcript before context compaction
# stdin: JSON with transcript_path, session_id, trigger

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r .transcript_path)
SESSION_ID=$(echo "$INPUT" | jq -r .session_id)
TRIGGER=$(echo "$INPUT" | jq -r .trigger)

if [ -z "$TRANSCRIPT" ] || [ "$TRANSCRIPT" = "null" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

BACKUP_DIR="$HOME/.claude/transcripts"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DEST="$BACKUP_DIR/${TIMESTAMP}_${SESSION_ID}_${TRIGGER}.jsonl"

cp "$TRANSCRIPT" "$DEST"
