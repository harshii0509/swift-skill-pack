# Combine to Async/Await Migration

Distilled from any-distance-ios `CombineExtensions.swift` and Haptics Firebase integration patterns.

---

## The Decision Framework

Don't migrate everything — use the right tool:

| Situation | Use |
|---|---|
| Single async operation (fetch, save) | `async/await` |
| Stream of values over time (auth state, real-time DB) | Combine publisher OR `AsyncStream` |
| Combining multiple publishers (combineLatest, merge, zip) | Combine |
| Sequential async with error handling | `async/await` with `do/catch` |
| Integrating Combine publisher into async context | `publisher.values` |

---

## Iterating a Publisher as AsyncSequence

The cleanest bridge — no custom code needed:

```swift
// Combine publisher
let statePublisher: AnyPublisher<AuthSessionState, Never>

// Use in async context
func observeAuth() async {
    for await state in statePublisher.values {
        switch state {
        case .authenticated(let userId):
            await loadUser(userId: userId)
        case .unauthenticated:
            showLogin()
        case .needsToProvideInfo:
            showOnboarding()
        }
    }
}

// In a .task modifier:
.task {
    for await state in authSession.statePublisher.values {
        // auto-cancels when view disappears
    }
}
```

`.values` converts any `Publisher` to an `AsyncSequence`. The loop ends when the publisher completes or the task is cancelled.

---

## asyncMap: Bridging async Closures into Combine (from any-distance-ios)

When you have a Combine pipeline that needs to call async code at some point:

```swift
extension Publisher {
    func asyncMap<T>(
        _ transform: @escaping (Output) async -> T
    ) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    let result = await transform(value)
                    promise(.success(result))
                }
            }
        }
    }
}

// Usage:
activityPublisher
    .asyncMap { activity in
        await ImageProcessor.thumbnail(for: activity.route)  // async call
    }
    .receive(on: DispatchQueue.main)
    .sink { thumbnail in
        self.thumbnail = thumbnail
    }
    .store(in: &cancellables)
```

**Caveat:** The `Task` inside `Future` is not cancellation-aware — it runs to completion even if the subscriber cancels. For cancellation, use `.values` + `for await` instead.

---

## @Published + ObservableObject vs @Observable

| | `@Published` + `ObservableObject` | `@Observable` (iOS 17+) |
|---|---|---|
| iOS support | iOS 13+ | iOS 17+ |
| Granularity | Whole object re-renders on any `@Published` change | Fine-grained — only views reading changed property re-render |
| Combine integration | Built-in `objectWillChange` publisher | Use `withObservationTracking` or `.values` |
| Syntax | `@Published var x` + `@ObservedObject` | `@Observable` class + `@State var model` |
| Testing | `XCTestExpectation` + `sink` | Same, or use `withObservationTracking` |

```swift
// Old: ObservableObject
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
}
// In view: @ObservedObject var vm = ViewModel()

// New: @Observable (iOS 17+)
@Observable
class ViewModel {
    var items: [Item] = []
    var isLoading = false
}
// In view: @State private var vm = ViewModel()
```

---

## PassthroughSubject → AsyncStream Migration

```swift
// Old: PassthroughSubject as event bus
let eventBus = PassthroughSubject<AppEvent, Never>()
// Emit: eventBus.send(.userDidLogin)
// Subscribe: eventBus.sink { ... }

// New: AsyncStream (structured, cancellable)
func makeEventStream() -> AsyncStream<AppEvent> {
    AsyncStream { continuation in
        let cancellable = eventBus.sink { event in
            continuation.yield(event)
        }
        continuation.onTermination = { _ in
            cancellable.cancel()
        }
    }
}

// Consume:
for await event in makeEventStream() {
    handle(event)
}
```

---

## AnyCancellable vs Task: What to Store

```swift
// Combine: store AnyCancellable in a Set — it cancels when removed from Set
private var cancellables = Set<AnyCancellable>()

somePublisher
    .sink { value in ... }
    .store(in: &cancellables)   // cancelled when `cancellables` is destroyed

// Common mistake: storing in a local var
func setup() {
    let c = somePublisher.sink { ... }
    // c goes out of scope immediately → subscription cancels instantly
}

// Fix: store in instance var
func setup() {
    somePublisher
        .sink { [weak self] value in self?.handle(value) }
        .store(in: &cancellables)  // lives as long as self
}
```

```swift
// async/await: store Task if you need to cancel it
private var loadTask: Task<Void, Never>?

func startLoading() {
    loadTask?.cancel()   // cancel previous before starting new
    loadTask = Task {
        await performLoad()
    }
}
```

---

## withPrevious: Comparing Old and New Values (from any-distance-ios)

When you need the previous value alongside the current one:

```swift
extension Publisher {
    func withPrevious() -> AnyPublisher<(previous: Output?, current: Output), Failure> {
        scan(Optional<(Output?, Output)>.none) { ($0?.1, $1) }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}

// Usage: detect direction of state change
authSession.statePublisher
    .withPrevious()
    .sink { previous, current in
        if previous == .unauthenticated && current != .unauthenticated {
            // just signed in
        }
    }
    .store(in: &cancellables)
```

---

## Error Propagation Patterns

```swift
// Combine: mapError, catch, replaceError
networkPublisher
    .mapError { NetworkError.underlying($0) }
    .catch { error -> AnyPublisher<[Item], Never> in
        logger.error("fetch failed: \(error)")
        return Just([]).eraseToAnyPublisher()   // recover with empty
    }
    .sink { items in ... }

// async/await: do/catch, try?
do {
    let items = try await api.fetch()
    self.items = items
} catch is CancellationError {
    // expected — task was cancelled
} catch let error as NetworkError {
    self.error = error
} catch {
    logger.error("unexpected error: \(error)")
}
```

---

## CombineLatestCollection: N Publishers in Parallel (from any-distance-ios)

When you have a dynamic array of publishers and need to combine them:

```swift
extension Collection where Element: Publisher {
    var combineLatest: CombineLatestCollection<Self> {
        CombineLatestCollection(self)
    }
}

// Usage:
let publishers: [AnyPublisher<Status, Never>] = items.map { $0.statusPublisher }

publishers.combineLatest
    .sink { statuses in
        // [Status] — one value per publisher, latest from each
    }
    .store(in: &cancellables)
```

This is the N-publisher version of `Publishers.CombineLatest` (which only does 2–4).
