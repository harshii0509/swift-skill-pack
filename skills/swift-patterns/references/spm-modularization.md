# SPM Modularization

Distilled from Haptics app (25 Swift packages) and its modular architecture design.

---

## When to Extract a New Package

Extract a new Swift package when **at least one** of these is true:
1. **3+ consumers** — three or more targets import the same code
2. **Hard boundary required** — you want the compiler to enforce that A cannot see B's internals
3. **Separate test surface** — this code has distinct testable behavior that warrants its own test target
4. **Independent release** — this code could theoretically be used by other apps

**Don't extract** just to organize. Three files sharing a folder is better than three single-file packages.

---

## Anatomy of a Well-Structured Package

From Haptics' `SharedSessions/Package.swift`:

```swift
// Package.swift
let package = Package(
    name: "SharedSessions",
    platforms: [.iOS(.v15)],
    products: [
        // Expose only what external targets need
        .library(name: "AuthSession", targets: ["AuthSession"]),
        .library(name: "AppHealthSession", targets: ["AppHealthSession"]),
    ],
    dependencies: [
        // External packages — use .upToNextMajor for stability
        .package(url: "https://github.com/pointfreeco/swift-dependencies",
                 .upToNextMajor(from: "1.12.0")),
        .package(url: "https://github.com/firebase/firebase-ios-sdk",
                 .upToNextMajor(from: "12.12.0")),
        // Internal packages (other packages in the same repo)
        .package(path: "./FirebaseExtensions"),
        .package(path: "./LoggerExtensions"),
    ],
    targets: [
        .target(
            name: "AuthSession",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "LoggerExtensions", package: "LoggerExtensions"),
            ]
        ),
        .testTarget(
            name: "AuthSessionTests",
            dependencies: ["AuthSession"]
        ),
    ]
)
```

Key decisions in this structure:
- **Multiple products, one package** — `AuthSession` and `AppHealthSession` share the same `Package.swift` because they share the same external dependencies (Firebase). One package resolution vs two.
- **Internal path packages** — `FirebaseExtensions`, `LoggerExtensions` are local packages referenced by `path:`. They're not published externally but still get separate compilation and test targets.
- **Product granularity** — each product exposes exactly one capability. Consumers only pay for what they import.

---

## Dependency Graph Design

**Goal:** A directed acyclic graph (DAG). No cycles.

```
App
├── AuthSession          (SharedSessions)
│   ├── FirebaseAuth
│   ├── LoggerExtensions (shared internal)
│   └── CryptoUtils      (shared internal)
├── ConversationsSession (standalone package)
│   ├── AuthSession      (depends on auth state)
│   └── RemoteDataModels
└── UIComponents         (no business logic dependencies)
    └── UIKitExtensions
```

**Anti-patterns that create cycles:**
- Business layer package imports UI layer package
- Two packages importing each other
- Shared `Utilities` package that grows to include business rules

**Fix cycles by:** extracting the shared concern into a new lower-level package that both can import.

---

## Internal vs Public API Discipline

Be explicit about access control. Public API should be intentional, not accidental.

```swift
// In a package target, default to internal
struct InternalHelper { ... }            // visible only within target

// Only expose what consumers actually need
public protocol AuthSession { ... }
public final class AuthSessionImpl: AuthSession { ... }

// Hide implementation details even from public protocol
public final class AuthSessionImpl: AuthSession {
    private let stateSubject: CurrentValueSubject<...>   // hidden
    public private(set) var state: AuthSessionState       // readable, not writable
}
```

**Rule of thumb:** Start with `internal`. Make `public` only when you write the first cross-package import. Remove `public` if that import is removed.

---

## Local Package Development Workflow

When iterating on a package that's also published externally:

```swift
// In the consuming app's Package.swift, override remote with local path:
dependencies: [
    // Temporarily override to test local changes
    .package(path: "../my-local-checkout/swift-dependencies"),
    // When done: revert to:
    // .package(url: "...", .upToNextMajor(from: "..."))
]
```

For internal monorepo packages, always use `path:` — no versioning needed between targets in the same repo.

---

## Testing Modular Packages in Isolation

Each package gets its own test target. Run it without building the whole app:

```bash
# Test a single package from its directory
swift test

# Or from the monorepo root with scheme
xcodebuild test -scheme AuthSession -destination 'platform=iOS Simulator,name=iPhone 16'
```

**What belongs in package tests:**
- Protocol conformance checks
- State machine transitions
- Edge cases in data transformation
- Mock-based integration tests for the package's boundary

**What doesn't belong:**
- Tests that require the real network/Firebase (use test scheme with separate config)
- UI tests (those live in the app target)

---

## Build Time Management

25 packages can parallelize well — the compiler builds non-dependent packages simultaneously.

Signs of build time problems:
- One large package that everything depends on → split it
- `@_implementationOnly import` needed → dependency is private but Package.swift doesn't reflect it
- Rebuild on every change → check that generated files aren't triggering dirty state

```swift
// Declare a dependency as implementation-only (not exposed in public headers)
// This prevents unnecessary rebuilds in consumers when the dep changes
@_implementationOnly import SomeInternalDep
```

---

## Naming Conventions in Haptics

From studying the package structure:
- Packages named after their primary type: `AuthSession`, `ProfileSession`, `ConversationsSession`
- Protocol and implementation in the same package (not separate)
- Logger extension in each package: `Logger+AuthSession.swift` with package-specific category
- Dependency extension: `AuthSession+Dependency.swift` (the `DependencyValues` extension)
- Error type: `AuthSessionError.swift` (typed errors per session, not a global error enum)
