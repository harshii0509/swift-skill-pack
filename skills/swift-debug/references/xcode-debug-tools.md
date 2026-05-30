# Xcode Debug Tools

---

## Instruments Workflows

### Time Profiler (CPU spikes, slow frames)

1. Product → Profile (⌘I)
2. Choose "Time Profiler"
3. Hit record, reproduce the slow behavior, stop
4. Look for the **heaviest stack frame** in the Call Tree
5. Filter to "Hide System Libraries" to see your code
6. Click the call stack to jump to the offending line

**What to look for:**
- `body` called more often than expected → body is too expensive, or too many state changes
- Main thread doing file I/O, JSON decoding, image processing → move to background
- SwiftUI layout calls in a hot loop → GeometryReader causing layout recursion

### Allocations (memory growing)

1. Instruments → Allocations
2. Look for "Persistent" bytes growing over time without dropping
3. Use "Mark Generation" before/after a flow to see what leaked between them
4. Click leaked allocation → Backtrace shows where it was created
5. Most common cause in SwiftUI: closure capturing `self` strongly + `self` not released

### Core Animation (GPU / frame drops)

1. Instruments → Core Animation
2. Look for "Commit" rows — long commits mean too much work per frame
3. "Color Blended Layers" overlay (View → Debug → Color Blended Layers in Simulator) shows where alpha compositing is expensive
4. `drawingGroup()` on a complex SwiftUI subtree can flatten this to one GPU call

---

## Memory Graph Debugger

**Access:** Debug → Debug Memory Graph (⌃⌥⌘B), or the memory graph button in the debug bar.

**How to read it:**
- Each node is a live object; arrows show retain edges
- A **retain cycle** looks like a circle: A → B → A
- Click a node to see what retains it in the right panel
- Filter by class name to find all live instances

**Common retain cycles in SwiftUI:**
```swift
// Closure captures viewModel strongly, viewModel holds closure
class ViewModel {
    var onUpdate: (() -> Void)?   // if this closure captures `self` → cycle
}

// Fix: use [weak self] in the closure
viewModel.onUpdate = { [weak self] in
    self?.refresh()
}

// Note: inside Task { } you usually DON'T need [weak self]
// Tasks are structured and don't create retain cycles with @MainActor actors
```

---

## View Hierarchy Debugger

**Access:** Debug → View Hierarchy (⌃⌥⌘V), or the 3-panel icon in the debug bar.

**How to use:**
- Rotate the 3D stack to see layering
- Click any layer to see its frame, bounds, constraints in the right panel
- Filter by `UISwiftUIView` to find SwiftUI view frames
- Use "Show Unclipped Subviews" to see views rendering outside their clip rect

**Common uses:**
- "Why is my tap area wrong?" → find the actual frame of the tappable element
- "Why is there empty space?" → find the invisible view eating layout
- "Why is text cut off?" → find which parent frame is too narrow

---

## Breakpoint Techniques

### Conditional Breakpoint
Right-click a breakpoint → Edit → Condition: `items.count == 0`

### Action Breakpoint (log without stopping)
Right-click → Edit → Add Action → "po self.state" → check "Automatically continue"

This is better than `print()` — it leaves no code behind, is controllable, and works in release builds.

### Symbolic Breakpoint
Breakpoints panel → + → Symbolic Breakpoint  
Symbol: `-[UIViewController viewDidLoad]` or `Swift.Array.append`  
Use to catch calls to methods you don't own.

### Swift Error Breakpoint
Breakpoints panel → + → Swift Error Breakpoint  
Breaks when any error is thrown — invaluable for "something throws but I don't know where."

---

## Thread Sanitizer and Main Thread Checker

**Enable:** Product → Scheme → Edit Scheme → Diagnostics

| Tool | Catches |
|---|---|
| Thread Sanitizer | Data races (two threads read/write same memory without sync) |
| Main Thread Checker | UIKit/SwiftUI updates from background threads (purple warnings) |
| Address Sanitizer | Buffer overflows, use-after-free |
| Undefined Behavior Sanitizer | Integer overflow, null dereference |

**Don't ship with these enabled** — they add significant overhead. Use in debug/test builds only.

---

## OSLog in Console.app

OSLog categories appear in Console.app's sidebar under the app subsystem.

**Setup:**
```swift
// Define once per subsystem/category — share across the file
private let logger = Logger(subsystem: "com.myapp", category: "Auth")

// In AppDelegate or @main:
// No setup needed — OSLog is always active
```

**Console.app workflow:**
1. Open Console.app
2. Select your device or "My Mac" in the sidebar
3. Start the app
4. Type `subsystem:com.myapp` in the filter bar
5. Add `AND category:Auth` to narrow further
6. Use `privacy: .public` on values you want visible; default is redacted

**Log levels for filtering:**
- `.debug` → only visible in Console.app during development
- `.info` → visible in Console.app
- `.error` / `.fault` → always persisted to disk, visible in crash reports

---

## Quick Commands in the LLDB Console

```bash
# Print an object
po self.viewModel.state

# Evaluate an expression
expr items.count

# Step over / into / out
n / s / finish

# Continue
c

# Print all local variables
frame variable

# Jump to a different frame in the call stack
frame select 2

# Print thread state
thread info

# List all threads
thread list
```

---

## Reading a Crash Log

When you get a crash in the wild:

1. Open Organizer → Crashes → select the crash
2. Xcode symbolicates automatically if you have the dSYM
3. Look for **Thread 0** — the main thread that crashed
4. The top frame in Thread 0 is usually where the crash happened
5. Common crash types:
   - `SIGABRT` with `abort()` → assertion failure or precondition failure
   - `EXC_BAD_ACCESS` → nil force-unwrap or use-after-free
   - `EXC_CRASH (SIGKILL)` → watchdog killed the app (main thread blocked > ~8 seconds)
   - `NSInternalInconsistencyException` → UIKit contract violated (often off-main update)
