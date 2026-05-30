#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT/skills"
CODEX_DEST="${CODEX_HOME:-$HOME/.codex}/skills"
CLAUDE_DEST="$HOME/.claude/skills"

rsync -a \
  "$SOURCE/swift" \
  "$SOURCE/swift-prototype" \
  "$SOURCE/swift-patterns" \
  "$SOURCE/swift-debug" \
  "$CODEX_DEST/"

rsync -a \
  "$SOURCE/swift" \
  "$SOURCE/swift-prototype" \
  "$SOURCE/swift-patterns" \
  "$SOURCE/swift-debug" \
  "$CLAUDE_DEST/"
