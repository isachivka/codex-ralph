#!/usr/bin/env bash

set -euo pipefail

SCRIPT_PATH="$(python3 - <<PY
import os
print(os.path.realpath("${BASH_SOURCE[0]}"))
PY
)"
ROOT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
SPRINT_FILE=""
MAX_ITERATIONS=10
NOTES_FILE=""
SESSION_EMOJI=""
USE_CURSOR_AGENT=false
USE_GEMINI_AGENT=false

session_emoji() {
  if [[ -n "${SESSION_EMOJI}" ]]; then
    echo "${SESSION_EMOJI}"
    return
  fi
  local emoji_pool=(
    "🧭" "🧩" "🧪" "🛰️" "🪁"
    "🪐" "🎛️" "🧿" "🧲" "🪄"
    "🧰" "🪚" "🪝" "🪶" "🧯"
    "🧵" "🧶" "🧷" "🪙" "🪬"
  )
  local index=$((RANDOM % ${#emoji_pool[@]}))
  SESSION_EMOJI="${emoji_pool[$index]}"
  echo "${SESSION_EMOJI}"
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
Usage: ralph-loop SPRINT_PATH [--max-iterations=N] [--cursor-agent]

Options:
  SPRINT_PATH            Path to the sprint markdown file (required).
  --max-iterations=N     Stop after N iterations (0 = no limit, default 10).
  --cursor-agent         Use cursor-agent instead of codex (default: disabled).
  --gemini-agent         Use gemini-agent instead of codex (default: disabled).
  -h, --help             Show this help.
USAGE
}

session_emoji >/dev/null

for arg in "$@"; do
  case "$arg" in
    --max-iterations=*)
      MAX_ITERATIONS="${arg#*=}"
      ;;
    --cursor-agent)
      USE_CURSOR_AGENT=true
      ;;
    --gemini-agent)
      USE_GEMINI_AGENT=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -z "$SPRINT_FILE" ]]; then
        SPRINT_FILE="$arg"
      else
        echo "Unexpected argument: $arg" >&2
        usage >&2
        exit 1
      fi
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

total_count() {
  python3 - <<PY
from pathlib import Path
import re

path = Path("$SPRINT_FILE")
text = path.read_text(encoding="utf-8")
items = re.findall(r"^## \[( |x|X)\] ", text, flags=re.M)
print(len(items))
PY
}

current_index() {
  python3 - <<PY
from pathlib import Path
import re

path = Path("$SPRINT_FILE")
text = path.read_text(encoding="utf-8")
items = re.findall(r"^## \[( |x|X)\] ", text, flags=re.M)
remaining = sum(1 for m in items if m.strip() != "x")
total = len(items)
current = total - remaining + 1 if remaining > 0 else total
print(current)
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

progress_bar() {
  local completed="$1"
  local total="$2"
  python3 - <<PY
completed = $completed
total = $total
filled = "🟩" * completed
empty = "⬜️" * (total - completed)
print(filled + empty)
PY
}

iteration=1
while true; do
  remaining="$(remaining_count)"
  if [[ "$remaining" == "0" ]]; then
    total="$(total_count)"
    session_marker="$(session_emoji)"
    progress="$(progress_bar "$total" "$total")"
    send_telegram "${session_marker}"$'\n'"✅ All requirements completed"$'\n'"🎯 ${total} of ${total}"$'\n'"${progress}"
    echo "All sprint requirements complete."
    echo "<promise>DONE</promise>"
    exit 0
  fi

  if [[ "$MAX_ITERATIONS" -gt 0 && "$iteration" -gt "$MAX_ITERATIONS" ]]; then
    echo "Reached max iterations ($MAX_ITERATIONS) with $remaining remaining." >&2
    exit 2
  fi

  desc="$(next_description)"
  total="$(total_count)"
  current="$(current_index)"
  completed=$((current - 1))
  session_marker="$(session_emoji)"
  progress="$(progress_bar "$completed" "$total")"
  send_telegram "${session_marker}  ${desc}"$'\n'"🎯 ${current} of ${total}"$'\n'"${progress}"
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

  if [[ "$USE_CURSOR_AGENT" == "true" ]]; then
    cursor-agent -f -p < "$prompt_tmp"
  elif [[ "$USE_GEMINI_AGENT" == "true" ]]; then
    gemini < "$prompt_tmp"
  else
    codex exec - < "$prompt_tmp"
  fi

  rm -f "$prompt_tmp"

  iteration=$((iteration + 1))
done
