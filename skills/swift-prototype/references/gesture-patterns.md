# Gesture Patterns

Distilled from: `draggable-slider`, `dots-interaction`, `bouncy-grid`, `swipe-interaction`, `tilt-grid`, `waves`, `paper-navigation`

---

## DragGesture Fundamentals

### Always Use Local Coordinate Space
```swift
// Wrong — location.x is in the parent's coordinate space
.gesture(DragGesture().onChanged { $0.location })

// Right — local gives you coordinates relative to the gesture view
.gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
    .onChanged { value in
        touchLocation = value.location
    }
    .onEnded { _ in
        touchLocation = nil
    }
)
```

### Accumulated Offset Pattern (drag-to-reposition)
When a draggable element should remember where you left it:
```swift
@State private var offset: CGSize = .zero
@State private var accumulatedOffset: CGSize = .zero

// In .gesture:
DragGesture()
    .onChanged { value in
        offset = value.translation  // live delta
    }
    .onEnded { value in
        accumulatedOffset = CGSize(
            width: accumulatedOffset.width + value.translation.width,
            height: accumulatedOffset.height + value.translation.height
        )
        offset = .zero  // reset live delta
    }

// In .offset modifier:
.offset(x: accumulatedOffset.width + offset.width,
        y: accumulatedOffset.height + offset.height)
```

### Clamped Position (knob in bounds)
```swift
let newPosition = CGPoint(
    x: min(max(value.location.x, knobSize/2), trackpadSize - knobSize/2),
    y: min(max(value.location.y, knobSize/2), trackpadSize - knobSize/2)
)
```

### @GestureState for Transient In-Flight State
Use `@GestureState` (not `@State`) when the value only matters during the gesture:
```swift
@GestureState private var isDragging = false

.gesture(DragGesture()
    .updating($isDragging) { _, state, _ in
        state = true
    }
    .onEnded { _ in
        // isDragging automatically resets to false here
    }
)
```

---

## Spring Physics on Release

### Snap-Back with Velocity
```swift
.onEnded { _ in
    withAnimation(.interpolatingSpring(
        mass: 0.6,
        stiffness: 120,
        damping: 10,
        initialVelocity: 0
    )) {
        offset = .zero
    }
}
```

### Responsive During Drag, Springy on Release
```swift
// Knob enlarges while dragging
withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
    isKnobEnlarged = true
}

// Shrinks back on release
withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
    isKnobEnlarged = false
}
```

### Wave/Grid Bounce After Release
Physics-accurate oscillation from `bouncy-grid`:
```swift
// After release, compute time-based oscillation
let oscillationTime = (timeSinceRelease - returnDuration) / oscillationDuration
let amplitude = 0.6 * initialDisplacement
let frequency = 22.0
let decay = 3.5

// Damped oscillation formula: A * sin(ωt) * e^(-γt)
let oscillation = sin(oscillationTime * frequency) * exp(-oscillationTime * decay)
let displacement = amplitude * oscillation
```
This requires `TimelineView(.animation)` to drive frame-by-frame updates.

---

## Distance-Based Influence

Pattern used in `dots-interaction` and `bouncy-grid` — elements near a touch point respond proportionally:

```swift
private func computeInfluence(position: CGPoint, touch: CGPoint, radius: CGFloat) -> CGFloat {
    let distance = sqrt(pow(position.x - touch.x, 2) + pow(position.y - touch.y, 2))
    guard distance < radius else { return 0 }
    let normalized = distance / radius       // 0 at center, 1 at edge
    return 1.0 - normalized                  // strongest at center
}
```

For a softer falloff (cosine):
```swift
let deformFactor = (cos(normalizedDistance * .pi) + 1) / 2.0
```

---

## Haptic Feedback

### Rate-Limited Continuous Haptics
```swift
@State private var lastFeedbackTime: Date = .now
let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)

// In .onChanged:
if Date().timeIntervalSince(lastFeedbackTime) > 0.05 {   // 50ms minimum gap
    feedbackGenerator.impactOccurred(intensity: 0.8)
    lastFeedbackTime = .now
}

// Pre-warm on appear (eliminates first-fire latency)
.onAppear { feedbackGenerator.prepare() }
```

### Haptic on State Change
Fire on threshold crossing, not every frame:
```swift
if previousDetailLevel != currentDetailLevel {
    feedbackGenerator.impactOccurred(intensity: 0.7)
}
```

### Custom Haptics with CoreHaptics
For more expressive patterns (from `paper-navigation`):
```swift
import CoreHaptics

@State private var engine: CHHapticEngine?

func prepareHaptics() {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
    engine = try? CHHapticEngine()
    try? engine?.start()
}

func triggerHaptic() {
    let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
    let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
    let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
    if let pattern = try? CHHapticPattern(events: [event], parameters: []),
       let player = try? engine?.makePlayer(with: pattern) {
        try? player.start(atTime: 0)
    }
}
```

---

## 3D Tilt / Gyroscope

### rotation3DEffect on Drag (from `draggable-slider`)
```swift
@State private var knobDragOffset: CGSize = .zero

// Applied to the card/surface:
.rotation3DEffect(
    .degrees(Double(knobDragOffset.height / 15)),
    axis: (x: 1, y: 0, z: 0)
)
.rotation3DEffect(
    .degrees(Double(-knobDragOffset.width / 15)),
    axis: (x: 0, y: 1, z: 0)
)
.animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: knobDragOffset)
```

### CMMotionManager for Accelerometer Parallax (from `tilt-grid`)
```swift
import CoreMotion
private let motionManager = CMMotionManager()

func startMotionUpdates() {
    guard motionManager.isAccelerometerAvailable else { return }
    motionManager.accelerometerUpdateInterval = 0.03   // ~33fps
    motionManager.startAccelerometerUpdates(to: .main) { data, _ in
        guard let data else { return }
        
        // Non-linear response curve — more sensitive in center, linear at extremes
        let x = CGFloat(data.acceleration.x)
        let responsiveX = x.sign == .minus ? -pow(abs(x), 0.8) * 40 : pow(x, 0.8) * 40
        
        withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
            tiltOffset.x = responsiveX
        }
    }
}

func stopMotionUpdates() {
    motionManager.stopAccelerometerUpdates()
}
```

---

## UIKit Gestures in SwiftUI (for complex scroll effects)

When you need full UIScrollView control (cube transition, custom paging), use `UIViewControllerRepresentable`:

```swift
struct CubePageRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CubeViewController {
        CubeViewController()
    }
    func updateUIViewController(_ vc: CubeViewController, context: Context) {}
}
```

The cube-fold effect (from `swipe-interaction`) rotates each page around its edge:
```swift
// Dynamic anchor point — key to the cube effect
let anchorX: CGFloat = (contentOffset.x / frameWidth) > CGFloat(index) ? 1.0 : 0.0
setAnchorPoint(CGPoint(x: anchorX, y: 0.5), for: view)

// When changing anchorPoint, compensate position to avoid visual jump
var position = view.layer.position
position.x -= oldAnchorOffset.x - newAnchorOffset.x
view.layer.position = position
view.layer.anchorPoint = anchorPoint
```

---

## Long Press → Reveal Pattern (from `draggable-slider`)
```swift
.onLongPressGesture(minimumDuration: 0.2) {
    feedbackGenerator.impactOccurred()
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        showingSlider = true
    }
}
```

Dismiss on background tap, reset state after animation completes:
```swift
Color.black.opacity(0.3)
    .onTapGesture {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showingSlider = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sliderOffset = .zero  // reset after dismiss animation finishes
        }
    }
```
