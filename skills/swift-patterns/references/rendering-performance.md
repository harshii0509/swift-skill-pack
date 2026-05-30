# Rendering Performance

Distilled from Haptics `WaveDistortionView.swift` (CADisplayLink + mesh distortion), `ParticleItem.swift` (Metal GPU compute+render), and the ParticleDissolveEffect architecture.

---

## CADisplayLink: Frame-Synchronized Updates

For any animation that needs frame-precise control (physics simulation, custom rendering):

```swift
class AnimatedView: UIView {
    private var displayLink: CADisplayLink?
    private var previousTimestamp: CFTimeInterval = 0
    
    // Avoid retain cycles by using a target object
    private final class DisplayLinkTarget {
        private let callback: () -> Void
        init(callback: @escaping () -> Void) { self.callback = callback }
        @objc func tick() { callback() }
    }
    private var displayLinkTarget: DisplayLinkTarget?
    
    func startAnimating() {
        guard displayLink == nil else { return }
        
        let target = DisplayLinkTarget { [weak self] in self?.handleFrame() }
        displayLinkTarget = target
        
        let link = CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.tick))
        link.add(to: .main, forMode: .common)   // .common keeps running during scroll
        displayLink = link
    }
    
    func stopAnimating() {
        displayLink?.invalidate()
        displayLink = nil
        displayLinkTarget = nil
    }
    
    private func handleFrame() {
        let now = CACurrentMediaTime()
        // Cap delta to 10 frames to prevent huge jumps after backgrounding
        let delta = previousTimestamp > 0
            ? max(0, min(10.0/60.0, now - previousTimestamp))
            : 1.0/60.0
        previousTimestamp = now
        
        update(deltaTime: delta)
    }
    
    private func update(deltaTime: Double) {
        // Update physics/animation state using deltaTime
    }
    
    deinit {
        stopAnimating()   // critical — prevents timer leak
    }
}
```

**Key patterns:**
- Separate `DisplayLinkTarget` class breaks the strong reference cycle (`CADisplayLink` → `self`)
- Cap delta time to prevent physics explosions after the app backgrounds
- Use `.common` runloop mode so animation continues during `UIScrollView` scroll

---

## TimelineView: The SwiftUI Alternative to CADisplayLink

For SwiftUI prototypes and views that don't need UIKit:

```swift
// Continuous frame-rate animation
TimelineView(.animation) { timeline in
    let t = timeline.date.timeIntervalSinceReferenceDate
    
    Canvas { ctx, size in
        // Draw using `t` for animation state
    }
}

// Self-pacing — control the schedule based on animation state
@State private var isAnimating = true

TimelineView(isAnimating ? .animation : .animation(minimumInterval: 1)) { _ in
    // renders fast when animating, slow when idle
}
```

Source-backed rule of thumb:

- `adaptive text` can stay in ordinary SwiftUI transitions
- `reading light` needs `TimelineView` + `Canvas` because the effect is continuously recomputed
- `RouteVideoRenderer` needs a dedicated offscreen pipeline because it is exporting deterministic frames, not drawing live UI

---

## Metal Pipeline: The Minimal Pattern

For GPU-accelerated effects (particle systems, image processing):

```swift
import MetalKit

class MetalRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    
    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.commandQueue = queue
    }
    
    func render(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let buffer = commandQueue.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        // Set pipeline, buffers, draw calls here
        encoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            buffer.present(drawable)
        }
        buffer.commit()
    }
}
```

**The two-pass pattern** used in ParticleDissolveEffect:
1. **Compute pass** — physics update (velocity, position, lifetime) on GPU
2. **Render pass** — draw each particle at its current position

```swift
// Compute pass (physics)
let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
computeEncoder.setComputePipelineState(computePipeline)
computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
let gridSize = MTLSize(width: particleCount, height: 1, depth: 1)
let threadgroupSize = MTLSize(width: min(particleCount, pipeline.maxTotalThreadsPerThreadgroup), height: 1, depth: 1)
computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadgroupSize)
computeEncoder.endEncoding()

// Render pass (draw)
let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
renderEncoder.setRenderPipelineState(renderPipeline)
renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: particleCount * 6)
renderEncoder.endEncoding()
```

`RouteVideoRenderer` in `any-distance-ios` shows a practical production variant:

- snapshot scene content at a fixed time
- composite it over a background image
- render into a pixel buffer
- append to a video writer at fixed frame steps
- publish export progress as state

---

## Shared Metal Buffers (CPU ↔ GPU)

For particle data that both CPU (initialization) and GPU (physics) need:

```swift
// Shared storage mode — accessible from both CPU and GPU without copying
let buffer = device.makeBuffer(
    length: particleCount * MemoryLayout<Particle>.stride,
    options: .storageModeShared  // NOT .storageModePrivate (GPU-only)
)

// Initialize from CPU:
let particles = buffer!.contents().bindMemory(to: Particle.self, capacity: particleCount)
for i in 0..<particleCount {
    particles[i] = Particle(position: startPosition, velocity: randomVelocity)
}

// GPU reads and writes via compute shader
```

**Storage mode guide:**
- `.storageModeShared` — CPU + GPU both see same memory, no copy, works on Apple Silicon
- `.storageModePrivate` — GPU only, fastest for data that never goes back to CPU (render targets)
- `.storageModeManaged` (macOS) — copy between CPU/GPU, must call `didModifyRange` after CPU writes

## Offscreen Export Loop

For export features, prefer a deterministic frame loop over a display-linked loop:

```swift
var currentTime: TimeInterval = 0

while currentTime < animationDuration {
    let image = snapshot(at: currentTime, viewport: viewport)
    writer.append(buffer: image, at: CMTimeMakeWithSeconds(currentTime, preferredTimescale: 30000))
    currentTime += 1.0 / 30.0
}
```

This gives you reproducible output, fixed export fps, and simple progress reporting.

---

## Texture Loading with MTKTextureLoader

```swift
let textureLoader = MTKTextureLoader(device: device)

// From UIImage
let options: [MTKTextureLoader.Option: Any] = [
    .SRGB: false,                    // don't gamma-correct (for non-color data)
    .generateMipmaps: true           // auto-generate mip levels
]
let texture = try? textureLoader.newTexture(cgImage: uiImage.cgImage!, options: options)

// From asset catalog
let texture = try? textureLoader.newTexture(name: "myTexture", scaleFactor: 2.0, bundle: nil)
```

**Size rule:** Keep textures at power-of-2 dimensions (256×256, 512×512, 2048×2048) for GPU efficiency. Non-power-of-2 works but wastes memory.

---

## drawingGroup(): SwiftUI GPU Compositing

When SwiftUI renders 100+ overlapping transparent views, each has its own compositing pass. `drawingGroup()` collapses the whole subtree into one offscreen render:

```swift
// Without drawingGroup: N compositing passes
ZStack {
    ForEach(0..<1000) { i in
        Circle().fill(Color.white.opacity(0.1)).frame(width: 4, height: 4)
    }
}

// With drawingGroup: 1 compositing pass
ZStack {
    ForEach(0..<1000) { i in
        Circle().fill(Color.white.opacity(0.1)).frame(width: 4, height: 4)
    }
}
.drawingGroup()   // renders entire ZStack to an offscreen Metal texture
```

**Cost:** `drawingGroup()` creates a texture the size of the view — expensive for large views on older devices. Profile before adding blindly.

---

## IOSurface: Zero-Copy Metal → Core Animation

The ParticleDissolveEffect uses IOSurface to share Metal render targets directly with Core Animation (no texture copy):

```swift
// Create an IOSurface-backed texture
let surfaceProps: [IOSurfacePropertyKey: Any] = [
    .width: width,
    .height: height,
    .pixelFormat: kCVPixelFormatType_32BGRA,
    .bytesPerElement: 4,
]
let surface = IOSurface(properties: surfaceProps)!

let descriptor = MTLTextureDescriptor.texture2DDescriptor(
    pixelFormat: .bgra8Unorm,
    width: width, height: height,
    mipmapped: false
)
descriptor.usage = [.renderTarget, .shaderRead]
descriptor.storageMode = .shared

let texture = device.makeTexture(descriptor: descriptor, iosurface: surface, plane: 0)!

// Set as CALayer contents — zero copy
layer.contents = surface
```

This pattern is used when you need Metal to render into a layer that Core Animation composites.

---

## AsyncImage Downsampling (avoid GPU memory spikes)

Loading large images without downsampling fills GPU memory and causes hitches:

```swift
// Wrong — loads full resolution into GPU memory
AsyncImage(url: url) { image in
    image.resizable().scaledToFill()
}

// Right — downsample before uploading to GPU
func downsampledImage(at url: URL, to size: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
    let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height) * scale
    ]
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    else { return nil }
    return UIImage(cgImage: image)
}
```

For `AsyncImage` with downsampling, use `URLSession` + the above function in a `.task`, then display with `Image(uiImage:)`.

## Choose the Lightest Rendering Tier

Use the simplest tier that can support the effect:

1. SwiftUI implicit animation
2. `TimelineView` + `Canvas`
3. UIKit + `CADisplayLink`
4. SceneKit / Metal / export pipeline

Escalate only when the lower tier cannot express the behavior or performance target cleanly.
