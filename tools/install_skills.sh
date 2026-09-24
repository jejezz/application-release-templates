#!/usr/bin/env bash
#
# Register this repo's skills with Claude Code for the current user:
# ~/.claude/skills/<name> -> <this repo>/skills/<name> (symlinks, so a
# `git pull` here updates the skills everywhere).
#
#   tools/install_skills.sh            install / refresh links
#   tools/install_skills.sh --remove   remove the links
#
# Keep this clone somewhere permanent (e.g. ~/FlutterProject/application-release-templates).

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$dest"

for dir in "$repo"/skills/*/; do
  name="$(basename "$dir")"
  link="$dest/$name"
  if [ "${1:-}" = "--remove" ]; then
    if [ -L "$link" ]; then rm "$link" && echo "removed $link"; fi
    continue
  fi
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "skip $link — a real directory is there, not a link from this repo" >&2
    continue
  fi
  ln -sfn "${dir%/}" "$link"
  echo "linked $link -> ${dir%/}"
done
