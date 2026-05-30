# UIKit–SwiftUI Bridge

Distilled from any-distance-ios (682-file UIKit+SwiftUI hybrid app) and swipe-interaction experiment.

---

## UIViewRepresentable Anatomy

Use when you have a UIKit view that SwiftUI can't replicate:

```swift
struct MyViewRepresentable: UIViewRepresentable {
    // Properties passed from SwiftUI parent
    var color: Color
    @Binding var isActive: Bool
    
    // 1. Create the UIKit view once
    func makeUIView(context: Context) -> MyUIView {
        let view = MyUIView()
        view.delegate = context.coordinator   // set delegate via coordinator
        return view
    }
    
    // 2. Update it when SwiftUI state changes (called on every render)
    func updateUIView(_ uiView: MyUIView, context: Context) {
        uiView.setColor(UIColor(color))
        // Only update what changed — UIKit views have internal state
        // Don't reset everything unconditionally
    }
    
    // 3. Coordinator bridges UIKit callbacks to SwiftUI
    func makeCoordinator() -> Coordinator {
        Coordinator(isActive: $isActive)
    }
    
    class Coordinator: NSObject, MyUIViewDelegate {
        var isActive: Binding<Bool>
        init(isActive: Binding<Bool>) { self.isActive = isActive }
        
        func myViewDidActivate() {
            isActive.wrappedValue = true
        }
    }
    
    // 4. Teardown (optional) — called when the representable is removed
    func dismantleUIView(_ uiView: MyUIView, coordinator: Coordinator) {
        uiView.stopAnimations()
    }
}
```

**Key rule:** `makeUIView` runs once. `updateUIView` runs every time SwiftUI re-renders the parent. Be defensive in `updateUIView` — don't reset properties the UIKit view manages internally.

Two concrete patterns from `any-distance-ios`:

- `SearchField` is a value bridge: `UISearchBar` owns editing behavior, SwiftUI owns the bound text
- `TappableScrollView` is a hosted-content bridge: UIKit owns scroll behavior, while a hosted SwiftUI tree supplies the content

---

## UIViewControllerRepresentable

Use when you need a UIViewController (navigation, camera, UIScrollView with custom delegate):

```swift
// Minimal pattern from swipe-interaction experiment
struct CubeStoriesRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CubeStoriesViewController {
        CubeStoriesViewController()
    }
    
    // Called on every SwiftUI re-render — keep lightweight
    func updateUIViewController(_ vc: CubeStoriesViewController, context: Context) {
        // Only update what needs to respond to SwiftUI state
    }
}

// In SwiftUI:
struct ContentView: View {
    var body: some View {
        CubeStoriesRepresentable()
            .ignoresSafeArea()   // UIKit views don't know about safe areas
    }
}
```

Use `UIViewControllerRepresentable` when a view controller is the natural owner of the behavior. Do not force controller-style lifecycle or delegate complexity into a plain `UIViewRepresentable`.

---

## Sizing: Getting UIKit and SwiftUI to Agree

SwiftUI uses proposal-response sizing; UIKit uses frame/autolayout.

```swift
// UIViewRepresentable can declare its preferred size
func sizeThatFits(_ proposal: ProposedViewSize, uiView: MyUIView, context: Context) -> CGSize? {
    // Return nil to let SwiftUI decide, or return a size
    return CGSize(width: proposal.width ?? 200, height: 60)
}

// Or use intrinsicContentSize on the UIView:
class MyUIView: UIView {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 60)
    }
}
```

For full-screen UIKit views (Camera, Maps, etc.):
```swift
MyRepresentable()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .ignoresSafeArea()
```

`ZoomableScrollView` in `any-distance-ios` is a good reminder that Auto Layout is not mandatory inside a representable. If UIKit's container behavior is the point, a hosted view with a flexible frame can be simpler and more correct than constraint-heavy setup.

---

## The Anchor Point Problem (from swipe-interaction)

When you programmatically change `layer.anchorPoint`, the view jumps because position is relative to anchor. Always compensate:

