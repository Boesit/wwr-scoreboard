#!/usr/bin/env bash
# publish-to-github-pages.sh <commit-message>
# Publishes updated scoreboard HTML files to Boesit/wwr-scoreboard (GitHub Pages).
#
# Env:
#   GITHUB_TOKEN      - GitHub PAT with push access to Boesit/wwr-scoreboard (required for push)
#   INDEX_HTML        - path to updated index.html
#   SCOREBOARD_HTML   - path to updated wwr-2026-scoreboard.html
#
# Behavior:
#   - pulls latest main first, copies the files into the repo,
#   - exits cleanly (no push) if nothing changed,
#   - otherwise commits and pushes, redacting the token from all output.

set -euo pipefail

MSG="${1:-Auto-refresh: update scoreboard}"
TOKEN="${GITHUB_TOKEN:-}"
INDEX_HTML="${INDEX_HTML:-}"
SCOREBOARD_HTML="${SCOREBOARD_HTML:-}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sanitize() {
  if [ -n "$TOKEN" ]; then
    sed "s#${TOKEN}#[REDACTED]#g"
  else
    cat
  fi
}

if [ -z "$INDEX_HTML" ] || [ ! -f "$INDEX_HTML" ]; then
  echo "INDEX_HTML is not set or file not found; aborting." | sanitize
  exit 1
fi
if [ -z "$SCOREBOARD_HTML" ] || [ ! -f "$SCOREBOARD_HTML" ]; then
  echo "SCOREBOARD_HTML is not set or file not found; aborting." | sanitize
  exit 1
fi

cd "$REPO_DIR"

# Refresh base and make sure we are on main with a clean scoreboard state.
git fetch origin main >/dev/null 2>&1 || true
git checkout main >/dev/null 2>&1 || true
git pull --ff-only origin main >/dev/null 2>&1 || true

if [ "$(readlink -f "$INDEX_HTML")" != "$REPO_DIR/index.html" ]; then
  cp "$INDEX_HTML" "$REPO_DIR/index.html"
fi
if [ "$(readlink -f "$SCOREBOARD_HTML")" != "$REPO_DIR/wwr-2026-scoreboard.html" ]; then
  cp "$SCOREBOARD_HTML" "$REPO_DIR/wwr-2026-scoreboard.html"
fi

if git diff --quiet -- index.html wwr-2026-scoreboard.html; then
  echo "No changes to publish; exiting cleanly." | sanitize
  exit 0
fi

if [ -z "$TOKEN" ]; then
  echo "Changes detected but GITHUB_TOKEN is not set; skipping push." | sanitize
  exit 0
fi

git add index.html wwr-2026-scoreboard.html
git -c user.name="${GIT_USER_NAME:-wwr-scoreboard-bot}" \
    -c user.email="${GIT_USER_EMAIL:-wwr-scoreboard-bot@users.noreply.github.com}" \
    commit -m "$MSG" | sanitize

PUSH_URL="https://x-access-token:${TOKEN}@github.com/Boesit/wwr-scoreboard.git"
git push "$PUSH_URL" HEAD:main 2>&1 | sanitize

echo "Published to GitHub Pages." | sanitize
