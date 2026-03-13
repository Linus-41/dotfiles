#!/bin/zsh

set -euo pipefail

MODEL="${OLLAMA_COMMIT_MODEL:-qwen2.5-coder:3b}"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is not installed."
  exit 1
fi

if ! command -v ollama >/dev/null 2>&1; then
  echo "Error: ollama is not installed or not in PATH."
  exit 1
fi

if ! command -v pbcopy >/dev/null 2>&1; then
  echo "Error: pbcopy is not available on this system."
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository."
  exit 1
fi

if git diff --staged --quiet; then
  echo "No staged changes found. Stage files first, then run again."
  exit 1
fi

staged_diff="$(git diff --staged --no-color)"

if [ -z "$staged_diff" ]; then
  echo "No staged diff content found."
  exit 1
fi

prompt=$(cat <<PROMPT
You are writing a git commit message.

Task:
- Read the staged diff.
- Return exactly one short commit message line.
- Use plain language only.
- No conventional commit prefix.
- No quotes, no markdown, no code fences, no explanation.
- Keep it under 72 characters.

Staged diff:
$staged_diff
PROMPT
)

raw_response="$(printf "%s" "$prompt" | TERM=dumb ollama run --hidethinking --nowordwrap "$MODEL" 2>/dev/null)"

message="$(
  printf "%s\n" "$raw_response" |
    sed -E $'s/\x1B\\[[0-9;?]*[ -/]*[@-~]//g' |
    sed -E 's/\[[0-9;?]*[ -/]*[@-~]//g' |
    tr -d '\000-\010\013\014\016-\037\177' |
    sed '/^[[:space:]]*$/d' |
    sed '/^```/d' |
    sed -E '/^[[:punct:][:space:]]*$/d' |
    head -n 1 |
    sed -E "s/^[[:space:]\"'\`-]+//; s/[[:space:]\"'\`]+$//" |
    tr '\n' ' ' |
    sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
)"

if [ -z "$message" ]; then
  echo "Error: failed to parse a commit message from model output."
  exit 1
fi

printf "%s" "$message" | pbcopy

echo "$message"
echo ""
echo "Copied to clipboard."
