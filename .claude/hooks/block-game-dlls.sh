#!/bin/bash
# PreToolUse hook: block edits to reference DLLs, game installs, and external repos
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Block .dll edits
if [[ "$FILE_PATH" == *.dll ]]; then
  echo '{"decision": "deny", "reason": "Cannot edit compiled DLL files"}' >&2
  exit 2
fi

# Block game install directories
if [[ "$FILE_PATH" == *"SteamLibrary"* ]] || [[ "$FILE_PATH" == *"steamapps"* ]]; then
  echo '{"decision": "deny", "reason": "Cannot edit game install files"}' >&2
  exit 2
fi

# Block reference repos (read-only copies of other mods)
if [[ "$FILE_PATH" == *"peterhaneve"* ]] || [[ "$FILE_PATH" == *"reference"* ]]; then
  echo '{"decision": "deny", "reason": "Read-only reference files"}' >&2
  exit 2
fi
