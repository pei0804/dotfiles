#!/bin/bash
# Log all Bash tool commands to audit log
# stdin: JSON with tool_input.command

CMD=$(jq -r .tool_input.command)
echo "$(date +%Y-%m-%dT%H:%M:%S) $(pwd) $CMD" >> ~/.claude/command-audit.log
