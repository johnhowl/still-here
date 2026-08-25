# still-here

**Every new AI session starts from zero. This one doesn't.**

A session-handover workflow for [Claude Code](https://claude.com/claude-code):
the next session opens already knowing what to do, where the project is, and
which conclusions were overturned last round — with no opening message from you.

```bash
git clone https://github.com/johnhowl/still-here
./still-here/install.sh ~/your-project "Your Project"
```

That's it. Open a new session in that project and the task file is already in
context.

---

## The problem it solves

You finish a session. You open a new one. The model remembers nothing.

You paste a summary. It's a little out of date. You paste a longer one. Now
there are two summaries and only one of them gets maintained. Thirty rounds
later you have a `docs/` folder that nobody trusts, and the new session trusts
it most of all.

Three distinct diseases, and they need three different cures:

| Disease | What it looks like |
|---|---|
| **Amnesia** | The new session redoes work, or overturns a conclusion that was already measured |
| **Doc rot** | Status is written in three places, one is maintained, the other two are lies — **and the entry page is usually one of the lies** |
| **Tunnel vision** | The session finishes "the task" and reports the project done, not knowing four other workstreams exist |

---

## What you get

Six files, each with one job. The split is the whole design — mixing them is
what rots documentation.

| File | Job | Mutability |
|---|---|---|
| `docs/handover/next-session-prompt.md` | **This round's** task + a **"where am I" tree** | **Overwrite-only** — rewritten whole each round, so it never bloats |
| `docs/handover/README.md` | Panorama, workflow, gate commands | **Pointers only, never status** |
| `docs/plan/tracker.md` | The single list of everything outstanding | Living document |
| `docs/workflow/portable-session-handover.md` | Why each rule exists | Copied from `METHOD.md` |
| `.claude/settings.json` | **SessionStart hook — auto-loads the task file** | Merged into whatever you already have |
| `CLAUDE.md` | Fallback if the hook is off + the wrap-up trigger phrase | One section appended |

The installer **never overwrites**. `settings.json` is merged with `jq`, your
existing hooks and permissions survive, and re-running doesn't duplicate
anything.

---

## The part people copy first: the tree

The task file opens with this, redrawn every round:

```
Your Project
├─ A. Backend ················ shipped
├─ B. Algorithms
│  └─ Beamforming ⬅ current line
│     └─ Validation ladder ⬅ you are here
│        ├─ 1 single source ✅
│        ├─ 2 two sources ✅
│        └─ 3 three sources ⬅ this round
├─ C. GUI ···················· 🔒 blocked on hardware
└─ D. Follow-on work
```

plus a table saying **what remains one level up, two levels up, and at the
root**.

This is the only thing in the system that answers *"done — now what?"*.

⚠️ **And it must live in the overwrite-only file.** Git enforces walking back
up a branch with commits; a document cannot. The walk-up is a **convention
maintained by redrawing, not a mechanism** — put it in an append-only file and
it's wrong after one round. That limitation is documented rather than hidden.

---

## Two rules that aren't about handover at all

`METHOD.md` carries two disciplines that apply to any project with tests or
acceptance numbers. Both came from real incidents:

**Measure the no-information baseline first.** Not just "what does this metric
read on random input" — **also "what do the acceptance numbers read when the
code under test never executes"**.

> A change shipped with three acceptance numbers. **Every one of them was
> satisfied by "the function returns false."** The code path had never
> executed since the day it landed. Three rounds of a fully green suite went by
> before anyone noticed.

**A new assertion must be shown able to fail** — and that check must be
automated, because doing it by hand only works when someone remembers.

> The same class of bug hit three times. Only the third was caught, and only
> because someone manually deleted the thing an assertion protected and saw
> that nothing moved.

`METHOD.md` §6 gives a language-agnostic way to gate this, including the three
places it's easy to get wrong (mutate *behaviour*, not the assertion's input;
match the *failure message*, not just the exit code; don't auto-enumerate
mutations).

---

## Why the entry page is navigation-only

The rule that surprises people: **the entry page is forbidden from stating
status.** It came from this:

> The entry page said *"read section 0k — the current state."* The file had
> moved on to 0p, five sections back. It said the window-length decision was
> "64 ms," while the config had been 32 ms for weeks. It listed a debt as
> outstanding that had been paid off long before.
>
> Three lies at once, in the document a new session reads first and trusts
> most. Not carelessness — **mechanism**: the same fact written in two places,
> one maintained, guarantees the other drifts.

So: **summaries hold pointers, never values.** Chapter references became
"read the last `## 0x` section" (with the command that finds it) instead of a
hardcoded number.

---

## Using it day to day

**New session** — say nothing. The hook already injected the task file.
(If it didn't: open `/hooks` once to reload, or restart.)

**Wrapping up** — say *"按交接工作流收口"* / *"wrap up per the handover
workflow"*, and four things happen:

1. Rewrite the task file's task section (overwrite) and **redraw the tree**
2. Append a new state section to the handover, stating **which earlier
   conclusions this round overturned**
3. Update the tracker
4. **Don't copy status into the entry page**

---

## Honest limits

Written down rather than glossed over — `METHOD.md` §7 has the full list.

- **The hook is Claude Code only.** Other clients fall back to the `CLAUDE.md`
  instruction, which is a convention, not a mechanism. That's why both layers
  get installed.
- **"Read the last `## 0x` section" depends on that naming.** Change the
  convention and the entry page needs updating with it.
- **The tree is redrawn by hand.** Forget, and it's stale — though because it
  lives in the overwrite-only file, the next round corrects it.
- **`jq` is required** (the hook uses it too).

---

## Layout

```
install.sh    Install into a project. Never overwrites; merges settings.json.
METHOD.md     The method: every rule with the incident that produced it,
              plus this system's own known failure modes.
templates/    Six skeletons the installer renders.
```

## License

MIT
