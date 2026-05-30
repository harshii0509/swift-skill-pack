# Debug Methodology

---

## The DREAM Process

### Step 1: Define the Symptom
Sloppy symptom definition leads to sloppy fixes. Before doing anything:
- What is the **expected** behavior?
- What is the **actual** behavior?
- What are the **exact conditions** that trigger it?

Bad: "The list doesn't update"  
Good: "After `save()` returns, the list still shows the old item count. Only happens when two saves fire within 500ms."

### Step 2: Reproduce Minimally
The smallest reproduction often reveals the cause:
1. Comment out everything not related to the symptom
2. Move to a fresh SwiftUI `PreviewProvider` if possible
3. If the bug disappears in isolation — it's a state interaction bug, not a logic bug

### Step 3: Examine State at the Failure Point

**Trace View body re-evaluation:**
```swift
struct MyView: View {
    var body: some View {
        let _ = Self._printChanges()   // prints which @State/binding changed
        // ...
    }
}
```

**Conditional breakpoint:** Right-click breakpoint → Edit → Add condition (e.g., `items.count == 0`)

**Expression breakpoint:** Add `po myViewModel.state` as a debugger action — prints without pausing.

**Structured logging (always prefer over print):**
```swift
import OSLog
private let logger = Logger(subsystem: "com.myapp.feature", category: "Auth")

logger.debug("signIn called, current state: \(state)")    // filtered out in release
logger.error("sign in failed: \(error.localizedDescription, privacy: .public)")
```

Filter in Console.app by subsystem or category. Use `privacy: .public` only for non-sensitive values.

### Step 4: Apply the Root Cause Fix
- If you found a workaround (e.g., reset a flag after 100ms) — keep looking
- The real fix removes the cause, not the symptom
- Ask: "What invariant was violated? How do I restore it?"

### Step 5: Measure After the Fix
- Does the original reproduction case pass?
- Does `_printChanges()` show fewer re-evaluations?
- If performance fix: does Instruments confirm the improvement?

---

## Writing a Minimal Reproduction

For SwiftUI bugs, the fastest path is a fresh ContentView:
```swift
struct ReproView: View {
    @State private var items: [String] = []
    
    var body: some View {
        VStack {
            ForEach(items, id: \.self) { Text($0) }
            Button("Add") { items.append(UUID().uuidString) }
        }
    }
}

#Preview { ReproView() }
```

Strip down to the minimum, then add back your actual logic piece by piece until the bug reappears. That piece is the culprit.

---

## Breakpoint Strategies

| Scenario | Breakpoint type |
|---|---|
| Want to know what called this function | Stack trace — run, then Debug → Pause |
| Bug only on specific value | Conditional breakpoint with expression |
| Want to log without stopping | Action breakpoint: "po myValue", auto-continue |
| UIKit method I don't own | Symbolic breakpoint: `-[UIViewController viewDidLoad]` |
| Exception thrown | Swift Error breakpoint (Add in breakpoints panel) |
| Main thread violation | MainThread checker: Product → Scheme → Diagnostics |

---

## When to Use Which Tool

| Issue | Tool |
|---|---|
| View re-renders too often | `_printChanges()` + breakpoint |
| Memory growing over time | Instruments → Allocations → Track leaked objects |
| CPU spike | Instruments → Time Profiler → find heaviest stack |
| GPU hitch | Instruments → Core Animation → find commit hitches |
| Data race (crash under concurrency) | Thread Sanitizer (scheme diagnostics) |
| Retain cycle | Memory Graph Debugger (⌃⌥⌘B in Xcode) |
| Unexpected nil crash | Add exception breakpoint + `po self` |
| Ordering bug | `Logger` with timestamps + Console.app filtering |

---

## OSLog Patterns

```swift
// One Logger per subsystem/category — define once, share across file
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Network")

// Levels: debug (dev only) → info → notice → error → fault
logger.debug("Request started: \(url.path, privacy: .public)")
logger.info("Fetched \(items.count) items")
logger.error("Request failed: \(error.localizedDescription, privacy: .public)")

// Redact user data by default — only expose with .public
logger.debug("User ID: \(userId, privacy: .private(mask: .hash))")
```

Filter in Console.app: `subsystem:com.myapp.feature AND category:Network`

---

## SwiftUI View Debugger

In simulator: Debug → View Hierarchy (⌃⌥⌘V) — or use Xcode's button in the debug bar.

Useful for:
- "Why is my tap area wrong?" — see the actual tappable frame
- "Why is padding different?" — inspect each layer's constraints
- "Why is text truncated?" — find which frame is too small
