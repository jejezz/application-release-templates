#!/usr/bin/env bash
#
# Bump the app version for a release (compose/conventions/versioning.md §5).
#
#   scripts/bump-version.sh patch        1.4.2+37 -> 1.4.3+38
#   scripts/bump-version.sh minor        1.4.2+37 -> 1.5.0+38
#   scripts/bump-version.sh major        1.4.2+37 -> 2.0.0+38
#   scripts/bump-version.sh build        1.4.2+37 -> 1.4.2+38
#   scripts/bump-version.sh 1.5.0-rc.1   1.4.2+37 -> 1.5.0-rc.1+38
#
# The version lives in gradle.properties (app.version / app.build). The build
# number always goes up by exactly one and never resets. MAJOR must stay >= 1
# (jpackage rejects 0.y.z on macOS). Commits as `chore(release): vX.Y.Z` but does
# NOT tag — tag the merge commit on main after the PR lands (tagging.md §2).
#
# From jejezz/application-release-templates compose/common/.

set -euo pipefail

usage() { sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
[ $# -eq 1 ] || usage

cd "$(git rev-parse --show-toplevel)"
PROPS=gradle.properties
[ -f "$PROPS" ] || { echo "no gradle.properties at the repository root" >&2; exit 1; }

# Only tracked files matter: the bump commit adds just gradle.properties, so
# untracked local files can't leak into it and shouldn't block a release.
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "tracked files have uncommitted changes — commit or stash first" >&2
  git status --short --untracked-files=no >&2
  exit 1
fi

CURRENT_NAME=$(grep -m1 '^app\.version=' "$PROPS" | sed -E 's/^app\.version=[[:space:]]*//; s/[[:space:]]*$//')
BUILD=$(grep -m1 '^app\.build=' "$PROPS" | sed -E 's/^app\.build=[[:space:]]*//; s/[[:space:]]*$//')
CURRENT="$CURRENT_NAME+$BUILD"
if ! [[ "$BUILD" =~ ^[0-9]+$ ]]; then
  echo "gradle.properties app.build '$BUILD' is not an integer" >&2
  exit 1
fi
# BASH_REMATCH is overwritten by every =~ match, so read it right after this one.
if ! [[ "$CURRENT_NAME" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-[0-9A-Za-z.]+)?$ ]]; then
  echo "gradle.properties app.version '$CURRENT_NAME' is not MAJOR.MINOR.PATCH[-pre]" >&2
  exit 1
fi
MAJOR=${BASH_REMATCH[1]} MINOR=${BASH_REMATCH[2]} PATCH=${BASH_REMATCH[3]} PRE=${BASH_REMATCH[4]}

case "$1" in
  major) NAME="$((MAJOR + 1)).0.0" ;;
  minor) NAME="$MAJOR.$((MINOR + 1)).0" ;;
  # Leaving a pre-release: 1.5.0-rc.2 -> patch -> 1.5.0 (not 1.5.1).
  patch) if [ -n "$PRE" ]; then NAME="$MAJOR.$MINOR.$PATCH"; else NAME="$MAJOR.$MINOR.$((PATCH + 1))"; fi ;;
  build) NAME="$MAJOR.$MINOR.$PATCH$PRE" ;;
  *)
    [[ "$1" =~ ^([0-9]+)\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$ ]] || usage
    NAME="$1"
    ;;
esac

# jpackage rejects a leading 0 on macOS, so the build would fail at configuration time.
if [ "${NAME%%.*}" -lt 1 ]; then
  echo "MAJOR must be >= 1 (jpackage rejects $NAME on macOS)" >&2
  exit 1
fi

NEW="$NAME+$((BUILD + 1))"

perl -pi -e "s/^app\\.version=.*/app.version=$NAME/; s/^app\\.build=.*/app.build=$((BUILD + 1))/" "$PROPS"

git add "$PROPS"
git commit -q -m "chore(release): v$NAME"

DISPLAY=$(grep -m1 '^app\.displayName=' "$PROPS" | sed -E 's/^app\.displayName=[[:space:]]*//; s/[[:space:]]*$//' || true)
[ -n "$DISPLAY" ] || DISPLAY="<Display Name>"

echo "$CURRENT -> $NEW  (committed: chore(release): v$NAME)"
echo
echo "Next: push, merge the PR, then tag the merge commit on main:"
echo "  git switch main && git pull"
echo "  git tag -a v$NAME -m \"$DISPLAY $NAME\" && git push origin v$NAME"
