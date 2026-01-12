#!/usr/bin/env bash

set -euo pipefail

SCRIPT_PATH="$(python3 - <<PY
import os
print(os.path.realpath("${BASH_SOURCE[0]}"))
PY
)"
ROOT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
SPRINT_FILE=""
MAX_ITERATIONS=0
NOTES_FILE=""
SESSION_UUID=""

session_uuid() {
  if [[ -n "${SESSION_UUID}" ]]; then
    echo "${SESSION_UUID}"
    return
  fi
  SESSION_UUID="$(python3 - <<PY
import uuid
print(uuid.uuid4())
PY
)"
  echo "${SESSION_UUID}"
}

send_telegram() {
  local message="$1"
  if [[ -z "${CODEX_RALPH_TG_KEY:-}" || -z "${CODEX_RALPH_TG_CHAT:-}" ]]; then
    return
  fi
  curl -sS -o /dev/null -X POST \
    "https://api.telegram.org/bot${CODEX_RALPH_TG_KEY}/sendMessage" \
    -d "chat_id=${CODEX_RALPH_TG_CHAT}" \
    --data-urlencode "text=${message}" \
    || true
}

usage() {
  cat <<USAGE
Usage: ralph-loop --sprint=PATH [--max-iterations=N]

Options:
  --sprint=PATH          Path to the sprint markdown file (required).
  --max-iterations=N     Stop after N iterations (0 = no limit).
  -h, --help             Show this help.
USAGE
}

session_uuid >/dev/null

for arg in "$@"; do
  case "$arg" in
    --sprint=*)
      SPRINT_FILE="${arg#*=}"
      ;;
    --max-iterations=*)
      MAX_ITERATIONS="${arg#*=}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
 done

if [[ -z "$SPRINT_FILE" ]]; then
  echo "Sprint file path is required." >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$SPRINT_FILE" ]]; then
  echo "Sprint file not found: $SPRINT_FILE" >&2
  exit 1
fi

if [[ -z "$NOTES_FILE" ]]; then
  sprint_dir="$(cd "$(dirname "$SPRINT_FILE")" && pwd)"
  sprint_base="$(basename "$SPRINT_FILE")"
  notes_base="${sprint_base/Sprint_/SprintNotes_}"
  if [[ "$notes_base" == "$sprint_base" ]]; then
    notes_base="${sprint_base%.*}Notes.${sprint_base##*.}"
  fi
  NOTES_FILE="$sprint_dir/$notes_base"
fi

if [[ ! -f "$NOTES_FILE" ]]; then
  mkdir -p "$(dirname "$NOTES_FILE")"
  : > "$NOTES_FILE"
fi

PROMPT_FILE="$ROOT_DIR/agent/prompt.md"
if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

remaining_count() {
  python3 - <<PY
from pathlib import Path
import re

path = Path("$SPRINT_FILE")
text = path.read_text(encoding="utf-8")
items = re.findall(r"^## \[( |x|X)\] ", text, flags=re.M)
print(sum(1 for m in items if m.strip() != "x"))
PY
}

next_description() {
  python3 - <<PY
from pathlib import Path
import re

path = Path("$SPRINT_FILE")
text = path.read_text(encoding="utf-8")
for match in re.finditer(r"^## \[( |x|X)\] (.+)$", text, flags=re.M):
    checked = match.group(1)
    desc = match.group(2).strip()
    if checked != "x" and checked != "X":
        print(desc)
        break
PY
}

current_item_block() {
  python3 - <<PY
from pathlib import Path
import re

path = Path("$SPRINT_FILE")
lines = path.read_text(encoding="utf-8").splitlines()
start = None
end = None
for i, line in enumerate(lines):
    if re.match(r"^## \[( |x|X)\] ", line):
        if start is None:
            checked = line.split("[", 1)[1].split("]", 1)[0].strip()
            if checked.lower() != "x":
                start = i
        elif start is not None:
            end = i
            break
if start is None:
    print("<no remaining items>")
else:
    block = lines[start:end] if end is not None else lines[start:]
    print("\n".join(block))
PY
}

iteration=1
while true; do
  remaining="$(remaining_count)"
  if [[ "$remaining" == "0" ]]; then
    send_telegram "Ralph loop finished all requirements. Session ${SESSION_UUID}."
    echo "All sprint requirements complete."
    echo "<promise>DONE</promise>"
    exit 0
  fi

  if [[ "$MAX_ITERATIONS" -gt 0 && "$iteration" -gt "$MAX_ITERATIONS" ]]; then
    echo "Reached max iterations ($MAX_ITERATIONS) with $remaining remaining." >&2
    exit 2
  fi

  desc="$(next_description)"
  send_telegram "Ralph loop starting requirement: ${desc}. Session ${SESSION_UUID}."
  echo "Iteration $iteration - next requirement: $desc"

  prompt_tmp="$(mktemp)"
  {
    cat "$PROMPT_FILE"
    echo ""
    echo "Sprint file: $SPRINT_FILE"
    echo "Sprint notes file: $NOTES_FILE"
    echo ""
    echo "Current requirement (Markdown):"
    current_item_block
  } > "$prompt_tmp"

  codex exec - < "$prompt_tmp"

  rm -f "$prompt_tmp"

  iteration=$((iteration + 1))
done
