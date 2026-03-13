#!/bin/zsh

set -euo pipefail

target="${1:-.}"
line=""

if [ "$#" -ge 2 ] && [[ "$2" == <-> ]]; then
  line="$2"
fi

typeset -a candidates
typeset -A seen
context_locked="false"

detect_jetbrains_from_process_tree() {
  local pid="$PPID"
  local depth=0
  local cmd=""

  while [ -n "$pid" ] && [ "$pid" -gt 1 ] && [ "$depth" -lt 20 ]; do
    cmd="$(ps -o command= -p "$pid" 2>/dev/null || true)"

    if [[ "$cmd" == *"/PyCharm.app/"* ]] || [[ "$cmd" == *" pycharm"* ]]; then
      echo "pycharm"
      return 0
    fi

    if [[ "$cmd" == *"/IntelliJ IDEA.app/"* ]] || [[ "$cmd" == *"/idea"* ]]; then
      echo "idea"
      return 0
    fi

    pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
    depth=$((depth + 1))
  done

  echo ""
}

add_candidate() {
  local name="$1"
  if [ -z "${seen[$name]:-}" ]; then
    candidates+=("$name")
    seen[$name]=1
  fi
}

is_xcode_target() {
  local path="$1"
  case "$path" in
    *.swift|*.xcodeproj|*.xcworkspace|*.pbxproj|*.storyboard|*.xib|*.plist)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

if [ -n "${PREFERRED_EDITOR:-}" ]; then
  case "$PREFERRED_EDITOR" in
    code|cursor|idea|pycharm)
      add_candidate "$PREFERRED_EDITOR"
      ;;
  esac
fi

if [ "${TERM_PROGRAM:-}" = "vscode" ]; then
  context_locked="true"
  add_candidate code
  add_candidate cursor
fi

if [ "${TERMINAL_EMULATOR:-}" = "JetBrains-JediTerm" ]; then
  context_locked="true"
  jetbrains_host="$(detect_jetbrains_from_process_tree)"
  frontmost_app=""
  if command -v osascript >/dev/null 2>&1; then
    frontmost_app="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || true)"
  fi

  if [ -n "${PYCHARM_HOSTED:-}" ] || [ "$jetbrains_host" = "pycharm" ] || [[ "$frontmost_app" == *"PyCharm"* ]]; then
    add_candidate pycharm
    add_candidate idea
  elif [ "$jetbrains_host" = "idea" ] || [[ "$frontmost_app" == *"IntelliJ IDEA"* ]]; then
    add_candidate idea
    add_candidate pycharm
  else
    add_candidate idea
    add_candidate pycharm
  fi
fi

if [ "$context_locked" = "false" ] && is_xcode_target "$target"; then
  add_candidate xcode
fi

add_candidate code
add_candidate cursor
add_candidate idea
add_candidate pycharm
add_candidate open_vscode

open_with_xcode() {
  if command -v xed >/dev/null 2>&1; then
    if [ -n "$line" ]; then
      xed --line "$line" "$target"
    else
      xed "$target"
    fi
  else
    open -a "Xcode" "$target"
  fi
}

open_with_code() {
  if [ -n "$line" ]; then
    code -g "${target}:${line}"
  else
    code -g "$target"
  fi
}

open_with_cursor() {
  if [ -n "$line" ]; then
    cursor -g "${target}:${line}"
  else
    cursor -g "$target"
  fi
}

open_with_idea() {
  if [ -n "$line" ]; then
    idea --line "$line" "$target"
  else
    idea "$target"
  fi
}

open_with_pycharm() {
  if [ -n "$line" ]; then
    pycharm --line "$line" "$target"
  else
    pycharm "$target"
  fi
}

for editor in "${candidates[@]}"; do
  case "$editor" in
    xcode)
      if command -v xed >/dev/null 2>&1 || command -v open >/dev/null 2>&1; then
        open_with_xcode
        exit 0
      fi
      ;;
    code)
      if command -v code >/dev/null 2>&1; then
        open_with_code
        exit 0
      fi
      ;;
    cursor)
      if command -v cursor >/dev/null 2>&1; then
        open_with_cursor
        exit 0
      fi
      ;;
    idea)
      if command -v idea >/dev/null 2>&1; then
        open_with_idea
        exit 0
      fi
      ;;
    pycharm)
      if command -v pycharm >/dev/null 2>&1; then
        open_with_pycharm
        exit 0
      fi
      ;;
    open_vscode)
      if command -v open >/dev/null 2>&1; then
        open -a "Visual Studio Code" "$target"
        exit 0
      fi
      ;;
  esac
done

echo "Error: no supported editor launcher found (code/cursor/idea/pycharm)." >&2
exit 1
