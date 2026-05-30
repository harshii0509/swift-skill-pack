# Swift Perception Patterns

Use this reference when the task involves older Apple deployment targets, Observation backports, `@Observable` compatibility, or when the user explicitly mentions `swift-perception` or `WithPerceptionTracking`.

This guidance is informed by `pointfreeco/swift-perception`.

Primary source:

- https://github.com/pointfreeco/swift-perception

---

## What Swift Perception Is Good At

The upstream project describes itself as Swift’s Observation tools, back-ported to more platforms. The README explicitly calls out back-porting:

- `@Observable`
- `withObservationTracking`
- `Observations`

to older OS generations, including iOS 13, macOS 10.15, tvOS 13, and watchOS 6.

This is valuable when a team wants modern observation-style state modeling but cannot raise deployment targets enough to use Apple’s Observation framework alone.

---

## Key Compatibility Rule

The main behavioral difference upstream highlights is:

- use `@Perceptible` instead of `@Observable`
- wrap SwiftUI view content in `WithPerceptionTracking`
- use `Perceptions` as the back-port of `Observations`
- use `@Perception.Bindable` where appropriate

If you forget `WithPerceptionTracking`, upstream says the library emits a runtime warning, which is exactly the kind of failure mode a skill should call out early.

---

## Decision Rule

Choose among three options:

1. Native Observation only
   Use when deployment targets are already aligned with Apple’s Observation framework and no backport is needed.
2. Swift Perception
   Use when the team wants Observation-style modeling but still supports older Apple OS versions.
3. Stay with existing ObservableObject / Combine
   Use when migrating observation semantics would add more churn than value for the current codebase.

Default bias:

- For new code on modern targets, prefer native Observation.
- For modern-style state on older targets, Swift Perception is the right compatibility layer.
- Avoid using it just because it exists if the codebase is stable on `ObservableObject` and migration value is low.

---

## Good Use Cases

- `We support iOS 16 and want Observation-style modeling now.`
- `Should we use Perception or keep ObservableObject until we drop older OS support?`
- `Why am I getting a Perception runtime warning?`

---

## Bad Use Cases

- Adding Swift Perception to a modern-target-only app for no reason.
- Treating Perception as a universal architecture answer rather than a compatibility layer.
- Forgetting that `WithPerceptionTracking` is part of the usage contract on older targets.

---

## Review Checklist

- Are deployment targets actually old enough to justify a backport?
- Is the team trying to adopt Observation semantics now, or just chasing novelty?
- Has the view tree been wrapped in `WithPerceptionTracking` where needed?
- Would staying on `ObservableObject` be lower-risk for this codebase?

---

## Escalation Rule

If the problem is about state ownership rather than observation compatibility, go back to `session-architecture.md`.

If it is about navigation state and deep linking, pair this with `swift-navigation-patterns.md`.