```swift
func setAnchorPoint(_ anchorPoint: CGPoint, for view: UIView) {
    guard view.layer.anchorPoint != anchorPoint else { return }
    
    let oldAnchor = view.layer.anchorPoint
    // Calculate how much the position shifts
    let oldOffset = CGPoint(x: view.bounds.width * oldAnchor.x,
                            y: view.bounds.height * oldAnchor.y)
    let newOffset = CGPoint(x: view.bounds.width * anchorPoint.x,
                            y: view.bounds.height * anchorPoint.y)
    
    let oldPoint = oldOffset.applying(view.transform)
    let newPoint = newOffset.applying(view.transform)
    
    var position = view.layer.position
    position.x += newPoint.x - oldPoint.x
    position.y += newPoint.y - oldPoint.y
    
    view.layer.position = position
    view.layer.anchorPoint = anchorPoint
}
```

This is needed for the cube transition effect where the pivot point must be on the left or right edge during the fold.

---

## Lifecycle Mismatch Pitfalls

UIKit lifecycle ≠ SwiftUI lifecycle. Key mismatches:

| UIKit | SwiftUI equivalent | Mismatch |
|---|---|---|
| `viewDidLoad` | `.onAppear` (but fires on every appearance) | UIKit runs once, SwiftUI runs each time |
| `viewWillAppear` | `.onAppear` | Same — SwiftUI is per-appearance |
| `viewDidDisappear` | `.onDisappear` | Same |
| No equivalent | `.task` | UIKit has no structured async scope |

```swift
// UIKit: viewDidLoad runs once, safe for one-time setup
override func viewDidLoad() {
    super.viewDidLoad()
    setupCADisplayLink()   // set up once
}

// SwiftUI: onAppear runs every time the view appears (navigation, sheet)
// Use @State to guard one-time setup:
@State private var hasAppeared = false
.onAppear {
    guard !hasAppeared else { return }
    hasAppeared = true
    setupAnimations()
}
```

If coordinator callbacks depend on current SwiftUI inputs, refresh the coordinator's reference model in `updateUIView` instead of assuming the coordinator's initial state is still accurate.

---

## UIHostingController: Adding SwiftUI to UIKit App

```swift
// Embed a SwiftUI view in a UIKit view hierarchy
let hostingController = UIHostingController(rootView: MySwiftUIView())

// Add as child view controller
addChild(hostingController)
view.addSubview(hostingController.view)
hostingController.view.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
    hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
])
hostingController.didMove(toParent: self)
```

**Important:** Always call `addChild` + `didMove(toParent:)`. Skipping these breaks lifecycle callbacks.

The inverse also matters: if UIKit hosts SwiftUI content through `UIHostingController(rootView:)`, create the hosting controller once and update `rootView` later rather than rebuilding the subtree on every render.

---

## When to Stay in UIKit vs Push to SwiftUI

**Stay in UIKit when:**
- Complex gesture recognizer interactions that need UIGestureRecognizerDelegate
- Scroll views with custom behaviors (paging, deceleration rate, scroll-linked animations)
- CALayer animations that require precise timing control
- UIKit views you don't own (MapKit, ARKit, camera preview)
- Cube/3D page transitions (CATransform3D manipulation)

**Push to SwiftUI when:**
- The view is mostly static or declarative
- You need `@Observable` / `@State` integration
- You're building something new without UIKit constraints
- The interaction is standard (list, form, navigation)

**Hybrid works best when:**
- UIKit owns the "complex rendering" views
- SwiftUI wraps them via `UIViewRepresentable`
- SwiftUI handles the overall navigation and data flow

## Concrete Bridge Shapes

### Value bridge
Use for `UISearchBar`, `UITextField`, pickers, or other controls where SwiftUI owns the data and UIKit owns the interaction surface.

### Behavior bridge
Use when UIKit gives you behavior SwiftUI still cannot express cleanly, such as custom scroll interception or gesture-threshold logic like `ThresholdPanGestureRecognizer`.

### Hosted-content bridge
Use when UIKit owns the container and SwiftUI supplies child content, such as zoom surfaces, carousels, or advanced scroll/paging shells.
