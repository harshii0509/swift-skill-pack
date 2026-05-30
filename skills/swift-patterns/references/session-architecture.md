# Session Architecture

Distilled from Haptics app: AuthSession, ConversationsSession, FeedbackSession, ProfileSession (25-package modular architecture).

---

## What Is a Session?

A Session is an `@Observable` (or `ObservableObject`) class that:
- **Owns** a domain's async state (auth state, conversation list, user profile)
- **Exposes** a protocol so it can be mocked in tests
- **Lives** for the app's lifetime (or the relevant scope)
- **Is injected** via SwiftUI environment, not passed as an init parameter

Sessions replace singletons and eliminate prop-drilling.

---

## Protocol-First Session Design (from AuthSession)

```swift
// Protocol in its own file — this is what the rest of the app depends on
public protocol AuthSession: AnyObject {
    var state: AuthSessionState { get }
    var statePublisher: AnyPublisher<AuthSessionState, Never> { get }
    
    func signIn() async throws
    func signOut() async throws
    func update(username: String) async throws
}

// Implementation in a separate file
public final class AuthSessionImpl: AuthSession {
    public private(set) var state: AuthSessionState {
        get { stateSubject.value }
        set { stateSubject.value = newValue }
    }
    
    public let statePublisher: AnyPublisher<AuthSessionState, Never>
    private let stateSubject: CurrentValueSubject<AuthSessionState, Never>
    private let syncQueue = DispatchQueue(label: "AuthSession")
    
    init() {
        let initialState = Self.cachedAuthState(for: Auth.auth().currentUser)
        let subject = CurrentValueSubject<AuthSessionState, Never>(initialState)
        self.stateSubject = subject
        self.statePublisher = subject.eraseToAnyPublisher()
        
        // Listen to Firebase auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            let newState = Self.cachedAuthState(for: user)
            self.syncQueue.async {
                self.state = newState   // thread-safe mutation
            }
        }
    }
}
```

Key patterns from the real implementation:
- `CurrentValueSubject` stores the current value and emits to new subscribers
- `syncQueue` serializes all state mutations (prevents races)
- `weak self` in the Firebase listener prevents retain cycle

---

## Dependency Injection via swift-dependencies

Haptics uses [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) for DI. It creates a global, typed dependency registry:

```swift
// 1. Register the session as a dependency (in the package that owns it)
public extension DependencyValues {
    private enum AuthSessionKey: DependencyKey {
        static let liveValue: AuthSession = AuthSessionImpl()
        // static let testValue: AuthSession = MockAuthSession()  // for tests
    }
    
    var authSession: AuthSession {
        get { self[AuthSessionKey.self] }
        set { self[AuthSessionKey.self] = newValue }
    }
}

// 2. Inject at call site with @Dependency
class SomeManager {
    @Dependency(\.authSession) private var authSession
    
    func doSomething() async {
        switch authSession.state {
        case .authenticated(let userId): ...
        case .unauthenticated: ...
        }
    }
}
```

**Without swift-dependencies**, use SwiftUI environment:
```swift
// In @main App:
.environment(authSession)  // iOS 17+ @Observable
// or:
.environmentObject(authSession)  // ObservableObject

// In any descendant view:
@Environment(AuthSession.self) private var authSession
```

In `Haptics`, this DI style is not limited to SwiftUI views. UIKit and service-layer types also pull dependencies with `@Dependency`, which is often the right fit in mixed UIKit/SwiftUI apps.

---

## Session State Machine Pattern

Sessions work well as state machines with enum states:

```swift
// From AuthSessionState
public enum AuthSessionState: Equatable {
    case unauthenticated
    case authenticated(userId: String)
    case needsToProvideInfo(userId: String, infoScopes: Set<AdditionalAuthInfoScope>)
    
    var userId: String? {
        switch self {
        case .authenticated(let id), .needsToProvideInfo(let id, _): return id
        case .unauthenticated: return nil
        }
    }
}
```

Benefits:
- Impossible states are unrepresentable
- Switch exhaustiveness catches missing cases at compile time
- `var userId: String?` computed property avoids repeated switching in callers

---

## Task Deduplication for Idempotent Operations

When multiple callers might trigger the same expensive operation, deduplicate using a stored Task:

```swift
private var currentUpdateTask: Task<Void, Error>?
private let lock = NSLock()

func update(username: String) async throws {
    let task = lock.withLock {
        if let current = currentUpdateTask { return current }
        let t = Task { try await doUpdate(username: username) }
        currentUpdateTask = t
        return t
    }
    defer { lock.withLock { currentUpdateTask = nil } }
    try await task.value
}
```

If two views call `update(username:)` at the same time, only one network request fires. Both await the same result.

---

## Session Lifecycle: Initialization Order

In Haptics' `AppDelegate`, sessions are initialized in dependency order:

```swift
// AuthSession must exist before ConversationsSession (needs userId)
let authSession = AuthSessionImpl()
let conversationsSession = ConversationsSessionImpl(authSession: authSession)
let profileSession = ProfileSessionImpl(authSession: authSession)

// Pass to SwiftUI environment
ContentView()
    .environment(authSession)
    .environment(conversationsSession)
    .environment(profileSession)
```

**Circular dependency rule:** If A needs B and B needs A, extract the shared concern into C. Never have circular session dependencies.

## App Bootstrap Pattern

The `Haptics` `AppDelegate` shows that production architecture needs an explicit bootstrap layer in addition to sessions:

- configure Firebase and optional emulators
- prewarm App Check
- observe token changes
- reconnect realtime services when credentials change
- emit launch diagnostics

Keep this bootstrap logic separate from feature sessions. Sessions should own domain state, not app-launch plumbing.

---

## Session Cleanup / Teardown

On sign-out, reset session state and cancel any in-flight operations:

```swift
func signOut() async throws {
    // Let session know about impending sign-out (so it can write pending data)
    try await delegate?.willSignOut(with: userId)
    
    // Sign out from the auth provider
    try Auth.auth().signOut()
    
    // State change listener will automatically update state to .unauthenticated
}

// In ConversationsSession — cleanup on auth state change:
authSession.statePublisher
    .filter { $0 == .unauthenticated }
    .sink { [weak self] _ in
        self?.clearLocalCache()
        self?.cancelSubscriptions()
    }
    .store(in: &cancellables)
```

The same principle applies to token or infrastructure resets. If a backend connection depends on expiring credentials, treat rebind/reconnect as an explicit lifecycle event rather than hidden magic.

---

## Mocking Sessions for Tests

```swift
final class MockAuthSession: AuthSession {
    var state: AuthSessionState = .unauthenticated
    
    let stateSubject = PassthroughSubject<AuthSessionState, Never>()
    var statePublisher: AnyPublisher<AuthSessionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    func signIn() async throws { state = .authenticated(userId: "test-user") }
    func signOut() async throws { state = .unauthenticated }
    func update(username: String) async throws {}
}

// In tests:
withDependencies {
    $0.authSession = MockAuthSession()
} operation: {
    // test code here
}
```

## When Not to Make a Session

Do not create a session just because code is shared.

Prefer:

- wrapper views for UI-only behavior
- managers/services for stateless work
- bootstrap objects for launch-time infrastructure
- plain helpers for local transformations

Use a session only when the type truly owns evolving shared app state.
