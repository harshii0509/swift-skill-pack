# Swift Skill Pack

A reusable 4-skill suite for Swift, SwiftUI, and iOS work across prototyping, production architecture, and debugging.

Use it with Codex, Claude, and similar coding agents when you want sharper routing and more grounded Swift guidance than a generic assistant usually gives you.

## Included Skills

| Skill | What it does |
|---|---|
| `swift` | Router skill that picks the right lane before implementation starts |
| `swift-prototype` | SwiftUI interaction design, motion, rendering, and Apple-native feel |
| `swift-patterns` | App structure, sessions, navigation, bridges, and modularization |
| `swift-debug` | Root-cause debugging for SwiftUI, UIKit bridges, concurrency, and performance |

The canonical installable source lives in [`skills/`](./skills).

## Best For

- SwiftUI interaction prototypes that need stronger feel and cleaner state models
- Production Swift app structure decisions around sessions, navigation, bridges, and modularization
- Difficult SwiftUI bugs involving stale state, `UIViewRepresentable`, concurrency, or rendering regressions
- Agent workflows where routing to the right Swift sub-skill matters as much as the final code

## Quick Start

## Install In Codex

Use Codex's installer skill against the public GitHub tree URLs:

```text
Use $skill-installer to install:
https://github.com/harshii0509/swift-skill-pack/tree/main/skills/swift
https://github.com/harshii0509/swift-skill-pack/tree/main/skills/swift-prototype
https://github.com/harshii0509/swift-skill-pack/tree/main/skills/swift-patterns
https://github.com/harshii0509/swift-skill-pack/tree/main/skills/swift-debug
```

After install, restart Codex so the new skills are picked up.

## Install In Claude

Copy the four folders from `skills/` into your Claude skills directory:

```bash
cp -R skills/swift ~/.claude/skills/
cp -R skills/swift-prototype ~/.claude/skills/
cp -R skills/swift-patterns ~/.claude/skills/
cp -R skills/swift-debug ~/.claude/skills/
```

## Example Usage

- `$swift Build a draggable card that tilts with my finger and springs back naturally.`
- `$swift Should we keep plain NavigationStack or adopt Swift Navigation for deep links?`
- `$swift My SwiftUI screen logs new values but only refreshes after I navigate away and back.`
- `$swift-prototype This settings flow works but still feels generic. Make it feel Apple-native.`
- `$swift-patterns We need one SwiftUI codebase for iPhone, iPad, Mac, widgets, and Live Activities.`
- `$swift-debug My UIViewRepresentable works once, then resets after state changes.`

## Benchmark

The benchmark suite lives in [`evals/swift-benchmark/`](./evals/swift-benchmark):

- `cases.yaml`: 18 benchmark prompts
- `rubric.md`: scoring rules
- `results-template.md`: empty run template
- `results-2026-05-30.md`: first packaged baseline

The harness is answer-only by default:

```text
Answer only. Do not edit files. First name the primary lane. Then name the first references you would load. Then give a short recommendation with the main tradeoff.
```

## Attribution

This repo ships the skill pack only. The study sources that informed it are credited in [ATTRIBUTION.md](./ATTRIBUTION.md) and are not redistributed here.

## Maintainer Commands

- Validate the full suite:

```bash
./scripts/validate-all-skills.sh
```

- Run the release sanity check:

```bash
./scripts/release-check.sh
```

- Sync local Codex and Claude installs from the canonical source:

```bash
./scripts/sync-local-installs.sh
```
