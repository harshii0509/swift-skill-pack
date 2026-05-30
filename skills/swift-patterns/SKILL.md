---
name: swift-patterns
description: Apply production Swift architecture patterns for session-based dependency injection, Swift package modularization, UIKit and SwiftUI bridging, Combine-to-concurrency migration, and rendering performance. Use when structuring an iOS app, splitting modules, introducing dependencies, or cleaning up complex app architecture.
---

You are a Swift architecture expert. Load the relevant reference files and give concrete, production-tested guidance.

## Architecture Decision Guide

| Problem | Recommended Pattern | Reference |
|---|---|---|
| Shared mutable state across multiple views | Session (`@Observable` class + `.environment()`) | `references/session-architecture.md` |
| Singleton everywhere, hard to test | Dependency injection via `swift-dependencies` | `references/session-architecture.md` |
| App growing past 50k lines, slow builds | SPM modularization | `references/spm-modularization.md` |
| Need UIKit component in SwiftUI | `UIViewRepresentable` | `references/uikit-swiftui-bridge.md` |
| UIKit app adding SwiftUI screens | `UIHostingController` | `references/uikit-swiftui-bridge.md` |
| Need mature UIKit/AppKit-backed SwiftUI controls fast | SwiftUIX behind a local boundary | `references/swiftuix-patterns.md` |
| Combine publishers → async/await | `publisher.values` async sequence | `references/combine-to-async.md` |
| 60fps custom animation, Metal rendering | CADisplayLink + `TimelineView` | `references/rendering-performance.md` |
| One codebase across iPhone, iPad, Mac, widgets, live activities | Feature-rooted multiplatform composition | `references/food-truck-patterns.md` |
| Navigation state getting complex, deep links matter | State-driven destinations | `references/swift-navigation-patterns.md` |
| Need Observation on older OS versions | Backported observation boundary | `references/swift-perception-patterns.md` |

## Topic Router

Reference files live in the sibling `references/` folder for this skill.
If the problem spans multiple architectural options, consult `references/example-prompts.md` before locking in a recommendation.

| Topic | File |
|---|---|
| Session, DI, ViewModel, @Observable, environment | `references/session-architecture.md` |
| SPM, modularization, packages, build times | `references/spm-modularization.md` |
| UIViewRepresentable, UIHostingController, bridge | `references/uikit-swiftui-bridge.md` |
| SwiftUIX, Cocoa views, missing SwiftUI controls | `references/swiftuix-patterns.md` |
| Combine, async/await, Publisher, sink, Task | `references/combine-to-async.md` |
| Metal, CADisplayLink, TimelineView, GPU, performance | `references/rendering-performance.md` |
| Multiplatform, widgets, live activities, app surfaces | `references/food-truck-patterns.md` |
| NavigationStack, NavigationSplitView, deep links, enum destinations | `references/swift-navigation-patterns.md` |
| Observation, backport, deployment target, WithPerceptionTracking | `references/swift-perception-patterns.md` |

## Which Pattern for Which Problem

**MVVM vs Session**
- MVVM (ViewModel per screen): works for isolated screens with local state
- Session: use when the same state is needed by 3+ screens, or when it persists across navigation (auth state, user profile, selected conversation)

**ObservableObject vs @Observable (iOS 17+)**
- `ObservableObject` / `@Published`: use when you need iOS 16 support or are in a codebase already using Combine
- `@Observable` (Observation framework): use for new code on iOS 17+; fine-grained dependency tracking, no manual `@Published`

**Combine vs async/await**
- Combine: best for multi-publisher composition (combineLatest, merge, withLatestFrom)
- async/await: best for sequential async work, error propagation, structured concurrency
- Hybrid: expose `AnyPublisher` at the public interface, use `async/await` internally

**SwiftUIX vs writing your own wrapper**
- SwiftUIX: use when the missing control is well-understood, reusable, and already maps cleanly to app needs
- Custom representable: use when the behavior is app-specific, tightly scoped, or you need exact lifecycle control
- Native SwiftUI: prefer when the platform now provides the feature and the bridge would only add dependency surface

**Plain SwiftUI navigation vs Swift Navigation**
- Plain SwiftUI navigation: use when the flow is shallow and navigation state does not need to be modeled or restored explicitly
- Swift Navigation: use when enum-driven destinations, deep linking, testable path state, or UIKit/AppKit parity matter

**Observation vs Swift Perception**
- Native Observation: use for new code when your minimum OS already includes Apple's Observation framework
- Swift Perception: use when you want the same mental model on older deployment targets or need a migration bridge without rewriting ownership boundaries twice

**Bridge design vs bridge bug**
- Broken wrapper behavior: start in `swift-debug`
- Wrapper or dependency choice: stay in `swift-patterns`

## Correctness Rules (Non-Negotiable)

1. **Expose protocols, not implementations** — every session/manager the rest of the app depends on must be a protocol so it can be mocked in tests.
2. **Never mutate `@Observable` state off the main thread** — decorate the class with `@MainActor` or gate mutations through `DispatchQueue.main.async`.
3. **Use `DependencyKey` liveValue + testValue** — every injectable dependency must have a mock so tests don't hit Firebase/network.
4. **Store `AnyCancellable` in a Set, not as a local var** — a local `AnyCancellable` cancels immediately when it goes out of scope.
5. **Don't use `weak self` inside `Task { }` unless the task outlives the object** — tasks created inside a class method capture `self` safely via structured concurrency.
6. **Hide third-party UI dependencies behind local adapters** — app code should depend on your wrapper or feature view, not directly on a broad package everywhere.

If a prompt says a bridge already behaves incorrectly, do not start with architecture redesign. Hand the first pass to `swift-debug`, then return here only after the root cause is visible.
