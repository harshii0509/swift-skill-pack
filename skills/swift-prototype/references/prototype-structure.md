# Prototype Structure

How to set up, evolve, and eventually graduate a SwiftUI prototype.

---

## Single-File Prototype Anatomy

The canonical structure from the SwiftUI-experiments collection:

```swift
import SwiftUI
import SpriteKit   // only if needed

// 1. Constants and enums at the top
extension ContentView {
    enum Mode: String, CaseIterable {
        case a, b, c
    }
    private static let trackpadSize: CGFloat = 240
}

// 2. Supporting views (small, above ContentView or in same file)
struct KnobView: View {
    let isEnlarged: Bool
    var body: some View { ... }
}

// 3. Main ContentView — state at top, body in middle
struct ContentView: View {
    // All @State vars grouped at top
    @State private var currentMode: Mode = .a
    @State private var isDragging = false
    @State private var offset: CGSize = .zero
    
    // Immutable constants
    private let generator = UIImpactFeedbackGenerator(style: .soft)
    
    var body: some View {
        ZStack {
            // ...
        }
        .onAppear { generator.prepare() }
    }
    
    // Private helpers — named for what they compute, not what they do
    private func colorForMode(_ mode: Mode) -> Color { ... }
}

// 4. Extensions for auxiliary types
extension Color { ... }
extension CGPoint { ... }

// 5. Preview — show the interesting state, not just the default
#Preview {
    ContentView()
}

#Preview("Dragging state") {
    ContentView()   // or set some initial state that shows the interaction
}
```

Real examples from the source set:

- `adaptive text` keeps the whole idea in one file, including a tiny `@Observable` sensor bridge
- `reading tracker` keeps the feature in one file but isolates imperative particle rendering in `ParticleView`
- `reading light` stays prototype-friendly even with a large effect by grouping state, rendering helpers, and gesture overlay clearly

---

## @State vs @GestureState Decision Guide

| Use | When |
|---|---|
| `@State` | Value persists after gesture ends; drives other views; part of app state |
| `@GestureState` | Value only matters *during* the gesture; auto-resets on release |
| `@Binding` | Parent owns the truth; this view just reads/writes it |
| `@State` + accumulated | Draggable element that remembers its last position |

```swift
// @GestureState auto-resets to false when gesture ends
@GestureState private var isPressing = false

.gesture(LongPressGesture()
    .updating($isPressing) { _, state, _ in state = true }
)

// @State persists
@State private var isExpanded = false

.gesture(TapGesture().onEnded {
    isExpanded.toggle()   // stays true after tap
})
```

---

## Timer vs TimelineView vs CADisplayLink

| API | Use when | Notes |
|---|---|---|
| `Timer.publish(every:)` | Simple interval (< 60fps), don't need frame sync | Stop by canceling or using `.autoconnect()` carefully |
| `TimelineView(.animation)` | 60fps frame-synced, stays in SwiftUI | Auto-pauses when not visible; can be `.pausable` |
| `CADisplayLink` (in UIView) | UIKit/imperative rendering, need exact timing | Must call `.invalidate()` in `deinit` |

```swift
// TimelineView (preferred for SwiftUI prototypes)
TimelineView(.animation) { timeline in
    let elapsed = timeline.date.timeIntervalSinceReferenceDate
    Canvas { ctx, size in
        // draw using `elapsed`
    }
}

// Timer (simple, but leaks if not cancelled)
let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
@State private var phase: CGFloat = 0

.onReceive(timer) { _ in
    phase += 0.015
}
.onDisappear {
    timer.upstream.connect().cancel()   // don't forget this
}
```

---

## Preview-Driven Development

Write multiple previews that show the component in different states:

```swift
#Preview("Empty") {
    ContentView()
}

#Preview("With content") {
    ContentView(items: Item.samples)
}

#Preview("Dark mode") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("Compact width") {
    ContentView()
        .frame(width: 390, height: 844)
}
```

For interactive previews that respond to gesture, just run in the simulator canvas — SwiftUI previews support full gesture interaction.

If the prototype depends on ARKit, CoreMotion, UIKit delegates, or camera input, preview the derived UI state instead of trying to make the hardware dependency work inside `#Preview`.

---

## Good vs Bad Prototype Code

**Good: one state var drives everything**
```swift
@State private var dragOffset: CGSize = .zero

// Offset, color, scale — all derived from dragOffset
.offset(dragOffset)
.scaleEffect(1 + abs(dragOffset.height) / 400)
.foregroundColor(dragOffset.width > 0 ? .blue : .red)
```

**Bad: duplicate state that can get out of sync**
```swift
@State private var dragOffset: CGSize = .zero
@State private var currentColor: Color = .blue   // redundant — should derive from dragOffset
@State private var currentScale: CGFloat = 1.0   // redundant
```

**Good: gesture state local to the gesture**
```swift
.gesture(
    DragGesture()
        .onChanged { value in
            dragOffset = value.translation   // single @State update
        }
)
```

**Bad: multiple state updates in one gesture handler**
```swift
.onChanged { value in
    dragOffset = value.translation
    currentColor = value.translation.width > 0 ? .blue : .red   // derive this, don't store it
    currentScale = 1 + abs(value.translation.height) / 400       // derive this
}
```

---

## Avoiding Premature Abstraction

Prototypes should stay readable — one file, minimum types. Extract only when:
- The same pattern appears in 2+ places
- A sub-view needs its own state that the parent doesn't care about
- A helper function is used in 3+ places

Don't extract:
- A single-use view just because it's more than 20 lines
- Helper functions used once
- Constants that are only used in one place

Extract earlier when you cross one of these boundaries:

- UIKit bridge boundary: `UIViewRepresentable`, `UIViewControllerRepresentable`, `Coordinator`
- sensor or delegate boundary: ARKit, CoreMotion, camera, scroll callbacks
- render-loop boundary: `TimelineView`, `Canvas`, `CAEmitterLayer`, `CADisplayLink`

---

## Upgrading a Prototype to Production

When the idea is validated and it's time to ship:

**Step 1: Identify what stays as @State**
- Purely UI state (is menu open? is item dragging?) → stays `@State`
- Data that should persist or be shared → move to ViewModel/Session

**Step 2: Extract the ViewModel**
```swift
@Observable
@MainActor
class DetailViewModel {
    var items: [Item] = []
    
    func load() async {
        items = await api.fetchItems()
    }
}

// In the view:
@State private var viewModel = DetailViewModel()
```

**Step 3: Separate concerns**
- Keep the gesture/animation logic in the View (it's UI)
- Move data loading, business rules, persistence to ViewModel
- Move reusable UI patterns into their own View types

**Step 4: Add Identifiable to all ForEach items**
Prototypes often use `id: \.self` — replace with proper `Identifiable` before shipping.

**Step 5: Replace DispatchQueue.main.asyncAfter with .task**
```swift
// Prototype: fire-and-forget
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { ... }

// Production: cancellable, structured
.task {
    try? await Task.sleep(for: .seconds(0.5))
    // ...
}
```

**Step 6: Separate raw input from presentation state**

- raw input: scroll percentage, face distance, drag translation
- presentation state: current size bucket, overlay visibility, label text, mode

`adaptive text` is a strong example: it maps raw face distance into a semantic `SizeLevel`, then animates the level rather than the sensor noise directly.
