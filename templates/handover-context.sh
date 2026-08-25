#!/usr/bin/env bash
#
# SessionStart hook body: inject the task file, and say whether it is STALE.
#
# Loading the task file is automatic. Writing it is not -- a session can be
# closed at any moment without anyone saying "wrap up", and then the next one
# opens onto a task file describing work that is already done, with no reason
# to doubt it. That is the failure this check exists for.
#
# It does not try to decide whether a wrap-up happened. It reports two facts
# and lets the reader judge:
#
#   commits since the task file last changed   > 0 means work landed after it
#   uncommitted changes in the tree            > 0 means work is in flight
#
# Either can be innocent (a typo fix after wrap-up, an unrelated branch), so
# this warns rather than blocks. What it prevents is the silent case: acting
# on a stale task file without knowing it is stale.
set -u

root="${CLAUDE_PROJECT_DIR:-.}"
rel="docs/handover/next-session-prompt.md"
file="$root/$rel"
[ -f "$file" ] || exit 0

note=""
if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
  last="$(git -C "$root" log -1 --format=%H -- "$rel" 2>/dev/null || true)"
  if [ -n "$last" ]; then
    after="$(git -C "$root" rev-list --count "$last"..HEAD 2>/dev/null || echo 0)"
    dirty="$(git -C "$root" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    if [ "${after:-0}" -gt 0 ] || [ "${dirty:-0}" -gt 0 ]; then
      note="⚠️ 任务书可能已过期：它最后一次更新之后又有 ${after} 个提交，工作区有 ${dirty} 处未提交改动。

上一轮很可能**没有收口**（用户直接关掉了对话）。所以下面这份任务书描述的，
可能是**已经做完的事**。

**开工前先核对实际状态**：跑状态脚本、\`git log --oneline -15\`、看交接件最后一个
\`## 0x\` 节，确认任务是否仍然成立。**不要盲信下面的内容。**
若确认已过期，先把它更新到当前状态，再开始干活。

"
    fi
  fi
fi

jq -Rs --arg p "$rel" --arg n "$note" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:
     ($n + "=== 交接工作流：本轮任务书 " + $p + " ===\n本文件已自动载入，不必再读一遍。\n\n" + .)}}' \
  "$file"
