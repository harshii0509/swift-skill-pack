# Animation Craft

Distilled from: `waves`, `blob-animation`, `bouncy-grid`, `tilt-grid`, `draggable-slider`, `particle-text`, `dots-interaction`

---

## Choosing the Right Curve

| Use case | Curve | Why |
|---|---|---|
| Element appearing | `.spring(response: 0.4, dampingFraction: 0.8)` | Overshoots slightly, feels alive |
| Snap-back after gesture | `.interpolatingSpring(mass: 0.6, stiffness: 120, damping: 10)` | Physically accurate release |
| Content transitions | `.easeInOut(duration: 0.25)` | Predictable, no overshoot |
| Interactive (follows finger) | `.interactiveSpring(response: 0.3, dampingFraction: 0.7)` | Low latency response |
| Dismiss/collapse | `.spring(response: 0.3, dampingFraction: 1.0)` | Critically damped, no bounce |
| Staggered list items | `.spring(response: 0.5).delay(Double(index) * 0.05)` | Progressive reveal |
| Rotation animation (CABasicAnimation) | `duration: 12, repeatCount: .infinity` | Smooth loop |

**Never use `.linear` for UI elements** — it feels mechanical and unnatural.

---

## Animating Custom Shapes (animatableData)

A `Shape` can smoothly interpolate between states by conforming to `Animatable`:

```swift
struct WaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    var pressDepth: CGFloat         // the animated property

    // Tells SwiftUI which value to interpolate
    var animatableData: CGFloat {
        get { pressDepth }
        set { pressDepth = newValue }
    }

    func path(in rect: CGRect) -> Path {
        // build path using pressDepth...
    }
}

// Trigger the animation:
withAnimation(.interpolatingSpring(mass: 0.6, stiffness: 120, damping: 10)) {
    pressDepth = 0
}
```

For two animated properties, use `AnimatablePair<CGFloat, CGFloat>`.

---

## Superimposed Sine Waves (organic motion)

A single sine wave looks mechanical. Combine three with different frequencies for organic feel (from `waves`):

```swift
func complexWave(x: CGFloat, phase: CGFloat, frequency: CGFloat) -> CGFloat {
    let primary   = sin(2 * .pi * frequency * x + phase)
    let secondary = sin(2 * .pi * frequency * 2.3 * x + phase * 1.5) * 0.3
    let tertiary  = sin(2 * .pi * frequency * 0.7 * x + phase * 0.8) * 0.2
    return primary + secondary + tertiary
}
```

Advance `phase` each frame to animate:
```swift
// Timer-driven phase advance (60fps)
let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
.onReceive(timer) { _ in phase += 0.015 }
```

---

## Blob / Spring-Particle Physics (CADisplayLink)

For physically simulated blobs, each point has position + velocity. Update every frame (from `blob-animation`):

```swift
// Spring back to rest position + noise + ripple forces
let fx = (restX - point.x) * springStrength + noiseX
let fy = (restY - point.y) * springStrength + noiseY
velocity.x = velocity.x * damping + fx    // damping: 0.95
velocity.y = velocity.y * damping + fy
point.x += velocity.x
point.y += velocity.y
```

Smooth the outline with quadratic Bézier curves through midpoints:
```swift
let cp1 = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
let cp2 = CGPoint(x: (p2.x + p3.x) / 2, y: (p2.y + p3.y) / 2)
path.addQuadCurve(to: cp2, controlPoint: p2)
```

Autonomous noise to keep it moving without touch:
```swift
let time: Double   // incremented each frame by += 0.016
let noiseX = sin(CGFloat(-time * 2 + Double(i) * 0.1)) * 0.3
let noiseY = cos(CGFloat(-time * 2 + Double(i) * 0.1)) * 0.3
```

---

## TimelineView for Animation-Clocked Rendering

`TimelineView` is the SwiftUI-native alternative to CADisplayLink:

```swift
// Drives re-render every display frame
TimelineView(.animation) { context in
    // context.date changes each frame
    let elapsed = context.date.timeIntervalSinceReferenceDate
    Path { path in
        // use elapsed to compute current animation state
    }
    .stroke(Color.white, lineWidth: 2)
}
```

Use `TimelineView(.animation(minimumInterval: 1/30))` to cap at 30fps for less intensive animations.

Stop rendering when idle by switching to a paused schedule:
```swift
@State private var isAnimating = false
TimelineView(isAnimating ? .animation : .pausable(isPaused: true)) { _ in ... }
```

---

## Damped Oscillation on Release

The bouncy-grid achieves a physically-satisfying snap-back by manually computing damped oscillation in TimelineView:

```swift
// Phase 1: Quick return to rest (first 0.15s)
let returnProgress = timeSinceRelease / 0.15
let easedProgress = sin(returnProgress * .pi / 2)
displacement = -initialDisplacement * (1.0 - easedProgress)

// Phase 2: Oscillation (0.15s – 0.95s)
let t = (timeSinceRelease - 0.15) / 0.8
let oscillation = sin(t * 22.0) * exp(-t * 3.5)   // frequency=22, decay=3.5
displacement = amplitude * oscillation * distanceFactor
```

The formula `sin(ωt) * e^(-γt)` is the standard damped oscillation. Tune:
- `ω` (frequency): higher = faster oscillation
- `γ` (decay): higher = faster damping

---

## Custom Transitions (ViewModifier)

Custom entry/exit transitions using `AnyTransition` (from `draggable-slider`):

```swift
extension AnyTransition {
    static var vaporize: AnyTransition {
        .modifier(
            active: VaporizeModifier(progress: 1),    // exit state
            identity: VaporizeModifier(progress: 0)   // resting state
        )
    }
}

struct VaporizeModifier: ViewModifier {
    let progress: CGFloat
    func body(content: Content) -> some View {
        content
            .scaleEffect(1 + (progress * 0.5))   // grows as it fades
            .opacity(1 - progress)
    }
}

// Usage: asymmetric — different in vs out
.transition(.asymmetric(
    insertion: .opacity.combined(with: .offset(y: 20)),
    removal: .vaporize.combined(with: .opacity)
))
```

---

## Staggered Animations

Animate a list of items with sequential delay:
```swift
ForEach(items.indices, id: \.self) { index in
    ItemView(item: items[index])
        .animation(
            .spring(response: 0.5, dampingFraction: 0.75)
            .delay(Double(index) * 0.06),
            value: isVisible
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
}
```

---

## Color Interpolation

Linear interpolation between two SwiftUI Colors (from `draggable-slider`):
```swift
extension Color {
    func interpolated(to other: Color, amount: CGFloat) -> Color {
        let t = min(max(amount, 0), 1)
        let from = UIColor(self)
        let to = UIColor(other)
        return Color(
            red:   from.r * (1 - t) + to.r * t,
            green: from.g * (1 - t) + to.g * t,
            blue:  from.b * (1 - t) + to.b * t,
            opacity: from.a * (1 - t) + to.a * t
        )
    }
}
```

---

## CABasicAnimation for Looping Rotation
```swift
let rotation = CABasicAnimation(keyPath: "rotation")
rotation.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
rotation.duration = 12
rotation.repeatCount = .infinity
node.addAnimation(rotation, forKey: "rotate")
```

For color animation:
```swift
let colorAnim = CABasicAnimation(keyPath: "fillColor")
colorAnim.fromValue = layer.fillColor
colorAnim.toValue = UIColor(white: 0.95, alpha: 1).cgColor
colorAnim.duration = 0.1
colorAnim.isRemovedOnCompletion = false
colorAnim.fillMode = .forwards
layer.add(colorAnim, forKey: "color")
```
