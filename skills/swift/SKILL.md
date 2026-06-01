---
name: swift
description: Route Swift and iOS tasks to the right focused workflow, or run a quick inline quality review. Use when working on SwiftUI prototypes, production app structure, UIKit and SwiftUI integration, async and state bugs, performance issues, or general Swift code review.
---

You are an expert Swift engineer. Read the user's request, identify which sub-skill applies, and load it.

## Routing Table

| User says… | Load sub-skill |
|---|---|
| prototype / experiment / animation / gesture / interaction / shader / effect / HIG / Liquid Glass / iOS 26 UI / glassEffect / safeAreaBar / tab bar accessory / "make this move" / "make this feel Apple-native" | `swift-prototype` |
| bug / crash / slow / freeze / not updating / weird / "why is this" / debug / race condition / async / memory / resets / works once / first render / lifecycle mismatch / coordinator loop | `swift-debug` |
| architecture / package / session / module / how to structure / MVVM / DI / dependency / UIKit / SwiftUIX / bridge / representable / navigation / deep link / observation / deployment target | `swift-patterns` |
| review / improve / is this good / clean this up | run the Quick Quality Checklist below |
| anything else | run Quick Quality Checklist + apply whichever sub-skill is most relevant |

## Routing Precedence

- If the prompt describes a broken behavior, choose `swift-debug` first even when it also mentions `UIViewRepresentable`, `Coordinator`, `SwiftUIX`, UIKit bridging, or architecture terms.
- Use `swift-patterns` for bridge and dependency design decisions.
- Use `swift-prototype` for building or reshaping interactions, then borrow `swift-patterns` only if the user explicitly wants to productionize the result.

## How to Load a Sub-Skill

Read the matching sibling skill folder in this skill collection and follow its SKILL.md before making changes.
If routing is ambiguous, consult `references/routing-examples.md` before choosing a lane.
If the task depends on newer SwiftUI naming, bars, safe areas, or Liquid Glass, also consult `references/swiftui-vocabulary.md` so you use the exact API terms in your plan and recommendation.

## Source-Aware Workflow

- Use the shipped reference files first.
- If the task clearly matches one of the Swift study repos, borrow patterns from them deliberately:
  - `SwiftUI-experiments` for interaction design, gesture state, animation timing, Canvas, and prototype structure
  - `any-distance-ios` for UIKit and SwiftUI bridging, reusable utilities, SwiftUIX-like wrappers, and production packaging
  - `Haptics` for session-style dependencies, modularization, realtime state flow, and debugging tricky app behavior
- Also use the curated external references when the prompt matches them closely:
  - `Inferno` for shader-pack tradeoffs, distortion effects, blur, and GPU-friendly visual experimentation
  - Apple HIG for Apple-native hierarchy, materials, motion feel, and platform consistency
  - Apple iOS 26 / SwiftUI updates for Liquid Glass, `safeAreaBar`, tab bar accessories, scroll edge effects, and modern bar terminology
  - Apple `Food Truck` for multiplatform SwiftUI structure across app, widgets, and live activities
  - `swift-navigation` for state-driven navigation and deep-linkable destination modeling
  - `swift-perception` for Observation-style state on older deployment targets
- If the user mentions `SwiftUIX`, route to `swift-patterns` unless the ask is purely review-only.

## Quick Quality Checklist (for inline code review)

When the user pastes code and asks for feedback without needing a full sub-skill, apply these 10 checks in order:

1. **No force unwrap** — `!` on optionals is a crash waiting to happen. Prefer `guard let`, `if let`, or `?? default`.
2. **@MainActor on all UI mutations** — any `@State`, view update, or UIKit call must happen on the main actor.
3. **No print() in production paths** — replace with `Logger(subsystem:category:)`.
4. **View body is cheap** — computed properties, closures, and initializers in `body` re-run on every render. Move heavy work out.
5. **ForEach has stable identity** — using `\.self` on non-Hashable or mutable data causes incorrect diffs. Use explicit `\.id` or `Identifiable`.
6. **No singletons for shared state** — use `@Observable` class injected via `.environment()` instead.
7. **Task cancellation is handled** — every `Task { }` that does I/O should check `Task.isCancelled` or use `withTaskCancellationHandler`.
8. **No business logic in View** — views should only read state and dispatch actions, never compute or transform data themselves.
9. **Sheet uses item binding, not Bool** — `sheet(item:)` prevents the memory leak pattern of `sheet(isPresented:)` + optional content.
10. **Animation has a meaningful curve** — `.easeIn` on a dismissal or `.linear` on a spring element feels wrong. Match curve to physicality.

Output: list only the checks that fail, with a one-line fix per finding. If all pass, say so.
