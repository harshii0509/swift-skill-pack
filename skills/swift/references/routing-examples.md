# Swift Routing Examples

Use this file when the request could fit more than one sub-skill.

For each prompt:

- choose the primary lane first
- load the named sub-skill before giving implementation advice
- borrow from a second lane only if the user’s task genuinely spans both

---

## Clear Prototype Prompts

**User prompt**
`Build a draggable glassy card that tilts with my finger and snaps back with a spring.`

**Primary lane**
`swift-prototype`

**Why**
Gesture-heavy interaction, motion feel, and rapid UI iteration matter more than architecture.

**Read first**
- `../../swift-prototype/SKILL.md`
- `../../swift-prototype/references/gesture-patterns.md`
- `../../swift-prototype/references/animation-craft.md`

---

## Shader / Effects Prompt

**User prompt**
`I want an interactive ripple and heat-distortion effect in SwiftUI. Should this use Inferno, native Shader, Canvas, or custom Metal?`

**Primary lane**
`swift-prototype`

**Why**
The first question is effect selection and prototype rendering tier, not app architecture.

**Read first**
- `../../swift-prototype/SKILL.md`
- `../../swift-prototype/references/inferno-patterns.md`
- `../../swift-prototype/references/custom-rendering.md`

---

## Apple-Native Feel Prompt

**User prompt**
`This SwiftUI settings screen works, but it does not feel like an Apple app yet. What would you change?`

**Primary lane**
`swift-prototype`

**Why**
The user needs design-native critique and UI feel calibration before any large structural changes.

**Read first**
- `../../swift-prototype/SKILL.md`
- `../../swift-prototype/references/apple-native-design.md`

---

## Clear Architecture Prompts

**User prompt**
`My SwiftUI app is getting messy. Should auth and profile live in sessions, view models, or environment objects?`

**Primary lane**
`swift-patterns`

**Why**
This is about long-lived state ownership and app structure, not an isolated bug.

**Read first**
- `../../swift-patterns/SKILL.md`
- `../../swift-patterns/references/session-architecture.md`

---

## Navigation Architecture Prompt

**User prompt**
`Our SwiftUI flow has sheets, drill-downs, and deep links. Should we stay with plain NavigationStack or adopt Swift Navigation?`

**Primary lane**
`swift-patterns`

**Why**
This is a state-modeling and navigation-architecture decision, not a debugging task.

**Read first**
- `../../swift-patterns/SKILL.md`
- `../../swift-patterns/references/swift-navigation-patterns.md`

---

## Observation Compatibility Prompt

**User prompt**
`We want Observation-style state, but still support older iOS versions. Should we use Swift Perception or stay with ObservableObject for now?`

**Primary lane**
`swift-patterns`

**Why**
The key question is compatibility strategy and ownership boundaries across deployment targets.

**Read first**
- `../../swift-patterns/SKILL.md`
- `../../swift-patterns/references/swift-perception-patterns.md`

---

## Clear Debug Prompts

**User prompt**
`My list updates correctly in logs but the UI only refreshes after I leave and re-enter the screen.`

**Primary lane**
`swift-debug`

**Why**
The user already has a broken behavior and needs diagnosis before redesign.

**Read first**
- `../../swift-debug/SKILL.md`
- `../../swift-debug/references/swiftui-body-bugs.md`

---

## Bridge-Focused Prompts

**User prompt**
`Should I use SwiftUIX, a custom UIViewRepresentable, or native SwiftUI for search and paging?`

**Primary lane**
`swift-patterns`

**Why**
This is a dependency and bridge-boundary decision.

**Read first**
- `../../swift-patterns/SKILL.md`
- `../../swift-patterns/references/swiftuix-patterns.md`
- `../../swift-patterns/references/uikit-swiftui-bridge.md`

---

## Review-Only Prompts

**User prompt**
`Is this SwiftUI code good, or are there obvious mistakes?`

**Primary lane**
Inline review with the Quick Quality Checklist

**Escalate to a sub-skill when**
- the review turns into a state/update bug → `swift-debug`
- the review turns into structure/package advice → `swift-patterns`
- the review turns into interaction polish → `swift-prototype`

---

## Mixed Prompt: Prototype Becoming Product

**User prompt**
`I have a cool experimental scroll effect. Help me make it production ready without losing the feel.`

**Primary lane**
Start with `swift-prototype`, then borrow from `swift-patterns`

**Why**
Protect the interaction first, then extract the structure.

**Read first**
- `../../swift-prototype/SKILL.md`
- `../../swift-prototype/references/prototype-structure.md`
- then `../../swift-patterns/references/session-architecture.md` only if state ownership becomes relevant

---

## Mixed Prompt: Bug Inside a Bridge

**User prompt**
`My UIViewRepresentable wraps a zoomable scroll view. Zoom works once, then state gets weird after SwiftUI updates.`

**Primary lane**
`swift-debug`

**Why**
Even though this involves architecture and wrappers, the immediate need is diagnosis.

**Read first**
- `../../swift-debug/SKILL.md`
- `../../swift-debug/references/xcode-debug-tools.md`
- `../../swift-patterns/references/uikit-swiftui-bridge.md` as supporting context

---

## Router Self-Check

Before finalizing the lane, ask:

1. Is the user building something new, structuring something large, or diagnosing something broken?
2. Is the user asking for motion/feel, long-lived ownership, or root-cause analysis?
3. Would the wrong lane lead to premature refactoring or premature debugging?

If still unsure, pick the lane that addresses the user’s most immediate bottleneck.

## Regression Finding

Bridge bug prompts can drift toward `swift-patterns` because they mention `UIViewRepresentable`, `Coordinator`, or SwiftUIX. If the prompt includes a failure symptom such as “resets,” “works once,” “stops updating,” or “after state changes,” route to `swift-debug` first.
