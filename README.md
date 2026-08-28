# Arena

A [Claude Code](https://claude.com/product/claude-code) skill that races
multiple **complete, competing solutions** to the same spec against each
other — in parallel, isolated git worktrees — and hands you an objective
comparison instead of a guess.

## Why

Every other parallel-agent pattern out there parallelizes *pieces* of
one agreed-on solution (split the work, merge it back). Arena does the
opposite: it takes 2-4 genuinely different architectural approaches to
the *same* problem, has each one implemented **to completion** — code
and tests, not a sketch — by its own agent in its own worktree, then
independently verifies and compares the results before you decide.

You get real, working code for every option, plus numbers: tests
passed, files touched, lines added/removed, and each agent's own
tradeoffs and risks — cross-checked, not just trusted.

## What it does

1. You give Arena a spec and (optionally) named approaches.
2. It locks the spec and approach list with you before dispatching
   anything.
3. Each approach runs as its own background agent in its own isolated
   git worktree — genuinely parallel, not sequential.
4. Every agent implements the full solution, writes and runs its own
   tests, and self-reports structured results.
5. Arena independently re-runs each agent's tests and pulls objective
   git metrics (lines changed, files touched, commits) rather than
   trusting the self-report alone.
6. It publishes a single comparison dashboard (metrics table,
   tradeoffs, risks, a recommendation) and lets you pick a winner.
7. Merging the winner and cleaning up the losing branches are both
   separate, explicit, human-confirmed steps — nothing is merged or
   deleted automatically.

## Install

Personal skill — available in every project on this machine once
installed:

```bash
git clone https://github.com/UtkukaanSCK/Arena ~/.claude/skills/arena
```

Or drop it into a single project instead, so it only applies there:

```bash
git clone https://github.com/UtkukaanSCK/Arena .claude/skills/arena
```

Claude Code auto-discovers `SKILL.md` files under `~/.claude/skills/`
or `.claude/skills/` at session start. If the top-level `skills/`
directory didn't already exist, restart Claude Code once after
installing so it starts watching the new directory.

## Use

In any git repository, with a clean working tree:

```
/arena Add rate limiting to the API. Approach A: token bucket in Redis. Approach B: fixed-window counter in Postgres.
```

Or let Claude propose the approaches itself:

```
/arena Add rate limiting to the API
```

## Requirements

- A git repository with a clean (or committed) working tree — Arena
  branches each competing agent from the current `HEAD` via
  `git worktree`.
- Bash (Git Bash on Windows) for the bundled metrics script.

## What's in this repo

| Path | Purpose |
|---|---|
| `SKILL.md` | The orchestration instructions Claude follows |
| `scripts/collect_metrics.sh` | Read-only git-metrics helper (files/lines/commits changed vs. base branch) — never modifies anything |

## Safety

Arena never merges or deletes anything on its own. Every git-affecting
action — the merge of the winning branch, cleanup of the losing
worktrees/branches — is a separate step that requires your explicit
confirmation, even after you've picked a winner.

## License

MIT — see [LICENSE](LICENSE).
