# Custom Rendering

Distilled from: `particle-text` (SpriteKit+CoreText), `waves` (SceneKit), `blob-animation` (CAShapeLayer+CADisplayLink), `dots-interaction` (Canvas-equivalent), `bouncy-grid` (Path in TimelineView)

---

## Rendering API Decision Guide

| Need | Use | Why |
|---|---|---|
| Custom 2D shapes, paths, compositing | `Canvas` or `Path` in SwiftUI | Zero overhead, stays in render tree |
| 2D physics simulation, sprites, particles | `SpriteKit` via `SpriteView` | Physics engine + action system built in |
| 3D objects, scenes, lighting | `SceneKit` via `SceneView` | Full scene graph, materials, lighting |
| GPU compute, custom shaders, high-performance particles | `Metal` (UIViewRepresentable) | Direct GPU access |
| Animated blob/mesh, no GPU | `CAShapeLayer` + `CADisplayLink` | Simple, fast for < 1000 points |
| Deform existing UIKit views with ripple | Custom `UIView` with mesh | Best for image/view distortion |

---

## Path-Based Drawing in SwiftUI (Body-Driven)

For shapes that re-draw every frame, use `TimelineView` with a `Path`:

```swift
TimelineView(.animation) { context in
    let elapsed = context.date.timeIntervalSinceReferenceDate
    
    Path { path in
        // Build path using `elapsed` for time-based animation
        path.move(to: startPoint)
        // ...quad curves, lines, etc.
    }
    .stroke(Color.white, lineWidth: 1)
}
```

For a custom `Shape` with animated properties, conform to `Shape` + `Animatable`:
```swift
struct WaveShape: Shape {
    var phase: CGFloat
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    func path(in rect: CGRect) -> Path { ... }
}
```

---

## Canvas API for High-Performance 2D

`Canvas` draws imperatively without creating child views — much faster for many elements (dots, grids, particles):

```swift
Canvas { context, size in
    for dot in dots {
        let rect = CGRect(center: dot.position, size: CGSize(width: 6, height: 6))
        context.fill(Circle().path(in: rect), with: .color(.white))
    }
}
.gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
    .onChanged { value in
        touchLocation = value.location
    }
)
```

`Canvas` redraws when any `@State` it reads changes — same trigger model as `body`.

---

## SpriteKit in SwiftUI

```swift
import SpriteKit

// 1. Create the scene
let scene: MyScene = {
    let s = MyScene()
    s.scaleMode = .resizeFill
    s.backgroundColor = .clear    // transparent over SwiftUI content
    return s
}()

// 2. Embed with SpriteView
SpriteView(scene: scene, options: [.allowsTransparency])
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .allowsHitTesting(false)    // pass-through for gesture to underlying views

// 3. Scene class
class MyScene: SKScene {
    override func didMove(to view: SKView) {
        // set up nodes
    }
    
    // Forward SwiftUI gesture to scene
    func handleTouch(at point: CGPoint) {
        let scenePoint = convertPoint(fromView: point)
        // interact with nodes
    }
}
```

**Core Text glyph path sampling** (particle-text pattern — extract glyph outlines for any font):
```swift
let font = UIFont.systemFont(ofSize: 80, weight: .heavy)
let attrString = NSAttributedString(string: "Hello", attributes: [.font: font])
let line = CTLineCreateWithAttributedString(attrString)
let runs = CTLineGetGlyphRuns(line) as! [CTRun]

let path = CGMutablePath()
let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
let xOffset = (sceneSize.width - bounds.width) / 2
let yOffset = (sceneSize.height - bounds.height) / 2

for run in runs {
    let count = CTRunGetGlyphCount(run)
    let glyphs = UnsafeMutablePointer<CGGlyph>.allocate(capacity: count)
    let positions = UnsafeMutablePointer<CGPoint>.allocate(capacity: count)
    CTRunGetGlyphs(run, CFRange(), glyphs)
    CTRunGetPositions(run, CFRange(), positions)
    
    for i in 0..<count {
        if let letterPath = CTFontCreatePathForGlyph(font, glyphs[i], nil) {
            let transform = CGAffineTransform(translationX: positions[i].x + xOffset, y: yOffset)
            path.addPath(letterPath, transform: transform)
        }
    }
    glyphs.deallocate(); positions.deallocate()
}

// Sample points inside the glyph outlines
for x in stride(from: path.boundingBox.minX, through: path.boundingBox.maxX, by: 3) {
    for y in stride(from: path.boundingBox.minY, through: path.boundingBox.maxY, by: 3) {
        if path.contains(CGPoint(x: x, y: y)) {
            targetPositions.append(CGPoint(x: x, y: y))
        }
    }
}
```

