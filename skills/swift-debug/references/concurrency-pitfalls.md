# Concurrency Pitfalls

Patterns distilled from production async/await code in any-distance-ios and Haptics.

---

## @MainActor: When Required vs Implicit

**Explicit annotation required:**
- `@Observable` or `ObservableObject` classes that mutate published properties
- Classes that directly update UIKit or SwiftUI views
- Any actor-isolated function called from background contexts

```swift
// Without @MainActor — silent crash waiting to happen
@Observable
class FeedViewModel {
    var items: [Item] = []
    
    func load() async {
        let data = await api.fetch()    // runs on background executor
        items = data                    // updates SwiftUI state off-main — CRASH
    }
}

// With @MainActor — safe
@Observable
@MainActor
class FeedViewModel {
    var items: [Item] = []
    
    func load() async {
        let data = await api.fetch()    // still awaits on background
        items = data                    // but assignment hops back to main
    }
}
```

**@MainActor is implicit in:**
- All `@State`, `@Binding`, `@StateObject` accessors
- SwiftUI `View.body`
- `UIViewController` lifecycle methods (`viewDidLoad`, etc.)
- `@MainActor`-isolated async functions

Real delegate-handoff pattern from `adaptive text`:

```swift
nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
    let faceDistance = -faceAnchor.transform.columns.3.z

    Task { @MainActor in
        self.distance = self.distance + self.smoothing * (faceDistance - self.distance)
        self.isTracking = true
    }
}
```

---

## Task vs async let vs withTaskGroup

| API | Use when |
|---|---|
| `Task { }` | Fire work from synchronous context; not structured |
| `async let` | 2–4 independent fetches, all needed before proceeding |
| `withTaskGroup` | Dynamic number of parallel operations |
| `for await` | Stream of values (Combine publisher, AsyncSequence) |

```swift
// async let — start both fetches simultaneously, await both
async let user = api.fetchUser(id: userId)
async let posts = api.fetchPosts(for: userId)
let (u, p) = try await (user, posts)

// withTaskGroup — N parallel operations, collect results
let results = try await withThrowingTaskGroup(of: Item.self) { group in
    for id in ids {
        group.addTask { try await api.fetchItem(id: id) }
    }
    var items: [Item] = []
    for try await item in group {
        items.append(item)
    }
    return items
}
```

---

## Task Cancellation Patterns

### Check Cancellation in Long Operations
```swift
func processItems(_ items: [Item]) async throws -> [Result] {
    var results: [Result] = []
    for item in items {
        try Task.checkCancellation()    // throws if cancelled
        results.append(try await process(item))
    }
    return results
}
```

### withTaskCancellationHandler for Cleanup
```swift
func fetch(url: URL) async throws -> Data {
    try await withTaskCancellationHandler {
        try await URLSession.shared.data(from: url).0
    } onCancel: {
        // URLSession handles this internally, but for custom resources:
        resource.cancel()
    }
}
```

### .task modifier vs onAppear + Task
```swift
// Bad — task not cancelled on disappear
.onAppear {
    Task { try? await viewModel.load() }
}

// Good — .task cancels when view disappears
.task {
    try? await viewModel.load()
}

// Good — .task with dependencies, re-runs when id changes
.task(id: userId) {
    try? await viewModel.load(userId: userId)
}
```

Real UI-sequence pattern from `reading tracker`:

- keep the active task in `@State`
- cancel the previous task before starting a new sequence
- check cancellation after each `Task.sleep`
- clear task state at the end

---

## Sendable Conformance Errors

**Symptom:** `Passing value of non-sendable type 'X' across actor boundaries`

**Root cause:** Sending a reference type (class) across actor boundaries requires `Sendable` conformance.

