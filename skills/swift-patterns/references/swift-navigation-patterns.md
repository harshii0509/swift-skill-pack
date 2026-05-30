# Swift Navigation Patterns

Use this reference when the task involves state-driven navigation, deep linking, destination enums, navigation architecture, or when the user explicitly mentions `swift-navigation`.

This guidance is informed by `pointfreeco/swift-navigation`.

Primary source:

- https://github.com/pointfreeco/swift-navigation

---

## What Swift Navigation Is Good At

The upstream project describes itself as a library for bringing simple and powerful navigation tools to Swift platforms, inspired by SwiftUI. It is strongest when plain SwiftUI navigation starts feeling under-modeled rather than merely under-documented.

High-value capabilities called out upstream:

- enum-driven navigation state
- compile-time guarantees that only one destination is active at a time
- deep-linkable navigation
- SwiftUI, UIKit, and AppKit support
- `observe`, `UIBinding`, `UINavigationPath`, and UIKitNavigation tooling

Use it when navigation is a state-modeling problem, not just a screen-wiring problem.

---

## Decision Rule

Choose among three options:

1. Plain SwiftUI navigation
   Use when the app has straightforward stacks, sheets, and destinations and the built-in APIs remain clear.
2. Better local modeling on top of SwiftUI
   Use when you only need to tighten state shape locally and can still stay within stock APIs.
3. Swift Navigation
   Use when the app needs enum-driven destinations, deep linking, UIKit parity, or tighter guarantees around mutually exclusive navigation states.

Default bias:

- Stay with native SwiftUI until navigation state becomes materially hard to reason about.
- Reach for Swift Navigation when the navigation model itself needs stronger structure.

---

## High-Value Patterns

### Destination enum instead of many optionals

Upstream explicitly contrasts multiple independent optionals with a single destination enum. Use this when a feature can present several mutually exclusive destinations and you want the type system to encode that exclusivity.

### Deep linking from state

Swift Navigation is especially compelling when navigation should be reconstructable from domain state rather than from imperative view-controller events.

### UIKit parity

The UIKitNavigation layer is useful when the codebase still contains UIKit screens but the team wants state-driven navigation semantics instead of fire-and-forget imperative presentation.

---

## Good Use Cases

- `Our feature has sheets, alerts, and detail pushes. State is getting messy.`
- `We want deep-linkable navigation from domain state.`
- `We still have UIKit screens but want better navigation modeling.`

---

## Bad Use Cases

- Adopting Swift Navigation for a simple app with one stack and a couple sheets.
- Introducing the library before proving that built-in navigation is the real bottleneck.
- Using it as a substitute for fixing broader state-ownership problems.

---

## Review Checklist

- Are multiple optionals or booleans representing mutually exclusive destinations?
- Does the team need deep-linkable state or UIKit parity?
- Is navigation complexity real, or just temporarily inconvenient?
- Would plain SwiftUI remain clearer for this specific feature?

---

## Escalation Rule

If the question is about multiplatform SwiftUI app organization more broadly, pair this with `food-truck-patterns.md`.

If the question is really about observation or older deployment targets, pair this with `swift-perception-patterns.md`.
