---
name: arena
description: Use when the user wants to compare multiple full architectural approaches to the SAME spec by implementing each one to completion in an isolated worktree and comparing objective results (tests, LOC, complexity, tradeoffs). Not for exploring ideas before a decision is made (use superpowers:brainstorming) and not for splitting one solution into independent subtasks (use superpowers:dispatching-parallel-agents or superpowers:subagent-driven-development) — arena is specifically for racing N *competing complete solutions* against each other.
argument-hint: <spec description>
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/collect_metrics.sh *)
---

# Arena — Competing Solutions

## Overview

Given one bounded spec and 2-4 candidate architectural approaches, Arena
implements EACH approach as a full, working solution in its own isolated
git worktree, in parallel, unattended, to completion (code + tests) —
then produces an objective side-by-side comparison so the human picks a
winner with data instead of gut feel.

This is different from every other parallel-agent pattern in this
toolkit: those parallelize *pieces* of one solution. Arena parallelizes
*whole competing solutions* to the same problem.

**Announce at start:** "Using the arena skill to race N approaches against this spec."

## When NOT to use this

- The spec is still fuzzy / the user hasn't decided what "done" looks like → use `superpowers:brainstorming` first.
- There's really only one sane approach → just implement it normally.
- The spec bundles multiple independent subsystems → decompose first (brainstorming's scope-check), then arena each subsystem separately if it has genuine approach-level ambiguity.
- You just need to split ONE agreed design into parallel chunks of work → use `superpowers:dispatching-parallel-agents` or `superpowers:subagent-driven-development` instead.

## Step 0: Confirm scope and repo state

Arena requires a git repository with a clean (or committed) working tree —
each competing agent gets its own worktree branched from the current
HEAD. Run `git status` first; if there are uncommitted changes, ask the
user whether to commit/stash them before branching, per the standard
safety rules (never discard uncommitted work silently).

## Step 1: Lock the spec and the approaches

State the spec back to the user in your own words (one paragraph) to
confirm scope — this becomes the identical brief every competing agent
receives.

If the user already named specific approaches, use those. Otherwise
propose 2-4 candidate approaches yourself, each as one line: name +
one-sentence differentiator (e.g. "A: normalized relational schema",
"B: single denormalized table with computed views", "C: event-sourced
with projections"). Get explicit approval on the approach list before
dispatching anything — this list cannot be changed once agents start,
since it defines what's being compared.

Cap at 4 approaches. More than that produces noise, not signal, and
burns a lot of tokens/compute for diminishing insight.

## Step 2: Dispatch competing agents

For each approach, call the `Agent` tool with `isolation: "worktree"`
and `run_in_background: true` (the default — send all N calls in ONE
message so they truly run in parallel, not sequentially). Use
`subagent_type: "general-purpose"` unless the spec is clearly in one
domain covered by a more specific agent type.

Each agent's prompt MUST include, self-contained (the agent has no
memory of this conversation):

1. The full locked spec from Step 1, verbatim.
2. Its assigned approach name and differentiator, with an instruction
   to commit to that approach even if another seems better mid-way —
   the comparison is only meaningful if each agent actually explored
   its assigned lane.
3. An instruction to implement the COMPLETE solution: code + tests,
   run the tests, and fix failures before finishing.
4. An instruction to end its work by writing a file named
   `.arena-report.json` at the worktree root with exactly this shape:

```json
{
  "approach": "short name",
  "status": "complete | incomplete | blocked",
  "summary": "2-4 sentences describing what was built",
  "files_changed": ["path/one", "path/two"],
  "tests": {"command": "the exact command used to run tests", "passed": 0, "failed": 0},
  "tradeoffs": ["short bullet", "short bullet"],
  "risks": ["short bullet", "short bullet"],
  "notes_for_reviewer": "anything a human comparing approaches should know that doesn't fit above"
}
```

5. An explicit instruction NOT to push, merge, or touch any branch
   other than its own, and not to delete anything outside its worktree.

Do not race: after dispatching, do not fabricate or guess at results.
Wait for the actual completion notifications.

## Step 3: Collect and independently verify

When each agent finishes, its result names the worktree path and
branch. For each one:

1. Read `.arena-report.json` from that worktree.
2. Independently re-run the test command it reported (don't just trust
   the self-reported pass/fail — actually run it) from within that
   worktree.
3. Run `bash ${CLAUDE_SKILL_DIR}/scripts/collect_metrics.sh <worktree-path> <base-branch>`
   to get objective, agent-independent numbers: lines added/removed,
   files touched, commits ahead of base. This script only reads git
   metadata — it never modifies anything.

If an agent's self-report and your independent check disagree (e.g. it
claims tests pass but they don't), note the discrepancy explicitly in
the comparison — don't silently trust either source.

If an agent failed to produce a report or didn't finish, mark it
`incomplete` in the comparison rather than excluding it — a partial
result (e.g. "ran out of approach viability at step X") is still
useful signal for the human.

## Step 4: Build the comparison

Load the `artifact-design` skill, then load `dataviz` if you'll chart
the metrics (a small comparison bar/radar chart is often clearer than
a table alone for 3+ approaches). Publish a single HTML Artifact with:

- A metrics table: approach, status, tests passed/failed, files
  changed, LOC added/removed, and any domain-specific metric that
  matters for this particular spec (ask yourself what the user would
  actually decide on).
- Tradeoffs and risks per approach, pulled from the reports.
- Discrepancy notes from Step 3, if any.
- Your own recommendation with one-paragraph reasoning — rank by:
  (1) tests actually passing and spec fully addressed, (2) fewer/lower-
  severity risks, (3) lower complexity (LOC/files as a rough proxy,
  used as a tiebreaker only — never rank a broken solution above a
  working one just because it's smaller).

Do not silently pick a winner and merge it — the artifact is a
recommendation, not a decision.

## Step 5: Let the human decide, then act carefully

Present the artifact link and ask the user which approach to keep (or
whether they want changes/a rematch).

Once they choose:

- Merging the winning branch into the branch Arena started from is a
  git-affecting action — confirm the exact merge command with the user
  first, per standard git safety rules (prefer a regular merge or PR,
  never force-push).
- Cleaning up the losing worktrees/branches is destructive — ask
  explicitly and separately from the merge question. Never delete a
  losing worktree/branch without that explicit confirmation, even
  though the user picked a winner — they may want to keep a losing
  approach around for reference.

## Failure handling

- If every agent reports `blocked`/`incomplete`, say so plainly and
  show what each one hit — don't retry automatically or silently widen
  scope.
- If the repo has no `.git` (not a git repository), tell the user
  Arena needs one and offer to `git init`, per standard safety rules —
  do not proceed without it.
