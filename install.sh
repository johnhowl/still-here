#!/usr/bin/env bash
#
# Install the session-handover workflow into a project.
#
#   ./install.sh /path/to/project ["Project Name"]
#
# Lays down four things:
#   docs/handover/README.md              entry page (navigation, never status)
#   docs/handover/next-session-prompt.md task file (overwrite-only, has the tree)
#   docs/plan/tracker.md                 the single source of truth
#   docs/workflow/...METHOD              why each rule exists
# and wires two:
#   .claude/settings.json                SessionStart hook, auto-loads the task file
#   CLAUDE.md                            fallback + the wrap-up trigger phrase
#
# Never overwrites. Existing files are reported and left alone -- an existing
# handover is someone's work. settings.json is MERGED with jq, and re-running
# does not duplicate the hook.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL="$HERE/templates"

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  echo "usage: $0 /path/to/project [\"Project Name\"]" >&2
  exit 2
fi
[[ -d "$TARGET" ]] || { echo "no such directory: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"
NAME="${2:-$(basename "$TARGET")}"
TODAY="$(date +%Y-%m-%d)"

command -v jq >/dev/null || { echo "jq is required (the hook uses it too)" >&2; exit 2; }

mkdir -p "$TARGET/docs/handover" "$TARGET/docs/plan" \
         "$TARGET/docs/design" "$TARGET/docs/testing" "$TARGET/docs/workflow"

render() {  # render <template> <destination>
  local src="$1" dst="$2"
  if [[ -e "$dst" ]]; then
    echo "  keep   ${dst#$TARGET/}  (exists)"
    return
  fi
  sed -e "s|{{PROJECT}}|$NAME|g" -e "s|{{DATE}}|$TODAY|g" "$src" > "$dst"
  echo "  write  ${dst#$TARGET/}"
}

render "$TPL/handover-README.md"      "$TARGET/docs/handover/README.md"
render "$TPL/next-session-prompt.md"  "$TARGET/docs/handover/next-session-prompt.md"
render "$TPL/tracker.md"              "$TARGET/docs/plan/tracker.md"
render "$HERE/METHOD.md"              "$TARGET/docs/workflow/portable-session-handover.md"

# --- SessionStart hook: merge, never clobber -------------------------------
SETTINGS="$TARGET/.claude/settings.json"
mkdir -p "$TARGET/.claude"
HOOK_CMD="$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$TPL/session-start-hook.json")"

if [[ ! -f "$SETTINGS" ]]; then
  cp "$TPL/session-start-hook.json" "$SETTINGS"
  echo "  write  .claude/settings.json  (SessionStart hook)"
elif jq -e --arg c "$HOOK_CMD" \
      '.hooks.SessionStart // [] | .[] | .hooks[]? | select(.command == $c)' \
      "$SETTINGS" >/dev/null 2>&1; then
  echo "  keep   .claude/settings.json  (hook already present)"
else
  # Merge into whatever is there. Other hooks and settings are preserved.
  tmp="$(mktemp)"
  jq --slurpfile add "$TPL/session-start-hook.json" \
     '.hooks = ((.hooks // {}) | .SessionStart = ((.SessionStart // []) + $add[0].hooks.SessionStart))' \
     "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "  merge  .claude/settings.json  (SessionStart hook added)"
fi

# --- CLAUDE.md: append the handover section --------------------------------
CLAUDEMD="$TARGET/CLAUDE.md"
if [[ -f "$CLAUDEMD" ]] && grep -q "Session handover" "$CLAUDEMD"; then
  echo "  keep   CLAUDE.md  (handover section already present)"
else
  [[ -f "$CLAUDEMD" ]] || printf '# %s\n' "$NAME" > "$CLAUDEMD"
  printf '\n' >> "$CLAUDEMD"
  cat "$TPL/CLAUDE-section.md" >> "$CLAUDEMD"
  echo "  append CLAUDE.md  (handover section)"
fi

cat <<EOF

Installed into $TARGET

Next, in this order:
  1. Fill the <placeholders> in docs/handover/next-session-prompt.md --
     above all the TREE (where you are, and what is left one level up).
  2. Fill the panorama table in docs/handover/README.md: one row per line of
     work, each pointing at the document that MAINTAINS its status. Do not
     write status there; that is what rots.
  3. Add a status script that prints branch / worktree / unpushed / test
     counts, so the task file never has to write those numbers down.
  4. Read docs/workflow/portable-session-handover.md. Every rule in it has a
     real incident attached -- rules get bypassed, incidents do not.

The hook fires on the NEXT session, not this one. If it does not, open
/hooks once (reloads config) or restart.
EOF
