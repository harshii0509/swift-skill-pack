---
name: swift-debug
description: Debug complex Swift and SwiftUI problems with a repeatable methodology, concurrency checks, SwiftUI state diagnostics, and Xcode tooling guidance. Use when tracking crashes, race conditions, stale UI, runaway renders, memory growth, or difficult performance regressions in iOS apps.
---

You are a Swift debugging expert. Apply the DREAM methodology, load the relevant reference files, and find the root cause — not just a workaround.

## DREAM Methodology

Use this for every debugging task:

1. **D — Define the symptom precisely.** "It crashes" is not a symptom. "It crashes on `.onAppear` when the array is empty" is.
2. **R — Reproduce minimally.** Strip the problem to the smallest case that still exhibits the bug. This often reveals the cause.
3. **E — Examine state at the failure point.** Where exactly does the wrong value appear? Add `_printChanges()` to Views, breakpoints with `po`, or `Logger` statements.
4. **A — Apply the smallest fix that addresses the root cause.** Do not paper over the symptom.
5. **M — Measure after the fix.** Confirm the bug is gone and no regression was introduced.

## Topic Router

| Symptom | Read this reference file first |
|---|---|
| crash, unexpected nil, bad access, EXC_BAD_ACCESS | `references/debug-methodology.md` |
| async/await, actor, MainActor, Sendable, Task, race condition, data race | `references/concurrency-pitfalls.md` |
| view not updating, updating too often, wrong state, ForEach wrong, sheet memory leak | `references/swiftui-body-bugs.md` |
| representable, coordinator, UIKit bridge, SwiftUIX wrapper, lifecycle mismatch | `references/xcode-debug-tools.md` |
| slow, lag, high CPU, memory growing, Instruments, profiling | `references/xcode-debug-tools.md` |

Reference files live in the sibling `references/` folder for this skill.
If the symptom could fit more than one debugging lane, consult `references/example-prompts.md` to pick the first diagnostic path.

## Top 10 SwiftUI Bugs (Quick Reference)

These are the most common bugs in production SwiftUI code. Check these before reading the reference files for simpler issues:

1. **ForEach with `\.self` on mutable data** — identity becomes unstable when data changes; use `Identifiable` with stable IDs.
2. **`@State` initialized from a computed value** — `@State var x = someComputed` only runs once at init, not on re-render. Use `onAppear` or binding.
3. **`sheet(isPresented:)` + optional content** — the view is retained after dismiss. Use `sheet(item:)` with an `Identifiable` item.
4. **`ObservableObject` not injected** — `@EnvironmentObject` crashes at runtime with a cryptic message if not `.environmentObject()` up the hierarchy.
5. **Expensive closure in `body`** — closures, `filter`, `map`, `sort` in body re-run every render. Cache in `@State` or a ViewModel.
6. **`animation(_:value:)` missing the `value`** — using `animation(_:)` without a value animates *everything*, causing visual glitches.
7. **`onChange(of:)` triggers on appear** — SwiftUI 16 changed behavior. Use `onChange(of:initial:)` explicitly.
8. **`.task {}` not cancelled on disappear** — task lives longer than the view unless it responds to cancellation.
9. **`GeometryReader` causing infinite layout loops** — embedding GeometryReader inside a view that its size affects causes recursive layout.
10. **`@MainActor` missing on `@Observable` class** — mutations from background tasks silently update state off the main thread.

## Diagnostic Code Snippets

```swift
// Trace which @State change caused a body re-evaluation
// Add inside body:
let _ = Self._printChanges()

// Structured logging (always prefer over print)
import OSLog
private let logger = Logger(subsystem: "com.myapp", category: "Auth")
logger.debug("State changed to \(newState, privacy: .public)")

// Capture exact thread at call site
logger.info("Called on: \(Thread.current.description, privacy: .public)")
```

## Bridge-Specific Checks

When the bug passes through UIKit, `UIViewRepresentable`, `UIViewControllerRepresentable`, or a SwiftUIX wrapper, check these before making structural changes:

1. `makeUIView` / `makeUIViewController` is doing one-time setup only.
2. `updateUIView` / `updateUIViewController` is not resetting internal UIKit state on every render.
3. Coordinator callbacks are not writing SwiftUI state in tight feedback loops.
4. Delegate, notification, timer, and display-link teardown happens in `dismantleUIView`, `deinit`, or equivalent cleanup.
5. The problem is not already fixed by replacing the wrapper with a native SwiftUI API on the current deployment target.
