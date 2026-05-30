#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Running skill validation"
"$ROOT/scripts/validate-all-skills.sh"

echo "Checking required skill metadata"
for skill in swift swift-prototype swift-patterns swift-debug; do
  test -f "$ROOT/skills/$skill/agents/openai.yaml"
done

echo "Checking top-level release files"
for file in README.md LICENSE .gitignore ATTRIBUTION.md; do
  test -f "$ROOT/$file"
done

echo "Checking benchmark case count"
case_count="$(rg -c '^  - id:' "$ROOT/evals/swift-benchmark/cases.yaml")"
if [[ "$case_count" != "18" ]]; then
  echo "Expected 18 benchmark cases, found $case_count" >&2
  exit 1
fi

echo "Checking canonical skill layout"
for skill in swift swift-prototype swift-patterns swift-debug; do
  test -f "$ROOT/skills/$skill/SKILL.md"
done

echo "Checking README install URLs"
rg -q 'https://github.com/harshii0509/swift-skill-pack/tree/main/skills/swift' "$ROOT/README.md"
if ! rg -q 'https://github.com/harshii0509/swift-skill-pack/tree/main/skills/swift-debug' "$ROOT/README.md"; then
  echo "README is missing the full public install URLs" >&2
  exit 1
fi

echo "Release check passed"
