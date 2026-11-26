#!/usr/bin/env sh
# Validates branch names. Used by the pre-push hook (reads git's pre-push
# stdin) and by CI (pass the branch name as the first argument).
#
# Allowed:
#   main, development, production
#   <type>/<description>            feat/game-scene
#   codex/<description>             codex/game-setup
#   <type>/<TICKET>-<description>   fix/GAME-123-score-total
#   release/<semver>                release/1.2.0
#   hotfix/<description>            hotfix/login-crash
# <type>: feat fix refactor chore docs test perf ci build style revert hotfix
# <description>: lowercase letters, digits and single hyphens, max 50 chars.

TYPES="feat|fix|refactor|chore|docs|test|perf|ci|build|style|revert|hotfix|codex"
PATTERN="^(main|development|production|(${TYPES})/([A-Z][A-Z0-9]*-[0-9]+-)?[a-z0-9]+(-[a-z0-9]+)*|release/[0-9]+\.[0-9]+\.[0-9]+)$"

check() {
  branch="$1"
  if ! printf '%s' "$branch" | grep -Eq "$PATTERN"; then
    fail "$branch" "does not match the naming rule"
    return 1
  fi
  description="${branch#*/}"
  if [ "${#description}" -gt 50 ]; then
    fail "$branch" "description is longer than 50 characters"
    return 1
  fi
  return 0
}

fail() {
  cat >&2 <<EOF

✖  Branch "$1" $2.

   Use <type>/<description> in lowercase-kebab-case, optionally with a ticket:
     feat/game-scene
     fix/GAME-123-score-total
     release/1.2.0
   Types: $(echo "$TYPES" | tr '|' ' ')

   Rename it:  git branch -m "$1" <new-name>

EOF
}

if [ -n "$1" ]; then
  check "$1"
  exit $?
fi

zero="0000000000000000000000000000000000000000"
status=0
while read -r local_ref local_sha remote_ref remote_sha; do
  case "$remote_ref" in
    refs/heads/*) ;;
    *) continue ;; # tags and other refs are not branches
  esac
  [ "$local_sha" = "$zero" ] && continue # deleting a remote branch
  check "${remote_ref#refs/heads/}" || status=1
done
exit $status