**SpriteKit action patterns:**
```swift
// Move to position with easing
let move = SKAction.move(to: targetPosition, duration: 2.0)
move.timingMode = .easeOut
particle.run(move)

// Group (parallel) vs Sequence (sequential)
particle.run(SKAction.group([move, scale]))
particle.run(SKAction.sequence([wait, move]))

// Explosion force away from point
let dx = particle.position.x - touchPoint.x
let dy = particle.position.y - touchPoint.y
let distance = hypot(dx, dy)
let force = max(0, 1000 - distance) / distance
let angle = atan2(dy, dx)
let impulse = CGVector(dx: cos(angle) * force, dy: sin(angle) * force)
particle.run(SKAction.move(by: impulse, duration: 0.3))
```

---

## SceneKit in SwiftUI

```swift
import SceneKit

struct SceneKitView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        
        // Create geometry
        let sphere = SCNSphere(radius: 8)
        sphere.segmentCount = 40
        
        // Material with wireframe
        let material = SCNMaterial()
        material.fillMode = .lines
        material.diffuse.contents = UIColor.cyan
        material.emission.contents = UIColor.cyan.withAlphaComponent(0.5)
        sphere.materials = [material]
        
        let sphereNode = SCNNode(geometry: sphere)
        sceneView.scene?.rootNode.addChildNode(sphereNode)
        
        // Continuous rotation
        let rotation = CABasicAnimation(keyPath: "rotation")
        rotation.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
        rotation.duration = 12
        rotation.repeatCount = .infinity
        sphereNode.addAnimation(rotation, forKey: "rotate")
        
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 25)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}
```

---

## CAShapeLayer + CADisplayLink (Blob Pattern)

For particle/blob effects that need per-frame CPU control but don't need GPU compute:

```swift
class MetalView: UIView {
    private var displayLink: CADisplayLink?
    private let shapeLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        shapeLayer.fillColor = UIColor.white.cgColor
        layer.addSublayer(shapeLayer)
        
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .current, forMode: .default)
    }
    
    @objc private func update() {
        // 1. Compute new positions
        updatePhysics()
        
        // 2. Build path
        let path = UIBezierPath()
        path.move(to: points[0])
        for i in 0..<points.count {
            let p1 = points[i]
            let p2 = points[(i+1) % points.count]
            let p3 = points[(i+2) % points.count]
            let mid1 = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
            let mid2 = CGPoint(x: (p2.x + p3.x) / 2, y: (p2.y + p3.y) / 2)
            path.addQuadCurve(to: mid2, controlPoint: p2)
        }
        path.close()
        
        // 3. Update layer (no animation block needed — displayLink drives it)
        shapeLayer.path = path.cgPath
    }
    
    deinit {
        displayLink?.invalidate()   // critical — prevents retain cycle
    }
}
```

---

## drawingGroup() for Complex SwiftUI Compositing

When a SwiftUI subtree has many overlapping transparent elements, `drawingGroup()` offscreen-renders it and composites as a single layer:

```swift
ZStack {
    ForEach(particles) { p in
        Circle()
            .fill(p.color.opacity(p.alpha))
            .frame(width: 4, height: 4)
            .position(p.position)
    }
}
.drawingGroup()   // flattens 1000 circles into one GPU draw call
```

**When to use:** 100+ overlapping views with opacity/blending.  
**When not to use:** Views that need individual hit testing or accessibility.

---

## Geometry-Based Scale in ScrollView

Scale items by distance from screen center (from `tilt-grid`):
```swift
private func scale(for geometry: GeometryProxy) -> CGFloat {
    let frame = geometry.frame(in: .global)
    let center = CGPoint(x: UIScreen.main.bounds.width / 2,
                        y: UIScreen.main.bounds.height / 2)
    let distance = sqrt(pow(frame.midX - center.x, 2) + pow(frame.midY - center.y, 2))
    return max(0.7, 1.0 - min(distance / 500, 0.3))
}

// Usage inside the cell:
GeometryReader { geo in
    CardView()
        .scaleEffect(scale(for: geo))
}
.frame(width: 200, height: 300)
```

Note: `geometry.frame(in: .global)` is accurate only inside `ScrollView` — it updates on scroll.
