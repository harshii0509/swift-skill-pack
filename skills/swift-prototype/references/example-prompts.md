# Swift Prototype Example Prompts

Use these prompts as calibration examples for when `swift-prototype` should trigger and what a strong response should optimize for.

---

## Gesture + Motion

**Prompt**
`Make a radial menu that expands where my thumb lands and settles with a soft spring.`

**Load first**
- `gesture-patterns.md`
- `animation-craft.md`

**Optimize for**
- minimal state model
- local gesture coordinates
- believable spring timing
- haptics only on meaningful thresholds

---

## Canvas / Render Loop

**Prompt**
`I want a candle flame effect that flickers in place and reacts to drag.`

**Load first**
- `custom-rendering.md`
- `animation-craft.md`

**Optimize for**
- `TimelineView` or `Canvas` if the effect is continuously recomputed
- clear boundary between render loop and gesture input
- stop the loop when idle if possible

---

## Shader / Effects Decision

**Prompt**
`I need a liquid distortion transition and glow-heavy hover effect in SwiftUI. Is Inferno the right choice, or should I stay with native Shader or Canvas?`

**Load first**
- `inferno-patterns.md`
- `custom-rendering.md`

**Optimize for**
- choosing the lightest viable rendering tier
- fast effect iteration before custom Metal work
- clear tradeoff between reusable shader packs and app-specific pipelines

---

## Apple-Native Review

**Prompt**
`This SwiftUI prototype is functional, but it feels generic. How do I make it feel at home on Apple platforms?`

**Load first**
- `apple-native-design.md`

**Optimize for**
- clearer hierarchy and grouping
- materials, spacing, and motion that match platform expectations
- avoiding generic cross-platform styling when native affordances are stronger

---

## Prototype Review

**Prompt**
`This experimental slider works, but it feels cheap. What would make it feel premium?`

**Load first**
- `gesture-patterns.md`
- `animation-craft.md`

**Optimize for**
- feel, not architecture
- rate-limited feedback
- spring tuning
- removal of redundant state

---

## Prototype to Production

**Prompt**
`This one-file experiment is validated. Help me split it without losing the interaction.`

**Load first**
- `prototype-structure.md`

**Optimize for**
- keep UI state local
- move data/persistence elsewhere
- isolate UIKit or sensor bridges as leaf wrappers
- preserve the original interaction semantics

---

## SwiftUIX Boundary

**Prompt**
`For this prototype, should I use SwiftUIX for paging or just write a small wrapper?`

**Load first**
- `prototype-structure.md`

**Optimize for**
- native first
- tiny wrapper before broad dependency
- if SwiftUIX is used, keep it behind one local view boundary

---

## Good Response Shape

- Start with the smallest state model that can express the interaction.
- Name one or two concrete implementation patterns, not ten alternatives.
- Keep the first version easy to read in one file unless there is a clear boundary.
- Prioritize feel, responsiveness, and debuggability over generalized abstraction.