```swift
// Error — class is not Sendable
class Config { var value: String = "" }

@MainActor
func update(config: Config) { ... }   // warning: Config not Sendable

// Fix 1: Make it a struct (value types are implicitly Sendable)
struct Config: Sendable { var value: String = "" }

// Fix 2: Annotate with @unchecked Sendable if you manage thread safety yourself
final class Config: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: String = ""
    var value: String {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }
}

// Fix 3: Use an actor to protect the mutable state
actor Config {
    var value: String = ""
}
```

---

## Actor Isolation Gotchas

### Calling nonisolated from @MainActor
```swift
@MainActor
class ViewModel {
    var state: State = .idle
    
    func load() async {
        // This is fine — await hops off main, result comes back to main
        let data = await fetchData()
        state = .loaded(data)
    }
}

nonisolated func fetchData() async -> [Item] {
    // Runs on background — can't access MainActor-isolated state here
}
```

### Isolated async function vs nonisolated
```swift
// @MainActor async — caller must be on main, or use await
@MainActor
func updateUI() async { ... }

// nonisolated async — can be called from anywhere
nonisolated func computeHash() async -> String { ... }
```

---

## Task Deduplication (from AuthSessionImpl)

When multiple callers might trigger the same async operation, deduplicate:

```swift
private var currentLoadTask: Task<[Item], Error>?
private let lock = NSLock()

func loadItems() async throws -> [Item] {
    let task = lock.withLock {
        if let existing = currentLoadTask { return existing }
        let newTask = Task { try await doLoad() }
        currentLoadTask = newTask
        return newTask
    }
    
    defer {
        lock.withLock { currentLoadTask = nil }
    }
    
    return try await task.value
}
```

Multiple concurrent calls to `loadItems()` all get the same `Task` and wait for the same result. Only one network request fires.

## Queue + Publisher Bridge

`ConversationViewModel` in `Haptics` serializes publisher delivery on a dedicated queue before forwarding events. This is a useful compromise when the source is Combine-based and not actor-aware, but you still need ordered state handling.

---

## Race Conditions in @Observable

**Symptom:** State looks correct in isolation, but wrong under concurrent access.

```swift
// Race — two tasks both check and modify items
func addItem(_ item: Item) async {
    if !items.contains(item) {   // Task A reads: not contained
        // Task B also reads: not contained
        items.append(item)        // Both append → duplicate
    }
}

// Fix — serialize through @MainActor (both reads and writes on same actor)
@Observable
@MainActor
class Store {
    private(set) var items: [Item] = []
    
    func addItem(_ item: Item) {
        guard !items.contains(item) else { return }
        items.append(item)
    }
}
```

## Cache and Loader Split

`AsyncCachedImageModel` in `any-distance-ios` is a good pattern for image-heavy features:

- serial queue for in-memory cache mutation
- request coalescing for identical URLs
- background resize/decode work
- `MainActor.run` only for final UI assignment

Avoid pushing the whole pipeline onto the main actor just because the end result is UI-facing.

---

## Combine Publisher → Async Bridge

When you have a Combine publisher and need to use it in async context:

```swift
// Iterate publisher values as an AsyncSequence
for await state in authSession.statePublisher.values {
    switch state {
    case .authenticated(let userId):
        await loadUser(userId: userId)
    case .unauthenticated:
        showLogin()
    }
}

// Bridge asyncMap (from any-distance-ios pattern)
// Wraps an async closure in a Combine publisher via Future
extension Publisher {
    func asyncMap<T>(_ transform: @escaping (Output) async -> T)
        -> Publishers.FlatMap<Future<T, Never>, Self>
    {
        flatMap { value in
            Future { promise in
                Task { promise(.success(await transform(value))) }
            }
        }
    }
}
```

---

## Common Diagnostic for Concurrency Bugs

1. Enable Thread Sanitizer (Product → Scheme → Diagnostics → Thread Sanitizer)
2. Enable Main Thread Checker (same location)
3. Run the app and exercise the concurrent code paths
4. TSan will surface data races; Main Thread Checker will surface UI updates off-main
