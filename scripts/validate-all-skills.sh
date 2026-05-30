#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="$HOME/.codex/skills/.system/skill-creator/scripts/quick_validate.py"

for skill in swift swift-prototype swift-patterns swift-debug; do
  echo "Validating $skill"
  python3 "$VALIDATOR" "$ROOT/skills/$skill"
done
