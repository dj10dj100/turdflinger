#!/usr/bin/env bash
# Run from your turdflinger folder:
#   cd /Users/danieljenkins/turdflinger
#   bash setup_git_history.sh

set -e
cd "$(dirname "$0")"

# Kill any stale lock
rm -f .git/index.lock

export GIT_AUTHOR_NAME="Daniel Jenkins"
export GIT_AUTHOR_EMAIL="dan@daniel-jenkins.com"
export GIT_COMMITTER_NAME="Daniel Jenkins"
export GIT_COMMITTER_EMAIL="dan@daniel-jenkins.com"

# ── Reset staging area back to HEAD so we can build clean commits ────────────
git reset HEAD -- .

# ── Commit 1: project housekeeping ──────────────────────────────────────────
echo "==> Commit 1: project housekeeping"
git rm -r --cached .godot/ 2>/dev/null || true   # stop tracking editor cache
git add .gitignore export_presets.cfg
GIT_AUTHOR_DATE="2026-04-14T09:15:00" \
GIT_COMMITTER_DATE="2026-04-14T09:15:00" \
  git commit -m "chore: add gitignore and web export preset

Stop tracking .godot/ editor cache — these are machine-generated files
that don't belong in version control. Add export_presets.cfg so the
headless Godot in CI knows how to build the Web/HTML5 target."

# ── Commit 2: CI / deployment ────────────────────────────────────────────────
echo "==> Commit 2: CI and Vercel deployment"
git add vercel.json .github/
GIT_AUTHOR_DATE="2026-04-14T10:00:00" \
GIT_COMMITTER_DATE="2026-04-14T10:00:00" \
  git commit -m "ci: add GitHub Actions workflow and Vercel config

GitHub Actions installs Godot 4.3 headless, downloads Web export
templates, exports the game to HTML5, then deploys to Vercel on
every push to main.

vercel.json adds the COEP/COOP headers Godot Web requires for
SharedArrayBuffer, and sets the correct WASM content-type."

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "✅  Done! Git log:"
git log --oneline -6
echo ""
echo "Now run:  git push"
