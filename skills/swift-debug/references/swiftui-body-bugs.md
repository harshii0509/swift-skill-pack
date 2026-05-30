# SwiftUI Body Bugs

The most common SwiftUI-specific bugs, each with diagnosis → root cause → fix.

---

## 1. ForEach Identity Instability

**Symptom:** Items animate incorrectly on update, views have wrong state, duplicates appear.

**Diagnosis:** `_printChanges()` shows all items changing on every update.

**Root cause:** Using `\.self` as identity on mutable or non-value-semantic types.

```swift
// Wrong — String content is the identity; any mutation looks like deletion + insertion
ForEach(names, id: \.self) { Text($0) }

// Wrong — UUID is random, so every rebuild creates "new" items
ForEach(items, id: \.id) where id = UUID()
```

**Fix:** Make items `Identifiable` with a stable ID that doesn't change:
```swift
struct Item: Identifiable {
    let id: UUID = UUID()   // created once, never changes
    var name: String
}

ForEach(items) { item in   // uses Identifiable automatically
    Text(item.name)
}
```

---

## 2. @State Initialization Trap

**Symptom:** State doesn't reflect changes to a value passed from parent.

**Root cause:** `@State` only reads its initial value from the initializer *once*. Subsequent parent re-renders don't update it.

```swift
// Wrong — parentValue changes, but @State ignores it after first init
struct Child: View {
    @State private var localCopy: String
    init(parentValue: String) {
        self._localCopy = State(initialValue: parentValue)  // only runs once!
    }
}

// Right — use @Binding if the parent owns the value
struct Child: View {
    @Binding var value: String
}

// Or: use .onChange to sync if the copy is intentional
struct Child: View {
    let externalValue: String
    @State private var localCopy: String = ""
    
    var body: some View {
        TextField("", text: $localCopy)
            .onAppear { localCopy = externalValue }
            .onChange(of: externalValue) { localCopy = $1 }
    }
}
```

---

## 3. Sheet Memory Leak Pattern

**Symptom:** Memory grows after repeated sheet presentations; objects aren't deallocated.

**Root cause:** `sheet(isPresented:)` keeps the content view in memory as long as `isPresented` is `true`, plus it doesn't clean up correctly on programmatic dismiss.

```swift
// Wrong — the Optional model inside persists after dismiss
@State private var showDetail = false
@State private var selectedItem: Item?

.sheet(isPresented: $showDetail) {
    if let item = selectedItem {
        DetailView(item: item)   // item never cleared on dismiss
    }
}

// Right — sheet(item:) deallocates when item is nil
@State private var selectedItem: Item?

.sheet(item: $selectedItem) { item in
    DetailView(item: item)
}

// Setting selectedItem = nil programmatically dismisses AND clears
```

---

## 4. EnvironmentObject Not Injected

**Symptom:** `Fatal error: No ObservableObject of type X found` at runtime.

**Root cause:** `@EnvironmentObject` requires the object to be injected somewhere *above* this view in the hierarchy.

```swift
// Common case: view used in a sheet or navigation destination that lacks the injection
.sheet(isPresented: $show) {
    MyView()   // crash if MyView uses @EnvironmentObject
        .environmentObject(myStore)   // fix: inject here
}
```

**Debug:** Add a breakpoint at the crash site and inspect the environment with `po` to see what's available.

---

## 5. Expensive Closure in Body

**Symptom:** Scrolling is janky, CPU pegged, UI lags on state changes.

**Diagnosis:** Add `let _ = Self._printChanges()` and see if body is called on unrelated state changes.

**Root cause:** Heavy computation (sort, filter, regex, image resize) placed directly in `body`.

```swift
// Wrong — sorts 1000 items every time ANY state changes
var body: some View {
    let sorted = items.sorted { $0.date > $1.date }   // runs on EVERY render
    ForEach(sorted) { item in ... }
}

// Right — cache in a computed property on the ViewModel, or use a separate @State
// Option 1: derive in ViewModel, only recompute when items change
// Option 2: use .onChange to maintain a sorted copy
@State private var sortedItems: [Item] = []

.onChange(of: items) { _, new in
    sortedItems = new.sorted { $0.date > $1.date }
}
.onAppear {
    sortedItems = items.sorted { $0.date > $1.date }
}
```

---

## 6. animation() Without a Value

**Symptom:** Things animate that shouldn't, or animations fire at wrong times.

**Root cause:** `.animation(_:)` (without `value:`) animates ALL changes in the subtree. This was deprecated in SwiftUI 4.

```swift
// Wrong — deprecated, animates everything
.animation(.spring())

// Right — only animates when `isExpanded` changes
.animation(.spring(), value: isExpanded)
```

---

## 7. Task Not Cancelled on View Disappear

**Symptom:** `@State` updates after a view is gone, purple runtime warning about publishing changes.

**Root cause:** An unstructured `Task { }` started in `onAppear` outlives the view.

```swift
// Wrong — task runs forever
.onAppear {
    Task {
        let data = try await api.fetch()
        self.items = data    // view might be gone by now
    }
}

// Right — use .task modifier, which cancels automatically on disappear
.task {
    do {
        items = try await api.fetch()
    } catch is CancellationError {
        // expected — view disappeared
    }
}

// Or store the task and cancel manually:
@State private var fetchTask: Task<Void, Never>?

.onAppear { fetchTask = Task { ... } }
.onDisappear { fetchTask?.cancel() }
```

---

## 8. GeometryReader Causes Layout Loop

**Symptom:** CPU spins, Xcode shows continuous view updates, frame changes every render.

**Root cause:** GeometryReader inside a view that its own size affects creates a recursive dependency.

```swift
// Wrong — GeometryReader changes the frame, which changes the parent, which...
VStack {
    GeometryReader { geo in
        Text("Width: \(geo.size.width)")
    }
}

// Right — read geometry without affecting layout via overlay or background
Color.clear
    .overlay(alignment: .center) {
        GeometryReader { geo in
            Color.clear.onAppear { width = geo.size.width }
        }
    }

// Better — use .containerRelativeFrame (iOS 17+) instead of GeometryReader
.containerRelativeFrame(.horizontal, count: 3, span: 2, spacing: 8)
```

---

## 9. @Observable Class Missing @MainActor

**Symptom:** Purple runtime warning: "Publishing changes from background threads is not allowed."

**Root cause:** An `@Observable` class (or `ObservableObject`) mutates its properties from a background thread.

```swift
// Wrong — background Task mutates @Observable state
@Observable
class FeedViewModel {
    var items: [Item] = []
    
    func load() async {
        let data = await api.fetch()
        items = data   // might be on background thread!
    }
}

// Right — annotate the whole class with @MainActor
@Observable
@MainActor
class FeedViewModel {
    var items: [Item] = []
    
    func load() async {
        let data = await api.fetch()
        items = data   // now guaranteed on main thread
    }
}
```

---

## 10. equatable() Modifier Silently Breaking Updates

**Symptom:** View doesn't update even when data changes.

**Root cause:** `.equatable()` tells SwiftUI to skip body if the view is `Equatable` and reports equal. If your `Equatable` implementation is wrong, updates are silently skipped.

```swift
// Wrong — custom Equatable only checks id, not content
struct ItemView: View, Equatable {
    let item: Item
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.item.id == rhs.item.id   // bug: doesn't check if item.name changed
    }
    var body: some View { Text(item.name) }
}

// Right — compare the full value, not just identity
static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.item == rhs.item   // requires Item: Equatable
}
```

Use `.equatable()` only when the performance gain is measured and confirmed.
