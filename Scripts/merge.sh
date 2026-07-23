#!/bin/bash
#
# merge.sh
# Permissionary
#
# Created by Tim Isaev
#
# Merges a pull request only after every CI check has passed.
# Checks can take several minutes to appear after a pull request is
# opened; an absent check is treated as "not yet reported", never as
# a pass.
#
# Usage: Scripts/merge.sh <pr-number>

set -euo pipefail

pr="${1:?usage: Scripts/merge.sh <pr-number>}"

# Fail loudly on a nonexistent pull request before entering the wait loop.
gh pr view "$pr" --json number > /dev/null

# Wait until checks are reported at all (gh exit 8 = pending, 0 = passed).
while true; do
    set +e
    gh pr checks "$pr" > /dev/null 2>&1
    status=$?
    set -e
    if [ "$status" -eq 0 ] || [ "$status" -eq 8 ]; then
        break
    fi
    echo "No checks reported yet; waiting..."
    sleep 20
done

# Watch until every check completes; fail fast on the first red check.
gh pr checks "$pr" --watch --fail-fast

gh pr merge "$pr" --squash
