#!/usr/bin/env bash
# Auto-commit + push any new/changed files in this folder.
# Usage: ./autosync.sh          (one-shot, safe to run any time)
#        ./autosync.sh --watch  (loop forever, checks every 5 min)

set -uo pipefail
cd "$(dirname "$0")" || exit 1

GIT_DIR_WIN='C:/Program Files/Git/cmd/git.exe'
git() { "$GIT_DIR_WIN" "$@"; }

do_commit() {
  git add -A || return 1
  if git diff --cached --quiet; then
    echo "[autosync] no changes"
    return 0
  fi
  n=$(git diff --cached --name-only | wc -l)
  msg="autosync: $n file(s) at $(date '+%Y-%m-%d %H:%M:%S')"
  git commit -q -m "$msg" || { echo "[autosync] commit FAILED"; return 1; }
  if git push -q origin HEAD 2>/dev/null; then
    echo "[autosync] committed + pushed: $msg"
  else
    echo "[autosync] committed LOCALLY (push failed - offline?): $msg"
  fi
}

if [ "${1:-}" = "--watch" ]; then
  echo "[autosync] watching every 5 min. Ctrl+C to stop."
  while true; do do_commit; sleep 300; done
else
  do_commit
fi
