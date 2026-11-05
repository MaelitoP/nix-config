[ -z "${SESSION_TITLE_HOOK:-}" ] || exit 0

mode=$1
input=$(cat)
session_id=$(jq -r '.session_id' <<<"$input")
cache=${TMPDIR:-/tmp}/claude-session-titles/$session_id

apply() {
  [ -f "$cache" ] || exit 0
  title=$(<"$cache")
  rm -f "$cache"
  current=$(jq -r '.session_title // ""' <<<"$input")
  [ -n "$title" ] && [ "$title" != "$current" ] || exit 0
  event=$(jq -r '.hook_event_name' <<<"$input")
  jq -cn --arg t "$title" --arg e "$event" '{hookSpecificOutput:{hookEventName:$e,sessionTitle:$t}}'
}

refresh() {
  transcript=$(jq -r '.transcript_path' <<<"$input")
  [ -f "$transcript" ] || exit 0
  prompts=$(jq -c 'select(.type=="user" and (.message.content|type)=="string")
    | .message.content
    | select((startswith("Another Claude session sent a message") or startswith("[Request interrupted")) | not)' "$transcript")
  count=$(grep -c . <<<"$prompts" || true)
  every=${SESSION_TITLE_EVERY:-5}
  [ "$count" -eq 1 ] || { [ "$count" -gt 0 ] && [ $((count % every)) -eq 0 ]; } || exit 0
  cwd=$(jq -r '.cwd' <<<"$input")
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  recent=$(tail -n 8 <<<"$prompts" | jq -r '.[0:300]')
  last=$(jq -r '.last_assistant_message // ""' <<<"$input" | head -c 600)
  out=$(mktemp)
  SESSION_TITLE_HOOK=1 CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1 CLAUDE_CODE_DISABLE_CLAUDE_MDS=1 CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 \
    claude -p --model haiku --no-session-persistence --setting-sources "" --disable-slash-commands --strict-mcp-config --tools "" --max-turns 1 \
    "Name this coding session. Reply with the title only: 3 to 7 words, Title Case, specific to what was actually worked on, no prefix, no quotes, no trailing period. Keep a ticket id such as sc-123456 if one appears.
Repository: $(basename "$cwd")
Branch: $branch
Recent user prompts, oldest first:
$recent
Last assistant message:
$last" </dev/null >"$out" 2>/dev/null || true
  title=$(tail -n 1 "$out" | sed -E 's/^ *(session )?title: *//I; s/"//g' | cut -c1-80)
  rm -f "$out"
  [ -n "$title" ] || exit 0
  mkdir -p "$(dirname "$cache")"
  printf '%s\n' "$title" > "$cache"
}

case $mode in
  apply) apply ;;
  refresh) refresh >/dev/null 2>&1 & ;;
esac
