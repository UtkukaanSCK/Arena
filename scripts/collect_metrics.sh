#!/usr/bin/env bash
# Read-only git metrics for one Arena worktree, compared against a base branch.
#
# Usage: collect_metrics.sh <worktree_path> <base_branch>
#
# Prints a JSON object with objective, agent-independent numbers:
# files changed, lines added, lines removed, commits ahead of base.
# Never modifies the worktree.
set -euo pipefail

worktree_path="${1:?usage: collect_metrics.sh <worktree_path> <base_branch>}"
base_branch="${2:?usage: collect_metrics.sh <worktree_path> <base_branch>}"

branch=$(git -C "$worktree_path" branch --show-current 2>/dev/null || true)
branch="${branch:-(detached)}"

numstat=$(git -C "$worktree_path" diff --numstat "${base_branch}...HEAD" 2>/dev/null || true)

files_changed=0
added=0
removed=0
while IFS=$'\t' read -r a r _path; do
  [ -z "${a:-}" ] && continue
  files_changed=$((files_changed + 1))
  case "$a" in (*[!0-9]*|'') ;; (*) added=$((added + a));; esac
  case "$r" in (*[!0-9]*|'') ;; (*) removed=$((removed + r));; esac
done <<< "$numstat"

commits_ahead=$(git -C "$worktree_path" rev-list --count "${base_branch}..HEAD" 2>/dev/null || echo "null")

cat <<JSON
{
  "worktree_path": "${worktree_path}",
  "branch": "${branch}",
  "base_branch": "${base_branch}",
  "files_changed": ${files_changed},
  "lines_added": ${added},
  "lines_removed": ${removed},
  "commits_ahead_of_base": ${commits_ahead}
}
JSON
